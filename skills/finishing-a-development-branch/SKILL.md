---
name: finishing-a-development-branch
description: Use when implementation is complete and you need to decide how to integrate the work, including cases where tests pass or are explicitly waived by the user
---

# Finishing a Development Branch

## Overview

Guide completion of development work by presenting clear options and handling the chosen workflow.

**Core principle:** Ask test choice -> Rebase (if merging) -> Verify tests (or record explicit waiver) -> Execute choice -> Clean up.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## The Process

### Step 1: Choose Test Path (Run or Waive)

**Before presenting options, ask:**
```
Do you want to run tests or waive them?
Reply with exactly one: run / waive
(Also accepted: 1=run, 2=waive)
```

If the response is `run` or `1`:
```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**If tests fail:**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

Stop. Don't proceed to Step 2.

**If tests pass:** Continue to Step 2.

If the response is `waive` or `2`:
- Continue to Step 2 **and** record: `Tests: not run (waived by user)` in the final summary and PR Test Plan.

If the response is anything else, stop and ask again.

**Do not proceed to Step 2 until the user explicitly replies `run` or `waive` (or `1`/`2`).**

### Step 2: Determine Base Branch

If the user specified a base branch (e.g., "alpha"), use that.

Otherwise, try common local base branches in this order: `alpha`, `main`, `master`.

```bash
for b in alpha main master; do
  if git show-ref --verify --quiet "refs/heads/$b" && git merge-base --is-ancestor "$b" HEAD; then
    echo "$b"
    break
  fi
done
```

If none match, ask: "Which local base branch should I integrate into (e.g., `alpha`, `main`)?"

**Assume local branches only.** Do not run `git pull` or rebase onto `origin/<branch>` unless the user explicitly asks.

### Step 3: Present Options

Present exactly these 4 options:

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

**Don't add explanation** - keep options concise.

**Do not execute any option until the user explicitly selects a numbered choice.**

### Step 4: Execute Choice

#### Option 1: Merge Locally (squash)

Before committing the squash:
- If this branch resolves Sentry issue(s) and base branch is `alpha` or `v2`, require issue short ID(s) in the subject.
- If short ID(s) are missing, ask once:
  `Provide Sentry short ID(s) for squash subject (e.g., HOPS-IOS-6D or HOPS-IOS-6D,HOPS-IOS-6F).`
- Subject format for Sentry fixes:
  `<HOPS-IOS IDs>: <summary> (session: ${SESSION_ID})`

```bash
# Rebase feature branch on local base branch (in the feature branch worktree)
# Use rebase-before-merge (honor test choice)

# Switch to base branch
git checkout <base-branch>

# Squash-merge feature branch
git merge --squash <feature-branch>

# Commit with session id (prefer $CODEX_THREAD_ID)
SESSION_ID="${CODEX_THREAD_ID:-unknown}"
# For Sentry fixes on alpha/v2: use "<HOPS-IOS IDs>: <summary> (session: ${SESSION_ID})"
git commit -m "<summary> (session: ${SESSION_ID})"
```

Then: Cleanup worktree + branch (Step 5)

#### Option 2: Push and Create PR

```bash
# Rebase feature branch on local base branch (in the feature branch worktree)
# Use rebase-before-merge (honor test choice)
```

```bash
# Push branch
git push -u origin <feature-branch>

# Create PR
cat > /tmp/pr_body.md <<'PR'
## Summary
<2-3 bullets of what changed>

## Test Plan
- [ ] <verification steps or "Tests: not run (waived by user)">
PR

gh pr create --title "<title>" --body-file /tmp/pr_body.md
```

Then: Keep worktree (do not remove unless the user asks)

#### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

**Don't cleanup worktree.**

#### Option 4: Discard

**Confirm first:**
```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

Wait for exact confirmation.

If confirmed:
```bash
git checkout <base-branch>
```

Then: Cleanup worktree + branch (Step 5)

### Step 5: Cleanup Worktree and Branch

**For Options 1 and 4:**

1) Identify feature-branch worktree path:
```bash
git worktree list
```

2) Remove the worktree first (if present):
```bash
git worktree remove <worktree-path>
```

3) Attempt branch cleanup once:
```bash
# Option 1 (merged branch): safe delete
git branch -d <feature-branch>

# Option 4 (discard): force delete
git branch -D <feature-branch>
```

If cleanup fails with policy/sandbox rejection (for example `blocked by policy` or `Rejected(`):
- Stop retrying immediately.
- Report cleanup as deferred.
- Provide exact manual cleanup commands to the user.

**For Options 2 and 3:** Keep worktree.

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | ✓ | - | - | ✓ |
| 2. Create PR | - | ✓ | ✓ | - |
| 3. Keep as-is | - | - | ✓ | - |
| 4. Discard | - | - | - | ✓ (force) |

## Common Mistakes

**Skipping the test choice prompt**
- **Problem:** Surprises the user or runs tests they didn't want
- **Fix:** Ask run vs waive before offering options

**Skipping rebase before merge**
- **Problem:** Squash merge hides conflicts or reintroduces stale base changes
- **Fix:** Use `rebase-before-merge` to rebase and resolve conflicts before merging or creating a PR

**Missing Sentry IDs in squash subject**
- **Problem:** Sentry-related squash commit on `alpha`/`v2` lacks traceable issue ID(s)
- **Fix:** Require `HOPS-IOS-*` prefix in the squash subject for Sentry fixes

**Open-ended questions**
- **Problem:** "What should I do next?" -> ambiguous
- **Fix:** Present exactly 4 structured options

**Assuming `origin/<branch>` exists**
- **Problem:** `origin/alpha` may not exist; rebase/pull fails
- **Fix:** Use local base branch only unless user explicitly requests a remote sync

**Automatic worktree cleanup**
- **Problem:** Remove worktree when might need it (Option 2, 3)
- **Fix:** Only cleanup for Options 1 and 4

**Retrying blocked cleanup commands**
- **Problem:** Repeated destructive cleanup attempts can loop when policy blocks them
- **Fix:** Attempt once, then mark cleanup deferred and provide manual commands

**Editing generated Xcode project files (XcodeGen repos)**
- **Problem:** Direct edits to `*.xcodeproj/project.pbxproj` drift from `project.yml` / generator output
- **Fix:** Edit the project spec (often `project.yml`) and re-run XcodeGen; avoid hand-editing `.pbxproj`

## Red Flags

**Never:**
- Proceed with failing tests
- Merge without verifying tests on result **or** explicit waiver
- Proceed without explicit test waiver response (`waive`) when skipping tests
- Delete work without confirmation
- Force-push without explicit request
- Run `git pull` or rebase onto `origin/<branch>` without explicit user request
- Hand-edit `*.xcodeproj/project.pbxproj` in XcodeGen-based repos
- Retry cleanup delete commands after policy/sandbox rejection

**Always:**
- Ask run vs waive before offering options
- Rebase feature branch on the local base branch before merging or pushing a PR (use `rebase-before-merge`)
- Verify tests **or** obtain explicit waiver response (`waive`) before offering options
- For Sentry fixes merged to `alpha`/`v2`, include `HOPS-IOS-*` short ID(s) in the squash commit subject
- Present exactly 4 options
- Get typed confirmation for Option 4
- Clean up worktree for Options 1 & 4 only
- Stop cleanup retries after a policy/sandbox block and report deferred cleanup explicitly

## Integration

**Called by:**
- `subagent-driven-development` (after all tasks complete)
- `executing-plans` (after all batches complete)

**Pairs with:**
- `using-git-worktrees` - helps keep feature work isolated and supports safe cleanup
