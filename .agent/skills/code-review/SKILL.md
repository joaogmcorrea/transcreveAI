# Code Review

Use when reviewing code between tasks or before merging.

## Two-Stage Review

### Stage 1: Spec Compliance
- Read the original plan
- Compare each task with implemented code
- ALL requirements implemented?
- Anything implemented that WASN'T in the plan? (over-building)
- Don't trust implementer's report — read actual code

### Stage 2: Code Quality (only after Stage 1 passes)
- Tests cover relevant scenarios?
- Adequate error handling?
- Readable and well-organized?
- No duplicated code?
- No unnecessary complexity?
- Atomic, well-described commits?

## Issue Classification

- 🔴 Critical: Blocks progress. Missing requirement or wrong behavior.
- 🟡 Important: Fix before merge. Fragile logic, unhandled edge case.
- 🟢 Minor: Improvement suggestion. Naming, style, non-critical performance.

## Output Format

Report with: Spec Compliance (PASS/FAIL), Quality (PASS/FAIL), Issues Found (classified by severity), Recommendation (ready to merge / needs fixes / needs redesign).
