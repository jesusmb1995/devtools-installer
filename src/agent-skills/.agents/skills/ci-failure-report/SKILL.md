---
name: ci-failure-report
description: Review CI failures, classify related vs unrelated, draft PR/MR comment. Use when asked to check CI, explain failures, or confirm safe to merge.
compatibility: Read `system_assets` skill (`forge.md`) for CI log + comment recipes.
---

# CI Failure Report

**Forge commands:** `system_assets` skill (`forge.md`) (CI list/logs, post comment).

Fetch failures → classify → draft comment → confirm → post.
Never push, rerun, or modify CI state unless asked.

## Steps

1. Recent runs for current upstream branch (forge asset).
2. Failed job logs (forge asset).
3. Classify each failure:

| Class | Signals |
|-------|---------|
| infra | timeout, OOM, runner killed, `exit 137`, rate limit |
| download | `curl` fail, `apt` 404, `npm ERR! network`, `git fetch` fail |
| git/hash | ref not found, shallow clone, `object not found` |
| unrelated | flaky test, file not in `git diff --name-only @{u}` |
| **related** | failure in changed file or its deps |

Uncertain → mark `uncertain`, include log line. No guessing.

4. Draft comment:

```
Tests passing for the most part here [RUN_URL] except:
- [job]: timeout (unrelated — infra)
- [job]: "npm ERR! network timeout" (unrelated — download)
- [job]: FAILED src/foo_test.cpp (RELATED — needs fix)
— overall OK to merge  ← or: blocking failures present
```

One bullet per failed job. Exact log quote ≤ 1 line. Omit passing jobs.

5. Show draft. Ask confirmation. Then post via forge asset.
