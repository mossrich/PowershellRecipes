#when running, checks the last user input and beeps if it's 30 seconds until the screen saver lockout engages

if (-not ([Management.Automation.PSTypeName]'user32.LastInputInfo').Type){
    Add-Type -namespace 'user32' -name 'LastInputInfo' -member @'
    [DllImport("user32.dll")] 
    [StructLayout(LayoutKind.Sequential)] public struct LASTINPUTINFO {public uint cbSize;public int dwTime;}
    public static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);
    public static int LastInputTicks{get{
        LASTINPUTINFO lii = new LASTINPUTINFO();
        lii.cbSize = (uint)Marshal.SizeOf(typeof(LASTINPUTINFO));
        GetLastInputInfo(ref lii);
        return lii.dwTime;
    }}
'@
}

$timeout = New-TimeSpan -Minutes 10 #should be same as screen saver lockout 
$warningTime = New-TimeSpan -Seconds 30 #beep before lockout. Also used for polling frequency to wake this script
While ($true){
    $idleTime = New-TimeSpan -Seconds (([System.Environment]::TickCount - [user32.LastInputInfo]::LastInputTicks) / 1000)#TickCount = milliseconds since boot. LastInputTicks = milliseconds of last key/mouse activity. 
    Write-Host ([string][datetime]::Now +  " Idle for " + $idleTime.TotalSeconds)
    if($idleTime -gt $timeout){#timed out - poll again once unlocked
        Write-Host ([string][datetime]::Now +  ' Timed out - Idle time ' + $idleTime + ' sleeping for ' + $timeout.TotalSeconds) 
        Start-Sleep -Seconds $timeout.TotalSeconds #poll again after timed out - user might unlock and reset the timer
    }Elseif($idleTime -lt ($timeout - $warningTime)){#sleep until we're nearing the warning time 
        $sleepSecs = [math]::max((($timeout - $warningTime) - $idleTime).TotalSeconds,1) #at least a second to prevent rapid polling 
        Write-Host ([string][datetime]::Now +  ' Sleeping for ' + $sleepSecs + ' seconds')
        Start-Sleep -Seconds $sleepSecs
    }Else{
        Write-Host ([string][datetime]::Now + ' Cease to be idle!')
        [console]::Beep(500,200)
        [console]::Beep(700,200)
        Start-Sleep -Seconds $warningTime.TotalSeconds
    }
}
