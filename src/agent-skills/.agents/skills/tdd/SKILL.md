---
name: tdd
description: Enforce test-first workflow for tasks invoked with /tdd. Use when user writes /tdd followed by a bugfix or feature task. Summarize task in 1-2 sentences, then write/reproduce and run tests before implementation to prove the issue is caught.
---

# TDD

When prompt starts with `/tdd` (test driven development), do test-first. If there is absolutely no red-seam possible then only add green-seam patch.

## Flow

1. Summarize task in 1-2 sentences.
2. Before implementation/fix, reproduce bug or add failing test.
3. Run focused test/repro and confirm it fails for expected reason, proving issue is caught.
   - **If a fix already exists in the working tree** (e.g. user is asking you to "follow TDD" mid-task, or you already have local changes for the bug), use `git stash push -k -- <production files>` (or `git stash push -- <files>` when needed) to temporarily drop ONLY the production fix while keeping the new test staged. Re-run the test, observe failure, then `git stash pop` to bring the fix back. Then re-run and observe pass. This proves the test actually catches the bug.
   - When the codebase is managed with stg, the equivalent is `stg refresh -p <other-patch>` / temporarily popping the fix patch and pushing only the test patch.
   - Skip this dance only when no fix exists yet (clean test-first flow) or when the test fails to compile against the unfixed tree (the compile error itself is the demonstrated failure — say so explicitly).
4. Implement smallest fix/change.
5. Run **focused** test again, then broader relevant tests if risk warrants.

## Rules

- No production code first unless no test harness exists.
- If no test harness exists, create and run minimal repro script, or document exact manual repro before fix.
- Keep tests focused on behavior, not implementation details.
- Mention failure observed before fix and pass observed after fix.
- **One bug = one new dedicated test (or small cluster).** Never piggy-back the repro inside an existing scenario test. A future reader must be able to delete the production fix and watch exactly that one test flip red.
- **Do not change the public API just to make the test expressible.** If the fix needs new state, put it on the existing data type (e.g. add a getter on the resource) instead of forcing every caller to pass redundant bookkeeping. Reject solutions that leak internal capacity/length/count back through the API surface.
- Trigger this skill whenever the user says "follow TDD", "TDD", or "test first" — even without the explicit `/tdd` prefix.
