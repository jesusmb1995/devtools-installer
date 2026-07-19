---
name: team-investigate
description: Spawn multiple subagents to parallelize investigation. Each subagent investigates one part (e.g., one CI failure, one file, one component). After all finish, aggregate results and continue in main agent. Use when user asks to investigate multiple things, check many failures, or parallelize analysis.
---

# Team Investigate

## What it do

Split big investigation into small pieces. Each piece get own subagent. All run same time. When done, collect results. Continue in main.

## When use

- CI have many failures → one agent per failure
- Many files need check → one agent per file
- Multiple components broken → one agent per component
- User say "investigate X, Y, Z" → one agent per thing

## How do

### Step 1: Break into pieces

Identify distinct investigation targets. Each target = one subagent.

**Example:**
- CI log show 3 test failures → 3 targets
- User say "check auth and payment" → 2 targets

### Step 2: Spawn parallel subagents

Use Task tool with `run_in_background: true`. Launch all subagents in single message for max parallel.

```markdown
Use Task tool for each investigation:
- description: Short name (e.g., "investigate auth failure")
- prompt: What to investigate + what info return
- subagent_type: generalPurpose
- run_in_background: true
```

**Critical:** Tell each subagent what info to return. Be specific.

### Step 3: Wait for completion

System notify when all done. Do NOT poll with AwaitShell. Just wait.

### Step 4: Aggregate and continue

When notifications arrive:
1. Read all subagent results
2. Synthesize findings
3. Report to user in main agent
4. Continue work based on findings

## Example workflow

**User ask:** "CI failed with 3 test errors. Investigate all."

**What do:**

1. **Parse failures:** Extract 3 distinct test names from CI log

2. **Launch 3 subagents in parallel:**
   ```
   Subagent 1: "Investigate test_auth_login failure"
   Subagent 2: "Investigate test_payment_process failure"  
   Subagent 3: "Investigate test_user_registration failure"
   ```

3. **Each subagent told:**
   - Which test failed
   - Find root cause
   - Return: test name, cause, file locations, suggested fix

4. **After all finish:**
   - Collect 3 reports
   - Show user summary table
   - Prioritize fixes
   - Continue with fixes if user want

## Tips

### Launch parallel

Always spawn all subagents in ONE message using multiple Task tool calls. This run them all same time.

**Good:**
```
[Single response with 3 Task tool calls]
```

**Bad:**
```
[Response with 1 Task tool call]
[Wait for result]
[Response with another Task tool call]
```

### Tell subagent what return

Be explicit. Subagent not know what you need.

**Good prompt:**
"Investigate auth test failure. Return: 1) failure cause, 2) which file/line, 3) minimal fix suggestion."

**Bad prompt:**
"Look at auth test."

### Keep subagent focused

One clear task per subagent. Not "investigate everything."

### Handle completion

System send notification when subagent done. Notification include summary. Read it. Continue from there.

## Common patterns

### Pattern: CI multiple failures

```
1. Parse CI log for distinct failures
2. One subagent per failure
3. Each returns: failure type, location, cause, fix
4. After all done: prioritize, fix in order
```

### Pattern: Multi-component check

```
1. Identify components (auth, db, api, frontend)
2. One subagent per component  
3. Each returns: component status, issues found, severity
4. After all done: summary report, tackle critical first
```

### Pattern: File investigation

```
1. Get file list needing review
2. One subagent per file or file group
3. Each returns: issues in file, severity, line numbers
4. After all done: consolidated issue list
```

## What NOT do

- Don't spawn subagent for single simple thing (just do it)
- Don't poll/check subagents (system notify when done)
- Don't make subagent spawn more subagents (keep flat)
- Don't use if investigation too small (overhead not worth)

## Summary

Split work → spawn parallel subagents → wait for all → collect results → continue in main.

Simple. Fast. Efficient.
