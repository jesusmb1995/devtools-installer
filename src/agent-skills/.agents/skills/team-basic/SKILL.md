---
name: team-basic
description: Generic master/sub-agent harness. Master splits task into pieces, spawns one subagent per piece, each subagent writes a summary .md to $AGENT_TMP (see /tmp-agent-skill), master evaluates every summary, aggregates them, then continues the task in main agent. Use as building block when a task splits into independent parallel pieces, or when another skill says "reuse team-basic".
---

# Team Basic

Load `/tmp-agent-skill` for the canonical per-agent temp root (`$AGENT_TMP = /tmp/agent-<id>/`). All scratch files go there — never the `/tmp` root.

Master orchestrate only. Split → spawn → judge → aggregate → continue. Master no do piece-work, only read to verify. Reusable harness (other skills call it).

## Notes
- Use /caveman skill to save tokens if possible
- Use proper ai model to be efficient as needed by task difficulty

## Do

1. **Split.** Break task into non-overlapping pieces, 1 piece = 1 subagent. Slug task. `mkdir -p $AGENT_TMP/team-basic-<slug>`. Shared input → save once to `input.md`.
2. **Spawn all parallel** in ONE message (background if can). Flat — subagents no spawn subagents. Each prompt: single piece + input path + write summary ONLY to `$AGENT_TMP/team-basic-<slug>/<piece>.md` (`## What checked` / `## Findings` w/ evidence file:line / `## Conclusion` verdict+confidence, say "nothing found" if so). Pass `AGENT_TMP` so subagents write only there. No edit code unless task say so. Return 1-line final msg.
3. **Wait.** No poll — system notify when done.
4. **Evaluate** each `.md`. Failed = missing/empty/vague/no-evidence/contradict-input. Verify vs real code, drop hallucinations, re-spawn weak piece (stronger model if can).
5. **Aggregate** verified summaries, dedupe (agreement = higher confidence).
6. **Continue** task in main agent from aggregate.

## No

Master do piece-work · sequential spawn · poll · nested subagents · show unverified summary · split tiny task (just do it).
