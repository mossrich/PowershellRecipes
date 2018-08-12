#puts a list of powershell snippets in the system tray - right click on the icon and select one to execute the scriptblock
Param($Snippets =  (
    [ordered]@{ # ordered hashtable of menu items to add 
       "User Name to Clipboard" = {Set-ClipBoardText $env:UserName}
       "Edit This Script" =       {powershell_ise.exe $MyInvocation.ScriptName}
       "Show output window" =     {ShowHideWindow $true}
       "Exit" =                   {$NotifyIcon.Visible = $False 
                                   $form1.close()}
     })
)
Add-Type -AssemblyName "System.Windows.Forms"

Function IconFromBase64Bytes([string]$b64EncodedImage){ #use this if the icon is just b64-encoded bytes, not compressed
    $ms = [System.IO.MemoryStream][System.Convert]::FromBase64String(($b64EncodedImage )) #-replace ".{80}" , "$&`r`n"))
    $bmp = [System.Drawing.Bitmap][System.Drawing.Image]::FromStream($ms)
    Return [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
}

Function IconFromCompressedB64Bytes([string]$CompressedBase64EncodedImage){#decompresses a b64 string to a byte array representing the icon image and returns an icon object
    $DecompressedBytes = New-Object System.IO.MemoryStream( , (Get-DecompressedBytesFromB64 $CompressedBase64EncodedImage))
    $bmp = [System.Drawing.Bitmap][System.Drawing.Image]::FromStream($DecompressedBytes)
    Return [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
}

Function Get-CompressedBytesB64Encoded([byte[]]$UnCompressedBytes){
    #Sample call that gets B64 string from .ico file to clipboard:    Set-ClipBoardText (Get-CompressedBytesB64Encoded (Get-Content .\DEVAUTH_ok.ico -Encoding Byte))
    $CompressedMS = New-Object System.IO.MemoryStream
    $gzStream = New-Object System.IO.Compression.GZipStream($CompressedMS, [System.IO.Compression.CompressionMode]::Compress, [System.IO.Compression.CompressionLevel]::Optimal)
    $gzStream.Write($UnCompressedBytes,0,$UnCompressedBytes.Length)
    $gzStream.Close()
    $CompressedMS.Close()
    Write-Host "Compressed from $($UnCompressedBytes.Length) to $($CompressedMS.ToArray().Length)"
    Return [Convert]::ToBase64String($CompressedMS.ToArray())
}

Function Get-DecompressedBytesFromB64([string] $b64EncodedCompressedBytes){ #from "H4sIAAA..." via un-gzip to [byte[]]
    $CompressedMS = [System.IO.MemoryStream][System.Convert]::FromBase64String($b64EncodedCompressedBytes)
    $DecompressedMS = New-Object System.IO.MemoryStream
    $gzStream = New-Object System.IO.Compression.GZipStream($CompressedMS, [System.IO.Compression.CompressionMode]::Decompress)
    $gzStream.CopyTo($DecompressedMS)
    $gzStream.Close()
    $DecompressedMS.Close()
    Return $DecompressedMS.ToArray()
}

function ShowHideWindow([bool] $show=$false) { #shows or hides a window using native windows API 
    $User32 = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'
    if (-not ([System.Management.Automation.PSTypeName]'native.win').Type){ add-type -name win -member $User32 -namespace native }
    $flag = if ($show){1}Else{0}
    [native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, $flag) | Out-Null
}

function Get-ClipboardText {
    if (-not ([System.Management.Automation.PSTypeName]'System.Windows.Forms').Type){ Add-Type -AssemblyName 'System.Windows.Forms' | Out-Null}
    [System.Windows.Forms.Clipboard]::GetText() 
}

function Set-ClipBoardText([string]$text) {
    if (-not ([System.Management.Automation.PSTypeName]'System.Windows.Forms').Type){ Add-Type -AssemblyName 'System.Windows.Forms' | Out-Null}
    [System.Windows.Forms.Clipboard]::SetText($text)	#This is slower:    powershell -sta -noprofile -command {add-type -an system.windows.forms;[System.Windows.Forms.Clipboard]::SetText($text) } #doesn't work for strings that are longer than command line supports
}

$form1 = New-Object System.Windows.Forms.form -Property @{ShowInTaskbar = $false; WindowState = "minimized"}
$iconKB = IconFromCompressedB64Bytes "H4sIAAAAAAAEANWSX0hTURzHjxDb3K7zOt0CI+qt3uLOQWbX3NSlFFEYKvkW/dNEEleiZcP8S4mVxFAf6iF9cup8GE33IvaQJMletDD/ZEISVA/ByTvnbt9+W2q+BEEP0ffyufec8+Nzz4/DYSyBHlFklP2sfBdjFhodJMT4CqNq7E2hmsnwk60A+K9h55lzd6X5o73lmGJvzub2RpnnumWe3yBz502ZF9TLvLBO5idqZX7yusxPuWRedMO+Zi3d+zXdwS6YKkwzvulB/Dbfd6BuQpl+PYmM4n2f5eYsJVZ88X4SfaE+DMx44Z31YuCNF4NzQxh6O4zheR+GF3zwLY3AuziIidWJ+D8uuc9GHW2Ob7FxydMSJFQnQHNLA00j0apB4t1EGDoMSHqQhORHyUjpSYHWo0WeP492VFHVVBbJac3hMb+4vxjMxaB1a5HYRF47eR3kdZL3MAWpnlSYe80wdBvg9B9HlPyrjaW//D7yaxg0tzXQ3dFB36aHcE+AsdMIsUuEyWNCWm8a9N165Pud237uZv9l/WXQuXQQ3AKEFqJdiO8v3ie3i1xPGiy9Fgg9Agr8hWTH+j8XyWrKVFRVRWg1hJHZETybCyAwTywQS6MYfTeKseUxBJeDCK4EEVgJ4OWnqfj5XWw4oxqvGF89ef4Y65EwohsRRNbDiISVOBsKfbdYozkRXQtDDa9jfCqAQ0XpH+j+ZIqXxUVbvVWx1Vl5Rq3EbS6iRuKHqyWeeU3iR6okfrRS4tkVEs+psHJHuU05cNr8ZY+DFf3r+//3sG3+NDudH6/EhY5+BAAA"
$NotifyIcon= New-Object System.Windows.Forms.NotifyIcon -Property @{Visible = $True; Icon =  $iconKB; ContextMenu = (New-Object System.Windows.Forms.ContextMenu) }

$Snippets.GetEnumerator() | %{ #iterate through the hashtable and add each name/value as a menu item label/click event handler
    $MenuItem = New-Object System.Windows.Forms.MenuItem -Property @{Text = $_.Name}
    $MenuItem.add_Click([scriptblock] $_.Value)
    $NotifyIcon.contextMenu.MenuItems.Add($MenuItem) | Out-Null
   } 

If(!$Host.Name.Contains("ISE")){ShowHideWindow $false}
[void][System.Windows.Forms.Application]::Run($form1)
