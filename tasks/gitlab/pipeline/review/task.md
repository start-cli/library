# Review GitLab Pipeline

Investigate a GitLab pipeline or job to determine its status, diagnose failures, and recommend fixes.

---

## Prerequisites

Confirm these values with the user before starting:

- Pipeline ID or Job ID (the user must provide at least one)
- GitLab project path (e.g., `group/project`) or project ID
- GitLab instance URL if not `https://gitlab.com`

Requirements:

- `glab` CLI authenticated, or `GITLAB_TOKEN` environment variable set
- Network access to the GitLab instance

---

## Investigation Process

Steps:

1. Determine what the user wants to review (pipeline or job)
2. Query the pipeline or job status
3. Identify failing jobs
4. Retrieve and analyse job logs
5. Determine root cause
6. Recommend a fix

---

## Step 1: Determine Review Target

Ask the user for the pipeline ID or job ID. If they provide a pipeline URL or job URL, extract the IDs from it.

Determine the GitLab project:

```bash
# If in a git repo with a GitLab remote
glab repo view

# Or use the project path directly
glab api projects/:id
```

---

## Step 2: Query Status

For a pipeline:

```bash
# Get pipeline details
glab api projects/:id/pipelines/:pipeline_id

# List all jobs in the pipeline
glab api projects/:id/pipelines/:pipeline_id/jobs
```

For a specific job:

```bash
# Get job details
glab api projects/:id/jobs/:job_id
```

Summarise the status for the user:

- Pipeline status (running, success, failed, cancelled, pending)
- List of jobs with their individual statuses
- Identify which jobs have failed

---

## Step 3: Investigate Failures

For each failing job, retrieve the log:

```bash
# Get job log (trace)
glab api projects/:id/jobs/:job_id/trace
```

Analyse the log output:

- Look for error messages, stack traces, or exit codes
- Check for timeout or runner issues
- Identify whether the failure is in the script, the environment, or the configuration
- Check for common patterns: dependency resolution failures, test failures, permission errors, resource limits

---

## Step 4: Check Configuration

If the failure appears configuration-related, examine the pipeline config:

```bash
# Get the merged pipeline YAML (resolved includes)
glab api projects/:id/ci/lint --method POST -f content_ref=:ref -f dry_run=true
```

Look for:

- Incorrect variable values or missing variables
- Wrong image or service definitions
- Rule evaluation issues (job not running when expected, or running when it should not)
- Cache or artifact misconfiguration
- Runner tag mismatches

---

## Step 5: Present Findings

Report to the user with:

- Root cause: Clear statement of what went wrong
- Evidence: Relevant log lines or configuration excerpts
- Recommendation: Specific fix with the configuration change or command needed
- If the fix involves a `.gitlab-ci.yml` change, show the diff

If the issue is environmental (runner problem, infrastructure, permissions), explain what needs to change and who would need to action it.

---

## Step 6: Additional Investigation

If the user wants to improve the pipeline rather than fix a failure:

- Review the pipeline structure for optimisation opportunities
- Identify jobs that could run in parallel
- Check for unnecessary stages or redundant work
- Look for caching improvements
- Suggest `needs` keyword for DAG optimisation
- Review artifact sizes and retention policies

---

## Troubleshooting

Common issues:

- `401 Unauthorized`: Check `GITLAB_TOKEN` is set and has `api` scope
- `404 Not Found`: Verify project path and pipeline/job ID are correct
- Empty job log: Job may still be pending or was cancelled before running
- `glab` not found: Install with `brew install glab` or equivalent
