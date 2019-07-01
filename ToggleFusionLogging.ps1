Param( $LogPath = "c:\temp\Fusion" )
#restart as admin if not started as admin 
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -PassThru -Verb RunAs | Out-null; exit 
}
$RegKey = 'HKLM:\SOFTWARE\Microsoft\Fusion'
If(!(Test-Path $RegKey)) {New-Item -Path $RegKey -ItemType Container | Out-Null}
If(!(Test-Path $LogPath -PathType Container)){New-Item $LogPath -ItemType Directory | Out-Null}
$NewValue = If((Get-ItemProperty $RegKey).EnableLog -eq 1){0} Else {1}
Set-ItemProperty -Path $RegKey -Name EnableLog        -Value $NewValue -Type DWord
Set-ItemProperty -Path $RegKey -Name ForceLog         -Value $NewValue -Type DWord
Set-ItemProperty -Path $RegKey -Name LogFailures      -Value $NewValue -Type DWord
Set-ItemProperty -Path $RegKey -Name LogResourceBinds -Value $NewValue -Type DWord
Set-ItemProperty -Path $RegKey -Name LogPath          -Value $LogPath  -Type String
Write-Host "$(If($NewValue -eq 1){'Enabled'}Else{'Disabled'}) Fusion Logging at $LogPath"
If(!$Host.Name.Contains("ISE")){Pause}
