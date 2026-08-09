---
name: team-pr-comments-tdd-fix
description: Takes $AGENT_TMP/{slug}/ reports from team-pr-comments-investigate (see /tmp-agent-skill), spawns one TDD agent per comment in an isolated git worktree to AUTHOR (not build/test) two stg patches each (red repro + green fix) and export them as .patch files. The master agent then sequentially imports every patch into the real working tree and is the ONLY actor that builds and runs tests. After user confirmation, resumes the same fix agents (no new spawns) to /comment-reply each original reviewer comment.
compatibility: Requires git, stg (StGit), forge access (see `system_assets` skill (`forge.md`)), and an existing stg-managed repo. Run from the repo root.
---

# PR Comments TDD Fix

Load `/tmp-agent-skill` for the canonical per-agent temp root (`$AGENT_TMP = /tmp/agent-<id>/`). All scratch files go there — never the `/tmp` root. The `{slug}` directory is resolved under `$AGENT_TMP`, matching the producer skill `team-pr-comments-investigate`.

**Forge commands:** `system_assets` skill (`forge.md`). Reply skill: `/comment-reply`.

Reads the `.md` reports produced by `/team-pr-comments-investigate`, then fixes each comment through strict TDD: one red patch that reproduces the bug with a failing test, one green patch that makes it pass.

**Division of labor:**
- **Sub-agents author patches only.** Each fix agent works in its own isolated git worktree and only *writes code* — it produces the red and green patches and exports them as `.patch` files. Sub-agents **never build and never run tests**, so they never compete for the same codebase, build artifacts, or test resources.
- **The master applies, builds, and tests.** Only the master imports the exported patches into the real working tree, and the master is the sole actor that compiles and runs the test suite — verifying the red patch fails and the green patch passes.

When all patches are applied and verified, the **same** fix agents are resumed to reply to their original review comments — no new agents are spawned.

**Input:** path to the reports directory, e.g. `$AGENT_TMP/my-pr-slug/`

---

## Phase 1 — Load reports

1. List all `comment-*.md` files under the given directory.
2. Parse each report: extract **verdict**, **file path**, **line**, and the **investigation** section.
3. Skip any report whose verdict is `incorrect` or `already fixed` — no fix needed.
4. Keep the remaining reports as the fix queue, sorted by comment id ascending.

---

## Phase 2 — Spawn patch-authoring agents in parallel (one per queued comment)

For each queued report, spawn an independent agent with `isolation: worktree`. Give each agent a **stable name** of the form `fix-agent-{id}` (e.g. `fix-agent-1234567890`) so it can be resumed later by `SendMessage` without spawning a new one.

Each agent receives:

- The full content of the report `.md` as context.
- The original comment URL (`html_url` from the report, or reconstructed per forge asset).
- The instructions below.

The agent must **stay alive** after producing its patches — it should not exit until it explicitly receives a `SendMessage` resume or a shutdown signal. It keeps its worktree and context in memory for Phase 4.

### Per-agent instructions

The agent works entirely inside its assigned worktree so its edits never touch the real working tree or any other agent's worktree. It produces patches by **authoring code only** — it does **not** build the project and does **not** run any tests. Verification of the patches (compile + test) is the master's job in Phase 3.

#### Step 1 — Name the two patches

```
red-comment-{id}   # failing test that reproduces the bug
grn-comment-{id}   # minimal fix that makes the test pass
```

#### Step 2 — Author the red patch

```bash
stg new red-comment-{id} -m "test(comment-{id}): reproduce {short description of issue}"
```

- Write a focused, isolated test that exercises exactly the behavior the reviewer flagged.
- Reason carefully about why this test **must fail** against the current code, and state that reason in the patch description — you will not run it, so the logic has to be airtight.
- Follow `/tdd` rules: one bug = one dedicated test, no piggy-backing, no API surface leaks.
- Do **not** build or run the test. Refresh the patch:
  ```bash
  stg refresh
  ```

#### Step 3 — Author the green patch

```bash
stg new grn-comment-{id} -m "fix(comment-{id}): {short description of fix}"
```

- Implement the smallest change that makes the red test pass.
- Keep the change minimal and localized so the master can apply it without conflicts.
- Do **not** build or run anything. Refresh the patch:
  ```bash
  stg refresh
  ```

#### Step 4 — Export patches

```bash
stg export --dir $AGENT_TMP/{slug}/patches/ red-comment-{id}
stg export --dir $AGENT_TMP/{slug}/patches/ grn-comment-{id}
```

Each patch lands as a `.patch` file in the shared patches directory. These files — not the worktree — are the agent's deliverable.

#### Step 5 — Report outcome

Write `$AGENT_TMP/{slug}/fix-comment-{id}.md`:

```markdown
# Fix — Comment #{id}

## Patches
- `red-comment-{id}.patch` — failing test
- `grn-comment-{id}.patch` — minimal fix

## Expected behavior (for the master to verify)
- Red patch alone: expected to FAIL because {precise reason}.
- Green patch applied: expected to PASS.
- Test/command the master should run: `{exact test invocation, e.g. cargo test comment_{id}_repro}`

## Summary
{one paragraph: what was wrong, what the test proves, what the fix does}
```

If the fix cannot be authored (repro can't be isolated, change is not localizable, requirements unclear), write the reason and verdict `FAILED` to the fix report and **do not export** the patches. The master step will skip this comment.

After writing the fix report, **pause and wait** — do not exit. The agent will receive a `SendMessage` in Phase 4 instructing it to post the review reply. Retain the comment URL and fix summary in context.

---

## Phase 3 — Master: import, build, and test (the only actor that builds/tests)

Wait for all agents to complete, then run the following **in the real (non-worktree) repo**, sequentially, in comment-id order. The master is the single place where compilation and tests happen.

### 3a — Verify prerequisites

```bash
stg series          # confirm stg is initialised
git status          # confirm working tree is clean
```

If the working tree is dirty, stop and tell the user to stash or commit first.

### 3b — Import, build, and verify each comment in order

For each comment that succeeded (has both `.patch` files in `$AGENT_TMP/{slug}/patches/`), use the **Test/command** and **Expected behavior** from `$AGENT_TMP/{slug}/fix-comment-{id}.md` to verify TDD at the master level:

1. **Import + verify red (expect FAIL):**
   ```bash
   stg import --series $AGENT_TMP/{slug}/patches/red-comment-{id}.patch
   ```
   Build the project and run the comment's test. It **must fail** for the reason the agent stated. If it unexpectedly passes (or fails to compile for the wrong reason), stop and flag comment #{id} as `RED-NOT-RED` — the repro is not valid; pop the patch and skip the green patch.

2. **Import + verify green (expect PASS):**
   ```bash
   stg import --series $AGENT_TMP/{slug}/patches/grn-comment-{id}.patch
   ```
   Rebuild and re-run the comment's test — it **must pass** now. Then run the broader relevant test suite to check for regressions. If the test still fails or regressions appear, stop and flag comment #{id} as `GREEN-FAILED`; leave the stack as-is and report.

3. Confirm the pair applied cleanly:
   ```bash
   stg show
   ```

If `stg import` rejects a patch (conflict), stop, report which comment failed, and leave the stack in the state it was before that import. Do not force-apply.

### 3c — Final summary

Print to terminal:

```
Patches applied, built, and tested on the stg stack
Output: $AGENT_TMP/{slug}/patches/

| Comment | Red patch            | Green patch          | Build/Test | Status   |
|---------|----------------------|----------------------|------------|----------|
| {id}    | red-comment-{id}     | grn-comment-{id}     | red✗ grn✓  | applied  |
| {id}    | —                    | —                    | —          | skipped (verdict: incorrect) |
| {id}    | red-comment-{id}     | grn-comment-{id}     | —          | CONFLICT |
| {id}    | red-comment-{id}     | —                    | red✓       | RED-NOT-RED (repro invalid) |
| {id}    | red-comment-{id}     | grn-comment-{id}     | grn✗       | GREEN-FAILED |
...

Run `stg series` to inspect the current stack.
Run `stg push --all` if patches are unapplied.
```

---

## Phase 4 — Ask user, then resume agents to reply (no new spawns)

### 4a — Ask for confirmation

After Phase 3 completes (summary table printed), pause and ask the user:

> "Patches have been applied, built, and tested on the stg stack. Want me to have each fix agent reply to its original review comment? The same agents will be reused — no new ones spawned. Reply `yes` to proceed or `no` to stop here."

Do not proceed until the user explicitly confirms. If they say no, shut down all fix agents and stop.

### 4b — Resume each fix agent via SendMessage

For every comment that was in the fix queue (applied **or** FAILED — both deserve a reply):

Send a message to the existing `fix-agent-{id}` with the following instructions:

---

**Message to `fix-agent-{id}`:**

> You previously investigated and authored the patches for comment #{id} on this PR.
> Now run `/comment-reply` for that comment using the context you already hold.
>
> Comment URL: `{html_url}`
>
> Additional context for the reply:
> - Your verdict from the investigation report: `{verdict from comment-{id}.md}`
> - Patches produced: `red-comment-{id}` (repro test), `grn-comment-{id}` (fix).
> - Master build/test result: `{applied | RED-NOT-RED | GREEN-FAILED | CONFLICT | FAILED}` from the Phase 3 summary.
> - Fix summary from `$AGENT_TMP/{slug}/fix-comment-{id}.md` (include the key sentence about what changed).
>
> Follow `/comment-reply` fully:
> 1. Fetch the comment and PR context via forge asset recipes.
> 2. Identify the fix commits from the stg patches now in the real branch (they were imported and verified in Phase 3).
> 3. Draft a concise reply linking the fix commits, noting the test added, and stating the verdict.
> 4. Show the drafted reply here (do NOT post yet).
>
> Report back with the drafted reply text when done.

---

Run all `SendMessage` calls in parallel — one per fix agent simultaneously.

### 4c — Collect drafts and show to user

Wait for all agents to report back their drafted replies. Display them grouped:

```
## Drafted replies

### Comment #{id} — {file}:{line}
{drafted reply text}

### Comment #{id} — {file}:{line}
{drafted reply text}
...
```

Then ask:

> "Post all replies above? (`yes` = post all, `no` = skip all, or list comment ids to skip, e.g. `skip 111 222`)"

### 4d — Post confirmed replies

For each reply the user approved, resume the corresponding `fix-agent-{id}` via `SendMessage`:

> "User confirmed. Post the reply now following the `/comment-reply` posting workflow: use forge asset to post, capture the response URL, and resolve/minimize the thread if the issue is fixed."

Run all approved `SendMessage` calls in parallel. Each agent handles its own posting, thread resolution, and reports back the public URL.

### 4e — Final summary

Once all agents report back, print:

```
## Replies posted

| Comment | File | Verdict | Reply URL |
|---------|------|---------|-----------|
| {id}    | {path}:{line} | correct | {html_url of posted reply} |
| {id}    | {path}:{line} | partially correct | skipped by user |
...
```

Shut down all fix agents.

---

## Rules

- Sub-agents **author patches only**. They write code in their own worktree and to `$AGENT_TMP/{slug}/` — they never build, never run tests, and never touch the real working tree or another agent's worktree.
- The master (Phase 3) is the **only** actor that imports patches, builds, and runs tests — and the only step that modifies the real git/stg state.
- TDD is verified at the master: red must fail, green must pass, no regressions.
- Never use `--force` on stg import.
- Never amend or rebase existing patches in the stack.
- Keep red and green as two distinct patches — never squash them.
- **Never spawn a new agent for Phase 4.** Always resume `fix-agent-{id}` via `SendMessage`. If an agent is unreachable (crashed), note it in the summary and skip that reply.
- Do not post any forge reply without explicit user confirmation in Phase 4c.
- The reply step (Phase 4) is fully optional — stopping at Phase 3 is a valid outcome.
