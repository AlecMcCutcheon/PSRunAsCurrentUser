function PSRunAsCurrentUser {
  param(
    [scriptblock]$ScriptBlock,
    [switch]$ForceFallback
  )

  $UsersAndTheirHomes = Get-WmiObject win32_userprofile | ForEach-Object { try { $out = New-Object psobject; $out | Add-Member noteproperty Name (New-Object System.Security.Principal.SecurityIdentifier ($_.SID)).Translate([System.Security.Principal.NTAccount]).Value; $out | Add-Member noteproperty LocalPath $_.LocalPath; $out } catch {} };
  $CurrentUserHome = ($UsersAndTheirHomes | Where-Object { $_.Name -eq ((Get-WmiObject -Class Win32_ComputerSystem).UserName) }).LocalPath;

  if ($ForceFallback) {
    function RunAsVBS { return $false }
  } else {
    function RunAsVBS {
      $EncodedCommandTest = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes(([scriptblock]::Create("((New-Item -Path '$CurrentUserHome\VBSTest.log' -Value 'Test').Attributes='Hidden')"))));
      ((New-Item -Path "$CurrentUserHome\VBSTest.vbs" -Value ("command = " + '"Powershell.exe -NonInteractive -WindowStyle Hidden -NoLogo -NoProfile -EncodedCommand ' + "$EncodedCommandTest" + '"' + "`n" + 'set shell = CreateObject("WScript.Shell")' + "`n" + "shell.Run command,0")).Attributes = "Hidden") > $null;
      wscript.exe "$CurrentUserHome\VBSTest.vbs";
      Start-Sleep -Seconds 2;
      if (Test-Path "$CurrentUserHome\VBSTest.vbs") { Remove-Item "$CurrentUserHome\VBSTest.vbs" -Confirm:$false -Force; }
      if (Test-Path "$CurrentUserHome\VBSTest.log") { Remove-Item "$CurrentUserHome\VBSTest.log" -Confirm:$false -Force; return $true; } else { return $false; }
    }
  }

  $TranscriptStart = "((New-Item -Path '$CurrentUserHome\RunASCurrentUserTemp.log' -Value '').Attributes='Hidden');Start-Transcript '$CurrentUserHome\RunASCurrentUserTemp.log' -Append" + ' > $null';
  $TranscriptEnd = "Stop-Transcript; Set-Content '$CurrentUserHome\RunASCurrentUserOutput.log' -Value (Get-Content '$CurrentUserHome\RunASCurrentUserTemp.log' -Force);";
  $Marker = (([guid]::NewGuid()).GUID);
  $ScriptBlock = [scriptblock]::Create($TranscriptStart + "`n" + "Write-Output '" + $Marker + "'" + "`n" + ($ScriptBlock).ToString() + "`n" + "Write-Output '" + $Marker + "'" + "`n" + $TranscriptEnd);
  $EncodedCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($ScriptBlock))
  if (!(Test-Path "$CurrentUserHome\RunASCurrentUserOutput.log")) { ((New-Item -Path "$CurrentUserHome" -Name "RunASCurrentUserOutput.log" -Type "file").Attributes = 'Hidden') > $null };
  if (!(Test-Path "$CurrentUserHome\RunASCurrentUserTemp.log")) { ((New-Item -Path "$CurrentUserHome" -Name "RunASCurrentUserTemp.log" -Type "file").Attributes = 'Hidden') > $null };
  Set-Content "$CurrentUserHome\RunASCurrentUserOutput.log" -Value "" -Force;
  Set-Content "$CurrentUserHome\RunASCurrentUserTemp.log" -Value "" -Force;
  Unregister-ScheduledTask -TaskName 'RunASCurrentUser' -Confirm:$false -ErrorAction SilentlyContinue;
  $LastWriteTime = (Get-Item "$CurrentUserHome\RunASCurrentUserOutput.log" -Force).LastWriteTime;

  if (RunAsVBS) {
    ((New-Item -Path "$CurrentUserHome\RunASCurrentUser.vbs" -Value ("command = " + '"Powershell.exe -NonInteractive -WindowStyle Hidden -NoLogo -NoProfile -EncodedCommand ' + "$EncodedCommand" + '"' + "`n" + 'set shell = CreateObject("WScript.Shell")' + "`n" + "shell.Run command,0")).Attributes = 'Hidden') > $null;
    $PSPath = "C:\Windows\System32\wscript.exe";
    $Args = "$CurrentUserHome\RunASCurrentUser.vbs";
  } else {
    $PSPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe";
    $Args = "-NonInteractive -WindowStyle Hidden -NoLogo -NoProfile -EncodedCommand $EncodedCommand";
  }

  $Action = New-ScheduledTaskAction -Execute $PSPath -Argument $Args;
  $Option = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -WakeToRun -DontStopOnIdleEnd -RestartInterval (New-TimeSpan -Minutes 1) -RestartCount 2 -StartWhenAvailable;
  $Option.ExecutionTimeLimit = "PT0S";
  $Trigger = New-JobTrigger -Once -at ((Get-Date) + (New-TimeSpan -Minutes 5)) -RandomDelay (New-TimeSpan -Minutes 1);
  Register-ScheduledTask -User ((Get-WmiObject -Class Win32_ComputerSystem).UserName) -TaskName "RunASCurrentUser" -Action $Action -Trigger $Trigger -Settings $Option > $null;
  Start-ScheduledTask -TaskName 'RunASCurrentUser';
  do { Start-Sleep -Seconds 1 } while (((Get-Item "$CurrentUserHome\RunASCurrentUserOutput.log" -Force).LastWriteTime -eq $LastWriteTime));
  Unregister-ScheduledTask -TaskName 'RunASCurrentUser' -Confirm:$false;
  $RunAsCurrentUserOutput = (((Get-Content ((Get-Item "$CurrentUserHome\RunASCurrentUserOutput.log" -Force).FullName)) | Out-String) -split $Marker)[1];
  if (Test-Path "$CurrentUserHome\RunASCurrentUserOutput.log") { Remove-Item "$CurrentUserHome\RunASCurrentUserOutput.log" -Confirm:$false -Force; };
  if (Test-Path "$CurrentUserHome\RunASCurrentUserTemp.log") { Remove-Item "$CurrentUserHome\RunASCurrentUserTemp.log" -Confirm:$false -Force; };
  if (Test-Path "$CurrentUserHome\RunASCurrentUser.vbs") { Remove-Item "$CurrentUserHome\RunASCurrentUser.vbs" -Confirm:$false -Force; };
  return $RunAsCurrentUserOutput;
}
