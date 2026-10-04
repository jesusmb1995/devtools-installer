---
name: facts
description: Verify the previous assistant message is actually true — URLs contain the claimed info, build/test logs show the claimed success, code claims match the real code. Use when the user writes /facts or wants claims checked.
---

# Facts

The user just typed `/facts`. Your last message may contain claims that are wrong. Check them before anything else.

## Trigger

User writes `/facts`.

## Procedure

1. Extract every checkable claim from YOUR most recent assistant message:
   - URLs/links → fetch or open each one, confirm it exists and contains the info you said it has.
   - Build/test/log outcomes ("build passes", "log shows X") → re-read the actual log output or re-run the command; quote the lines that prove it.
   - Code claims ("file X contains Y", "function Z does W") → read/grep the file, confirm verbatim.
2. Report a verdict per claim, nothing else:
   - confirmed — claim matches the source.
   - contradicted — claim is wrong; state the correction plainly.
   - unverifiable — source unreachable or no evidence; say what is missing.
3. If any claim is contradicted, correct the record in the same reply. No hedging, no new work.

## Rules

- Check, don't re-answer. No new information, no tools beyond verification.
- Facts survive verbatim: paths, commands, numbers, URLs stay EXACTLY as they were unless the check proves them wrong.
- Nothing checkable in the last message? Say so in one line.
