# Writing Implementation Plans

Use when there is an approved design ready for implementation.

## Overview

Write comprehensive plans assuming the engineer has zero codebase context. Document everything: files to touch, complete code, testing steps, verification commands. Bite-sized tasks (2-5 min each). DRY. YAGNI. TDD. Frequent commits.

## Task Granularity

Each step is ONE action:
- "Write the failing test" → step
- "Run it to verify it fails" → step
- "Write minimal code to pass" → step
- "Run tests to verify pass" → step
- "Commit" → step

## Plan Format

Every plan starts with: Feature name, Goal (1 sentence), Architecture (2-3 sentences), Tech Stack.

Each task includes: exact file paths, complete code, exact commands with expected output, commit message.

## Rules

- Exact file paths always
- Complete code (never "add validation")
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits

Save to `docs/plans/YYYY-MM-DD-<feature>.md`
