 # PSRunAsCurrentUser
A PowerShell Script/Function that can run a PowerShell scriptblock as the current user Non-Elevated, using a scheduled task.

Note: The task and any log files used are cleaned up after execution.

Use the following One-liner to Temp Run in session: 

```
iex ((New-Object System.Net.WebClient).DownloadString("https://rawcdn.githack.com/AlecMcCutcheon/PSRunAsCurrentUser/b419b135641597982a2a4fa38e27502cde172584/PSRunAsCurrentUser.ps1"));
```

# Usage

```
PS C:\WINDOWS\system32> iex ((New-Object System.Net.WebClient).DownloadString("https://rawcdn.githack.com/AlecMcCutcheon/PSRunAsCurrentUser/b419b135641597982a2a4fa38e27502cde172584/PSRunAsCurrentUser.ps1"));

PS C:\WINDOWS\system32> (PSRunAsCurrentUser -ScriptBlock {Get-Partition | ConvertTo-Json} | ConvertFrom-Json).Size;

554696704
104857600
16777216
254770743296
610271232

```
The scheduled task executes the given Scriptblock in a hidden PowerShell window through a VBS script by default to make it hidden to the end user, however it has a fallback in case it is unable to create/run VBS scripts properly on the target machine, The Fallback is to just run the hidden PowerShell window directly, not using a VBS script, which results in a powershell window flashing up on screen for half a second when it is executed. If you want to test the fallback or you prefer to use it, you can use this switch "-ForceFallback"

Check out my other project: "[Get-CUOneDriveStatus](https://github.com/AlecMcCutcheon/Get-CUOneDriveStatus)" to see how I use this function as a compatibility layer for "Get-ODStatus"
