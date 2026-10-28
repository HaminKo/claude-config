# claude-config

My personal Claude Code setup: rules, settings and skills shared by all my projects. Claude Code reads them from the `.claude` folder in my Windows user folder (`$env:USERPROFILE\.claude`) at the start of every session, in every project. Git is only the backup and history; Claude Code reads the files whether or not they are committed.

## What's in it

| File or folder | What it is |
| --- | --- |
| `CLAUDE.md` | Personal rules for every project (research, parallel sessions, how I like to work, git). |
| `settings.json` | Settings for every project (`env`, `attribution`, theme, model effort). Tracked: never put a secret such as an API key in it. |
| `skills/` | My personal skills (`skills/synced/` is managed by the Claude app and not tracked). |
| `guides/` | Guides for me, e.g. `guides/git-branching.md`. |
| `.gitignore` | An allowlist: everything else in the folder (login, chat history, project memory, caches) is never committed. A new top-level file or folder needs its own `!/name` line. |

## Set up on a new PC

Quickest: open Claude Code anywhere and say:

> Clone my personal Claude config from https://github.com/HaminKo/claude-config into my `.claude` folder, then follow the "Set up on a new PC" section of its README.

Sign in to GitHub as HaminKo when the browser opens (the repo is private). By hand, in PowerShell:

1. Get the files.
   - If `.claude` doesn't exist yet (Claude Code not run on this PC yet):
     ```powershell
     git clone https://HaminKo@github.com/HaminKo/claude-config.git "$env:USERPROFILE\.claude"
     ```
   - If it already exists (cloning into a non-empty folder fails):
     ```powershell
     cd "$env:USERPROFILE\.claude"
     git init -b main
     git remote add origin https://HaminKo@github.com/HaminKo/claude-config.git
     git fetch origin
     git checkout -f -B main origin/main
     ```
     The last line replaces Claude Code's default `settings.json` with mine; its own files stay, because the allowlist ignores them.
2. Set this repo's git identity (it lives in the local git config, not in the repo):
   ```powershell
   git -C "$env:USERPROFILE\.claude" config user.name haminko
   git -C "$env:USERPROFILE\.claude" config user.email ha_min_ko@outlook.com
   ```
   `HaminKo@` in the remote URL makes git use the HaminKo GitHub login for this repo, also when another account is signed in for other repos.
3. Start a new Claude Code session (settings and rules are read at session start) and check it with: "Which CLAUDE.md files and settings did you load at the start?" It should name this `CLAUDE.md` and `settings.json`.

Not included, by design: the Claude login (sign in again), chat history and project memory (they stay on the old PC), and each project's own setup (that comes with the project's repo).

## Day to day

- After a change: `git -C "$env:USERPROFILE\.claude" --no-pager diff`, then commit and push.
- With two PCs: `git -C "$env:USERPROFILE\.claude" pull` before editing, so the two copies don't drift apart.
- Cloud sessions (Claude Code on the web) don't read this folder.
