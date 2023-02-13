 # PSRunAsCurrentUser
A PowerShell Script/Function that can run a PowerShell scriptblock as the current user Non-Elevated, using a scheduled task.

Note: The task and any log files used are cleaned up after execution.

Use the following One-liner to Temp Run in session: 

```
iex ((New-Object System.Net.WebClient).DownloadString("https://tinyurl.com/PSRunAsCurrentUser"));
```

# Usage

```
PS C:\WINDOWS\system32> iex ((New-Object System.Net.WebClient).DownloadString("https://tinyurl.com/PSRunAsCurrentUser"));

PS C:\WINDOWS\system32> (PSRunAsCurrentUser -ScriptBlock {Get-Partition | ConvertTo-Json} | ConvertFrom-Json).Size;

554696704
104857600
16777216
254770743296
610271232

```
The scheduled task executes the PowerShell through a VBS script by default to make it hidden to the end user, however it has a fall back in case it is unable to create/ran a VBS script properly on the target machine, which just gets executed as a normal PowerShell window that is hidden what does flash for half a second when it is executed. If you want to test the fall back or you prefer to use it you can use this switch "-ForceFallback"

Check out my other project: "[Get-CUOneDriveStatus](https://github.com/AlecMcCutcheon/Get-CUOneDriveStatus)" to see how I use this function as a compatibility layer for "Get-ODStatus"
