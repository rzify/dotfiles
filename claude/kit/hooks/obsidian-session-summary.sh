#!/bin/bash
set -u

[ -n "${CLAUDE_SUMMARY_IN_PROGRESS:-}" ] && exit 0

INPUT=$(cat)
TP=$(echo "$INPUT" | jq -r '.transcript_path // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[ -z "$TP" ] && exit 0
[ ! -f "$TP" ] && exit 0

LINES=$(wc -l < "$TP" | tr -d ' ')
[ "${LINES:-0}" -lt 4 ] && exit 0

VAULT_ROOT="$HOME/Documents/rz-notes/claude-sessions"
PENDING_DIR="$HOME/.claude/pending-memory-updates"
LOG_FILE="$HOME/.claude/memory-updates-log.md"

# Detect if CWD is a development project
if [ -n "$CWD" ] && [ "$CWD" != "$HOME" ]; then
  case "$CWD" in
    "$HOME/Development/personal"/*|"$HOME/Development/enterprise"/*)
      REL="${CWD#$HOME/Development/}"
      SCOPE="${REL%%/*}"
      REST="${REL#*/}"
      PROJECT="${REST%%/*}"
      [ -n "$PROJECT" ] && SUBFOLDER="Projects/$SCOPE/$PROJECT"
      ;;
  esac
fi

DATE=$(date +%Y-%m-%d)
TIME=$(date +%H%M)

CATEGORIES="devops, frontend, backend, database, ai-ml, marketing, seo, content, business, finance, learning, config-tooling, debugging, research, personal, other"

# ---------- STEP 1: Session summary ----------

SUMMARY_PROMPT='Read this Claude Code session transcript (JSONL, one message per line) and write an Obsidian-friendly markdown summary.

Format exactly:
---
date: '"$DATE"'
category: <one of: '"$CATEGORIES"'>
tags: [claude-code, <1-3 relevant topic tags, kebab-case, no # prefix>]
---

# <short topic, 3-8 words>

## Summary
<2-4 sentence overview of what was discussed>

## Key points
- <bullet>
- <bullet>
(3-7 bullets, decisions made, findings, conclusions)

## Files touched
- `path/to/file` — what changed
(omit section if no files were edited)

Rules:
- Pick exactly one category from the list — do not invent new ones.
- Keep under 350 words.
- No preamble, no code fences around the whole output.
- Use [[wikilinks]] for concepts that deserve their own note.

Transcript:
'

TRANSCRIPT=$(cat "$TP")
SUMMARY=$(CLAUDE_SUMMARY_IN_PROGRESS=1 claude -p "$SUMMARY_PROMPT$TRANSCRIPT" 2>/dev/null)
[ -z "$SUMMARY" ] && exit 0

TITLE=$(echo "$SUMMARY" | grep -m1 '^# ' | sed 's/^# *//' | tr '/:' '--' | cut -c1-60 | sed 's/ *$//')
[ -z "$TITLE" ] && TITLE="session"

CATEGORY=$(echo "$SUMMARY" | awk '/^---$/{f++; next} f==1 && /^category:/{sub(/^category:[[:space:]]*/,""); print; exit}' | tr -d '"' | tr -d "'" | sed 's/[^a-z0-9-]//g')
[ -z "$CATEGORY" ] && CATEGORY="other"

if [ -n "${SUBFOLDER:-}" ]; then
  OUTDIR="$VAULT_ROOT/$SUBFOLDER"
else
  OUTDIR="$VAULT_ROOT/Topics/$CATEGORY"
fi

mkdir -p "$OUTDIR"
SUMMARY_FILE="$OUTDIR/$DATE-$TIME-$TITLE.md"
echo "$SUMMARY" > "$SUMMARY_FILE"

# ---------- STEP 2: Auto-apply CLAUDE.md patches ----------

APPLY_RESULT=""

if [ -z "${CLAUDE_DISABLE_AUTO_APPLY:-}" ]; then

  CLAUDE_FILES_CONTEXT=""
  for f in "$HOME/.claude/CLAUDE.md" \
           "$HOME/Documents/CLAUDE.md" \
           "$HOME/Development/personal/CLAUDE.md" \
           "$HOME/Development/enterprise/CLAUDE.md"; do
    if [ -f "$f" ]; then
      CLAUDE_FILES_CONTEXT="$CLAUDE_FILES_CONTEXT

===== FILE: $f =====
$(cat "$f")
===== END =====
"
    fi
  done

  PATCH_PROMPT='You review a Claude Code session transcript and emit JSON patches to apply to the user'\''s CLAUDE.md files. These patches are AUTO-APPLIED — be conservative.

Current CLAUDE.md contents:
'"$CLAUDE_FILES_CONTEXT"'

Session transcript:
'"$TRANSCRIPT"'

Rules for proposing a patch:
- Only propose when the session revealed durable info worth baking in: stated preferences, stack/tool choices, new/updated project facts, identity/convention updates, corrections.
- Do NOT propose for: one-off task details, debugging traces, ephemeral state, anything already present (even approximately) in the files.
- Route correctly:
  - '"$HOME"'/.claude/CLAUDE.md → universal prefs
  - '"$HOME"'/Documents/CLAUDE.md → personal/non-code (notes, fitness, finance, admin)
  - '"$HOME"'/Development/personal/CLAUDE.md → RzLabs dev work
  - '"$HOME"'/Development/enterprise/CLAUDE.md → Hypnotic dev work
- If unsure, DO NOT propose. Under-proposing is safer than over-proposing — you are auto-applying.

Actions:
- "replace": exact string replacement. `find` MUST appear exactly once in the file. Include enough surrounding context to be unique. Prefer this over append when updating an existing line/section.
- "append": append content to end of file. Use for genuinely new sections only.

Output ONE of:

(a) If nothing durable was revealed:
NO_PATCHES

(b) Otherwise, ONLY a JSON object (no code fences, no preamble, no trailing prose):
{
  "summary": "<one-line human description of what you are changing and why>",
  "patches": [
    {
      "file": "<absolute path from the whitelist above>",
      "action": "replace",
      "find": "<exact unique string from the current file>",
      "replace": "<new string>",
      "why": "<one short sentence>"
    },
    {
      "file": "<absolute path>",
      "action": "append",
      "content": "<markdown to append, starting with a heading if it is a new section>",
      "why": "<one short sentence>"
    }
  ]
}

Keep patches minimal. Prefer fewer, higher-signal patches over many marginal ones. Do not edit files outside the whitelist.
'

  RAW=$(CLAUDE_SUMMARY_IN_PROGRESS=1 claude -p "$PATCH_PROMPT" 2>/dev/null)

  if [ -n "$RAW" ] && ! echo "$RAW" | grep -qx "NO_PATCHES"; then
    # Try to extract JSON — strip leading/trailing non-JSON if present.
    JSON=$(echo "$RAW" | awk '/^\{/{found=1} found{print}' | awk 'BEGIN{depth=0} {
      for(i=1;i<=length($0);i++){
        c=substr($0,i,1);
        if(c=="{")depth++;
        if(c=="}")depth--;
      }
      print;
      if(depth==0 && NR>1) exit;
    }')

    if [ -n "$JSON" ] && echo "$JSON" | python3 -c "import json,sys; json.loads(sys.stdin.read())" 2>/dev/null; then
      mkdir -p "$PENDING_DIR"
      JSON_FILE="$PENDING_DIR/$DATE-$TIME-$TITLE.json"
      BACKUP_DIR="$PENDING_DIR/backups/$DATE-$TIME"
      echo "$JSON" > "$JSON_FILE"
      APPLY_RESULT=$(python3 "$HOME/.claude/hooks/apply-claude-md-patches.py" \
        "$JSON_FILE" "$DATE $TIME" "$LOG_FILE" "$BACKUP_DIR" 2>&1)
    fi
  fi
fi

# ---------- Output ----------

if [ -n "$APPLY_RESULT" ]; then
  MSG="Resumo: $SUMMARY_FILE | CLAUDE.md: $APPLY_RESULT (log: $LOG_FILE)"
else
  MSG="Resumo: $SUMMARY_FILE"
fi

# Escape for JSON output
MSG_ESCAPED=$(echo "$MSG" | python3 -c "import json,sys; print(json.dumps(sys.stdin.read().strip()))")
echo "{\"systemMessage\": $MSG_ESCAPED}"
