---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Goal
Transform requirements into a clear, minimal plan that can be executed step-by-step with checkpoints.

## Process

### 1) Read the request and scope
- Confirm goals, constraints, and success criteria.
- Identify missing info; ask only if it blocks the plan.

### 2) Draft the plan
- 5–10 steps, action-oriented.
- Sequence matters; keep dependencies explicit.
- Mention key files/commands if known.

### 3) Validate against constraints
- Keep it minimal, avoid overengineering.
- Respect existing conventions and tooling.

### 4) Save the plan
- Save to `docs/plans/<slug>.md` (or the file/path user requested).
- Include: summary, constraints, plan steps, and validation notes.

### 5) Execution handoff (Codex default)
- Do not ask which approach to use.
- Default to executing sequentially in this session.
- Only mention `superpowers:executing-plans` if the user explicitly asks for a separate session.

## Style
- Use concise, direct language.
- Prefer present tense.
- Avoid unnecessary prose.

## Plan Template

```
# <Plan Title>

## Summary
- <Short summary of the goal>

## Constraints
- <Key constraints>

## Plan
1. <Step one>
2. <Step two>
3. <Step three>

## Validation
- <Tests or checks to run (if any)>
```

## Notes
- Default to sequential execution in Codex.
- Ask clarifying questions only when truly blocking.
