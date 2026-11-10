# Systematic Debugging

Use when fixing bugs, investigating errors, or troubleshooting issues.

## 4-Phase Process

### Phase 1: Evidence Collection
Reproduce bug consistently. Document expected vs. observed behavior. Identify when it started. Collect logs, stack traces, error messages.

### Phase 2: Component Tracing
For each component boundary: log input, log output, verify config propagation, check state at each layer. Run ONCE to find WHERE it breaks, then investigate that component.

### Phase 3: Hypothesis & Test
Formulate ONE specific hypothesis. Write a test that PROVES the hypothesis (reproducing the bug). Apply MINIMAL fix. Verify test passes. Run ALL tests.

### Phase 4: Verification & Defense in Depth
Verify fix resolves original bug. Add validation at multiple layers. Document root cause in commit message.

### Phase 4.5: Question Architecture
If 3+ fixes failed: the problem may be architectural. Discuss with user before more attempts.

## Stop Signals — Return to Phase 1
- Making multiple simultaneous changes
- Guessing instead of following evidence
- Fix "works" but you don't understand why
- Attempting partial fix without understanding root cause
