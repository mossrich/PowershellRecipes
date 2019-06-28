#Toggles the state of fusion logging on or off
Param(
    $LogPath = "c:\temp\Fusion"
)
#restart as admin if not started as admin 
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -PassThru -Verb RunAs | Out-null; exit 
}
Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Fusion
If(!(Test-Path HKLM:\SOFTWARE\Microsoft\Fusion)) {New-Item -Path HKLM:\SOFTWARE\Microsoft\Fusion -ItemType Container | Out-Null}
$LoggingEnabled = ((Get-ItemProperty -path HKLM:\SOFTWARE\Microsoft\Fusion).EnableLog) -eq 1
If(!$LoggingEnabled){
    Write-Host "Enabling Fusion Logging at $LogPath"
    Set-ItemProperty -Path HKLM:\Software\Microsoft\Fusion -Name EnableLog        -Value 1               -Type DWord
    Set-ItemProperty -Path HKLM:\Software\Microsoft\Fusion -Name ForceLog         -Value 1               -Type DWord
    Set-ItemProperty -Path HKLM:\Software\Microsoft\Fusion -Name LogFailures      -Value 1               -Type DWord
    Set-ItemProperty -Path HKLM:\Software\Microsoft\Fusion -Name LogResourceBinds -Value 1               -Type DWord
    Set-ItemProperty -Path HKLM:\Software\Microsoft\Fusion -Name LogPath          -Value $LogPath
    If(!(Test-Path $LogPath -PathType Container)){New-Item $LogPath -ItemType Directory}
}Else{
    Write-Host "Disabling Fusion Logging"
    Set-ItemProperty -Path HKLM:\Software\Microsoft\Fusion -Name EnableLog        -Value 0               -Type DWord
    Set-ItemProperty -Path HKLM:\Software\Microsoft\Fusion -Name ForceLog         -Value 0               -Type DWord
    Set-ItemProperty -Path HKLM:\Software\Microsoft\Fusion -Name LogFailures      -Value 0               -Type DWord
    Set-ItemProperty -Path HKLM:\Software\Microsoft\Fusion -Name LogResourceBinds -Value 0               -Type DWord
}
If(!$Host.Name.Contains("ISE")){Pause}
