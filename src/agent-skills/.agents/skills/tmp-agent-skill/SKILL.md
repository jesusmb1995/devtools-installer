---
name: tmp-agent-skill
description: Centralized rule for agent scratch files. ALL skills that write under /tmp MUST load this and use the per-agent root /tmp/agent-<id>/ (set AGENT_TMP) instead of /tmp root. See .agents/permissions.json for the deny/allow policy.
---

# Agent Temp-File Isolation

Set `AGENT_TMP=/tmp/agent-<id>/` (`<id>` = agent session id; derive one if none) and `mkdir -p "$AGENT_TMP"`.

Rules:
- Write/read scratch ONLY under `$AGENT_TMP`. Never `/tmp` root.
- Pass `AGENT_TMP` to sub-agents; consumers read the same path the producer wrote.

Permissions (`.agents/permissions.json`, enforced by harness): deny `/tmp/**`, allow `/tmp/agent-<id>/**`.
