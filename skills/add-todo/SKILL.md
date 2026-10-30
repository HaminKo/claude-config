---
name: add-todo
description: Write a new to-do into the project's to-do list (docs/todo.md) without building it - the next number, the project's to-do template, its place in the build order, and a commit message. Use when the user asks to add, write or note a to-do, or describes a feature, bug or idea for later ("add a to-do", "new to-do", "put this on the list", "for later"). Also used by the build-todo skill for "New feature: <goal>".
argument-hint: "<the goal in your words>"
---

# Add a to-do

Arguments: $ARGUMENTS (the goal in the user's words; if empty, take it from the message).

Writing a to-do is not building it: no code changes, and only a quick look at the code.

## 1. Read
- docs/todo.md: "Writing a to-do" (the template, where the number and the text go), the list (it is the build order), and a "Later" section if there is one. Where that section differs from this skill, follow the section.
- Look for a to-do that already covers the goal: grep its key words in docs/todo.md and docs/todo/. If one does, suggest adding to that one instead, and wait.
- A quick look at the code, enough to name the files and functions for "Read first" and to judge the size: grep, then a few line ranges. The research and the design are the build session's job.

## 2. Ask, only if needed
In one message, each with a suggested answer, ask only what the template needs and the message and the code don't answer. Typical: for a bug or research to-do, what the user has seen (where it happens, an example that works) and what is ruled out; where it goes in the list when that isn't clear. If nothing is missing, go straight to writing.

## 3. Write
- Number: the "Next number" in docs/todo.md; raise that line by one. Numbers are never reused or renumbered.
- The text in the template's shape: a title with the size (small / medium / large) and the goal in the user's words (quote them); Problem / Goal with an example; Read first; Approach; Ask the user (open questions with suggested answers, for the build session); Test.
- Where the template says: a list entry, or its own file docs/todo/NN-name.md plus one line in the list.
- Place it where the user said. Otherwise where it fits the build order (after any to-do it needs, near related ones), or in the Later section for a "someday" idea, and say where and why so the user can move it.
- If it lands first in the list, update "Next:" in the Status section of CLAUDE.md.

## 4. Report
- A few lines: the number, title, size, its place in the list and why, the open questions it carries.
- The commit message as plain text in a code block, in this shape: `To do 12 added after To do 9 (small; user: "<their words>"): <the goal in one line>; next number 13.`
- When the user says "commit": stage only the files this skill changed (docs/todo.md, the new to-do file, CLAUDE.md if changed), by explicit path.
