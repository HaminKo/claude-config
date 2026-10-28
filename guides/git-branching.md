# Git branching: the basic cycle

2026-10-28. Copied from the claude.ai doc of the same name; the Worktrees section was added here later, so this file is the newer copy.

## Words you need

A branch is only a movable label on a commit; most of git gets easier once you see it that way.

| Word | What it means |
| --- | --- |
| commit | A saved snapshot with a message, named by a short code such as `02bd2af`. |
| branch | A named label on a commit. A new commit on the branch moves the label forward. |
| `main` | The main branch: what you push and what others see. |
| `HEAD` | Where you are now. In the log, `HEAD -> main` means you are on `main`. |
| `origin/main` | Git's memory of where `main` is on GitHub. Only push, pull or fetch update it. |
| staging (`git add`) | Picking which changes go into the next commit. |
| merge | Bringing a branch's commits into the branch you are on. |
| fast-forward | A merge where `main` had no new commits of its own, so git only moves the `main` label forward. |
| push | Sending your commits to GitHub. |
| worktree | A second folder of the same repo, with another branch checked out. |

## Check where you are

Before any git command, check which repo and which branch you are in: most mistakes start there.

| Command or place | Tells you |
| --- | --- |
| The terminal prompt, e.g. `PS C:\...\.claude>` | Which folder, and so which repo, the next git command acts on. Move with `cd`, or run `git -C <folder> <command>` from anywhere. |
| `git status` | The branch you are on, whether it matches GitHub, and what is changed or staged. |
| `git branch` | All branches; `*` marks the one you are on. |
| `git log --oneline --graph --all` | The history of every branch, one line per commit, with the labels (`main`, `origin/main`, your branch) next to the commits they point at. |
| `git diff` | Changes not yet committed; `+` lines are new, `-` lines are removed. |
| VS Code, bottom-left corner | The branch of the folder VS Code has open (not the terminal's folder). `4↑` = 4 commits to push, `2↓` = 2 to pull. |

## The cycle, step by step

Seven commands take a change from a new branch into `main` on GitHub; run them in the repo's folder and replace `<name>` with a short branch name.

Commits stay put: commit, merge and push each move one label. Where the labels point after each step (**bold** = the label that moved; `02bd2af` is the newer commit):

| After | `839218b` | `02bd2af` |
| --- | --- | --- |
| 1. Commit on the branch | `main`, `origin/main` | **`parallel-rules`** |
| 2. Merge (fast-forward) | `origin/main` | **`main`**, `parallel-rules` |
| 3. Push, then `git branch -d` | | `main`, **`origin/main`** |

1. **Start clean:** `git status`. You should see `On branch main`, `up to date with 'origin/main'` and `working tree clean`. If not, commit or finish what is there first.
2. **Create a branch and switch to it:** `git switch -c <name>`. You see `Switched to a new branch '<name>'`; `git branch` marks it with `*`. `-c` means create; without it, `git switch` only moves to a branch that already exists.
3. **Edit and commit on the branch:** edit and save the file, check with `git diff`, then `git add <file>` and `git commit -m "<message>"`. You see `[<name> 02bd2af] <message>`. In `git log --oneline --graph --all` the new commit carries `HEAD -> <name>`, and `main` is still one commit below.
4. **Switch back to main:** `git switch main`. The files change to `main`'s version, so your change seems gone; it is safe in the commit on the branch.
5. **Merge:** `git merge <name>`. You see `Fast-forward` when `main` had no new commits of its own: git only moves the `main` label to the branch's commit.
6. **Push:** `git push`. You see `main -> main`. The first push of a new repo needs `git push -u origin main` once; after that, plain `git push` is enough.
7. **Delete the label:** `git branch -d <name>`. You see `Deleted branch <name> (was 02bd2af)`. The commits stay, because they are part of `main` now.

The whole cycle to copy:

```powershell
git status
git switch -c <name>
# edit and save, then:
git diff
git add <file>
git commit -m "<message>"
git switch main
git merge <name>
git push
git branch -d <name>
```

## Traps

None of these break anything, but each looks like a problem the first time.

| What you see | What it means | What to do |
| --- | --- | --- |
| A `:` or `(END)` at the bottom, and no prompt | Git's pager is showing long output. | Press `q`. Arrow keys or Space scroll. |
| No output at all from `git log --oneline --graph -- all` | `--` followed by a space means "file names follow", so git showed the history of a file called `all`. | Type `--all`, no space. An empty answer can mean you asked something slightly different. |
| A `>>` prompt after a command | PowerShell is waiting for more input, often because pasted text ended with an extra line break. | Harmless if the command ran; otherwise press Ctrl+C. |
| `LF will be replaced by CRLF` | Windows and Linux end lines differently; git converts for you. | Ignore it. |
| `git branch -d` refuses | The branch has commits that are not merged anywhere yet. | Merge first. `-D` (capital) deletes anyway: only to throw work away on purpose. |
| A command changed the wrong project | The terminal was in another repo's folder. | Check the prompt or `git status` before you commit. |
| Push fails with `Repository not found`, and you have two GitHub accounts | Git used the other account's login. | Put the account in the remote URL: `https://<account>@github.com/<account>/<repo>.git`. |

## Worktrees: a second folder

When two Claude sessions work at the same time, give each its own folder. A worktree is a second folder of the same repo with another branch checked out. Both folders share one history, branches and git config, so nothing is pushed or pulled between them: a commit made in one folder shows up in `git log` of the other right away.

Three rules:
- **Only tracked files come along.** Gitignored files (local notes, local Claude settings, extracted data) stay behind: copy them in, or point the project to the main folder's copy.
- **One branch, one folder.** A branch checked out in one folder can't be checked out in another, so merge from the folder that has `main`.
- **Put it next to the project** (`..\<repo>-wt`) when the project looks for sibling folders, such as a test data folder next to it.

| Step | Where | What |
| --- | --- | --- |
| 1. Create | main folder | `git worktree add "<sibling folder>" -b <name>`, then `git worktree list` shows both folders, each with its branch. |
| 2. Set up | | Copy the gitignored files a session needs. Open the folder in its own window with `code "<worktree>"` and start a Claude chat there. (`code <file>` opens a tab in the current window instead.) |
| 3. Work and commit | worktree | Edit, `git diff`, `git add <file>`, `git commit -m "<message>"`. From the main folder's terminal, add `-C "<worktree>"` after `git`. |
| 4. Merge | main folder | `git merge <name>`. You see `Fast-forward` when `main` had no new commits. |
| 5. Clean up | main folder | Close the worktree's files and window. `git worktree remove "<worktree>"`, then `git branch -d <name>` (in this order). |
| 6. Push | main folder | `git push`. |

The whole cycle to copy (from the main folder):

```powershell
git worktree add "<sibling folder>" -b <name>
git worktree list
# edit and save in the worktree, then:
git -C "<sibling folder>" diff
git -C "<sibling folder>" add <file>
git -C "<sibling folder>" commit -m "<message>"
git merge <name>
git worktree remove "<sibling folder>"
git branch -d <name>
git push
```

| What you see | What it means | What to do |
| --- | --- | --- |
| `fatal: 'main' is already used by worktree at ...` | That branch is checked out in the other folder. | Work with it in that folder. |
| `git branch -d` refuses: the branch is checked out | Its worktree still exists. | `git worktree remove` first. |
| `git worktree remove` refuses | The worktree has uncommitted or untracked files. | Commit or copy them. `--force` throws them away. |
| The folder was deleted by hand | Git still lists the worktree. | `git worktree prune` clears the stale entry. |

**Built into Claude Code.** `claude --worktree <name>`, or asking Claude to "work in a worktree", makes the worktree for you in `.claude/worktrees/<name>/` on a branch `worktree-<name>`. A `.worktreeinclude` file in the project (`.gitignore` syntax) lists the gitignored files to copy in. When the session ends, Claude asks whether to keep or remove the worktree; merging is still yours. Two catches:
- It branches from GitHub's `main` (`origin/main`), so unpushed commits are missing unless the project's settings have `"worktree": {"baseRef": "head"}`.
- The worktree sits inside the project, so a project that looks for sibling folders doesn't find them there. Use the manual steps above for such a project.

## What comes next

One more thing builds on this cycle; practise it on a throwaway repo before using it on a real project.

**Merge commits and conflicts.** When `main` also got new commits while you worked on the branch, `git merge` cannot fast-forward and makes a merge commit instead. If both sides changed the same lines, git stops with a conflict and marks the file with `<<<<<<<`, `=======` and `>>>>>>>` sections. VS Code shows buttons above each one (Accept Current, Accept Incoming, Accept Both). Pick the right text, save, then `git add <file>` and `git commit`.
