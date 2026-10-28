# Personal rules (all projects)

## Research and debugging
- Before changing code for a bug or an unknown format: list 2-3 possible causes and the cheapest test for each, and run the tests first. Reason: a first theory that looked right has cost long detours.
- In findings, say which numbers were measured and which were estimated. Reason: an estimate was once 7x too high.
- When the user says something exists or works somewhere, treat it as a fact to explain, not a claim to check.

## Parallel sessions
Other Claude sessions may work in the same folder at the same time.
- At the start, run git status. If files this task will change already have uncommitted changes, tell the user before starting. Reason: two sessions editing one file mix their changes.
- A check that fails in a file this session didn't change may be another session's unfinished work: report it, don't fix it.
- Commit only this session's files. If a file to commit also holds another session's changes, stop and ask the user. Reason: staging a file stages every change in it.
