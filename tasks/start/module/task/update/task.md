# Update Task

Update an existing task in the start-cli/library repository. This is primarily a design and discussion process — understanding what the task is doing wrong or not doing, and agreeing on the changes before implementing them.

## Prerequisites

- The task path under tasks/ (e.g., `jira/item/comment/git-commit`)
- Write access to the start-cli/library repository
- CUE CLI installed (`cue version`)

## Process

Steps:

1. Identify the task to update
2. Read the current task files
3. Understand the problem
4. Design the changes
5. Implement the changes
6. Validate
7. Publish
8. Close related GitHub issue (if applicable)

## Step 1: Identify the Task

If a task path was supplied in the instructions, use it.

Otherwise, ask the user which task they want to update and confirm the full path under tasks/.

## Step 2: Read the Current Task Files

Read the existing files for the task:

- `tasks/<path>/task.md` — the task instructions
- `tasks/<path>/task.cue` — the CUE schema definition
- `tasks/<path>/cue.mod/module.cue` — the module definition

Summarise the current task behaviour to the user so they can confirm your understanding before proceeding.

## Step 3: Understand the Problem

Ask the user to describe what the task is doing wrong or what it is not doing.

Probe with questions if needed:

- Is the agent misunderstanding a step?
- Is a step missing or incomplete?
- Is the output format wrong?
- Is the confirmation or interaction behaviour off?
- Is there a new requirement to add?

Do not proceed until the problem is clearly understood.

## Step 4: Design the Changes

This is the core of the update process. Discuss the proposed changes with the user before writing anything.

- Describe what you plan to change and why
- If multiple changes are needed, discuss each one
- Confirm the approach with the user before proceeding
- Consider whether changes affect task.md only, or also task.cue

Do not implement until the design is agreed.

## Step 5: Implement the Changes

Apply the agreed changes to the task files.

If task.md is changing, update the relevant sections only — do not rewrite sections that are not affected.

If task.cue is changing (e.g., description, tags, prompt), update accordingly.

## Step 6: Validate

Run validation from the task directory:

```bash
cd tasks/<path>
cue mod tidy
cue vet task.cue
```

Expected results:

- `cue mod tidy` completes without errors
- `cue vet task.cue` produces no output (valid)

## Step 7: Publish

Determine the next patch version for the task and the index:

```bash
git ls-remote --tags origin | grep "refs/tags/tasks/<path>/" | sort -t/ -k<n> -V | tail -1
git ls-remote --tags origin | grep "refs/tags/index/" | sort -t/ -k4 -V | tail -1
```

Update the version in `index/index.cue` for the task entry, then stage both together in a single commit:

```bash
git add tasks/<path>/
git add index/index.cue
git commit -m "fix(tasks): update <path> task"
git tag "tasks/<path>/${VERSION}"
git tag "index/${INDEX_VERSION}"
git push origin main
git push origin "tasks/<path>/${VERSION}"
git push origin "index/${INDEX_VERSION}"

cd tasks/<path>
cue mod publish ${VERSION}

cd <repo-root>/index
cue mod publish ${INDEX_VERSION}
```

Important: The CUE registry has tag immutability. Always check the latest remote tag with `git ls-remote` before tagging to avoid version conflicts.

## Step 8: Close Related GitHub Issue

If a GitHub issue exists for this update, close it:

```bash
gh issue close <issue-number> --repo start-cli/library --comment "Fixed in tasks/<path>@${VERSION}"
```
