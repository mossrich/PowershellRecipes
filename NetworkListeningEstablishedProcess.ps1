#shows processes & paths with listening ports and established remote connections

<#from https://stackoverflow.com/questions/67217348/find-kill-64-bit-processes-by-path-in-32-bit-powershell  #>
$pinvoke = Add-Type -PassThru -Name pinvoke -MemberDefinition @'
    [DllImport("kernel32.dll", SetLastError=true)] private static extern bool CloseHandle(IntPtr hObject);
    [DllImport("kernel32.dll", SetLastError = true)] private static extern IntPtr OpenProcess(uint processAccess,bool bInheritHandle,int processId);
    [DllImport("kernel32.dll", SetLastError=true)]
    private static extern bool QueryFullProcessImageName(
        IntPtr hProcess,
        int dwFlags,
        System.Text.StringBuilder lpExeName,
        ref int lpdwSize);
    private const int QueryLimitedInformation = 0x00001000;

    public static string GetProcessPath(int pid){
        var size = 1024;
        var sb = new System.Text.StringBuilder(size);
        var handle = OpenProcess(QueryLimitedInformation, false, pid);
        if (handle == IntPtr.Zero) return null;
        var success = QueryFullProcessImageName(handle, 0, sb, ref size);
        CloseHandle(handle);
        if (!success) return null;
        return sb.ToString();
    }
'@

$connections = Get-NetTCPConnection 
Get-Process  | 
  Select Id,ProcessName, 
    @{n='NonPagedMem';e={[int]($_.NPM/1024)}},
    @{n='WorkingSet';e={[int64]($_.WorkingSet64/1024)}},
    @{n='VirtualMem';e={[int]($_.VM/1MB)}},
    @{n='BinaryPath';e={$pinvoke::GetProcessPath($_.Id)}},
    @@{n="FileName";e={$_.FileName}}, # requires -FileVersionInfo parameter to Get-Process
    @{n='ListeningPorts';e={foreach($c in $connections){if($c.OwningProcess -eq $_.Id -and $c.State -eq 'Listen'){$c.LocalPort}} }},
    @{n='EstablishedRemoteAddess';e={foreach($c in $connections){if($c.OwningProcess -eq $_.Id -and $c.State -eq 'Established'){$c.RemoteAddress}} }},
    @{n='EstablishedPort';e={foreach($c in $connections){if($c.OwningProcess -eq $_.Id -and $c.State -eq 'Established'){$c.RemotePort}} }} |
  Out-GridView

#Get-NetTCPConnection | Out-GridView

#https://azega.org/list-open-ports-using-powershell/
Get-NetTCPConnection | 
Select-Object LocalAddress,LocalPort,RemoteAddress,RemotePort,State,
@{Name="Process";Expression={(Get-Process -Id $_.OwningProcess).ProcessName}},
@{Name="FileName";Expression={(Get-Process -Id $_.OwningProcess -FileVersionInfo).FileName}} | 
Out-GridView
