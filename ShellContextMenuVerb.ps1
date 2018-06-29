#Uses Shell.Application to invoke the verb in the right-click context menu 
Param(
    [string] $filePath = "C:\Windows\System32\notepad.exe",
    [string] $verbName = "Properties" #as it appears in the right-click context menu, without & for underlining
)
$Shell = New-Object -ComObject Shell.Application
$folder = $Shell.NameSpace( (Split-Path $filePath -Parent))
$File = $folder.ParseName( (Split-Path $filePath -Leaf ))
$file.Verbs() | %{if($_.Name.Replace('&','') -eq $verbName ){$_.DoIt() } }
