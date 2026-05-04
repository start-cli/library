# Issue Triage

Investigate the next open GitHub issue for the current repository. Analyse the codebase to understand the issue, then report findings and discuss effort with the user.

## Prerequisites

- The current working directory is a git repository with a GitHub remote
- `gh` CLI is installed and authenticated
- The repository has open issues

## Process

Steps:

1. Identify the repository and select the next issue
2. Analyse the issue
3. Investigate the codebase
4. Report findings to the user
5. Discuss effort and complexity

## Step 1: Identify Repository and Select Issue

Detect the repository from the current working directory:

```bash
gh repo view --json nameWithOwner -q '.nameWithOwner'
```

List open issues sorted by creation date (oldest first) to find the next issue to triage:

```bash
gh issue list --state open -S "sort:created-asc" --json number,title,labels,createdAt,author --limit 10
```

Present the list to the user and ask which issue to triage. Default to the oldest open issue if no preference is given.

Fetch the full issue details:

```bash
gh issue view <NUMBER> --json title,body,labels,comments,assignees,createdAt,author,milestone
```

Also fetch any comments for additional context:

```bash
gh issue view <NUMBER> --comments
```

Fetch the repository's available labels for later reference:

```bash
gh label list --json name,description
```

## Step 2: Analyse the Issue

Read the issue title, body, and all comments carefully. Determine:

- What is being requested or reported
- Is this a bug report, feature request, enhancement, question, or other
- Are there reproduction steps (for bugs)
- Are there acceptance criteria (for features)
- What area of the codebase is likely affected
- Are there any linked PRs, issues, or external references

If the issue is unclear or lacks detail, note what information is missing.

## Step 3: Investigate the Codebase

Based on the issue analysis, explore the relevant parts of the codebase:

- Search for files, functions, and types related to the issue
- Read the relevant source code to understand current behaviour
- Identify the specific code paths involved
- Check for existing tests related to the affected area
- Look for related TODOs, FIXMEs, or comments in the code
- Check recent git history for the affected files to understand recent changes
- Check if there are related or duplicate issues

For bug reports:
- Try to identify the root cause from the code
- Determine if the bug is reproducible from the code path analysis

For feature requests:
- Identify where the new functionality would need to be added
- Determine what existing code would need to change
- Check if there are architectural implications

## Step 4: Report Findings

Present a structured report to the user:

### Issue Summary
- Issue number and title
- Type (bug / feature / enhancement / other)
- Age and any existing labels or milestones

### Investigation Results
- What the issue is about (in your own words, based on code analysis)
- Root cause or implementation location identified
- Files and code paths involved (with file paths and line numbers)
- Any missing information or ambiguities in the issue

### Impact Assessment
- Which parts of the codebase are affected
- Are there potential side effects from changes
- Are there existing tests covering the affected area

### Suggested Labels
- From the repository's available labels, suggest which labels best fit this issue
- Explain why each suggested label applies
- If the issue already has appropriate labels, note that no changes are needed

## Step 5: Discuss Effort and Complexity

After presenting findings, discuss the effort required with the user. Frame the conversation around:

### Complexity Rating

Suggest one of:

- Trivial: A few lines changed in one file, clear fix, low risk
- Small: Changes to 1-3 files, straightforward approach, can be done in one session
- Medium: Changes across multiple files, some design decisions needed, might need new tests
- Large: Significant changes, architectural considerations, should be broken into subtasks
- Epic: Major feature or refactor, needs a project plan with multiple phases

### What Needs to Happen

- List the specific changes required
- Identify any decisions the user needs to make
- Note any dependencies or blockers

### Recommendation

Based on the complexity:

- For Trivial/Small: Suggest proceeding directly with a fix
- For Medium: Outline the approach and confirm with the user before starting
- For Large/Epic: Recommend breaking it down into smaller issues or a project plan, and suggest what those pieces might look like

Ask the user how they want to proceed.
