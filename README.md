# Exam Countdown Timer

I built this software when I was preparing for a competitive exam for me and my friends, it really helped us to stay motivated by seeing the remaining time we had left.

A lightweight always-on-top countdown timer that floats over your desktop. Built with PowerShell + WPF, Windows only.

*Originally made around June 2024*

<p align="center">
  <img src="media/preview.png" alt="Countdown Timer" />
</p>

---

## Features

- Transparent, borderless overlay — stays on top of everything
- Click-through mode so it never gets in your way
- Drag to move, resize from any edge or corner
- Runs silently in the background via Task Scheduler

---

## Keyboard Shortcut

| Shortcut | Action |
|----------|--------|
| `Alt + C` | Toggle click-through mode on/off |

- **Gray border** — click-through is ON (clicks pass through the window)
- **White border** — click-through is OFF (you can drag to move or resize)

---

## Configuration

Open `countdown_timer.ps1` and edit these two lines near the top:

```powershell
# Set your target date and time
$examDate = Get-Date "2025-01-22 00:00:00"
```

```powershell
# Change the label text shown in the timer
$countdownLabel.Content = "42C, $days D $hours H $minutes M $seconds S"
```

---

## Auto-start with Task Scheduler

To have the timer launch automatically on login:

1. Open **Task Scheduler** and create a new task.
2. Add **two triggers**:
   - *At log on* of your user — no expiry
   - *On a schedule* (one-time, any date) — repeat every **1 minute** for **indefinitely**, no expiry
3. Under **Actions**, set:
   - **Program:** `powershell.exe`
   - **Arguments:**
     ```
     -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\path\to\countdown_timer.ps1"
     ```
     *(update the path to match where you saved the script)*
4. Under **Settings**, enable:
   - *If the task fails, restart every:* **1 minute**
   - *Allow task to be run on demand*
   - *If the task is already running:* **Do not start a new instance**

---

## Requirements

- Windows 10 or Windows 11
- PowerShell 5.1+

---
