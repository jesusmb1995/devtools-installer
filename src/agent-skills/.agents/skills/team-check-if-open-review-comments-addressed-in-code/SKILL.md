---
name: team-check-if-open-review-comments-addressed-in-code
description: Team variant of check-if-open-review-comments-addressed-in-code. Uses /team-basic harness to spawn one sub-agent per open review comment, each checking if it's addressed in code. Use for PRs/MRs with many open comments.
compatibility: Read `system_assets` skill (`forge.md`). Needs forge access for the target repo.
---

# Team: Check If Open Review Comments Are Addressed In Code

**Forge commands:** `system_assets` skill (`forge.md`).

Load `/check-if-open-review-comments-addressed-in-code` for the full investigation logic, then apply `/team-basic` to fan it out: one sub-agent per open/unresolved comment, each checking whether its concern is addressed in current code and writing a verdict `.md` to `$AGENT_TMP/<pr-slug>/` (see `/tmp-agent-skill`). Master aggregates into final summary table.

**Post-check actions run in the master agent only** (never in sub-agents): after aggregating verdicts, master follows step 6 of `/check-if-open-review-comments-addressed-in-code` — asks user to resolve addressed threads and optionally approve the PR/MR.
