param(
    #[Parameter(Mandatory=$true)] 
    [int]$SecondsToCountDown = 5
)
#start-sleep (10); write-host ("`a"*4)
for([int] $i=$SecondsToCountDown;$i -gt 0;$i--){ Write-Progress "Starting in a few seconds" -PercentComplete ((($SecondsToCountDown - $i)/$SecondsToCountDown) * 100)   ;Start-Sleep 1; }


#terse version
$secs=5; $secs..0|%{Write-Progress "Starting in $_ seconds" -PercentComplete ((($secs - $_)/$secs) * 100); Start-Sleep 1}

$input = $(
      Add-Type -AssemblyName Microsoft.VisualBasic
      [Microsoft.VisualBasic.Interaction]::InputBox('Enter your city','Titlebar Text', 'Default new york')
     )
$inputAdd
