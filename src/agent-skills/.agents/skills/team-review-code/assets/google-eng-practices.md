# Google Engineering Practices — Code Review Reference

Condensed from https://google.github.io/eng-practices/ (review/reviewer/* + review/developer/* pages). Shared reference for all review agents.

## Standard of code review

- **Senior principle:** approve once change **definitely improves overall code health**, even if not perfect. No "perfect" code — only *better* code.
- Balance two needs: developer progress (excess friction discourage future improvements) vs. code health (small erosions accumulate into big problems).
- No demand perfection; demand continuous improvement. Mark non-mandatory polish `Nit:`.
- Resolving disagreements:
  1. Technical facts + data override opinions + personal preference.
  2. Style guide = absolute authority on style; anything uncovered = personal preference.
  3. Software design rarely pure preference — evaluate against underlying principles.
  4. No other rule apply → stay consistent with existing codebase, as long as no degrade health.

## What to look for (core checklist)

- **Design** — most important. Pieces of change interact sensibly? Change belong in codebase, or in library? Integrate well with rest of system? Now right time to add?
- **Functionality** — code do what author intended? Good for users (end-users *and* future developers)? Think edge cases. Look hard at **concurrency**: deadlocks + race conditions hard to spot in review, hard to catch in testing.
- **Complexity** — "too complex" = readers can't understand quickly. Flag at every level (lines, functions, classes). Watch **over-engineering**: solving speculative future problems, not actual current one. Solve today problem; refactor when future arrive.
- **Tests** — require unit/integration/e2e tests appropriate to change. Tests must be correct, sensible, useful: **fail when code break**, no false positives, simple clear assertions. "Tests do not test themselves" — review as code.
- **Naming** — names fully communicate what thing is/does, not so long they hard to read.
- **Comments** — explain **why**, not what. Code need "what" comment → usually simplify code instead. Exceptions: regexes, complex algorithms. Remove stale TODOs + obsolete comments.
- **Style** — follow project style guide. Prefix non-mandatory style points `Nit:`. No mix major style changes with functional changes.
- **Consistency** — style guide beats existing inconsistent code; else stay locally consistent.
- **Documentation** — change affect how users build, test, interact, release → check docs (READMEs, reference docs) updated; deleted code take its docs with it.
- **Every line** — look at every assigned line. Can't understand it = finding itself: code hard for reviewer = hard for next developer. Flag areas needing specialist (security, concurrency, accessibility) if outside competence.
- **Context** — read beyond diff. View whole file/function, not just changed lines; 4-line diff inside 200-line function may mean different thing than appears. Judge change against overall system health, not in isolation.
- **Good things** — call out things done well, not only problems.

## Navigating change

1. **Broad view first:** read description. Change make sense at all? Should not happen → say so immediately, courteously, with reasoning + alternative.
2. **Main parts next:** find file(s) with major logical change, review first for context. Major design problem → report **immediately** — no finish reviewing rest first.
3. **Then rest** in logical sequence (e.g. tests before implementation, learn intent).

## Writing review comments

- **Be kind.** Comment on code, never developer ("this adds unnecessary complexity" — not "why did *you* use threads here?").
- **Explain why** — give reasoning/principle, so author learn, not just comply.
- Balance pointing out problem vs. explicit direction; no redesign code for author.
- Code need explanation in review tool → usually need **rewrite or code comment** instead — review explanations help no future reader.
- **Severity labels** (use in findings):
  - `Nit:` — minor, should fix, won't materially matter
  - `Optional:` / `Consider:` — good idea, not mandatory
  - `FYI:` — informational, no action expected

## Handling pushback

- First consider author may be right — closer to code.
- Still right → explain further; politeness keep friction-free.
- Reject "I'll clean it up in later CL": longer cleanup wait, less likely happen. Require cleanup before merge, except true emergencies.

## Speed (for orchestrator)

- Optimize **team** velocity. One business day = max response time; fast feedback matter more than fast approval.
- `LGTM with comments` fine when remaining points minor or trust author address them.
- Legitimate push back on CL **solely because too large** — ask split into stacked smaller changes; can't split → at least fast design-level feedback.

## What good change look like (developer side — useful for architect agent)

- **Small CLs:** one self-contained change doing one thing, with its tests; ~100 lines comfortable, ~1000 usually too much; 200 lines in one file ≠ 200 lines across 50 files. Exceptions: file deletions, tool-generated refactors.
  - Small CLs reviewed faster + more thoroughly, fewer bugs, merge + roll back easier.
- **Good descriptions:** first line = short, specific, imperative summary ("Delete the FizzBuzz RPC and replace it with the new system"), then blank line, then body: problem, rationale, alternatives considered, shortcomings, bug/design-doc links. Anti-patterns: "Fix bug", "Fix build", "Add patch", "Phase 1".

## Sources

- https://google.github.io/eng-practices/review/reviewer/standard.html
- https://google.github.io/eng-practices/review/reviewer/looking-for.html
- https://google.github.io/eng-practices/review/reviewer/navigate.html
- https://google.github.io/eng-practices/review/reviewer/comments.html
- https://google.github.io/eng-practices/review/reviewer/pushback.html
- https://google.github.io/eng-practices/review/reviewer/speed.html
- https://google.github.io/eng-practices/review/developer/small-cls.html
- https://google.github.io/eng-practices/review/developer/cl-descriptions.html
