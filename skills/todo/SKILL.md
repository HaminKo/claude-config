---
name: todo
description: Build a to-do from the project's to-do list (docs/todo.md, or docs/todo/NN-name.md for a big one), one step per chat. Questions and a plan first, then small steps, checks, a review, and a test checklist for the user. Use when the user types /todo N, or says "Build To do N", "Build To do N, step X" or "New feature: <goal>".
argument-hint: "<to-do number> [step]"
---

# Build a to-do

Arguments: $ARGUMENTS (a to-do number, optionally a step, e.g. "7" or "7 B"). With no number, take "Next:" from the Status section of CLAUDE.md and confirm it with the user.

If the project's CLAUDE.md describes its own build process (for example a "Feature sessions" section), follow that instead of this skill.

The project's details come from the "## Build specifics" section of its CLAUDE.md: the checks and when to run them, the docs and help texts a change may need, behaviour that must keep working, and a review checklist if there is one. If the section is missing, ask the user for these (suggest answers from the code, the dependency files and docs/local.md) and offer to add the section (under ~1.5 KB) before starting.

## 1. Start
- Read the to-do: its entry in docs/todo.md, or its own file docs/todo/NN-name.md with its Progress list if earlier steps were built.
- Read what its "Read first" names, only the parts that matter: grep for a heading or function, then read that line range, not whole files.
- "New feature: <goal>" with no to-do yet: write the to-do first with the template in docs/todo.md ("Writing a to-do"), show it, and go on when the user agrees.

## 2. Questions and plan (no code yet)
- Look at the code and the references first, so you only ask what they don't answer.
- In one message: the to-do's open questions plus any new ones, each with a suggested answer, so "go with your suggestions" is a valid reply. Then a short plan: the steps, a size per step (files, rough lines), what existing code is reused, which docs or help texts change, and how each step is tested.
- Split a to-do into steps (one chat each: "Build To do N, step B") when it's bigger than ~300 changed lines or gives the user more than one thing to test. Write the steps into a Progress list in the to-do's own file (move a list entry into docs/todo/NN-name.md for that).
- Wait for the answers.

## 3. Build
- A refactor the feature needs goes first and alone, as its own step: "no visible change" for the user to confirm.
- Build in small steps. Reuse existing functions; move shared logic into one function instead of copying it.
- If the code shows the plan was wrong (another design, a much bigger size), stop and ask rather than quietly changing course.
- Match the project's style, types and lint rules in new and changed code.
- Keep token use low: grep, then read line ranges; edit with Edit; don't re-read a file just to check an edit.

## 4. Check
- Fast checks (lint, quick tests) after edits. Slow checks once, when the step's code is done, each in its own call; re-run one only after a fix. Commands and timing: Build specifics.
- A new feature gets an automated test in the same step (for a UI change: a step in the project's GUI test, if it has one). Tests write only into temporary folders.
- Explain every failing check before fixing it. Update stored expected results only for a deliberate change, and say which.

## 5. Review
Before the user tests, so the fixes get tested too. Skip it for docs-only changes.
- With a review checklist in Build specifics: under ~50 changed lines, review the diff yourself with it. Bigger, or any change that deletes, moves, renames or overwrites the user's files, or touches the project's safety rules (CLAUDE.md Decisions), whatever its size: a fresh general-purpose subagent that hasn't seen the work, briefed with the checklist, the to-do's goal, and how to get the diff (git diff; git status --short for new files, read whole). It edits nothing and returns findings, most severe first, each marked must-fix or note.
- Without a checklist: the built-in code-review skill on the current diff, at medium effort (high for a change that deletes, moves, renames or overwrites the user's files).
- Fix the must-fix findings and re-run the affected checks. Tell the user in one or two lines what the review found and what was fixed or left.

## 6. Hand over for testing
- A few lines: what was built, which checks ran and their results, the review in one line.
- A numbered test checklist for the user: what to do and what they should see. Include behaviour that must keep working (Build specifics) when the change touches it. Commands are copy-ready with real paths from docs/local.md.
- Then wait. When the user says the step is tested, or says "commit" for a check-in commit, use the project's finish-step skill. If the project has none, update the to-do's Progress list and give the commit message as plain text in a code block.
