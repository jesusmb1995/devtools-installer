---
name: review-comment-investigate
description: Investigate whether a PR/MR review comment is correct. Explains verdict (humanized), then implements fix only if truly needed and user confirms.
compatibility: Read `system_assets` skill (`forge.md`). Needs forge access for the target repo.
---

# Review Comment Investigator

**Forge commands:** `system_assets` skill (`forge.md`).

1. Fetch comment + PR/MR via forge asset. Read full file, check git history for existing fixes.
2. Verdict: correct / partially correct / incorrect / already fixed — with specific line/commit evidence.
3. Run `/humanizer` on explanation if available. Present to user.
4. If fix needed: describe it, wait for confirmation, then implement minimal scope only IN TWO PATCHES when possible (skill `/tdd`). One patch that reproduces bug (if applicable) with red test, another that fixes it and test is green.
5. Use stg (stacked-git) if available, otherwise git.
