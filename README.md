<img width="512" height="512" alt="logo" src="https://github.com/user-attachments/assets/8659294a-faf0-4a5c-9c68-0c70a5812245" />

# BloatwareCleaner

Uninstaller and Bloatware Remover for Windows!

A lightweight PowerShell tool with a graphical interface for bulk-uninstalling programs on Windows. It reads installed applications directly from the registry, lets you filter and multi-select them, and automatically flags common OEM bloatware (trial antivirus, toolbars, pre-installed games, etc.) so you can clean up a new PC in minutes instead of clicking through dozens of individual uninstallers.

## Recommended: create a restore point first

Before your first bulk uninstall run:

```powershell
Checkpoint-Computer -Description "Before BloatwareCleaner" -RestorePointType "MODIFY_SETTINGS"
```

## Installation & Usage

Either install the `.exe` file from the [Releases](../../releases) page, or run the `.ps1` script directly with PowerShell:

```powershell
cd C:\Users\yourname\Downloads
powershell -ExecutionPolicy Bypass -File .\BloatwareCleaner.ps1
```

> **Note:** To run the `.exe` file, you may need to temporarily disable Windows Defender / SmartScreen, since the file isn't code-signed.

## Features

- Lists all installed programs (64-bit, 32-bit, and per-user registry entries)
- Sortable table with name, publisher, version, size, and install date
- Search/filter box
- One-click "select known bloatware" based on a built-in pattern list (fully customizable)
- Bulk uninstall with live progress log
- Export the full program list to CSV
- Requests admin rights automatically (most uninstallers need them)

## ⚠️ Use at your own risk

This tool directly triggers each program's own uninstaller via the Windows registry. It does **not** delete files, drivers, or system components on its own — it simply calls the same uninstall routine you'd normally run by hand from "Apps & Features."

That said:

- **There is no undo.** Once a program is uninstalled, its settings and data may be gone for good.
- **Some uninstallers behave unpredictably** in silent/unattended mode — a few may fail silently, hang, or (rarely) leave leftover files or registry entries.
- **Be careful with system-critical-looking entries** (drivers, runtimes like "Microsoft Visual C++ Redistributable," GPU/chipset utilities). Removing the wrong thing can break other software or, in rare cases, Windows itself.
- **Always review your selection before hitting "Uninstall"** — the built-in bloatware list is a helpful starting point, not a guarantee. Double-check anything you're not 100% sure about.
- The author(s) take no responsibility for data loss, broken installations, or any other damage resulting from the use of this tool. You are running it on your own system, at your own discretion.

## License

MIT — free to use, modify, and share.
