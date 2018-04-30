#restart as admin if not started as admin 
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit 
}
$baseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('ClassesRoot', ".")
#set these file types to be previewable as text, if not already set
@(".ps1",".log",".hta",".json",".md",".bat",".cmd",".csv",".config",".proj",".reg",".resx",".sln",".sql",".svc",".svclog",".targets",".vbs",".vcproj") | % {
    Write-Host "Enabling preview for $_ "
    If(!($baseKey.GetSubKeyNames() -contains $_)){$baseKey.CreateSubKey($_)}
    $regKey = $baseKey.OpenSubKey($_,$true)
    If($regKey.GetValue('PerceivedType') -eq $null) {
        $regKey.Setvalue('PerceivedType', 'text', 'String')
    }else{
        Write-Warning "PerceivedType already set to '$($regKey.GetValue('PerceivedType'))'. Existing value was not overwritten. "
    }
    If($regKey.GetValue('Content Type') -eq $null) {
        $regKey.Setvalue('Content Type', 'text/plain', 'String')
    }else{
        Write-Warning "Content Type already set to '$($regKey.GetValue('Content Type'))'. Existing value was not overwritten. "
    }
    $regKey.Close()
}
Try{#allow treating .nupkg files as .zip files and navigating into them
    $regKey = $baseKey.OpenSubKey(".nupkg",$true)
    If($regKey.GetValue('') -eq $null){
        $regKey.Setvalue('', 'CompressedFolder', 'String')
    }
    $regKey.Close()
}Catch{
    cmd /c "assoc .nupkg=CompressedFolder" 
}

If($Host.Name -ne "Windows PowerShell ISE Host") {Pause} #pause if not in ISE so the user can see errors if running from rt-click 
