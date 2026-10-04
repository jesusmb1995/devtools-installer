---
name: ask-if-safe-to-approve-for-client
description: Triage whether a change/approval is safe to stamp for a client — blast radius (my alerts/infra vs client-only), reversibility, and a stamp verdict. Use when the user writes /ask-if-safe-to-approve-for-client.
---

# Ask If Safe To Approve For Client

The user wants to know: can I just stamp this without a deep look, or is it risky?

## Trigger

User writes `/ask-if-safe-to-approve-for-client <what to approve>`.

## Procedure

1. Establish what the approval actually changes (files, config, permissions, data, external calls).
2. Blast radius: does it touch MY alerts/infra/pipeline, or only the client's side (which the client owns and understands)?
3. Reversibility: can it be reverted, and how fast?
4. Verdict, exactly one:
   - safe to stamp — client-only effect, reversible, no action on my side.
   - stamp with checks — list the 1-3 things to glance at first.
   - risky, look closely — affects my alerts/infra, hard to reverse, or unclear effect; say what to review.

## Rules

- The verdict comes first, reasons after. No hedging between verdicts.
- Unknown effect counts as risky, never as safe.
