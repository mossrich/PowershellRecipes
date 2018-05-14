#restart as admin if not started as admin - required to run AppCmd
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
cd c:\windows\system32\inetsrv
.\appcmd list wp
If( $Host.Name -ne "Windows PowerShell ISE Host") {Pause}
