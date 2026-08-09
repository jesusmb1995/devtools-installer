---
name: comment-reply
description: Draft concise replies to PR/MR review or issue comment URLs. Use when the user provides or previously mentioned a review/issue comment URL and asks how to respond, explain fixes made, evaluate whether the reviewer comment was correct, or link fix commits.
compatibility: Read `system_assets` skill (`forge.md`) for host CLI recipes. Needs forge access for the target repo.
---

# Comment Reply

**Forge commands:** `system_assets` skill (`forge.md`) (sections: fetch comments, post, resolve, commit links).

## Goal

Given a review/issue comment URL, inspect the original comment, the PR/MR context, and the fixing commits, then draft a concise reply that states:

- What was fixed.
- Whether the reviewer comment was correct, partially correct, or incorrect, and why.
- Links to the commits that contain the fix.

Do not post the reply unless the user explicitly asks you to post and then confirms the exact drafted reply.

## Workflow

1. Determine the target URL (arg → conversation → ask).
2. Parse host, owner/repo (or project path), PR/MR number, comment anchor — use forge asset for host-specific anchors.
3. Fetch the comment + PR/MR context via forge asset recipes.
4. Inspect local/remote changes: `git log`, `git show`, `git diff`. Prefer commits after the comment timestamp when choosing fixes.
5. Verdict on reviewer claim: `correct` / `partially correct` / `incorrect` (or say what was verified if unclear).
6. Resolve only when fixed or not applicable; else leave open. Nested reply when thread API exists; else top-level with short quote.
7. Build commit links using forge asset conventions for this host.

## Reply Style

- Short: 2–5 sentences or 2–4 bullets. Outcome first.
- Direct, professional. Link only relevant fix commits.
- No raw API dumps. Standalone: at most one short quote of original.

## Template

```markdown
[One concise sentence explaining what changed or why the original concern does/does not apply.]

Fixed in [short SHA](COMMIT_URL). [Optional: Tests updated/run in ...]
```

## Posting

Show draft first. Confirm before any create/edit API call. Confirmation must name the target URL and quote the body. If resolving/minimizing, say so in the confirm prompt. After confirm: post exactly, capture public URL, resolve/minimize per forge asset if planned.
