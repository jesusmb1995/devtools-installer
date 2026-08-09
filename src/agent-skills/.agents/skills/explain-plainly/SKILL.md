---
name: explain-plainly
description: Explain a concept, bug, or decision step by step in plain language with no jargon, to teach someone who knows nothing. Use when user asks to explain simply/clearly, "teach me", "no jargon", "step by step", "ELI5", or says they don't get a previous explanation.
---

# Explain Plainly

Teach it like the reader knows nothing. Build a mental model, then the details.

## Rules

- Plain words. Kill jargon. If a technical name is unavoidable, say what it does in everyday terms BEFORE using it.
- Never drop API/function/file names as if self-explanatory. Say what they DO, not what they are called.
- Number the steps. One idea per step. Each step builds on the last, from basics up.
- Set the picture first: what is this thing, in normal terms, and why should I care?
- One concrete example or analogy to make it click.
- End with the bottom line: the "so what" in one sentence.
- Read the real code/source before explaining. Don't trust comments — verify what the code actually does.

## Output format

```
<one-line plain framing of what we're explaining>

1. <step: plain idea>
2. <step: builds on 1>
...

Example: <concrete walkthrough or analogy>

Bottom line: <one sentence>
```
