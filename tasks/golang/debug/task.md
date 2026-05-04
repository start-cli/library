# Debugging

The primary goal of this debugging task is to systematically identify and resolve the issue described in the custom instructions.

Workflow:

- Read the custom instructions to understand the reported problem
- Read relevant code files to understand the implementation
- Form hypotheses about potential causes
- Investigate each hypothesis systematically
- Implement and verify the fix

Outcome:

- Identify the root cause of the issue
- Implement a fix that resolves the problem
- Ensure the fix doesn't introduce regressions
- Add tests to prevent the issue from recurring
- Document the findings if the issue was non-obvious

Notes:

- Focus on understanding before fixing
- Avoid shotgun debugging (random changes hoping something works)
- Consider whether this is a symptom of a larger problem
- The simplest explanation is often correct

## 1. Reproduce the Issue

Confirm and isolate the problem.

- Consistent Reproduction: Can you reliably reproduce the issue?
- Minimal Case: What is the simplest scenario that triggers it?
- Environment: What Go version, OS, and dependencies are involved?
- Recent Changes: What changed recently that might have caused this?
- Error Messages: What exact errors or unexpected behaviors occur?

## 2. Gather Information

Collect data about the problem.

- Stack Traces: Examine any panic stack traces carefully.
- Log Output: Review logs around the time of the issue.
- Input Data: What inputs trigger the problem?
- Timing: Is it intermittent or consistent? Time-related?
- Dependencies: Could external services or dependencies be involved?

## 3. Form Hypotheses

Generate potential explanations.

- Most Likely: What is the most probable cause?
- Alternative Causes: What are other possible explanations?
- Assumptions: What assumptions might be wrong?
- Similar Issues: Have similar issues occurred before?
- Code Review: Does reading the code suggest issues?

## 4. Use Debugging Tools

Apply Go debugging tools.

- Print Debugging: Strategic `fmt.Printf` or `log.Printf` statements.
- Delve Debugger: Use `dlv debug` for interactive debugging.
- Breakpoints: Set breakpoints at suspicious locations.
- Variable Inspection: Examine variable values at runtime.
- Step Through: Step through code execution line by line.

## 5. Check Common Issues

Review frequent sources of bugs.

- Nil Pointers: Is there a nil pointer dereference?
- Off-by-One: Are loop bounds correct?
- Race Conditions: Run with `-race` flag.
- Error Handling: Is an error being ignored?
- Type Assertions: Are type assertions failing?
- Goroutine Leaks: Are goroutines not terminating?
- Channel Deadlocks: Are channels blocking unexpectedly?

## 6. Isolate the Cause

Narrow down the source.

- Binary Search: Comment out half the code, see if issue persists.
- Unit Tests: Write a failing test that demonstrates the bug.
- Minimal Example: Create the smallest code that reproduces it.
- Git Bisect: Use `git bisect` to find the commit that introduced it.
- Dependencies: Test with different dependency versions.

## 7. Implement the Fix

Make the correction.

- Targeted Fix: Fix the specific issue, don't refactor unrelated code.
- Understand Fully: Ensure you understand why the fix works.
- Side Effects: Consider if the fix might affect other code.
- Code Style: Match existing code style and patterns.
- Comments: Add comments if the fix is non-obvious.

## 8. Verify the Fix

Confirm the issue is resolved.

- Reproduction Test: Does the original reproduction case now pass?
- New Tests: Add tests that would have caught this bug.
- Existing Tests: Do all existing tests still pass?
- Race Detector: Run with `-race` to check for race conditions.
- Edge Cases: Test related edge cases.

## 9. Prevent Recurrence

Guard against similar issues.

- Test Coverage: Is there now a test for this scenario?
- Code Review: Should similar code elsewhere be checked?
- Documentation: Should anything be documented?
- Linter Rules: Could a linter catch this in the future?
- Root Cause: Is there a deeper issue to address?

## 10. Document Findings

Record what was learned.

- Issue Description: What was the symptom?
- Root Cause: What was the actual problem?
- Solution: How was it fixed?
- Lessons: What can be learned for the future?
- Related Issues: Are there related issues to file?
