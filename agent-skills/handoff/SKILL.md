---
name: handoff
description: Write a handoff prompt that lets a fresh chat continue this conversation's work without losing context. Use when the user says handoff, refresh, "pass this to a new chat", "continua noutro chat", or when the conversation is getting very long and the user wants to start over cleanly.
---

# Handoff

Write a handoff prompt the user can paste into a brand-new chat so that chat continues the work exactly where this one stands.

The reader starts with an empty context. It cannot see this chat. It does load its own standing instructions by itself (AGENTS.md / CLAUDE.md for a coding agent, Project instructions and files in a chat app), so do not repeat those.

In a coding agent, start the handoff with the working directory (`Continue work in <path>.`) and list file paths under "Files and sources"; the next session can open them itself.

## How to do it

1. Reread the whole conversation, from the first message to now.
2. Write the handoff in the shape below. Leave out any section that has nothing in it.
3. Put the whole handoff inside one fenced code block (```markdown) so the user can copy it in one click.
4. After the block, add one line telling the user to open a new chat or session (in the same Project or folder, if they are in one) and paste it as the first message. Match the user's language for that line.

Write the handoff in the language the user has been writing in. Plain, short sentences. Under 1,500 words.

## Shape

```
# Handoff: <the goal, in a few words>

Goal: <what the user is working toward right now>.

## What the user asked for
Every request in this chat, in order, with the user's own key words. Mark each one: done, in progress, or not started.

## Where things stand
What is done and checked, the key decisions and why, and what was tested and what was not.

## Rules the user set
Standing constraints and preferences given in this chat: words to avoid, things never to do, approval steps, tone.

## Files and sources
- <file name, link or attachment>: why it matters, in one line. Say which ones the user must re-attach in the new chat. Never copy file content.

## Tools and connectors
- <connector, tool or skill>: when to use it, and any trap found in this chat.

## Errors already solved
- <the error>: <the fix>. So the next chat does not hit them again.

## Carried-over data
Only data that exists nowhere else: ids, URLs, numbers, names, drafts and decisions that live only in this chat. Verbatim.

## Next steps
1. The very next action, specific enough to start without asking a question.
```

## Rules

- Never write an API key, token or password. Write where it lives instead (for example "in the Stripe dashboard").
- Drafts or final text the user approved go in "Carried-over data" verbatim, not summarised.
- Do not invent progress. If something was discussed but not confirmed, say so.
