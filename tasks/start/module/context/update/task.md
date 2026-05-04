# Update Context

Update an existing context definition in the library repository. This is primarily a design and discussion process — understanding what the context is doing wrong or not doing, and agreeing on the changes before implementing them.

## Prerequisites

- The context path (e.g., `cwd/environment`, `cwd/dotai/environment`)
- Write access to the library repository
- CUE CLI installed (`cue version`)

## Process

Steps:

1. Identify the context to update
2. Read the current context file
3. Understand the problem
4. Design the changes
5. Implement the changes
6. Validate
7. Publish
8. Close related GitHub issue (if applicable)

## Step 1: Identify the Context

If a context path was supplied in the instructions, use it.

Otherwise, ask the user which context they want to update and confirm the full path under contexts/.

## Step 2: Read the Current Context File

Read the existing file for the context:

- `contexts/<path>/context.cue` — the full context definition

Note: Context definitions have no separate markdown file. The entire definition is in `context.cue`.

Summarise the current context configuration to the user so they can confirm your understanding before proceeding.

## Step 3: Understand the Problem

Ask the user to describe what the context is doing wrong or what it is not doing.

Probe with questions if needed:

- Is the file path or command incorrect?
- Is the prompt template not producing the right output?
- Is the selection behaviour wrong (required, default, or tag-based)?
- Are the tags inaccurate for discovery?
- Is there new information that should be included in the context?

Do not proceed until the problem is clearly understood.

## Step 4: Design the Changes

This is the core of the update process. Discuss the proposed changes with the user before writing anything.

- Describe what you plan to change and why
- For content source changes, confirm the new file path, command, or prompt template
- For selection behaviour changes, confirm whether the context should be required, default, or tag-based
- Confirm the approach with the user before proceeding

Do not implement until the design is agreed.

## Step 5: Implement the Changes

Apply the agreed changes to `context.cue`.

Update only the fields that are changing.

## Step 6: Validate

Run validation from the context directory:

```bash
cd contexts/<path>
cue mod tidy
cue vet context.cue
cue export context.cue
```

Expected results:

- `cue mod tidy` completes without errors
- `cue vet context.cue` produces no output (valid)
- `cue export context.cue` shows valid JSON with context definition

## Step 7: Publish

Determine the next patch version for the context and the index:

```bash
git ls-remote --tags origin | grep "refs/tags/contexts/<path>/" | sort -t/ -k<n> -V | tail -1
git ls-remote --tags origin | grep "refs/tags/index/" | sort -t/ -k4 -V | tail -1
```

Update the version in `index/index.cue` for the context entry, then stage both in a single commit:

```bash
git add contexts/<path>/
git add index/index.cue
git commit -m "fix(contexts): update <path> context"
git tag "contexts/<path>/${VERSION}"
git tag "index/${INDEX_VERSION}"
git push origin main
git push origin "contexts/<path>/${VERSION}"
git push origin "index/${INDEX_VERSION}"

cd contexts/<path>
cue mod publish ${VERSION}

cd <repo-root>/index
cue mod publish ${INDEX_VERSION}
```

Important: The CUE registry has tag immutability. Always check the latest remote tag with `git ls-remote` before tagging to avoid version conflicts.

## Step 8: Close Related GitHub Issue

If a GitHub issue exists for this update, close it:

```bash
gh issue close <issue-number> --repo start-cli/library --comment "Fixed in contexts/<path>@${VERSION}"
```
