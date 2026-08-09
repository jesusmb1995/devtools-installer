#!/bin/bash

# Scaffold a tool-agnostic "skill" in the current project.
#
# Canonical source of truth: .ai/<skill>/SKILL.md. Keep .ai/ OUT of .gitignore
# so tools that scan the tree can see it. Wiring differs by discovery model:
#
#   Folder-of-SKILL.md (ONE folder symlink, scales to all skills, no re-run).
#   They all read the same SKILL.md format, just from different dirs:
#     - Claude Code : .claude/skills   -> ../.ai
#     - Antigravity : .agents/skills   -> ../.ai
#     - Codex       : .codex/skills    -> ../.ai   (also scans .agents/skills)
#     - OpenCode    : .opencode/skills -> ../.ai   (also reads .claude/.agents)
#
#   Recursive single-file scan (drop the file INSIDE each skill folder; Gemini
#   concatenates every GEMINI.md it finds below cwd, so skills coexist):
#     - Gemini CLI  : .ai/<skill>/GEMINI.md -> SKILL.md
#       (no .gemini/ folder needed; .gemini/ is only home/global config)
#
#   Different extension, per-skill (only tool that can't fold-symlink):
#     - Cursor      : .cursor/rules/<skill>.mdc -> ../../.ai/<skill>/SKILL.md
#
# Usage: init-skill-agnostic [skill-name]   (default: example-skill)



function disable-skills {
  mv "${HOME}"/.agents/skills "${HOME}"/.agents/skills.disabled || echo "Skills were already disabled"
}


function enable-skills {
  mv "${HOME}"/.agents/skills.disabled "${HOME}"/.agents/skills || echo "Skills were already enabled"
}
