---
name: investigate
description: Run a deep investigation of the given question and store the findings in a file (.md or similar). No code changes — analysis only. Use when the user writes /investigate.
---

# Investigate

Go deep on one question, then leave the findings in a file the user can keep.

## Trigger

User writes `/investigate <question> [output file]`.

## Procedure

1. Fix the scope first: what is in, what is out. One or two lines.
2. Gather evidence: read code, run read-only commands, follow every lead worth following. State each hypothesis and what the evidence says about it.
3. Write the findings to a file (default `$AGENT_TMP/investigate-<slug>.md`; user path or shared doc when asked). Structure: scope, evidence, verdict per hypothesis, open questions.
4. Reply with the verdict summary + file path. Keep the summary short — detail lives in the file.

## Rules

- Analysis only. No code changes, no fixes — propose next steps instead.
- Evidence before synthesis. Every claim in the report points at something inspected, never at a guess.
