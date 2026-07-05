<p align="center">
  <img width="512" height="512" alt="image" src="https://github.com/user-attachments/assets/34d49140-15dd-409d-a1ce-4a436334481b" />
>
</p>

<h1 align="center">BloatwareCleaner</h1>

<p align="center">
  A lightweight PowerShell GUI tool for bulk-uninstalling Windows programs — fast enough to clean up a new PC in minutes.
</p>

<p align="center">
  <img src="https://img.shields.io/github/v/release/Kirakiller1547/BloatwareCleaner" alt="Latest release">
  <img src="https://img.shields.io/github/license/Kirakiller1547/BloatwareCleaner" alt="License">
  <img src="https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white" alt="PowerShell 5.1+">
  <img src="https://img.shields.io/badge/platform-Windows-0078D6?logo=windows&logoColor=white" alt="Windows">
</p>

---


<img width="902" height="624" alt="{E79C7185-F7A9-4A89-A68A-459D0D894E34}" src="https://github.com/user-attachments/assets/aaf13ba7-d763-4d04-b8d5-b9f039e8e986" />

## What it does

BloatwareCleaner reads every installed program directly from the Windows registry (64-bit, 32-bit, and per-user entries), shows them in a sortable, filterable table, and lets you multi-select and uninstall in bulk. A built-in pattern list automatically flags common OEM bloatware — trial antivirus, toolbars, pre-installed games — so you're not clicking through dozens of individual uninstallers by hand.

<!-- 
  TODO: Add 1-3 screenshots or a short GIF of the GUI here, e.g.:
  ![Main window](docs/screenshot-main.png)
  ![Bloatware auto-select](docs/screenshot-select.png)
-->

## Requirements

- Windows 10 or 11
- PowerShell 5.1 or later (included by default on Windows 10/11)
- Administrator rights (the tool will prompt for elevation automatically)

## Recommended: create a restore point first

Before your first bulk uninstall run:

```powershell
Checkpoint-Computer -Description "Before BloatwareCleaner" -RestorePointType "MODIFY_SETTINGS"
```

## Installation & Usage

**Option A — Download the release**
Grab the latest `.exe` from the [Releases](https://github.com/Kirakiller1547/BloatwareCleaner/releases) page and run it.

> **Note:** The `.exe` isn't code-signed, so Windows Defender / SmartScreen may flag or block it on first run. This is a common false positive for small, unsigned PowerShell-to-exe tools — not a sign of malicious behavior — but you should always verify by reading the source (`BloatwareCleaner.ps1`) if you're unsure. You may need to click "More info → Run anyway" or temporarily allow the file through SmartScreen.

**Option B — Run the script directly**

```powershell
cd C:\Users\yourname\Downloads
powershell -ExecutionPolicy Bypass -File .\BloatwareCleaner.ps1
```

## Features

- Lists all installed programs (64-bit, 32-bit, and per-user registry entries)
- Sortable table with name, publisher, version, size, and install date
- Search/filter box
- One-click "select known bloatware" based on a built-in, customizable pattern list
- Bulk uninstall with live progress log
- Export the full program list to CSV
- Requests admin rights automatically (most uninstallers need them)

## Customizing the bloatware list

The pattern list used for auto-detection lives near the top of `BloatwareCleaner.ps1`, as an array of name/publisher patterns matched against registry entries. To add your own:

1. Open `BloatwareCleaner.ps1` in a text editor.
2. Find the bloatware pattern array (e.g. `$bloatwarePatterns`).
3. Add a new entry following the existing format, for example:
   ```powershell
   "*McAfee*",
   "*Toolbar*"
   ```
4. Save and re-run the script — new patterns take effect immediately without needing to rebuild the `.exe`.

## ⚠️ Use at your own risk

This tool directly triggers each program's own uninstaller via the Windows registry. It does **not** delete files, drivers, or system components on its own — it simply calls the same uninstall routine you'd normally run by hand from "Apps & Features."

That said:

- **There is no undo.** Once a program is uninstalled, its settings and data may be gone for good.
- **Some uninstallers behave unpredictably** in silent/unattended mode — a few may fail silently, hang, or (rarely) leave leftover files or registry entries.
- **Be careful with system-critical-looking entries** (drivers, runtimes like "Microsoft Visual C++ Redistributable," GPU/chipset utilities). Removing the wrong thing can break other software or, in rare cases, Windows itself.
- **Always review your selection before hitting "Uninstall"** — the built-in bloatware list is a helpful starting point, not a guarantee. Double-check anything you're not 100% sure about.
- The author(s) take no responsibility for data loss, broken installations, or any other damage resulting from the use of this tool. You are running it on your own system, at your own discretion.

## Contributing

Issues and pull requests are welcome — whether that's bug reports, new bloatware patterns, or general improvements. If you're adding a device-specific pattern (e.g. a particular OEM's preinstalled app), please mention the manufacturer/model in your PR description so it's easy to verify.

## License

MIT — free to use, modify, and share.
