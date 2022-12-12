# zomg-windows-desktop

## What's that?

This repository contains information regarding my Windows setup and some scripts and utils I use.

---
### Tools, applications, languages

A short list of tools I use:

* [Windows Terminal](https://aka.ms/terminal)
* [Starship (shell prompt)](https://starship.rs)
* [Visual Studio Code](https://code.visualstudio.com)
* [PowerShell Core](https://github.com/PowerShell/PowerShell)
* [WSL2](https://docs.microsoft.com/en-us/windows/wsl/install-win10)
* [Python](https://www.python.org) - installed with [installer provided by upstream](https://www.python.org/downloads/release/python3)
* [ShutUp10](https://www.oo-software.com/en/shutup10) - "Free antispy tool for Windows 10". Use with default settings, you don't want to mess with Windows internals.
* [Patch My PC Home Updater](https://patchmypc.com/home-updater) - keeps your application updated.
* [Sysinternals](https://docs.microsoft.com/en-us/sysinternals/)
* [PowerToys](https://docs.microsoft.com/en-us/windows/powertoys/) - a set of utilities for power users to tune and streamline their Windows 10 experience for greater productivity.
  - [FancyZones](https://docs.microsoft.com/en-us/windows/powertoys/fancyzones) - a window manager that makes it easy to create complex window layouts and quickly position windows into those layouts.

Fonts:

* [Cascadia Code](https://github.com/microsoft/cascadia-code) - currently shipped with the [Windows Terminal](https://aka.ms/terminal)

#### Package manager

For dev-related stuff I use [Scoop](https://scoop.sh) with `main` and [extras](https://github.com/lukesampson/scoop-extras) buckets.

To install scoop:

```powershell
Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
```
or
```powershell
iwr -useb get.scoop.sh | iex
```

⚠️ If you get an error you might need to change the execution policy (i.e. enable Powershell) with:

```powershell
Set-ExecutionPolicy RemoteSigned -scope CurrentUser
```

To add `extras` bucket:

```
scoop bucket add extras
```

Packages I usually install:

```
bind ripgrep starship
```

##### Keeping envirionment up to date

For this purpose I've created a small script that updates applications with [PatchMyPC](https://patchmypc.com) and [Scoop](https://scoop.sh).
Additionally, it also checks for available security and critical Windows updates with [PSWindowsUpdate PowerShell module](https://www.powershellgallery.com/packages/PSWindowsUpdate/2.2.0.2).

---

### Caveats

### Symlinks and junctions
Some applications may require symlinks which require special privileges.
These privileges can be assigned to the user by enabling [Developer Mode](https://docs.microsoft.com/en-us/windows/apps/get-started/enable-your-device-for-development), or [updating the Local Security Policy](#local-security-policy).

###### Local Security Policy

Open `Local Security Policy` (`secpol.msc`) and go to `Local Policies` -> `User Rights Assignment`, select `Create symbolic links`, add your user to the list and **reboot**.

⚠️ I would recommend doing so only when absolutely required, e.g. the tooling you use doesn't support [junctions](https://docs.microsoft.com/en-us/windows/win32/fileio/hard-links-and-junctions#junctions)

More detail about junctions on [superuser.com](https://superuser.com/a/343079).
___

### Long paths
While `MAX_PATH` limitations have been removed in Windows 10, version 1607, the behavior remains opt-in.

More information can be found in [Microsoft docs](https://docs.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation#enable-long-paths-in-windows-10-version-1607-and-later).

To enable long paths from PowerShell creating a registry key (run as admin):
```powershell
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
-Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
```
---
#### High DPI

[Windows scaling issues](https://support.microsoft.com/en-us/topic/windows-scaling-issues-for-high-dpi-devices-508483cd-7c59-0d08-12b0-960b99aa347d)

[Fix apps that appear blurry in Windows 10](https://support.microsoft.com/en-us/windows/fix-apps-that-appear-blurry-in-windows-10-e9fe34ab-e7e7-bc6f-6695-cb169b51de0f)

[Make older apps or programs compatible with Windows 10](https://support.microsoft.com/en-us/windows/make-older-apps-or-programs-compatible-with-windows-10-783d6dd7-b439-bdb0-0490-54eea0f45938)

---

### Prevent applications from taking exclusive control of sound adapter

There are cases when applications takes control over sound adapter adjusting volume level automatically messing with our settings. Also, it means that only one application at a time can use your audio interface.

To prevent such behavior open `Control Panel` and go to `Sound` section, select your device and from `Advanced` tab uncheck `Allow applications to take exclusive control of this device` checkbox.

___
### Shrink WSL2 Virtual Disks
When working with WSL2, Docker Desktop uses WSL to manage virtual hard drives (`ext4.vhdx`).
Those virtual hard drives can grow quite significantly even if you've cleaned up some space.
Virtual hard drives can be optimized with [Optimize-VHD](https://docs.microsoft.com/en-us/powershell/module/hyper-v/optimize-vhd).

I've written [a dead simple script](scripts/powershell/Optimize-VHDX.ps1) to find `ext4.vhdx` files and optimize them.

#### Bonus
Scott Hanselman blog post: [Shrink your WSL2 Virtual Disks and Docker Images and Reclaim Disk Space](https://www.hanselman.com/blog/shrink-your-wsl2-virtual-disks-and-docker-images-and-reclaim-disk-space)
