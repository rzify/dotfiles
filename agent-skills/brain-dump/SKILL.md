---
name: brain-dump
description: Shape a long, loose, rambling message (a voice-note style brain dump) into a clear four-part brief (the job, the why, the guardrails, done means) before doing the work. Use when the user's message is long and unstructured (roughly 120+ words of stream of thought), or when they say brain dump, "shape this", "organiza isto", "turn this into a brief", or "/shape".
---

# Brain dump to brief

The user sent a long, loose message. Before doing the work, turn it into a clear brief they can check.

## Step 1: offer (only when not asked explicitly)

If the user did not ask for shaping and the message is a long, unstructured dump, ask in one line whether to shape it into a brief first or go ahead as is (match the user's language). If they say go ahead, do the work normally and stop using this skill.

If they asked for it ("shape this", "brain dump", "/shape"), skip the offer.

## Step 2: look for real gaps

Read the dump for real gaps only:
- two instructions that contradict each other, or
- a must-know fact that is missing and would change the work (who it is for, the deadline, the format, which source to use).

Ask 0 to 3 questions, fewer is better. Zero when the dump is clear. Never ask about something the dump already answers, or about style and nice-to-haves. For a conflict, name both sides and offer each as an option. Give each question 2 or 3 short options (1 to 5 words) taken from the dump where possible; the user can also answer in their own words.

Ask them all in a single message, then wait. If the user skips a question, treat it as "unknown: ask me".

## Step 3: write the brief

Output exactly this shape inside one fenced code block, nothing else in the block:

```
THE JOB
<one or two lines: what to make or do>

THE WHY
<who it is for and what it is used for>

THE GUARDRAILS
- <rules, limits, things to avoid, sources to use>

DONE MEANS
- <how we know it is finished and right>
```

Rules:
- Keep every fact, name, number, date, link, file and tool from the dump. Drop only filler and repeats.
- Add no new facts, numbers, names or requirements that are not in the dump or in the user's answers.
- Where the dump says nothing for a part, write "unknown: ask me" for that part.
- Write in the user's voice (I, we, my), as if they wrote it themselves, and in the language of the dump. The four headings stay in English.
- Plain, short lines and bullets.
- Never use em dashes or en dashes. Never use the word "ship"; say publish or deliver instead.

## Step 4: confirm, then work

After the block, ask in one line whether the brief is right or needs changes. When the user confirms, do the work following the brief.
