# Create Role

Generate a system prompt role file for the current repository at `.ai/roles/default.md`.

## Process

Steps:

1. Analyse the repository to identify technologies and content
2. Determine role title and expertise areas
3. Generate the role markdown file
4. Write to `.ai/roles/default.md`

## Step 1: Analyse the Repository

Perform a thorough analysis of the repository to determine the technology stack and domain. Examine dependency manifests, configuration files, source code, project documentation, and directory structure.

Identify:

- Primary programming languages and their ecosystems
- Frameworks and libraries
- Build tools, task runners, and automation
- Testing frameworks and patterns
- CI/CD and deployment infrastructure
- Code architecture and design patterns
- Domain-specific technologies or protocols

## Step 2: Determine Role Identity

Based on the analysis, determine:

1. Role title: A concise expert title (e.g., "Go Microservices Expert", "React TypeScript Expert", "Terraform Infrastructure Expert")
2. Primary expertise bullets: 4-8 statements defining the agent's capabilities
3. Skill set: 8-13 numbered skills with brief descriptions
4. Style priority: Choose the most fitting from this list: creativity, conciseness, precision, depth, elegance, performance

For technical/programming repositories, include these expertise patterns adapted to the specific technologies found:

- Deep understanding of the primary language(s) and their ecosystems
- Algorithmic thinking and problem-solving, breaking down complex issues into manageable parts
- Problem-solving by identifying issues and coming up with creative solutions
- Outstanding attention to detail when working with the codebase

For non-code repositories (documentation, configuration, content), adapt the expertise bullets to the domain (e.g., information architecture, technical writing, schema design).

For monorepos or multi-language projects, identify the dominant technology and list secondary technologies as additional expertise areas.

## Step 3: Generate the Role File

Write the role following this structure:

```
# Role: <Title> Expert

- You are an expert in <primary technology>
- <additional expertise bullets, one per line, each starting with "You">

## Skill Set

1. <Skill Name>: <Brief description of the skill and its relevance>
2. ...

## Instructions

- <Actionable directives for how the agent should behave>
- Prioritize <chosen-style> in your responses
- <Additional instructions relevant to the technology stack>

## Restrictions

- <Boundaries on what the agent should avoid>
- <Technology-specific constraints>
```

### Section Guidelines

Title and Expertise Bullets:

- Title should reflect the dominant technology or domain
- Each bullet starts with "You" defining a capability
- Cover the breadth of the technology stack, not just the primary language
- Include ecosystem knowledge (tooling, deployment, testing)

Skill Set:

- 8-13 numbered items
- Format: `<Number>. <Skill Name>: <Description>`
- Order from most fundamental to most specialised
- Cover: language fundamentals, frameworks, testing, tooling, architecture, deployment
- Include domain-specific skills identified in the analysis

Instructions:

- Actionable directives, not descriptions
- Include the style priority line: "Prioritize <chosen-style> in your responses"
- Add technology-specific best practices
- Reference relevant standards or conventions found in the repo
- Keep items focused and non-overlapping

Restrictions:

- Define boundaries relevant to the technology
- Include language/framework-specific anti-patterns to avoid
- Keep restrictions practical and enforceable

### Markdown Format Rules

The role file must use token-efficient markdown.

Do not use:

- Bold or italic formatting
- Horizontal rules
- Emojis
- HTML comments
- Image embeds
- Multiple consecutive blank lines
- Nested lists beyond 3 levels
- Task lists
- Heading depth beyond `###`

Keep:

- Headings for structure
- Single blank lines between sections
- Inline code for technical terms
- Lists (ordered and unordered)
- Callout prefixes (Note:, Warning:) without bold

## Step 4: Write the File

Create the directory and write the role:

```bash
mkdir -p .ai/roles
```

Write the generated content to `.ai/roles/default.md`.

If `.ai/roles/default.md` already exists, read it first. If the existing content is substantively different, inform the user before overwriting.
