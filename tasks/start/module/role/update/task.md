# Update Role

Update an existing role in the library repository. This is primarily a design and discussion process — understanding what the role is doing wrong or not doing, and agreeing on the changes before implementing them.

## Prerequisites

- The role path (e.g., `golang/assistant`, `gitlab/pipeline/agent`)
- Write access to the library repository
- CUE CLI installed (`cue version`)

## Preconditions

Before starting, verify the role actually exists at `roles/<path>/`. If the target directories are missing, this task is the wrong one — direct the user to `start/module/role/create` to author a new role.

## Process

Steps:

1. Identify the role to update
2. Read the current role files
3. Understand the problem
4. Design the changes
5. Implement the changes
6. Validate
7. Publish
8. Close related GitHub issue (if applicable)

## Step 1: Identify the Role

If a role path was supplied in the instructions, use it.

Otherwise, ask the user which role they want to update. Confirm whether the change affects one mode (agent, assistant, or teacher) or all three.

## Step 2: Read the Current Role Files

Read the existing files for each affected mode:

- `roles/<path>/<mode>/role.cue` — the CUE schema definition
- `roles/<path>/<mode>/role.md` — the role prompt content

Summarise the current role behaviour to the user so they can confirm your understanding before proceeding.

## Step 3: Understand the Problem

Ask the user to describe what the role is doing wrong or what it is not doing.

Probe with questions if needed:

- Is the agent's tone or behaviour off?
- Is a skill or knowledge area missing from the role?
- Are the instructions too restrictive or too permissive?
- Is there a new capability or constraint to add?
- Does the problem affect all three modes or just one?

Do not proceed until the problem is clearly understood.

## Step 4: Design the Changes

This is the core of the update process. Discuss the proposed changes with the user before writing anything.

- Describe what you plan to change and why
- Confirm which modes are affected (agent, assistant, teacher, or all)
- Note that the Skill Set and base Restrictions are shared across modes — changes here affect all three
- Mode-specific changes (Instructions tone, identity bullets) only affect the targeted mode(s)
- Confirm the approach with the user before proceeding

Do not implement until the design is agreed.

## Step 5: Implement the Changes

Apply the agreed changes to the affected role files.

Update only the sections that are changing. Do not rewrite sections that are not affected.

When adding new content (instructions, identity bullets, restrictions), follow the authoring rules from `start/module/role/create` — in particular the required Instructions directives (style, quality, comment discipline) and the Restrictions guidance (intrinsic role constraints, not task directives). To view the create task content, run:

```bash
start get start/module/role/create
```

If the change affects all three modes, apply consistently across agent, assistant, and teacher, respecting the mode-specific tone of each.

## Step 6: Validate

Run validation from each affected mode directory:

```bash
cd roles/<path>/<mode>
cue mod tidy
cue vet role.cue
cue export role.cue
```

Repeat for each affected mode.

## Step 7: Publish

Determine the next patch version for each affected mode and the index:

```bash
# Check latest tags for affected modes (path-depth-agnostic)
git ls-remote --tags origin "refs/tags/roles/<path>/*" | sed 's|.*/||' | sort -V | tail -1

# Check latest index tag
git ls-remote --tags origin | grep "refs/tags/index/" | sort -t/ -k4 -V | tail -1
```

Update the version in `index/index.cue` for each affected mode entry, then stage everything in a single commit:

```bash
# Stage all affected mode files and index together
git add roles/<path>/<mode>/       # repeat for each affected mode
git add index/index.cue
git commit -m "fix(roles): update <path> role"

# Tag each affected mode and the index
git tag "roles/<path>/<mode>/${VERSION}"   # repeat for each
git tag "index/${INDEX_VERSION}"

# Push everything
git push origin main
git push origin "roles/<path>/<mode>/${VERSION}"  # repeat for each
git push origin "index/${INDEX_VERSION}"

# Publish each affected mode module
cd roles/<path>/<mode> && cue mod publish ${VERSION}  # repeat for each

# Publish index
cd <repo-root>/index && cue mod publish ${INDEX_VERSION}
```

Important: The CUE registry has tag immutability. Always check the latest remote tag with `git ls-remote` before tagging to avoid version conflicts.

## Step 8: Close Related GitHub Issue

If a GitHub issue exists for this update, close it:

```bash
gh issue close <issue-number> --repo start-cli/library --comment "Fixed in roles/<path>/<mode>@${VERSION}"
```
