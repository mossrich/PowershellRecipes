<# Shows an ascii menu: highlight with up/down arrows and choose with [Enter]. 
┌Choose an option┐
│first           │
│second option   │
│third           │
└────────────────┘
#>
function Show-SimpleMenu ([array]$MenuOptions, [string]$Title ='Choose an option'){
    $maxLength = ($MenuOptions | Measure-Object -Maximum -Property Length).Maximum #get longest string length
    If($maxLength -lt $Title.Length){$maxLength = $Title.Length}
    $highlighted = 0 
    $MenuTop = [Console]::CursorTop
    Do{
        [Console]::CursorTop = $MenuTop
        Write-Host "┌$($Title.PadRight($maxLength,'─'))┐" 
        for ($i = 0; $i -lt $MenuOptions.Length;$i++) {
            Write-Host "│" -NoNewLine
            if ($i -eq $highlighted) {
                Write-Host "$(([string]$MenuOptions[$i]).PadRight($maxLength,' '))" -fore $host.UI.RawUI.BackgroundColor -back $host.UI.RawUI.ForegroundColor -NoNewline
            } else {
                Write-Host "$(([string]$MenuOptions[$i]).PadRight($maxLength,' '))" -fore $host.UI.RawUI.ForegroundColor -back $host.UI.RawUI.BackgroundColor -NoNewline
            }
            Write-Host "│"
        }
        Write-Host "└$('─' * ($maxLength))┘"
        $keycode = [Console]::ReadKey($true)#$keyCode = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown")
        If ($keyCode.Key -eq [ConsoleKey]::UpArrow -and $highlighted -gt 0 ) {$highlighted--}
        If ($keycode.Key -eq [ConsoleKey]::DownArrow -and $highlighted -lt $MenuOptions.Length - 1) {$highlighted++}
    }While($keyCode.Key -ne [ConsoleKey]::Enter -and $keycode.Key -ne [ConsoleKey]::Escape )
    If($keyCode.Key -eq [ConsoleKey]::Enter){ $MenuOptions[$highlighted] }
}

<#
Shows an ascii menu: highlight with up/down arrows, select with space bar and choose with [Enter]. 
┌─Select with spacebar┐
│√first               │
│ second option       │
│√third               │
└─────────────────────┘
#>

function Show-MultiSelectMenu ([array]$MenuOptions, [string]$Title ='Select with spacebar'){
    $maxLength = ($MenuOptions | Measure-Object -Maximum -Property Length).Maximum #get longest string length
    If($maxLength -lt $Title.Length){$maxLength = $Title.Length}
    $highlighted = 0 
    $selected = New-Object bool[] $MenuOptions.Length #defaults to $false
    $MenuTop = [Console]::CursorTop
    Do{
        [Console]::CursorTop = $MenuTop
        Write-Host "┌─$($Title.PadRight($maxLength,'─'))┐" 
        for ($i = 0; $i -lt $MenuOptions.Length;$i++) {#draw the menu
            If($selected[$i]){ Write-Host "│√" -NoNewLine }else{ Write-Host "│ " -NoNewLine }
            if ($i -eq $highlighted) {
                Write-Host "$(([string]$MenuOptions[$i]).PadRight($maxLength,' '))" -fore $host.UI.RawUI.BackgroundColor -back $host.UI.RawUI.ForegroundColor -NoNewline
            } else {
                Write-Host "$(([string]$MenuOptions[$i]).PadRight($maxLength,' '))" -fore $host.UI.RawUI.ForegroundColor -back $host.UI.RawUI.BackgroundColor -NoNewline
            }
            Write-Host "│"
        }
        Write-Host "└─$('─' * ($maxLength))┘"
        $keycode = [Console]::ReadKey($true)#$keyCode = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown")
        If ($keyCode.Key -eq [ConsoleKey]::Spacebar) {$selected[$highlighted] = !$selected[$highlighted] }
        If ($keyCode.Key -eq [ConsoleKey]::UpArrow -and $highlighted -gt 0 ) {$highlighted--}
        If ($keycode.Key -eq [ConsoleKey]::DownArrow -and $highlighted -lt $MenuOptions.Length) {$highlighted++}
    }While(! @([ConsoleKey]::Enter, [ConsoleKey]::Escape ).Contains($keycode.Key)) #stop if Enter or Esc
    If($keyCode.Key -eq [ConsoleKey]::Enter){ #return the menu options that are selected
        $MenuOptions | %{$i=0}{#TIL: foreach can have a 'begin' scriptbock that's executed only once
            If($selected[$i]){$_}
            $i++
        }
    }
}

Show-SimpleMenu @('first','second option','third')

Show-MultiSelectMenu @('first','second option','third')
