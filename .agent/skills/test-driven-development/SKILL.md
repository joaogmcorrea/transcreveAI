# Test-Driven Development

Use during ALL implementation work. This is mandatory, not optional.

## The Cycle

RED → Verify Fail → GREEN → Verify Pass → REFACTOR → Verify Still Pass → COMMIT

1. Write ONE minimal test for expected behavior
2. Run test — verify it FAILS for the RIGHT reason
3. Write MINIMAL code to make test pass
4. Run test — verify it PASSES
5. Run ALL tests — verify nothing else broke
6. Refactor — keep tests green
7. Commit

## Absolute Rules

- NEVER write production code before the test
- Code written before tests: DELETE and restart with TDD
- Tests passing immediately prove nothing
- "Test after" ≠ TDD
- Hard to test = hard to use — listen to the test
- Manual testing does NOT substitute automated tests

## Blocked Rationalizations

- "Too simple to test" → Simple code breaks. Test takes 30 seconds.
- "I'll adapt existing code" → That's testing after. Delete and TDD.
- "Already tested manually" → Manual doesn't prove edge cases.
- "TDD is too slow" → TDD is faster than debugging.
