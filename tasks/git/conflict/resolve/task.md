# Resolve Git Conflicts

Resolve git conflicts for any in-progress operation including merge, rebase,
cherry-pick, revert, stash, and patch.

## Prerequisites

- A git repository with an in-progress operation that has conflicts
- Access to both sides of the conflict to make informed resolution decisions

## Process

Steps:

1. Detect the in-progress operation
2. List all conflicted files
3. Resolve each conflict
4. Stage resolved files
5. Complete the operation

## Step 1: Detect the In-Progress Operation

Check which operation is in progress by examining git state files:

```bash
git status
```

Then identify the operation from the git state:

```bash
# Check for in-progress operations
ls .git/MERGE_HEAD 2>/dev/null && echo "merge"
ls .git/rebase-merge 2>/dev/null && echo "rebase"
ls .git/CHERRY_PICK_HEAD 2>/dev/null && echo "cherry-pick"
ls .git/REVERT_HEAD 2>/dev/null && echo "revert"
```

| State file | Operation | Continue command |
|---|---|---|
| `.git/MERGE_HEAD` | merge or pull | `git merge --continue` |
| `.git/rebase-merge/` | rebase | `git rebase --continue` |
| `.git/CHERRY_PICK_HEAD` | cherry-pick | `git cherry-pick --continue` |
| `.git/REVERT_HEAD` | revert | `git revert --continue` |
| None of the above | stash or patch | `git commit` |

Note: If no in-progress operation is detected, ask the user to describe how
the conflicts occurred before proceeding.

## Step 2: List Conflicted Files

```bash
git diff --name-only --diff-filter=U
```

This lists all files with unresolved conflict markers. Work through them
one at a time.

## Step 3: Resolve Each Conflict

For each conflicted file:

1. Read the file and locate all conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
2. For each conflict block, understand what each side is doing:
   - `<<<<<<< HEAD` to `=======` is the current branch (ours)
   - `=======` to `>>>>>>>` is the incoming change (theirs)
3. Determine the correct resolution:
   - Keep ours if the incoming change is superseded or incompatible
   - Keep theirs if our change is superseded or incorrect
   - Merge both if both changes are valid and compatible
   - Rewrite the block if neither side alone is correct
4. Remove all conflict markers and write the resolved content
5. Verify the file is syntactically correct after resolution

Note: If the correct resolution is unclear, show the user both sides and
ask for guidance before resolving.

## Step 4: Stage Resolved Files

After resolving each file, stage it:

```bash
git add <resolved-file>
```

Verify no conflicts remain:

```bash
git diff --name-only --diff-filter=U
```

This should return no output when all conflicts are resolved.

## Step 5: Complete the Operation

Run the appropriate continue command based on the operation detected in Step 1:

```bash
# merge or pull
git merge --continue

# rebase
git rebase --continue

# cherry-pick
git cherry-pick --continue

# revert
git revert --continue

# stash or patch
git commit
```

For rebase operations with multiple commits, conflicts may recur at each
commit. Repeat Steps 2-5 until the rebase completes.

Verify the final state:

```bash
git log --oneline -5
git status
```

## Troubleshooting

If you accidentally staged a file with unresolved markers:

```bash
git restore --staged <file>
```

To abort the operation entirely and return to the previous state:

```bash
git merge --abort
git rebase --abort
git cherry-pick --abort
git revert --abort
```

Note: Stash conflicts cannot be aborted after `git stash pop`. Use
`git checkout -- <file>` to discard changes to a specific file if needed.
