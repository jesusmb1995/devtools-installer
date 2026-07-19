---
name: review-code
description: Review code changes for severe bugs, safety, simplicity, syntax, tests, and security. Use when user asks for code review, PR review, patch review, or risk scan. Write findings to $AGENT_TMP/review.md (see /tmp-agent-skill).
---

# Review Code

Load `/tmp-agent-skill` for the canonical per-agent temp root (`$AGENT_TMP = /tmp/agent-<id>/`). All scratch files go there — never the `/tmp` root.

Review like merge gate. Find real issues, not style noise.

## Checks

- **Safety**: crashes, thread races/deadlocks, lifetime/null bugs, error returns/status not checked, cleanup leaks.
- **Security**: authz/authn, secrets, injection, unsafe deserialization, path traversal, CI/workflow permission risks.
- **Correctness**: edge cases, state machines, API contracts, migrations, backward compatibility.
- **Simplicity**: syntax/readability, needless abstraction, confusing control flow.
- **Tests**: major test cases missing.

## Output

Write only to `$AGENT_TMP/review.md` (see `/tmp-agent-skill`).

Sort by severity:
1. Critical
2. High
3. Medium
4. Low

Explain only most severe issues in depth. Keep other findings one-line.
Give final score over `/4`:
- `1/4 bad`
- `2/4 almost ready production`
- `3/4 ready for prod with minor`
- `4/4 perfect`

Use:
```markdown
# Review

## Critical
- [file] Bug. Impact. Evidence. Fix.

## High
- [file] Issue. Impact. Fix.

## Medium
- [file] Short issue.

## Low
- [file] Short issue.

## Summary
Most important risk + test gap.

## Score
N/4 label
```

If no real issues, write that clearly plus residual risk/test gaps.
