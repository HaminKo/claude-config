# Claude Code hook (settings.json: Stop, PermissionRequest): when a chat finishes a reply, needs
# permission or asks a question, show a popup naming the project folder in the bottom-right corner of
# every monitor except the main one (the main one if there is no other), plus a sound, so it is noticed
# from any window. Clicking a popup brings that project's VS Code window to the front; its X only
# dismisses; either closes all popups. There is no timer: they stay until clicked, until a newer one for
# the same folder replaces them, or until you switch to that project's VS Code window yourself (whatever
# still shows is still waiting for you). They never take focus (a full-screen game stays in front) and
# ignore Windows' Do Not Disturb. A Windows toast also goes silently into the notification center as history.
# One popup per project: a newer notification closes the older one of the same folder. Popups of different
# folders stack upward from the corner, each in the lowest free spot.
# Nothing is shown while that project's VS Code window has the keyboard focus (you are looking at it).
# Not the Notification event: the VS Code extension never fires it (measured 2026-10-31: no event in
# 4 minutes of idle chats, while Stop fired after every reply).
# Runs in Windows PowerShell 5.1: the toast API below is not available in PowerShell 7.
# Off switch: while a file notify.off sits next to this script, nothing happens (the /notify skill flips it).
# Each call appends one line to notify.log (deleted when over 100 KB).

# Keep this file ASCII-only: Windows PowerShell 5.1 reads it in the ANSI codepage, so a typed special
# character turns into garbage (measured 2026-10-31).

function Escape-Xml([string]$text) { [System.Security.SecurityElement]::Escape($text) }

# The first line of a Markdown reply as plain text: no heading, quote or list marks, no ** or backticks.
function First-Line([string]$text) {
    foreach ($line in ($text -split "`r?`n")) {
        $plain = ($line -replace '^\s*(#+|>|[-*]|\d+\.)\s+', '' -replace '\*\*|`', '').Trim()
        if ($plain) {
            if ($plain.Length -gt 140) { $plain = $plain.Substring(0, 139) + [char]0x2026 }
            return $plain
        }
    }
    return ''
}

[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$data = [Console]::In.ReadToEnd() | ConvertFrom-Json
if (Test-Path (Join-Path $PSScriptRoot 'notify.off')) { exit 0 }
$script:folder = Split-Path -Leaf $data.cwd
$title = "Claude: $folder"
$event = $data.hook_event_name
switch ($event) {
    'Stop' {
        $line = First-Line $data.last_assistant_message
        $message = if ($line) { "Finished: $line" } else { 'Finished' }
    }
    'PermissionRequest' {
        # Claude's question dialog (AskUserQuestion) also arrives as a permission request (measured 2026-10-31).
        if ($data.tool_name -eq 'AskUserQuestion') {
            $question = if ($data.tool_input.questions) { @($data.tool_input.questions)[0].question } else { $null }
            $message = if ($question) { "Has a question: $question" } else { 'Has a question for you' }
        }
        else { $message = "Needs your permission to use $($data.tool_name)" }
    }
    default { $message = if ($data.message) { $data.message } else { 'Needs your attention' } }
}

$log = Join-Path $PSScriptRoot 'notify.log'
if ((Test-Path $log) -and (Get-Item $log).Length -gt 100KB) { Remove-Item $log }

Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type -ReferencedAssemblies System.Windows.Forms, System.Drawing -WarningAction SilentlyContinue -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Forms;

// A borderless always-on-top popup that never takes focus (WS_EX_NOACTIVATE; TopMost through the
// window style, because setting the TopMost property would activate it). Sizes are in pixels at 100%
// and multiplied by the monitor's scale; fonts are given in pixels so the process DPI doesn't matter.
// Also the window helpers: find a project's VS Code window by its title, check focus, bring it to front.
public class ClaudePopup : Form
{
    [StructLayout(LayoutKind.Sequential)] struct POINT { public int X, Y; }
    [StructLayout(LayoutKind.Sequential)] struct RECT { public int Left, Top, Right, Bottom; }
    delegate bool EnumWindowsProc(IntPtr window, IntPtr data);
    [DllImport("user32.dll")] static extern bool PostMessage(IntPtr window, uint message, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr window, out RECT rect);
    [DllImport("user32.dll")] static extern bool SetProcessDpiAwarenessContext(IntPtr value);
    [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] static extern bool SetForegroundWindow(IntPtr window);
    [DllImport("user32.dll")] static extern bool EnumWindows(EnumWindowsProc callback, IntPtr data);
    [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr window);
    [DllImport("user32.dll")] static extern bool IsIconic(IntPtr window);
    [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr window, int command);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowText(IntPtr window, StringBuilder text, int count);
    [DllImport("user32.dll")] static extern IntPtr MonitorFromPoint(POINT pt, uint flags);
    [DllImport("shcore.dll")] static extern int GetDpiForMonitor(IntPtr monitor, int type, out uint dpiX, out uint dpiY);

    // Per-monitor DPI aware: screen areas and window positions are real pixels, so each popup lands in its
    // monitor's corner. (The DPI-unaware mode put the popups in the wrong place on this PC's mix of 100%
    // and 150% monitors: measured 2026-10-31.)
    public static void UseRealPixels() { SetProcessDpiAwarenessContext(new IntPtr(-4)); }

    static string TitleOf(IntPtr window)
    {
        StringBuilder text = new StringBuilder(512);
        GetWindowText(window, text, text.Capacity);
        return text.ToString();
    }

    // VS Code window titles end in "<folder> - Visual Studio Code"; the parts before are a file or chat name.
    static bool IsVsCodeWindowFor(string title, string folder)
    {
        string[] parts = title.Split(new string[] { " - " }, StringSplitOptions.None);
        if (parts.Length < 2 || parts[parts.Length - 1] != "Visual Studio Code") return false;
        for (int i = 0; i < parts.Length - 1; i++)
            if (string.Equals(parts[i], folder, StringComparison.OrdinalIgnoreCase)) return true;
        return false;
    }

    public static bool HasFocus(string folder) { return IsVsCodeWindowFor(TitleOf(GetForegroundWindow()), folder); }

    // Windows lets this process take the foreground because the user's click on the popup was its last input.
    // Returns what happened, for the log.
    public static string BringToFront(string folder)
    {
        IntPtr found = IntPtr.Zero;
        EnumWindows((window, data) =>
        {
            if (IsWindowVisible(window) && IsVsCodeWindowFor(TitleOf(window), folder)) { found = window; return false; }
            return true;
        }, IntPtr.Zero);
        if (found == IntPtr.Zero) return "no VS Code window found";
        if (IsIconic(found)) ShowWindow(found, 9);  // SW_RESTORE
        return SetForegroundWindow(found) ? "window brought to front" : "Windows refused the focus change";
    }

    // The popups of every running call of this script, found by their window title (never seen: no title bar).
    const string TitlePrefix = "Claude popup: ";

    static List<IntPtr> Popups()
    {
        List<IntPtr> found = new List<IntPtr>();
        EnumWindows((window, data) =>
        {
            if (IsWindowVisible(window) && TitleOf(window).StartsWith(TitlePrefix, StringComparison.Ordinal)) found.Add(window);
            return true;
        }, IntPtr.Zero);
        return found;
    }

    static bool IsPopupFor(IntPtr popup, string folder)
    {
        return string.Equals(TitleOf(popup), TitlePrefix + folder, StringComparison.OrdinalIgnoreCase);
    }

    // Closes the popups of an older notification for this folder; their own script logs "replaced".
    public static void CloseOlder(string folder)
    {
        foreach (IntPtr popup in Popups())
            if (IsPopupFor(popup, folder)) PostMessage(popup, 0x0010, IntPtr.Zero, IntPtr.Zero);  // WM_CLOSE
    }

    static float ScaleOf(Rectangle area)
    {
        POINT center = new POINT();
        center.X = area.X + area.Width / 2;
        center.Y = area.Y + area.Height / 2;
        uint dpiX, dpiY;
        if (GetDpiForMonitor(MonitorFromPoint(center, 2), 0, out dpiX, out dpiY) != 0) return 1f;
        return dpiX / 96f;
    }

    public Label CloseButton { get; private set; }

    public ClaudePopup(string folder, string title, string message, Rectangle area)
    {
        float s = ScaleOf(area);
        Func<int, int> px = n => (int)Math.Round(n * s);

        Text = TitlePrefix + folder;
        FormBorderStyle = FormBorderStyle.None;
        ShowInTaskbar = false;
        StartPosition = FormStartPosition.Manual;
        BackColor = Color.FromArgb(43, 43, 43);
        Cursor = Cursors.Hand;
        Size = new Size(px(420), px(96));

        // The lowest spot in the corner that no other folder's popup covers; back to the corner when the
        // column is full. (Two notifications in the same instant can still land on one spot.)
        List<Rectangle> taken = new List<Rectangle>();
        foreach (IntPtr popup in Popups())
        {
            RECT r;
            if (!IsPopupFor(popup, folder) && GetWindowRect(popup, out r))
                taken.Add(Rectangle.FromLTRB(r.Left, r.Top, r.Right, r.Bottom));
        }
        int corner = area.Bottom - Height - px(16);
        Rectangle spot = new Rectangle(area.Right - Width - px(16), corner, Width, Height);
        while (taken.Exists(r => r.IntersectsWith(spot)))
        {
            spot.Y -= Height + px(8);
            if (spot.Y < area.Top) { spot.Y = corner; break; }
        }
        Location = spot.Location;

        CloseButton = new Label();
        // From its code, not typed: Windows PowerShell 5.1 reads this file in the ANSI codepage.
        CloseButton.Text = ((char)0x2715).ToString();  // the X mark
        CloseButton.ForeColor = Color.FromArgb(160, 160, 160);
        CloseButton.Font = new Font("Segoe UI", 14f * s, FontStyle.Regular, GraphicsUnit.Pixel);
        CloseButton.TextAlign = ContentAlignment.MiddleCenter;
        CloseButton.SetBounds(Width - px(38), px(6), px(32), px(32));
        CloseButton.MouseEnter += (sender, e) => CloseButton.ForeColor = Color.White;
        CloseButton.MouseLeave += (sender, e) => CloseButton.ForeColor = Color.FromArgb(160, 160, 160);

        Panel accent = new Panel();
        accent.BackColor = Color.FromArgb(217, 119, 87);
        accent.Dock = DockStyle.Left;
        accent.Width = px(6);

        Label titleLabel = new Label();
        titleLabel.Text = title;
        titleLabel.ForeColor = Color.White;
        titleLabel.Font = new Font("Segoe UI", 15f * s, FontStyle.Bold, GraphicsUnit.Pixel);
        titleLabel.AutoEllipsis = true;
        titleLabel.SetBounds(px(20), px(12), Width - px(64), px(26));

        Label body = new Label();
        body.Text = message;
        body.ForeColor = Color.FromArgb(220, 220, 220);
        body.Font = new Font("Segoe UI", 13f * s, FontStyle.Regular, GraphicsUnit.Pixel);
        body.AutoEllipsis = true;
        body.SetBounds(px(20), px(40), Width - px(32), px(46));

        Controls.Add(CloseButton);
        Controls.Add(titleLabel);
        Controls.Add(body);
        Controls.Add(accent);
    }

    protected override bool ShowWithoutActivation { get { return true; } }

    protected override CreateParams CreateParams
    {
        get
        {
            CreateParams cp = base.CreateParams;
            cp.ExStyle |= 0x08000000 | 0x00000080 | 0x00000008;  // NOACTIVATE, TOOLWINDOW, TOPMOST
            return cp;
        }
    }
}
'@

# Also when nothing new is shown: an older popup for a window you are looking at is out of date.
[ClaudePopup]::CloseOlder($folder)
if ([ClaudePopup]::HasFocus($folder)) {
    Add-Content -Path $log -Encoding UTF8 -Value "$(Get-Date -Format s) [$event, not shown: window in focus] $folder : $message"
    exit 0
}
Add-Content -Path $log -Encoding UTF8 -Value "$(Get-Date -Format s) [$event] $folder : $message"

# Toast: history only (SuppressPopup), the popups below are what you see.
$null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
$null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
$xml.LoadXml("<toast><visual><binding template='ToastGeneric'><text>$(Escape-Xml $title)</text><text>$(Escape-Xml $message)</text></binding></visual><audio silent='true'/></toast>")
$toast = New-Object Windows.UI.Notifications.ToastNotification $xml
$toast.SuppressPopup = $true
# One toast per folder: a newer one for the same window replaces the older one.
$toast.Tag = $folder.Substring(0, [Math]::Min(64, $folder.Length))
$toast.Group = 'claude'
# The AppUserModelID of Windows PowerShell, so Windows accepts the toast without registering an app.
$appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)

[ClaudePopup]::UseRealPixels()
$screens = @([System.Windows.Forms.Screen]::AllScreens | Where-Object { -not $_.Primary })
if ($screens.Count -eq 0) { $screens = @([System.Windows.Forms.Screen]::PrimaryScreen) }

$script:context = New-Object System.Windows.Forms.ApplicationContext
$script:popups = @()
$script:closed = $false
$script:closeAll = {
    if ($script:closed) { return }
    $script:closed = $true
    foreach ($popup in $script:popups) { $popup.Close() }
    $script:context.ExitThread()
}
# How each popup ended goes into the log: clicked (and what Windows did), dismissed with X, replaced (a
# newer call for the same folder closed it), or window opened (you switched to it yourself).
function Write-Ending([string]$how) {
    if (-not $script:closed) { Add-Content -Path $log -Encoding UTF8 -Value "$(Get-Date -Format s) [$how] $($script:folder)" }
}
$openWindow = {
    Write-Ending "clicked: $([ClaudePopup]::BringToFront($script:folder))"
    & $script:closeAll
}
$dismiss = { Write-Ending 'dismissed with X'; & $script:closeAll }
$checkFocus = {
    if ([ClaudePopup]::HasFocus($script:folder)) { Write-Ending 'window opened'; & $script:closeAll }
}
$replaced = { Write-Ending 'replaced by a newer one'; & $script:closeAll }
foreach ($screen in $screens) {
    $popup = New-Object ClaudePopup $folder, $title, $message, $screen.WorkingArea
    # Only a close from outside gets here first: closeAll sets $script:closed before closing the popups.
    $popup.add_FormClosed($replaced)
    foreach ($control in @($popup) + @($popup.Controls)) {
        if ($control -eq $popup.CloseButton) { $control.add_MouseDown($dismiss) }
        else { $control.add_MouseDown($openWindow) }
    }
    $script:popups += $popup
    $popup.Show()
}

$sound = Join-Path $env:WINDIR 'Media\Windows Notify System Generic.wav'
if (Test-Path $sound) { $player = New-Object System.Media.SoundPlayer $sound; $player.Play() }
else { [System.Media.SystemSounds]::Asterisk.Play() }

# No time limit: twice a second, check whether you switched to that project's window yourself.
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 500
$timer.add_Tick($checkFocus)
$timer.Start()
[System.Windows.Forms.Application]::Run($script:context)
