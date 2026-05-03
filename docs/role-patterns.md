# Role Patterns

Role patterns define how an AI interacts with users. Each pattern establishes consistent behavioral expectations, making roles predictable and fit for purpose.

All roles share domain expertise (skill set) and constraints (restrictions). The pattern determines the interaction style (instructions).

## Patterns

### Agent

Autonomous executor that works independently with minimal interruption.

- Makes informed decisions without confirmation
- Completes tasks end-to-end
- Communicates results, not process
- Asks questions only when blocked

Best for: Repetitive tasks, well-defined workflows, batch operations, CI/CD pipelines.

### Assistant

Collaborative partner that works alongside the user.

- Clarifies requirements before acting
- Explains decisions and trade-offs
- Confirms approach at key decision points
- Refines work iteratively based on feedback

Best for: Interactive development, exploratory tasks, complex problem-solving, unfamiliar codebases.

### Teacher

Patient instructor that builds understanding.

- Explains concepts and rationale
- Breaks down complex topics into digestible parts
- Uses examples and analogies
- Checks for understanding before proceeding

Best for: Learning new tools, onboarding, understanding complex systems, skill development.

## Applying Patterns

A role combines domain expertise with an interaction pattern. Structure:

1. **Identity** - What the AI is (domain expert)
2. **Skill Set** - Specific capabilities and knowledge areas
3. **Instructions** - Pattern-specific behavior (agent/assistant/teacher)
4. **Restrictions** - Constraints and boundaries

Example identity statements:

- Agent: "You are an expert... operating in autonomous mode"
- Assistant: "You are an expert... working collaboratively"
- Teacher: "You are an expert... with a passion for teaching"

Example instruction differences for the same domain:

| Pattern | Instruction Focus |
|---------|-------------------|
| Agent | "Operate autonomously, make decisions, communicate results" |
| Assistant | "Clarify requirements, confirm approach, refine iteratively" |
| Teacher | "Explain concepts, use examples, check understanding" |

## Choosing a Pattern

| Situation | Pattern |
|-----------|---------|
| "Just do it" | Agent |
| "Help me do it" | Assistant |
| "Show me how" | Teacher |

Consider:

- **User expertise**: New to the domain? Teacher. Expert? Agent.
- **Task clarity**: Well-defined? Agent. Exploratory? Assistant.
- **Risk tolerance**: High stakes? Assistant. Routine? Agent.
- **Learning goal**: Building skills? Teacher. Shipping code? Agent or Assistant.

Users can override the default pattern with `--role` to match their current need.
