#!/usr/bin/env python3
"""
Apply JSON patches to CLAUDE.md files. Called by the SessionEnd hook.

Invoked as:
  apply-claude-md-patches.py <patches.json> <timestamp> <log_file> <backup_dir>

Safety:
- Only `replace` and `append` actions. No `remove`, no overwriting whole files.
- `replace` requires exact unique match. Ambiguous / missing → skipped.
- Every modified file is backed up before first modification in this run.
- All applied and skipped patches are logged to the audit log.
"""
import json
import os
import shutil
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 5:
        print("usage: apply-claude-md-patches.py <patches.json> <timestamp> <log> <backup_dir>", file=sys.stderr)
        return 2

    patches_path, timestamp, log_file, backup_dir = sys.argv[1:]

    try:
        data = json.loads(Path(patches_path).read_text())
    except Exception as e:
        print(f"parse error: {e}", file=sys.stderr)
        return 1

    patches = data.get("patches", [])
    summary = data.get("summary", "")

    applied = []
    skipped = []
    backed_up: set[str] = set()

    os.makedirs(backup_dir, exist_ok=True)

    # Whitelist of files we're willing to touch. Prevents the LLM from
    # proposing patches against arbitrary paths.
    home = os.path.expanduser("~")
    allowed = {
        f"{home}/.claude/CLAUDE.md",
        f"{home}/Documents/CLAUDE.md",
        f"{home}/Development/personal/CLAUDE.md",
        f"{home}/Development/enterprise/CLAUDE.md",
    }

    for p in patches:
        file = p.get("file", "")
        action = p.get("action", "")

        if file not in allowed:
            skipped.append((p, f"file not in whitelist: {file}"))
            continue

        try:
            if file not in backed_up and os.path.exists(file):
                safe = file.lstrip("/").replace("/", "_")
                shutil.copy2(file, os.path.join(backup_dir, f"{safe}.bak"))
                backed_up.add(file)

            if action == "replace":
                if not os.path.exists(file):
                    skipped.append((p, "file does not exist"))
                    continue
                find = p.get("find", "")
                replace = p.get("replace", "")
                if not find:
                    skipped.append((p, "empty find string"))
                    continue
                text = Path(file).read_text()
                count = text.count(find)
                if count == 0:
                    skipped.append((p, "find string not found"))
                    continue
                if count > 1:
                    skipped.append((p, f"find string ambiguous ({count} matches)"))
                    continue
                Path(file).write_text(text.replace(find, replace, 1))
                applied.append(p)

            elif action == "append":
                content = p.get("content", "")
                if not content.strip():
                    skipped.append((p, "empty content"))
                    continue
                Path(file).parent.mkdir(parents=True, exist_ok=True)
                existing = Path(file).read_text() if os.path.exists(file) else ""
                sep = "" if existing.endswith("\n\n") else ("\n" if existing.endswith("\n") else "\n\n")
                tail = "" if content.endswith("\n") else "\n"
                with open(file, "a") as f:
                    f.write(f"{sep}{content}{tail}")
                applied.append(p)

            else:
                skipped.append((p, f"unknown action: {action}"))

        except Exception as e:
            skipped.append((p, f"error: {e}"))

    # Append to audit log
    os.makedirs(os.path.dirname(log_file), exist_ok=True)
    with open(log_file, "a") as f:
        f.write(f"\n## {timestamp}\n\n")
        if summary:
            f.write(f"{summary}\n\n")
        if applied:
            f.write("### Applied\n")
            for p in applied:
                f.write(f"- `{p.get('file')}` — **{p.get('action')}** — {p.get('why', '')}\n")
            f.write("\n")
        if skipped:
            f.write("### Skipped\n")
            for p, reason in skipped:
                f.write(f"- `{p.get('file', '?')}` — {p.get('action', '?')} — {reason}\n")
            f.write("\n")
        if not applied and not skipped:
            f.write("_no patches proposed_\n\n")

    print(f"applied={len(applied)} skipped={len(skipped)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
