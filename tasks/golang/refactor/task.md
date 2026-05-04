# Code Refactoring

The primary goal of this refactoring task is to improve the code structure, readability, and maintainability based on the custom instructions provided.

Workflow:

- Read the README.md and any design documents for context
- Read the relevant *.go files based on the custom instructions
- Understand the current implementation before making changes
- Plan the refactoring approach before implementing

Outcome:

- Implement the refactoring changes directly in the codebase
- Ensure all tests pass after refactoring
- Run `go fmt`, `go vet`, and linters to verify code quality
- Document any significant architectural decisions made

Notes:

- Refactoring should not change external behavior (unless explicitly requested)
- Make incremental changes that can be verified at each step
- Preserve or improve test coverage
- Follow existing code conventions in the project

## 1. Understand Before Changing

Thoroughly understand the code before refactoring.

- Behavior: What does the current code do?
- Dependencies: What other code depends on this?
- Tests: What tests cover this code?
- Edge Cases: What edge cases does the current implementation handle?
- History: Is there git history explaining why it was written this way?

## 2. Extract Functions

Break down large functions into smaller, focused ones.

- Single Responsibility: Each function should do one thing well.
- Naming: Choose descriptive names that explain what the function does.
- Parameters: Minimize the number of parameters (consider struct for many params).
- Return Values: Be consistent with return patterns (value, error).
- Visibility: Only export functions that need to be public.

## 3. Extract Types

Create types to improve code clarity.

- Named Types: Create named types for domain concepts.
- Struct Organization: Group related fields into structs.
- Methods: Attach behavior to types via methods.
- Interfaces: Extract interfaces for testability and flexibility.
- Type Aliases: Use type aliases sparingly and with clear purpose.

## 4. Simplify Conditionals

Reduce complexity in conditional logic.

- Early Returns: Use early returns to reduce nesting.
- Guard Clauses: Handle error cases first.
- Switch Statements: Prefer switch over long if-else chains.
- Boolean Simplification: Simplify complex boolean expressions.
- Eliminate Dead Code: Remove unreachable code paths.

## 5. Improve Naming

Make code self-documenting through better names.

- Variables: Names should describe what the value represents.
- Functions: Names should describe what the function does (verb + noun).
- Packages: Short, lowercase, single-word names.
- Consistency: Use consistent naming patterns throughout.
- Avoid Abbreviations: Prefer clarity over brevity (with Go idiom exceptions).

## 6. Reduce Duplication

Eliminate repeated code patterns.

- DRY Principle: Don't Repeat Yourself.
- Extract Common Code: Create shared functions or types.
- Table-Driven Logic: Use data structures instead of repetitive code.
- Generics: Consider generics for type-safe code reuse (Go 1.18+).
- Avoid Over-Abstraction: Some duplication is better than wrong abstraction.

## 7. Package Organization

Improve package structure.

- Cohesion: Keep related code together.
- Coupling: Minimize dependencies between packages.
- Circular Dependencies: Eliminate any circular imports.
- Package Size: Split large packages if they have distinct responsibilities.
- Internal Packages: Use internal/ for implementation details.

## 8. Error Handling

Improve error handling patterns.

- Error Wrapping: Use `fmt.Errorf("context: %w", err)` for context.
- Custom Errors: Create custom error types where appropriate.
- Error Checking: Ensure all errors are checked.
- Consistent Patterns: Use consistent error handling throughout.
- Actionable Errors: Errors should help users understand what went wrong.

## 9. Testing Considerations

Maintain or improve testability.

- Test Coverage: Ensure tests still pass after refactoring.
- New Tests: Add tests for newly extracted functions.
- Test Clarity: Refactoring may reveal opportunities for better tests.
- Mocking: Interfaces enable easier mocking.
- Benchmark Impact: Run benchmarks if performance is critical.

## 10. Verification

Validate the refactoring is correct.

- Tests Pass: All existing tests must pass.
- Behavior Unchanged: External behavior is preserved (unless intentionally changed).
- Code Quality: `go fmt`, `go vet`, and linters pass.
- Review: Self-review the changes before committing.
- Incremental Commits: Commit logical chunks separately.
