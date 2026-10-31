---
name: notify
description: Turn the Windows notifications for waiting Claude chats on or off (the Notification hook in ~/.claude/settings.json). Use when the user types /notify, /notify on or /notify off.
disable-model-invocation: true
---

# Notifications on / off

The Notification hook (~/.claude/hooks/notify.ps1) shows a toast and plays a sound when a chat needs permission or waits for input. While the file `~/.claude/hooks/notify.off` exists, it does nothing. The change counts at once in every window; nothing restarts.

Argument: `on`, `off`, or none (= flip the current state).

1. Run one PowerShell command:
   - off: `New-Item -ItemType File -Force "$env:USERPROFILE\.claude\hooks\notify.off" | Out-Null`
   - on: `if (Test-Path "$env:USERPROFILE\.claude\hooks\notify.off") { Remove-Item "$env:USERPROFILE\.claude\hooks\notify.off" }` (not -ErrorAction SilentlyContinue: the PowerShell tool reports a failed Remove-Item as exit 1 even then)
   - none: `if (Test-Path "$env:USERPROFILE\.claude\hooks\notify.off") { Remove-Item "$env:USERPROFILE\.claude\hooks\notify.off" } else { New-Item -ItemType File "$env:USERPROFILE\.claude\hooks\notify.off" | Out-Null }`
2. Then `Test-Path "$env:USERPROFILE\.claude\hooks\notify.off"` and answer in one line: "Notifications are now on." (False) or "Notifications are now off." (True). Nothing else.
