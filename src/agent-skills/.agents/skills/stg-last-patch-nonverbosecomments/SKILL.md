---
name: stg-last-patch-nonverbosecomments
description: Strip redundant comments in last StGit patch. Keep code self-documenting. Use when asked to clean comments.
---

# Non-Verbose Comments

Strip useless comments. Prefer self-documenting code. Use `stg show` to view last patch changes.

**CRITICAL**: Balanced approach. Do NOT remove all comments. Keep when helpful. Compress when dubious.

However, when invoked it rarely should end in no modifications at all. AI editing leaves many thins to be improved.

## Rules

- **Kill redundant comments**: No `x = true; // set x to true`.
- **Kill obvious intent**: If code clear, drop comment.
- **Keep API docs**: Keep comments for public APIs.
- **Keep side-effect warnings**: Keep comments warning about non-obvious side-effects.
- **Keep "Why"**: Keep comments explaining *why* (business logic, weird hacks), drop *what* (code already says what).

## Examples

**Kill:**
```cpp
// Set flag to true
isActive = true;

// Loop over items
for (auto& item : items) {
  item.process(); // Process item
}
```

**Keep:**
```cpp
/// Flushes the write buffer to disk. Warning: Blocks thread.
void flush();

// Sleep needed because hardware takes 50ms to reset
std::this_thread::sleep_for(50ms);
```
