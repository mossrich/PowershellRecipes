Param(
    $hostToCheck = "127.0.0.1:135",#choose a host and port to check
    $interval = 100000, #check every x milliseconds
    $MenuItems =  (
    [ordered]@{ # ordered hashtable of menu items to add 
       "Edit This Script" = {powershell_ise.exe $MyInvocation.ScriptName}
       "Check Now" =        {CheckHost}
       "Exit" =             {$NotifyIcon.Visible = $False;$form1.close()}
     })
)
Add-Type -AssemblyName "System.Windows.Forms" | Out-Null

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

function CheckHost(){
    try {
        $NotifyIcon.Icon = $iconWait
        $NotifyIcon.Text = "Attempting to connect to $($hostToCheck.Split(':')[0]) port $($hostToCheck.Split(':')[1])"
        $t = New-Object Net.Sockets.TcpClient $hostToCheck.Split(':')[0], $hostToCheck.Split(':')[1]
        $NotifyIcon.Icon = $iconOK
        $NotifyIcon.Text = "OK - Last checked @ ("+(Get-Date -Format HH:mm)+") "
        
    } catch {
        $NotifyIcon.Icon = $iconWarn
        $NotifyIcon.Text = "FAILED - Last checked @ ("+(Get-Date -Format HH:mm)+") "

    }
}

 $CompressedIcons = @{#These are Base-64 encoded strings representing the G-Zip compressed bytes of an ICO file. 
    "Good" = "H4sIAAAAAAAEAI2Ta0zbZRTGD+NWQFj5c5EFKAgptNg7hV6QABvYcrNQbkI6oIu6S8zMjCYz++DUzdvmMnZnhpmNBQ2XMMFEGMIK6waYDF0QOohjzE0tZQYYUtAvj2/r9sVPPv/83py85zwn/w/vQ+TDPj6fmBJplx9RNKtEDL73hljXczKxHhfyL0+lVDMyGBIiWSqFyFOoUiPjDW01xi0b6kQbBotoY1uRYEWjCLrBehaZkEI9syrmS08nUitZzfwyMSVligN6CndIUNNtQcPDd2F1H4V1/TM0/noQNd80oHCnApq0wH6ZiEQej8cfZyRKVVGSXhkyVdqUD8P8ThiW3oLZ/R4acIJxEhXu91G48jYMv+xCyTkjsjI2zymkJE5n/xBaSSEpOv/OgiN6ZDjKoZl5GQVzu2F2vYO61Y9g+fMTVCweYHv3QHenFuoZM4wnc6CV8AbZDn5YOZVI9wogs+dAPJ4L7Q9m5M1aUfRgL0zO/Shb2M/qN7B1dge0P1YgbTwPz4/mIK8xGSoxbQ+2BvSIWySIH5QixaaD8nsjtLerkDvTgIK7ryGfkTfbCP1kNesVQTSsx5ZhCTRn5NApg29w+yJcSR2pCL8iQEKfHCLbC5CPGZA5YWJ7KrxkTpRBMW6EeCQbif0KhPcm4LkOIbINkY9j90W4o9qiEfwVh5gryYj/VorEQRWSh7VItWd7SR7RI2EoHfF9Emz5Wohn2qMQ/mUkssq5jcTdnJvfEo5NlwIQ1MYH1xkHeZ8OpbZKWOxWLyZbFZT9WYjoEiCYzfi2BiLsQhh0Jm49sY7vjDkWDTpB4F/kUP1dDQ7d+gBnJ8/iC8cFL82T5/DhxGHUDtWBa40CnSZEHYuEfhu3HF/i3/nsmxwCDvNQP1CP5ulmtP/cjqsPrmLktxFcd17HwMMBdNztwHnHebx67RUEfhoCwescdGretdhCyg+v9YP8tApNU03ovNcJu9OO6aVpzD2e8+JYduCm8ya673Xj1J1T0LRkQZjvjwwZVcUWES+0mFozjmpw+X4bxhbH4FhyYGFtAat/r3pxuV2YXZ7B2B/jaPu9Cy8dYm9ARL0qOYXGFrM8lZLAr9ZntPiiGfZHo1jDOv6rNfyF8aVb2HPcApnCb4plKFmlIvL4I0xEvtUUR/XUlnZAiiO9H2Ny/jYerbgYi3Dc/wmfdx1H6XYVRELq8mRN/SQ/T/1+NSzMVgokMxVszqN25YvRzqIyibvYLF3X58a4xGmbesQpVCpJpSA5y6/6SX7nA4lsvkQHfeh/yzPr8Xi8/wCp5s7jfgQAAA=="
    "Bad" = "H4sIAAAAAAAEAH2TXUiTURjHn5mmkOBQbH4gdqeCsAuR+dGFNynahRFMmwihbC+p1UCw6UXOSBBSmCII88bwphyE+BFTGGwI0zTjhSy1MLWXpA/FLWgRfezfc/bhR4nn5fe+h/c8/z/Pec5ziFT8qNXE4wLdiCU6z7NcRh36Q7wq3jx4LflcmFPGWaIrF4nq+4huTxLdYupsRJfKeS3xVCVdqyR6oBC5QfSe2WBWGZlxMHd3iC7XcOCZ/7V1N4nmOOY7843xM1+YDxGfV8wS85C52nbcQ6rOyvIiIQGIjwdiY4NQqX5z3A/mK/OZ2Y7k8jzq0RhVl5Y+2srJAdLTgeRkBa2tXmg0MnuFfbTaDZjNM6x5xryO5HF/J1wP6Xp1tYLcXCAvDxgY8EIMWVaQmSlDp1Pg8wVC/6xWsb8t5iXzFGLP2dndI3o9UFQEFBcD5eWug3jhEZ2Lr1brYc1H5i3zgml9XFhod9fXA5WVYSoqgKqqQ4+otqDAxfG/GB+jROppXdbp7O6mJsBgCFNbCzQ0KMf0Io+MDBlxccHI+Xxi3jBdy1qtbbyrCxAezc3gOh3P+eheUlNFH/xk9phN5h73lmQeGgqgvR3o7ARmZ9cPtAaDCzU1h3vp7/ciJuZPpDdEDSUzk2QyOX2Tk8D0tKixjPFxGS0tLj4LoKcHaGx0welchyTtQq8PIj9f9JfDR6RPEeefltZhdTgUzhFYWAA8HmBmBpiYAMbGgNFRYHgYGBwE+vqCMJnesf6O9Wj35uR0j0xNKdjcBNbWgJUVhPyWloD5eWBuDnC7gd5eBYmJbSMn3R6NpsNqsbiwuhqA3w/s7wN7e8DuLrC4GIDR6IJa3WE9SXvkLmSnpFhsZWV2t9H4xCdJTl9Jid2tVltsYu3faH8S3wy+SR4Vn6bgdPNQjIfjt+PD2r8Q4QshfgQAAA=="
    "Wait" = "H4sIAAAAAAAEAI3Ta0iTYRQH8LM0txxryyTEIkoNtTCie9GXohvZDUuCnJeUnEVEFFlomV00iTDddOYNDLXIlqvZTU0tdSZdjC5WRNkywSVWdnEu3Tr93+2tL33pGb+X8TznnOfsZYdIgo9KRVhTKMmTaAK+hYDKtUM4FZ5YOPORu/1dScVEO0qI4vKJ1LlyUms3y7bpG/2TKwaCMoz2oEyjfeKByq+yhAIzRWnVFJWrkMQiNrEICom2n3Xnx+QFeKm1pmmna3j9/Te858sgHx9xuuwdsPHGji4OzrnO0mhdLal1IaQpduenVBNpSgLk8frOWTcf85phB0cz837Ihhw4AHEQ7nDy7MbnrEgs7KI4fShpkH+iTj56Z5kh8NZTno6YxRABuyAdjsJuiIQlMAOCmjpZGqNroHi9SpJ+c61vqZl9cK8fzubAalCDBpJA6Ccc5oI/jEMfE3JusCRKG+2V3WLye2plCfYVQm1YACthg2gVLIJgUIEQ6/fQwrL4ArOy5FGfb6+daYR51C/UxlkAhME80UwIBB/wQAw5ENdnY2Vy5Tdl6QObotfB9B37Q+Bk9hR78RWNZfceCbl2+MHs3e9k5TGjXaE32xSWEaY+7H9CfRvzZNRfKr4zwTKYKtTFGX2GfuT3OFlx1DjknVVnVT4bZOrGPVbmTcPMGYgvgnOiYsiCLcNC38jvQX+dgyzfVzHgkVJtkF17zzILcwz6L0TcJaiFu9AM9eKeUCfxJ+7+wCy9+pY9E/RNdNCwnM60clj3CGtxboBWeAFd8A5eQhsYoQDmW51MadeYYnWRlGqUUerV8rD6t1yJ99Muxn+E7yK0zK/hPlTBwponTFu1Nfj/KOjQFaI002TKari3prWbW4YcjJ/xz0Lb3G4b5ghTByOvk2LzAl2zI+QfqSHKvD2Jss3nQ8of87F2Cz+wfuXeHz/ZCh3WAT7V/IrDMq/g3tzLFKMLcM2tMD9/8k82EOW0SSmjbgUlG6rGJ1+whqRetIUerhry3VPWR7H5Jsz2OorWjnHNusY9vxYp0R0PonQJ/fcSYoUcIfc3y0lIiH4EAAA="
 }


$form1 = New-Object System.Windows.Forms.form -Property @{ShowInTaskbar = $false; WindowState = "minimized"}
$form1.add_Load({CheckHost})
$iconOK = IconFromCompressedB64Bytes $CompressedIcons['Good']  
$iconWarn = IconFromCompressedB64Bytes $CompressedIcons['Bad'] 
$iconWait = IconFromCompressedB64Bytes $CompressedIcons['Wait'] 


$TimerHDD = New-Object System.Windows.Forms.Timer -Property @{Interval = $interval} 
$TimerHDD.add_Tick({CheckHost}) 
$TimerHDD.start()


$NotifyIcon= New-Object System.Windows.Forms.NotifyIcon -Property @{Visible = $True; Icon =  $iconWait; ContextMenu = (New-Object System.Windows.Forms.ContextMenu) }

$MenuItems.GetEnumerator() | %{ #iterate through the hashtable and add each name/value as a menu item label/click event handler
    $MenuItem = New-Object System.Windows.Forms.MenuItem -Property @{Text = $_.Name}
    $MenuItem.add_Click([scriptblock] $_.Value)
    $NotifyIcon.contextMenu.MenuItems.Add($MenuItem) | Out-Null
   } 

If(!$Host.Name.Contains("ISE")){ShowHideWindow $false}
[void][System.Windows.Forms.Application]::Run($form1)
