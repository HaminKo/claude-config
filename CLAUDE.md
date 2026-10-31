# Personal rules (all projects)

## Research and debugging
- Before changing code for a bug or an unknown format: list 2-3 possible causes and the cheapest test for each, and run the tests first. Reason: a first theory that looked right has cost long detours.
- In findings, say which numbers were measured and which were estimated. Reason: an estimate was once 7x too high.
- When the user says something exists or works somewhere, treat it as a fact to explain, not a claim to check.

## Research and decisions are written down
A new chat knows only what's in the files.
- Write findings and decisions into the project's docs when they happen, not only at the end of a step: anything a later chat would otherwise redo or undo, dead ends included (what was tried, why it failed).
- Decisions: docs/decisions.md, one entry each: date, the decision, the reason, who decided, and what was rejected and why. The project's CLAUDE.md keeps only the rule that follows from it, in one line.
- Research: docs/research/TOPIC.md, one file per topic, updated in place, with sources. When a finding turns out wrong, mark it wrong and say what replaced it instead of deleting it.
- Before researching a topic, read its file and docs/decisions.md.
- A project's CLAUDE.md can name other places for these.

## Parallel sessions
Other Claude sessions may work in the same folder at the same time.
- At the start, run git status. If files this task will change already have uncommitted changes, tell the user before starting. Reason: two sessions editing one file mix their changes.
- A check that fails in a file this session didn't change may be another session's unfinished work: report it, don't fix it.
- Commit only this session's files. If a file to commit also holds another session's changes, stop and ask the user. Reason: staging a file stages every change in it.

## How I like to work
- Give honest, critical feedback: I'm not an experienced app developer, so don't just agree. When an idea has a real drawback, or a simpler or more standard way exists, say so with the reason and an alternative, then let me decide. Agree when it's genuinely good.
- Keep explanations short and practical.
- When you ask me questions, give each a suggested answer, so "go with your suggestions" is a valid reply.
- When walking me through several items, do one at a time: help me finish it, then wait until I say "move on". Reason: a long multi-part answer is too much to take in at once.
- Commands for me run in the VS Code terminal, which is PowerShell: give them complete and copy-ready, with real paths and no placeholders, and never cmd syntax such as %VAR% (use $env:USERPROFILE).

## Git
- Commit only when I ask, and never push unless I ask. Reason: I push myself after checking.
- Never change a repo's git config (user.name, user.email): each repo has its own identity.
- Never put personal paths (my user folder, drive paths) in tracked files or commit messages; machine-specific paths go in a gitignored local notes file such as docs/local.md.
