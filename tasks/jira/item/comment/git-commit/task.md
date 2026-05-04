# Jira Item Git Commit Comment

Analyse git commits and changes for a given period and post a human-readable summary as a comment on a Jira work item.

## Prerequisites

- Access to Jira via available tools
- A git repository in the current working directory
- A Jira work item ID (discovered or supplied)

## Process

Steps:

1. Discover the Jira work item ID
2. Determine the time range
3. Gather git commits and changes for the period
4. Confirm with the user before continuing
5. Compose the comment
6. Post the comment

## Step 1: Discover the Work Item ID

If a work item ID was supplied in the instructions, use it.

Otherwise, attempt to discover it from context:

- The current git branch name is the strongest signal (e.g., `feature/PROJ-123-description`)
- Recent git commit messages may reference an item ID
- Other context clues in the working directory

If the item ID cannot be determined, ask the user to supply it.

## Step 2: Determine the Time Range

If a time range was supplied in the instructions, use it.

Otherwise, default to today.

## Step 3: Gather Git Commits and Changes

Retrieve the following for the determined time range:

- `git log` — commit messages and authors
- `git diff` — actual code changes, used to write a more accurate summary

If today is within the time range, also check for staged and uncommitted changes and include them in the analysis.

If staged or uncommitted changes are found, warn the user before proceeding to Step 4:

> Warning: There are staged or uncommitted changes not yet in a commit. These will be included in the analysis. Would you like to continue, or commit your changes first?

## Step 4: Confirm Before Continuing

Confirm with the user before posting anything to Jira:

- The identified work item ID
- The time range being used
- The number of commits found (and whether uncommitted changes are included)

Example:

> I've found Work Item PROJ-123 and identified 5 commits from today. Shall I continue?

If the user wants to correct any value, update accordingly before proceeding.

## Step 5: Compose the Comment

Write a technical summary of the changes suitable for a developer or tech lead reading the Jira ticket.

Structure:

- 1-2 sentence prose introduction summarising the overall work
- If commits are focused on one area: bullet points for individual changes
- If commits span multiple features or components: headed sections (### Heading) with bullets under each

Style guidelines:

- Past tense, neutral tone
- Technical language is appropriate
- File references are welcome (e.g., `auth/token.go`)
- Focus on what changed and why — the intent behind the work
- Avoid raw SHA hashes
- If there are multiple authors, mention contributors
- Use markdown formatting throughout

Period reference in the prose introduction:

- If the period is today, say "today" or omit the date entirely
- If the period is a named range (e.g., "last week"), use that natural language
- If the period is a specific past date or range, state it explicitly (e.g., "during the week of 24 Mar 2026")

Single area example:

> Authentication module work continued today, focusing on token lifecycle improvements.
>
> - Refactored `auth/token.go` to correctly handle expiry edge cases in the refresh flow
> - Resolved a bug in `auth/logout.go` causing intermittent session failures on concurrent requests
> - Updated `auth/token_test.go` to cover the new refresh behaviour

Multi-area example:

> Work covered several areas of the codebase during the week of 24 Mar 2026.
>
> ### Authentication
> - Refactored `auth/token.go` to correctly handle expiry edge cases
> - Resolved a bug in `auth/logout.go` causing intermittent session failures
>
> ### API Layer
> - Added rate limiting middleware in `api/middleware.go`
> - Updated `api/routes.go` to apply limits to all public endpoints
>
> ### Tests
> - Extended `auth/token_test.go` and `api/middleware_test.go` to cover new behaviour

## Step 6: Post the Comment

Post the composed summary as a comment on the Jira work item.

Confirm to the user that the comment was posted successfully.
