---
name: team-review-code
description: Team version of review-code. Spawns specialized parallel reviewer subagents — one per review dimension (safety, security, correctness, simplicity, tests), one architect for general overview, plus extra area agents chosen by main agent based on what change touches (e.g. JS side, C++ API, C++ class internals). Prints roster+model plan for user approval first, picking cheapest sufficient model per agent; escalates underperforming agents to stronger models (continuing same .md report) on user approval. Each writes .md report under $AGENT_TMP (see /tmp-agent-skill); main agent then critically vets every finding against actual diff (push back, drop hallucinated/inflated comments) before aggregating into single $AGENT_TMP/review.md like review-code. Use when user asks for team code review, deep PR/MR review, or parallel multi-agent review.
---

# Team Review Code

Load `/tmp-agent-skill` for the canonical per-agent temp root (`$AGENT_TMP = /tmp/agent-<id>/`). All scratch files go there — never the `/tmp` root.

Like `review-code`, but each dimension get own specialized subagent, all parallel. Main agent orchestrate + aggregate only — NOT review code itself.

## Shared reference asset

All subagents (and main agent when aggregating) can consult condensed Google engineering practices guide bundled with skill:

`assets/google-eng-practices.md` (relative to this SKILL.md — resolve absolute path before passing to subagents)

Summarizes https://google.github.io/eng-practices/ — review standard ("approve when definitely improves code health, even if not perfect"), what-to-look-for checklist (design, functionality, complexity, tests, naming, comments, context), comment severity labels (`Nit:`, `Optional:`, `FYI:`), navigation order, pushback/small-CL guidance. Every spawned agent prompt must include path + tell agent apply guidance relevant to its dimension.

## Step 1: Scope change

Determine what under review (PR diff, stg patch, working tree diff, branch diff). Get:
- Diff itself (`git diff`, forge PR/MR diff (see `system_assets` skill (`forge.md`)), `stg show`, etc.)
- Changed file list

Pick short kebab-case slug (PR title or branch name). Reports go under `$AGENT_TMP/team-review-<slug>/`.

```bash
mkdir -p $AGENT_TMP/team-review-<slug>
```

Save diff to `$AGENT_TMP/team-review-<slug>/diff.patch` — every subagent read exact same input.

## Step 2: Decide agent roster

**Always spawn (fixed dimension agents):**

| Agent | Focus |
|---|---|
| `safety` | crashes, thread races/deadlocks, lifetime/null bugs, unchecked error returns/status, cleanup leaks |
| `security` | authz/authn, secrets, injection, unsafe deserialization, path traversal, CI/workflow permission risks |
| `correctness` | edge cases, state machines, API contracts, migrations, backward compatibility |
| `simplicity` | syntax/readability, needless abstraction, confusing control flow |
| `tests` | major missing test cases, weak assertions, untested edge paths |
| `architect` | general overview: design fit, layering, module boundaries, naming, does change belong where it lives, long-term maintainability |

**Conditionally spawn (area agents) — main agent discretion, based on changed files:**

Examples (adapt to actual PR — not fixed list):
- `area-js` — JS/TS side touched: bindings, async flows, API ergonomics from JS consumer view
- `area-cpp-api` — public C++ API/headers changed: ABI/API stability, ownership semantics, const-correctness of interface
- `area-cpp-impl` — C++ class internals changed: invariants, RAII, move semantics, member lifetime
- `area-build` — build system / CI files changed
- `area-docs` — docs/comments changed alongside behavior

Spawn area agent only when PR meaningfully touch that area. Skip trivial/no-change areas. Invent new area agents if PR call for it (e.g. `area-sql`, `area-protocol`).

## Step 3: Plan models, get user approval

Before spawning anything, print plan table, ask user approve or adjust (use environment question/approval mechanism if available, else plain chat):

```markdown
| Agent | Focus | Model | Why this model |
|---|---|---|---|
| safety | races, lifetimes, leaks | <mid tier> | needs real reasoning over C++ |
| simplicity | readability, control flow | <fast tier> | mechanical, narrow scope |
| architect | design overview | <top tier> | cross-module judgment |
| ...
```

Pick **cheapest sufficient model per task** — no shotgun when small efficient model enough. Choose freely from models current environment (Claude Code, Cursor, Antigravity, ...) offer for subagents, mapped to three rough tiers:

- **Fast/cheap tier** (e.g. Claude Haiku, GPT mini-class, Gemini Flash) — narrow mechanical checks on small diffs: style/simplicity, docs, small area sweeps
- **Mid/default tier** (e.g. Claude Sonnet, GPT standard, Gemini Pro) — substantive dimensions: safety, security, correctness, tests, most area agents
- **Top tier** (e.g. Claude Opus, GPT pro/reasoning-class, or inherit main session model) — architect overview, large/subtle diffs, heavy concurrency or cross-module reasoning

- Generic/simple GPT 5.5 high with very simple prompt: Let it do its work. Use different frontier model type when/if you do have access to it.

Environment no support per-subagent model selection → note in plan, run all on session model. Scale baseline up when diff large or high-risk. Spawn only after user approve roster + models.

Generally always prefer to use `/caveman` skill with each of them for efficiency unless strictly needed due to task requirements.

## Step 4: Spawn all agents parallel

Launch ALL agents at once via environment subagent mechanism (Agent/Task tool in Claude Code, background agents in Cursor/Antigravity, ...), single message/batch so parallel, background mode if available. Keep flat — subagents must not spawn subagents.

Each agent prompt must include:
1. Single focus (one dimension or one area — nothing else).
 2. Shared diff path: `$AGENT_TMP/team-review-<slug>/diff.patch` (may also read repo for context).
3. Absolute path to shared reference `assets/google-eng-practices.md` (bundled next to SKILL.md) — apply guidance relevant to dimension (e.g. "Comments"/"Complexity" sections for `simplicity`, "Tests" for `tests`, "Design"/small-CL/description guidance for `architect`).
4. If `coding-preferences` skill exist, tell agent follow that style guide.
5. Exact output contract:

```
Write your findings ONLY to $AGENT_TMP/team-review-<slug>/<agent-name>.md using:

# <Agent name> review

## Critical
- [file:line] Bug. Impact. Evidence. Fix.

## High
- [file:line] Issue. Impact. Fix.

## Medium
- [file:line] Short issue.

## Low
- [file:line] Short issue.

## Notes
Residual risk or "no issues found in this dimension" stated clearly.

Report only real issues in YOUR dimension. No style noise outside your scope.
Do not modify any code. Return a one-line summary as your final message.
```

## Step 5: Wait, check quality, escalate if needed

NO polling. System notify when each agent complete.

As reports land, sanity-check each. Subagent **failed** if: report missing, empty, vague/hand-wavy ("looks fine", no evidence on risky diff), clearly hit wall (could not read files, gave up), or contradict diff. Then:

1. Tell user which agent underperformed + why.
2. Prompt user **escalate that agent to stronger model** (one tier up: fast → mid → top, from available models) — or accept report as-is.
 3. On approval, spawn escalated agent: same focus + prompt, plus partial report path `$AGENT_TMP/team-review-<slug>/<agent-name>.md`, plus instruction **continue where previous agent left off** — keep valid findings, fill gaps, update same .md in place (no fresh report).

Escalate only failing agents, not whole roster.

## Step 6: Vet every finding (mandatory)

After ALL reports final, BEFORE aggregating or presenting ANY finding to user, main agent MUST vet every individual comment. No raw subagent findings in chat — user only see vetted results. Be very critical, actively push back — assume each finding wrong until evidence hold.

Per finding, per report:

 1. **Verify against actual diff/code.** Open `$AGENT_TMP/team-review-<slug>/diff.patch` (and repo if needed). Confirm cited file:line exist in change, claim match what code really do. Subagents hallucinate line numbers, misread control flow, flag pre-existing code as new — catch here.
2. **Challenge claim itself.** "Bug" actually reachable? Edge case already handled elsewhere (guard upstream, test coverage, framework behavior)? Out of scope for PR? Suggested fix even work?
3. **Drop documented tradeoffs.** "Issue" is deliberate documented tradeoff (code comment, PR/commit description, obvious project convention) + not serious impediment to merge → remove finding entirely — author made call knowingly; re-litigating = noise. Keep only if tradeoff has genuinely severe consequence documentation not acknowledge.
4. **Challenge severity.** Downgrade inflated (theoretical nit reported Critical), upgrade undersold.
5. **Verdict per finding:** keep, downgrade/upgrade, reword (claim real, evidence/fix wrong), or **drop** (unverifiable, hallucinated, duplicate of pre-existing behavior, pure speculation, documented tradeoff that no block merge). When in doubt, drop — false positive cost author more than missed nit.

Record vetting outcome inline (annotate each finding `[verified]` / `[dropped: reason]`) so aggregation consume only verified findings. Briefly tell user how many dropped/adjusted per agent.

Only place main agent allowed (and required) read code itself — verification, not fresh review.

## Step 7: Aggregate

When vetting done:

1. Take only **verified** findings from `$AGENT_TMP/team-review-<slug>/*.md`.
2. Merge findings, **dedupe** issues reported by multiple agents (keep best-evidenced version, note which agents flagged — multi-agent agreement raise confidence/severity).
3. Write final aggregated report to `$AGENT_TMP/review.md`, same format as `review-code`:

```markdown
# Review

## Critical
- [file] Bug. Impact. Evidence. Fix. (flagged by: safety, correctness)

## High
- [file] Issue. Impact. Fix.

## Medium
- [file] Short issue.

## Low
- [file] Short issue.

## Architecture overview
2-5 sentence synthesis from the architect agent.

## Summary
Most important risk + test gap.

## Score
N/4 label
```

Score scale (same as review-code):
- `1/4 bad`
- `2/4 almost ready production`
- `3/4 ready for prod with minor`
- `4/4 perfect`

Explain only most severe issues in depth; other findings one-line. No real issues → say clearly + residual risk/test gaps.

4. Show user short chat summary: roster used, per-agent one-liners (incl. dropped/adjusted counts from vetting), top findings, score, path `$AGENT_TMP/review.md` (per-agent reports stay in `$AGENT_TMP/team-review-<slug>/`).

## What NOT do

- No review code yourself in main agent — delegate everything; read code only in Step 6 to verify subagent findings, never hunt new issues.
- No skip vetting round, no rubber-stamp findings into final report — every comment must survive critical pushback first.
- No show user unvetted finding — vetting before results presented, not after.
- No spawn agents sequentially — all in one message.
- No spawn area agents for areas PR barely touch.
- No let subagents modify code — analysis only.
- No poll for completion.
