# Multi-Agent Review Orchestrator

Orchestrate a comprehensive code review by discovering relevant review types and spawning parallel review agents.

## Step 1: Discover Edit Agent

Run the following command to find installed agents:

```
start config list agents
```

Select an agent with "edit" in the name. Edit agents auto-accept file writes while maintaining other safety permissions.

Do not use "unattended" or "bypass-permissions" variants.

If no edit agent is installed, search the registry for one:

```
start assets list agents
```

Pick an agent with "edit" in the name and install it:

```
start assets add agents:<name>
```

If no edit agent is available at all, use a standard agent.

Record the selected agent name for use in Step 5.

## Step 2: Discover Review Tasks

Run the following command to list available review tasks:

```
start assets search review/
```

Extract review task names from the output. Exclude any task with "orchestrator" in the name.

## Step 3: Install Missing Modules

Check installed modules:

```
start assets list
```

Install each review task from Step 2 that is not already installed:

```
start assets add review/<name>
```

## Step 4: Analyse Codebase for Relevance

Analyse the project structure, source files, dependencies, and patterns to determine which of the discovered review types apply. Select only the reviews that are relevant to what the project actually contains.

## Step 5: Spawn Parallel Reviews

Create the output directory:

```bash
mkdir -p .start/reviews
```

Launch each selected review as a separate shell tool call so they can be monitored independently:

```bash
start task review/<type> --agent <agent> "Write your review report to .start/reviews/ using the filename pattern YYYY-MM-DD-<type>-NN.md where NN is a zero-padded sequential count starting at 01 based on existing matching files. Use low-token markdown: headings, lists, tables, code blocks, callout prefixes (NOTE:, WARNING:, IMPORTANT:). Do not use bold, italic, horizontal rules, emojis, HTML comments, or nested lists beyond 3 levels."
```

Replace `<type>` with each selected review name and `<agent>` with the agent from Step 1. Execute one shell tool call per review so each runs as a separate background process.

## Step 6: Monitor Progress

As reviews complete, report progress using this format:

```
Status: <N> done, <N> running, <N> pending

| Review      | Status  | Output                                    |
|-------------|---------|-------------------------------------------|
| security    | Done    | .start/reviews/YYYY-MM-DD-security-01.md  |
| correctness | Running | —                                         |
| holistic    | Pending | —                                         |
```

After each review completes, verify:

- The expected output file exists in `.start/reviews/`
- The file is not suspiciously small (under ~200 bytes may indicate an error)

Mark any review with a missing or empty output file as failed and note it in the Step 7 summary.

## Step 7: Summarise Findings

After all reviews complete, read every generated report in `.start/reviews/`.

Compile a prioritised summary of findings across all reports:

- Critical findings: issues that must be addressed
- High findings: issues that should be addressed
- Medium findings: issues worth considering

Not all reviews produce severity-tagged findings. Reviews like security and correctness classify by severity natively; others organise by type, location, or impact. Use your judgement to assign severity to unclassified findings based on their potential effect on correctness, security, and reliability.

Each finding should include: source review, brief description, file or location.

Also report:

- Reviews selected and rationale for selection
- Reviews skipped and rationale for skipping
- Any failures or issues encountered
