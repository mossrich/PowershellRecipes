[int] $ProcessId = ([xml] (& "$env:SystemRoot\system32\inetsrv\appcmd.exe" list wp /xml /apppool.name:"DefaultAppPool")).appcmd.WP."WP.NAME"
[Runtime.InteropServices.Marshal]::GetActiveObject('VisualStudio.DTE').Debugger.LocalProcesses | ? {$_.ProcessID -eq $ProcessId} | %{$_.Attach()}
