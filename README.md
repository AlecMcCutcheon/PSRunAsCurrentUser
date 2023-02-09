# PSRunAsCurrentUser
A PowerShell Script/Function that can run a PowerShell scriptblock as the current user, using a scheduled task

Use the following One-liner to Temp Run in session: 

```
iex ((New-Object System.Net.WebClient).DownloadString("https://tinyurl.com/PSRunAsCurrentUser"));
```

# Usage

```

PS C:\WINDOWS\system32> (PSAsCurrentUser -ScriptBlock {Get-Partition | ConvertTo-Json} | ConvertFrom-Json).Size;

554696704
104857600
16777216
254770743296
610271232

```
