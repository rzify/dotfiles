---
name: reflect
description: When the user corrects the assistant ("no", "don't", "never", "stop", "too long", "I said...", "instead", "não faças", "já disse", "demasiado longo"), turn the correction into one lasting, general rule and offer to keep it in the agent's persistent instructions (AGENTS.md / CLAUDE.md, or personal preferences / Project instructions in a chat app). Also use when the user says reflect, "remember this rule", or "save this as a rule".
---

# Reflect

When the user corrects you, capture the lesson as a rule they can keep for every future chat.

## When it applies

The user's message corrects your last reply: tells you something was wrong, too long, in the wrong tone, used something they don't want, or repeats an instruction you ignored.

It does not apply when the fix is a one-off for this task only (for example "change the date to Tuesday"). In that case just apply the fix and say nothing about rules.

## What to do

1. Apply the correction first and give the fixed answer. The rule never replaces the fix.
2. At the end of that reply, add a short block, in the user's language:

   > **Rule to save:** <the rule>
   >
   > Want me to save it, or adjust it first?

   Where it goes depends on where you run:
   - **Coding agent with file access** (Claude Code, Codex, Cursor): offer to append it under a `## Rules from corrections` heading in the project's `AGENTS.md` or `CLAUDE.md`, or in the user-level one for rules that apply everywhere. Write only after the user says yes.
   - **Chat app without file access** (claude.ai): the user saves it in Settings → Profile → personal preferences (every chat) or in the Project instructions (that Project only).

## Rules for the rule

- One line, plain imperative, under 20 words. Example: "Never use em dashes in newsletter copy."
- General enough to apply next time, specific enough to act on. Name the kind of work it applies to when that matters.
- Write it in the language the user writes in.
- No em dashes. Never use the word "ship".
- Offer at most one rule per correction.

## If the user says "save it" or "remember"

With file access, append the rule where the user chose, skip it if an equivalent rule is already there, and confirm the file path in one line.

Without file access, say in one line that you cannot write to their settings, and repeat the final rule in a code block so they can copy it straight into their preferences or Project instructions.
