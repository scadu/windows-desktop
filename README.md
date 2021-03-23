# zomg-windows-desktop

## What's that?
This repository contains information regarding my Windows setup and some scripts and utils in use.
___
### Preparation
#### Enable symlink support for standard (non-administrator) accounts
You can do it by enabling [Developer Mode](https://docs.microsoft.com/en-us/windows/apps/get-started/enable-your-device-for-development), or [updating the Local Security Policy](#local-security-policy).

###### Local Security Policy
Open `Local Security Policy` (`secpol.msc`) and go to `Local Policies` -> `User Rights Assignment`, select `Create symbolic links`, add your user to the list and **reboot**.

> Haven't found a reliable way to automate it.
> It's possible to export Local Security Policy to a file, edit the file and import back but I'm not convinced of this method.

#### Enable long paths
More information can be found in [Microsoft docs](https://docs.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation#enable-long-paths-in-windows-10-version-1607-and-later).

You can enable long path support editing the registry key or administrative template in the Group Policy that controls this registry key.
##### Registry key
> Run as administrator

`Set-ItemProperty 'HKLM:\System\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -value 1`

##### Group policy
`Computer Configuration > Administrative Templates > System > Filesystem > Enable Win32 long paths`.
___