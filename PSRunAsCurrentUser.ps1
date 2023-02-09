Function PSRunAsCurrentUser {
param (
 [scriptblock]$ScriptBlock
)
$UsersAndTheirHomes = Get-WmiObject win32_userprofile | ForEach-Object {try {$out = new-object psobject;$out | Add-Member noteproperty Name (New-Object System.Security.Principal.SecurityIdentifier($_.SID)).Translate([System.Security.Principal.NTAccount]).Value;$out | Add-Member noteproperty LocalPath $_.LocalPath;$out} catch {}};
$CurrentUserHome = ($UsersAndTheirHomes | Where {$_.Name -eq ((Get-WMIObject -class Win32_ComputerSystem).UserName)}).LocalPath;
$TranscriptStart = "(Start-Transcript '$CurrentUserHome\RunASCurrentUserTemp.log')" + ' > $null';
$TranscriptEnd = "Stop-Transcript; Get-Content '$CurrentUserHome\RunASCurrentUserTemp.log' | Out-File '$CurrentUserHome\RunASCurrentUserOutput.log'";
$Marker = (([guid]::NewGuid()).Guid);
$ScriptBlock = [scriptblock]::Create($TranscriptStart + "`n" + "Write-Output '" + $Marker + "'" + "`n" + ($ScriptBlock).ToString() + "`n" + "Write-Output '" + $Marker + "'" + "`n" + $TranscriptEnd);
$EncodedCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($ScriptBlock))
(New-Item -Path "$CurrentUserHome\RunASCurrentUser.vbs" -Value ("command = " + '"Powershell.exe -NonInteractive -WindowStyle Hidden -NoLogo -NoProfile -EncodedCommand ' + "$EncodedCommand" + '"' + "`n" + 'set shell = CreateObject("WScript.Shell")' + "`n" + "shell.Run command,0")) > $null;
if (!(Test-Path "$CurrentUserHome\RunASCurrentUserOutput.log")){New-Item -path "$CurrentUserHome" -name "RunASCurrentUserOutput.log" -type "file" > $null};
if (!(Test-Path "$CurrentUserHome\RunASCurrentUserTemp.log")){New-Item -path "$CurrentUserHome" -name "RunASCurrentUserTemp.log" -type "file" > $null};
Set-Content "$CurrentUserHome\RunASCurrentUserOutput.log" -Value $null;
Unregister-ScheduledTask -TaskName 'RunASCurrentUser' -Confirm:$false -ErrorAction SilentlyContinue;
$LastWriteTime = (Get-Item "$CurrentUserHome\RunASCurrentUserOutput.log").LastWriteTime;
$PSPath = "C:\Windows\System32\wscript.exe";
$Args = "$CurrentUserHome\RunASCurrentUser.vbs";
$Action = New-ScheduledTaskAction -Execute $PSPath -Argument $Args;
$Option = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -WakeToRun -DontStopOnIdleEnd -RestartInterval (New-TimeSpan -Minutes 1) -RestartCount 2 -StartWhenAvailable;
$Option.ExecutionTimeLimit = "PT0S";
$Trigger = New-JobTrigger -Once -at ((Get-Date) + (New-TimeSpan -Minutes 5)) -RandomDelay (New-TimeSpan -Minutes 1);
Register-ScheduledTask -User ((Get-WMIObject -class Win32_ComputerSystem).UserName) -TaskName "RunASCurrentUser" -Action $Action -Trigger $Trigger -Settings $Option > $null;
Start-ScheduledTask -TaskName 'RunASCurrentUser';
Do {Start-Sleep -Seconds 1} While (((Get-Item "$CurrentUserHome\RunASCurrentUserOutput.log").LastWriteTime -eq $LastWriteTime));
Unregister-ScheduledTask -TaskName 'RunASCurrentUser' -Confirm:$false;
$RunAsCurrentUserOutput = (((Get-Content ((Get-Item "$CurrentUserHome\RunASCurrentUserOutput.log").FullName)) | Out-String) -split $Marker)[1];
Remove-Item "$CurrentUserHome\RunASCurrentUserOutput.log" -Confirm:$false -Force;
Remove-Item "$CurrentUserHome\RunASCurrentUserTemp.log" -Confirm:$false -Force;
Remove-Item "$CurrentUserHome\RunASCurrentUser.vbs" -Confirm:$false -Force;
return $RunAsCurrentUserOutput;
}
