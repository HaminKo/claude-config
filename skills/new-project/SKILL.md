---
name: new-project
description: Set up a new or existing project folder for working with Claude Code (a short CLAUDE.md, a gitignored docs/local.md, a to-do list, a finish-step skill, and the git and GitHub steps). Only when the user types /new-project.
disable-model-invocation: true
---

# New project setup

Sets up a project folder the way the user likes to work. The user's personal rules (~/.claude/CLAUDE.md) already apply in every project: don't copy them into the project's files.

## 1. Look first
- Run git status (or note that there is no repo yet) and list the folder. Check the installed language version and tools (e.g. `python --version`) instead of guessing them. If there is code, read enough of it (README, entry point, dependency files) to answer the questions below yourself; ask only what the code doesn't show.
- If the folder already has a CLAUDE.md, docs/ or .claude/skills/, show what's there and ask before changing it. Never overwrite a file without asking.

## 2. Ask
Ask these in one message, each with a suggested answer (from the code where possible), then wait:
1. Name and goal in one or two sentences; who uses it.
2. Language and tools: how to run it, and the checks (tests, lint, type check) with their commands. For Python, suggest ruff and pyright.
3. Public later, or private? If public: what must never appear in tracked files (real name, personal paths, a pseudonym to keep separate).
4. "Which name and email should this repo's commits use?" Don't suggest or list any identity; the user decides.
5. Folders outside the project that it uses (data, test files), for docs/local.md.

## 3. Write the files
Show the file list with one line each, and write after the user says yes.
- **CLAUDE.md** (under ~5 KB). Sections:
  - Goal.
  - User and environment: OS, language version, shell (PowerShell in VS Code), "real paths: docs/local.md (gitignored)".
  - Working style: one to-do per chat, built with the /todo skill ("Build To do N"); commit after each working step; end a step with the finish-step skill.
  - Build specifics (read by the /todo skill), a few lines: Checks (fast ones after edits, e.g. lint; slow ones once per step, e.g. tests and type check; each with its command and rough time); Docs to update when behaviour changes (README.md for headline features and install steps, plus any help texts); Must keep working (the main things the user relies on; empty at first); Review checklist ("none yet: the built-in code-review skill"; add docs/review.md once the project has its own rules to check).
  - Status: "Next:" the first to-do.
  - Decisions: empty, with "decisions go here with their reason".
  - Project docs: docs/local.md, docs/todo.md.
  - Never in tracked files: the answer to question 3 (personal paths always; they go in docs/local.md).
- **.gitignore**: docs/local.md, .claude/settings.local.json, and the language's usual entries (Python: __pycache__/, *.pyc, .venv/, .ruff_cache/). Write it before docs/local.md.
- **docs/local.md**: this PC's paths (project, data folders) and copy-ready PowerShell commands with real quoted paths for running the project and its checks.
- **docs/todo.md**: "Next number: 1", an empty "## To do" list, and "## Writing a to-do" with this template:
  - Title with size (small / medium / large) and the goal in the user's words.
  - Problem / Goal: what is wrong or wanted, with an example. For a bug or research to-do, also what the user has seen (it exists, where, what works) and what is already ruled out.
  - Read first: files and functions to look at, outside references.
  - Approach: the suggested design, what to reuse.
  - Ask the user: open questions, each with a suggested answer.
  - Test: what Claude checks, and what the user tests by hand.

  Each to-do starts as an entry in the list. When one grows past ~10 lines, offer to move it into its own file, docs/todo/NN-name.md.

  Offer the first one or two to-dos. For a new project, #1 is usually a skeleton: the environment, the dependency file, and all checks running.
- **.claude/skills/finish-step/SKILL.md**: the template below, with this project's docs and checks filled in.

## 4. Git and GitHub (the user runs these)
Give complete, copy-ready PowerShell commands with the real folder path. Never run git config yourself.
- New repo: `git init -b main`, then `git config user.name ...` and `git config user.email ...` with the answer to question 4 (never --global).
- Existing repo without its own identity: only the two git config lines.
- First commit: when the user says "commit", stage the new files by explicit path and commit ("Project setup: CLAUDE.md, docs, finish-step skill").
- GitHub: the user creates an empty repo on github.com (private unless they say otherwise; no README or .gitignore, so the first push doesn't conflict). Then give `git remote add origin https://HaminKo@github.com/OWNER/REPO.git` and `git push -u origin main`, with OWNER and REPO filled in. The login in the URL picks the HaminKo login, also for repos owned by an organization.

## 5. Check
Tell the user to start a new chat in the project and ask "Which CLAUDE.md files and skills did you load?" It should name the project's CLAUDE.md, ~/.claude/CLAUDE.md, finish-step and todo.

## finish-step template
```markdown
---
name: finish-step
description: End of a build step or session in this project. Use when the user says the step is tested, the test passed, it works, or similar, or says "commit". Updates the docs, gives the commit message, and commits only this session's files when the user says "commit". Not when only part of a test checklist passed.
---

# Finish a step

Phase 1 runs when the user says the whole step is tested. Phase 2 runs only when the user says "commit" (for a check-in commit in the middle of a step, skip phase 1).

## Phase 1: docs and commit message
Only when the user has tested the whole step; if part of the test failed, fix that first.
- Run the checks in CLAUDE.md "Build specifics"; all must pass.
- Check the changed files for anything on the "Never in tracked files" list in CLAUDE.md.
- Finished to-do: remove its entry from docs/todo.md (numbers are never reused) and update "Next:" in CLAUDE.md Status.
- One step of a bigger to-do: update its Progress list (what was built, choices, test results, what the next step does).
- Update the docs the change affects (CLAUDE.md "Build specifics": Docs to update).
- Give the commit message as plain text in a code block.
- Say what comes next: the next step or to-do, and the short message to start it in a new chat.

## Phase 2: commit (only when the user says "commit")
Other Claude sessions may be editing this folder at the same time.
1. Run git status. Show the files this session changed; list any other changed files as "left untouched (another session)".
2. Stage only this session's files, by explicit path. Never git add -A, git add . or git stash.
3. Commit with the message from phase 1. No Co-Authored-By or other attribution lines.
4. Never push; the user pushes.
```
