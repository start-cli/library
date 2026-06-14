# Create Role

Create a new role in the library repository. This is an interactive process that produces all three modes (agent, assistant, teacher) for a given domain.

## Prerequisites

Confirm these values with the user before starting:

- Domain: The subject area (e.g., `golang`, `terraform`, `python`)
- Specialisation: Optional narrowing segment (e.g., `pipeline` under `gitlab`)
- Description Base: Brief description of the role's expertise (e.g., "Go programming language expert")
- Source Content: Either:
  - An existing role document to adapt
  - A description of the domain expertise (to create from scratch)

Requirements:

- Write access to the library repository
- CUE CLI installed (`cue version`)
- Understanding of the domain the role covers

## Preconditions

Before starting, verify the role does not already exist. Check whether `roles/<domain>/[specialisation/]agent`, `.../assistant`, or `.../teacher` directories are present. If any exist, this task is the wrong one — direct the user to `start/module/role/update` to modify an existing role.

## Role Creation Process

Steps:

1. Gather prerequisites from user
2. Design the role interactively
3. Create directory structure for all three modes
4. Create role.cue for each mode
5. Create role.md for each mode using the Role Prompt Guide
6. Create cue.mod/module.cue for each mode
7. Publish following the publishing workflow

## Step 1: Gather Prerequisites

Ask the user for:

1. Domain - kebab-case subject area (e.g., `golang`, `gitlab`, `markdown`)
2. Specialisation - optional narrowing segment (e.g., `pipeline`, `low-token`). Omit if not needed
3. Description base - the expertise summary without mode suffix (e.g., "Go programming language expert")
4. Source - either a file path to adapt or a description of the domain expertise

The role path follows the naming standard: `domain/[specialisation/]mode`

Example values:

```
Domain: terraform
Specialisation: (none)
Description base: Terraform infrastructure-as-code expert
Source: Expert in HashiCorp Terraform for cloud infrastructure provisioning and management
```

## Step 2: Design the Role

Before creating any files, discuss and agree on the following with the user:

- Domain and specialisation — confirm the path is correct and follows naming conventions
- Role identity — what makes this role distinctive; key skills and mindset
- Content source — whether to adapt an existing document or draft from scratch
- Style word — which style word best fits the domain (creativity, conciseness, precision, depth, elegance, performance)

This task always produces all three modes (agent, assistant, teacher). Mode selection is not optional.

Do not proceed to file creation until the design is agreed.

## Step 3: Create Directory Structure

Create directories for all three modes:

```bash
DOMAIN="<domain>"
# Include specialisation in path if provided
SPEC=""  # or "<specialisation>/"

mkdir -p roles/${DOMAIN}/${SPEC}agent/cue.mod
mkdir -p roles/${DOMAIN}/${SPEC}assistant/cue.mod
mkdir -p roles/${DOMAIN}/${SPEC}teacher/cue.mod
```

Expected structure:

```
roles/<domain>/[specialisation/]
├── agent/
│   ├── cue.mod/module.cue
│   ├── role.cue
│   └── role.md
├── assistant/
│   ├── cue.mod/module.cue
│   ├── role.cue
│   └── role.md
└── teacher/
    ├── cue.mod/module.cue
    ├── role.cue
    └── role.md
```

## Step 4: Create role.cue for Each Mode

Each mode's `role.cue` uses this template, varying only by mode:

```cue
package <mode>

import "github.com/start-cli/library/schemas@v1"

role: schemas.#Role & {
	description: "<description-base> - <suffix>"
	tags: ["<domain>", "<topic-tags>", <mode-tags>]
	file: "@module/role.md"
}
```

Mode-specific values:

| Mode | Package | Suffix | Mode tags |
| --- | --- | --- | --- |
| agent | `agent` | `autonomous agent mode` | `"agent", "autonomous"` |
| assistant | `assistant` | `collaborative assistant mode` | `"assistant", "collaborative"` |
| teacher | `teacher` | `instructional teacher mode` | `"teacher", "instructional", "learning"` |

Notes:

- Package name must match the mode directory name
- Tags use kebab-case and include the domain plus mode-relevant keywords
- The `@module/` prefix resolves to the role's directory at runtime

## Step 5: Create role.md for Each Mode

Write the role.md content for each mode. Use the Role Prompt Guide below to generate each role.md, applying the mode-specific adjustments described after it.

### Role Prompt Guide

Use this guide to craft the content for each role.md file:

- Determine the best topic name or phrase and use it as the role title
- Think carefully before writing; the output should be complete and well-considered
- The generated Instructions section must contain only role-level behavioural guidelines, not task directives
- In the Instructions section, include a style directive:
  - Use this list of style words: creativity, conciseness, precision, depth, elegance, performance
  - Choose the most fitting style word based on the topic's nature (e.g., "creativity" for brainstorming, "precision" for technical specs, "depth" for analysis)
  - If unsure, default to conciseness
  - Add this line: "Prioritise <chosen-style> in your responses"
- In the Instructions section, include a quality directive:
  - Add this line: "Bias your work toward the principled long-term solution that reduces maintenance and improves quality. Do not default to the smallest-diff fix."
- In the Instructions section, include a comment discipline directive:
  - Add this line: "Default to writing no comments. Add a comment only when the WHY is non-obvious — a hidden constraint, invariant, intentional tradeoff, or surprising behaviour — and keep it to one short line."
  - Add this line: "Never restate what code does in comments. Never leave task, PR, ticket, or conversation references. Never leave bare TODOs without an owner or tracker."

Restrictions:

- Keep the prompt succinct
- Follow the markdown rules from the repository code style (no bold, italic, emojis, horizontal rules; use headings, code blocks, tables, lists)
- Follow the required sections and format below

Required sections:

- Title: a `# Role:` heading followed by identity and capability bullets
- Skill Set: a numbered list of skills relevant to the role
- Instructions: role-level behavioural guidelines only; no task directives
- Restrictions: boundaries and constraints intrinsic to the role

Optional sections (include only if they add meaningful context):

- Context: background on the domain or environment the agent operates in
- Constraints: specific external limitations the agent must work within
- Format: expected output format for the role's responses
- Example: a sample interaction demonstrating the role in action
- Project: background context if the role is tied to a specific project

Format rules:

- Avoid periods at the end of list items
- Identity bullets should go beyond restating the role title — convey the mindset, approach, and distinctive qualities that make the role effective
- The Skill Set should be specific to the role; each skill should be directly relevant and meaningful for the topic
- Restrictions are intrinsic role constraints, not task instructions — keep task-level directives out of the Restrictions section

Tailor the identity bullets and skill set to the nature of the role:

| Role nature | Emphasise |
| --- | --- |
| Technical | problem-solving, debugging, algorithmic thinking, attention to detail |
| Creative | originality, ideation, audience awareness, aesthetic judgment |
| Analytical | critical thinking, pattern recognition, data interpretation, synthesis |
| Communication | clarity, tone, empathy, precision |
| Domain Expert | deep knowledge, accuracy, current awareness of the field |

Output template:

```md
# Role: <role-title>

- You are an expert in <topic>
<list-of-identity-bullets>

## Skill Set

<numbered-list-of-required-skills>

## Instructions

<list-of-instructions>

## Restrictions

<list-of-restrictions>
```

### Mode-Specific Adjustments

Apply these adjustments when generating each mode's role.md:

Agent mode:

- Title suffix: "- Autonomous Agent"
- Identity bullets: emphasise autonomy, initiative, independent decision-making
- Instructions tone: operate autonomously, make informed decisions, act without asking, communicate concisely about actions taken
- Add this line: "Operate autonomously with minimal need for user confirmation"
- Add this line: "Proactively identify and resolve potential issues"
- Restrictions: add "Make reasonable assumptions when details are not specified, documenting them clearly"

Assistant mode:

- Title: no suffix (this is the default mode)
- Identity bullets: emphasise collaboration, debugging skill, creative problem-solving
- Instructions tone: collaborative, friendly, interactive, clarify requirements, work alongside the user
- Add this line: "Be a helpful assistant who clarifies requirements, designs, implements, tests, and deploys perfect solutions"
- Add this line: "Communicate in a friendly manner"

Teacher mode:

- Title suffix: "- Teacher"
- Identity bullets: emphasise teaching passion, clear explanation, patience
- Instructions tone: educational, patient, thorough explanations, build understanding
- Add this line: "Be a patient teacher who explains concepts thoroughly and checks for understanding"
- Add this line: "Focus on building understanding, not just providing solutions"
- Restrictions: add "Don't assume prior knowledge — explain foundational concepts when needed"

### Content Consistency

The three modes for a role share:

- The same Skill Set (domain knowledge is identical across modes)
- The same Restrictions base (domain constraints apply equally)
- Similar identity bullets (adapted for mode tone)

They differ in:

- Title suffix
- Instructions section (mode-specific behavioural guidelines)
- Additional restrictions specific to the mode

## Step 6: Create cue.mod/module.cue for Each Mode

Create a module definition for each mode:

```cue
module: "github.com/start-cli/library/roles/<domain>/[specialisation/]<mode>@v1"
language: {
	version: "v0.16.0"
}
source: {
	kind: "git"
}
deps: {
	"github.com/start-cli/library/schemas@v1": {
		v: "v1.0.0"
	}
}
```

Replace `<domain>`, `[specialisation/]`, and `<mode>` with the actual values. Create one for each of the three modes: agent, assistant, teacher.

## Step 7: Publish

Before publishing, confirm the role is complete: all three modes (agent, assistant, teacher) are authored, the shared Skill Set and base Restrictions are consistent across the three, and each mode's `role.cue` and `role.md` are present.

Then load the publishing workflow and follow it end to end:

```bash
start get contexts:start/library/publishing
```

It is the single source for validation, version determination, the mandatory index update, the single module-plus-index commit, the tag pushes, the registry publish, verification, and closing any related GitHub issue. A role publishes all three modes, so apply the per-module steps once per mode and add one index entry per mode, as the workflow describes. This is a create, so each mode starts at v1.0.0.
