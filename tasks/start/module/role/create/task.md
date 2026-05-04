# Create Role

Create a new role in the start-cli/library repository. This is an interactive process that produces all three modes (agent, assistant, teacher) for a given domain.

## Prerequisites

Confirm these values with the user before starting:

- Domain: The subject area (e.g., `golang`, `terraform`, `python`)
- Specialisation: Optional narrowing segment (e.g., `pipeline` under `gitlab`)
- Description Base: Brief description of the role's expertise (e.g., "Go programming language expert")
- Source Content: Either:
  - An existing role document to adapt
  - A description of the domain expertise (to create from scratch)

Requirements:

- Write access to the start-cli/library repository
- CUE CLI installed (`cue version`)
- Understanding of the domain the role covers

## Role Creation Process

Steps:

1. Gather prerequisites from user
2. Design the role interactively
3. Create directory structure for all three modes
4. Create role.cue for each mode
5. Create role.md for each mode using the Role Prompt Guide
6. Create cue.mod/module.cue for each mode
7. Validate with CUE tools
8. Publish to CUE registry
9. Close related GitHub issue (if applicable)

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
- Three-mode approach — confirm whether all three modes (agent, assistant, teacher) are needed
- Role identity — what makes this role distinctive; key skills and mindset
- Content source — whether to adapt an existing document or draft from scratch
- Style word — which style word best fits the domain (creativity, conciseness, precision, depth, elegance, performance)

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

## Step 3: Create role.cue for Each Mode

Create three role.cue files. The only differences are the package name, description suffix, and tags.

Agent (`agent/role.cue`):

```cue
package agent

import "github.com/start-cli/library/schemas@v1"

role: schemas.#Role & {
	description: "<description-base> - autonomous agent mode"
	tags: ["<domain>", "<topic-tags>", "agent", "autonomous"]
	file: "@module/role.md"
}
```

Assistant (`assistant/role.cue`):

```cue
package assistant

import "github.com/start-cli/library/schemas@v1"

role: schemas.#Role & {
	description: "<description-base> - collaborative assistant mode"
	tags: ["<domain>", "<topic-tags>", "assistant", "collaborative"]
	file: "@module/role.md"
}
```

Teacher (`teacher/role.cue`):

```cue
package teacher

import "github.com/start-cli/library/schemas@v1"

role: schemas.#Role & {
	description: "<description-base> - instructional teacher mode"
	tags: ["<domain>", "<topic-tags>", "teacher", "instructional", "learning"]
	file: "@module/role.md"
}
```

Notes:

- Package name must match the mode directory name
- Tags use kebab-case and include the domain plus mode-relevant keywords
- The `@module/` prefix resolves to the role's directory at runtime

## Step 4: Create role.md for Each Mode

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
- Identity bullets should go beyond restating the role title -- convey the mindset, approach, and distinctive qualities that make the role effective
- The Skill Set should be specific to the role; each skill should be directly relevant and meaningful for the topic
- Tailor the identity bullets and skill set to the nature of the role:
  - Technical: emphasise problem-solving, debugging, algorithmic thinking, attention to detail
  - Creative: emphasise originality, ideation, audience awareness, and aesthetic judgment
  - Analytical: emphasise critical thinking, pattern recognition, data interpretation, and synthesis
  - Communication: emphasise clarity, tone, empathy, and precision
  - Domain Expert: emphasise deep knowledge, accuracy, and current awareness of the field

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
- Add: "Operate autonomously with minimal need for user confirmation"
- Add: "Proactively identify and resolve potential issues"
- Restrictions: add "Make reasonable assumptions when details are not specified, documenting them clearly"

Assistant mode:

- Title: no suffix (this is the default mode)
- Identity bullets: emphasise collaboration, debugging skill, creative problem-solving
- Instructions tone: collaborative, friendly, interactive, clarify requirements, work alongside the user
- Add: "Be a helpful assistant who clarifies requirements, designs, implements, tests, and deploys perfect solutions"
- Add: "Communicate in a friendly manner"

Teacher mode:

- Title suffix: "- Teacher"
- Identity bullets: emphasise teaching passion, clear explanation, patience
- Instructions tone: educational, patient, thorough explanations, build understanding
- Add: "Be a patient teacher who explains concepts thoroughly and checks for understanding"
- Add: "Focus on building understanding, not just providing solutions"
- Restrictions: add "Don't assume prior knowledge - explain foundational concepts when needed"

### Content Consistency

The three modes for a role share:

- The same Skill Set (domain knowledge is identical across modes)
- The same Restrictions base (domain constraints apply equally)
- Similar identity bullets (adapted for mode tone)

They differ in:

- Title suffix
- Instructions section (mode-specific behavioural guidelines)
- Additional restrictions specific to the mode

## Step 5: Create cue.mod/module.cue for Each Mode

Create a module definition for each mode:

```cue
module: "github.com/start-cli/library/roles/<domain>/[specialisation/]<mode>@v0"
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

## Step 6: Validate with CUE Tools

Run validation from each mode directory:

```bash
# Repeat for each mode: agent, assistant, teacher
cd roles/<domain>/[specialisation/]<mode>
cue mod tidy
cue vet role.cue
cue export role.cue
```

Expected results:

- `cue mod tidy` completes without errors
- `cue vet role.cue` produces no output (valid)
- `cue export role.cue` shows valid JSON with role definition

If validation fails:

- Check import paths match module.cue dependencies
- Verify package name matches the directory name
- Ensure all required fields are present
- Check for syntax errors in CUE files

## Step 8: Publish to CUE Registry

After validation passes, update the index and publish everything in one commit.

Add three entries to `index/index.cue`:

```cue
"<domain>/[specialisation/]agent": {
    module:      "github.com/start-cli/library/roles/<domain>/[specialisation/]agent@v0"
    version:     "v0.1.0"
    description: "<description-base> - autonomous agent mode"
    tags: ["<domain>", "<topic-tags>", "agent", "autonomous"]
}
"<domain>/[specialisation/]assistant": {
    module:      "github.com/start-cli/library/roles/<domain>/[specialisation/]assistant@v0"
    version:     "v0.1.0"
    description: "<description-base> - collaborative assistant mode"
    tags: ["<domain>", "<topic-tags>", "assistant", "collaborative"]
}
"<domain>/[specialisation/]teacher": {
    module:      "github.com/start-cli/library/roles/<domain>/[specialisation/]teacher@v0"
    version:     "v0.1.0"
    description: "<description-base> - instructional teacher mode"
    tags: ["<domain>", "<topic-tags>", "teacher", "instructional", "learning"]
}
```

Then commit, tag, and publish:

```bash
DOMAIN="<domain>"
SPEC=""  # or "<specialisation>/"
VERSION="v0.1.0"

# Check latest remote index tag
git ls-remote --tags origin | grep "refs/tags/index/" | sort -t/ -k4 -V | tail -1
INDEX_VERSION="<next version>"

# Stage all role files and index together — single commit
git add roles/${DOMAIN}/${SPEC}
git add index/index.cue
git commit -m "feat(roles): add ${DOMAIN}/${SPEC} role (agent, assistant, teacher)"

# Tag all three modes and the index
for MODE in agent assistant teacher; do
  git tag "roles/${DOMAIN}/${SPEC}${MODE}/${VERSION}"
done
git tag "index/${INDEX_VERSION}"

# Push everything
git push origin main
git push origin --tags

# Publish each mode module
for MODE in agent assistant teacher; do
  cd roles/${DOMAIN}/${SPEC}${MODE}
  cue mod publish ${VERSION}
  cd -
done

# Publish index
cd index && cue mod publish ${INDEX_VERSION}
```

Important: The CUE registry has tag immutability. Always check the latest remote tag with `git ls-remote` before tagging to avoid version conflicts.

## Step 9: Close Related GitHub Issue

If a GitHub issue exists for this role, close it:

```bash
gh issue close <issue-number> --repo start-cli/library --comment "Implemented as roles/${DOMAIN}/${SPEC}@${VERSION}"
```
