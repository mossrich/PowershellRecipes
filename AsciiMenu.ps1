<# Shows an ascii menu: highlight with up/down arrows or 1..9, or first letter of option and choose with [Enter]. 
┌Choose an option┐
│first           │
│second option   │
│third           │
└────────────────┘
#>
function Show-SimpleMenu ([array]$MenuOptions, [string]$Title ='Choose an option',$border = '┌─┐│└┘'){
    $maxLength = ($MenuOptions | Measure-Object -Maximum -Property Length).Maximum #get longest string length
    If($maxLength -lt $Title.Length){$maxLength = $Title.Length}
    $highlighted = 0 
    $MenuTop = [Console]::CursorTop
    Do{
        [Console]::CursorTop = $MenuTop
        Write-Host "$($border[0])$($Title.PadRight($maxLength,$border[1]))$($border[2])" #top border: ┌Title─┐
        for ($i = 0; $i -lt $MenuOptions.Length;$i++) {
            Write-Host $border[3] -NoNewLine
            if ($i -eq $highlighted) {
                Write-Host ([string]$MenuOptions[$i]).PadRight($maxLength,' ') -fore ([Console]::BackgroundColor) -back ([Console]::ForegroundColor) -NoNewline
            } else {
                Write-Host ([string]$MenuOptions[$i]).PadRight($maxLength,' ') -fore ([Console]::ForegroundColor) -back ([Console]::BackgroundColor) -NoNewline
            }
            Write-Host $border[3] 
        }
        Write-Host "$($border[4])$([string]$border[1] * $maxLength)$($border[5])" #bottom border:└─┘
        $key = [Console]::ReadKey($true).Key
        If ($key -eq [ConsoleKey]::UpArrow -and $highlighted -gt 0 ) {$highlighted--}
        If ($key -eq [ConsoleKey]::DownArrow -and $highlighted -lt $MenuOptions.Length - 1) {$highlighted++}
        If ((1..9).Contains($key.value__ - [ConsoleKey]::NumPad0.value__) -and #change highlight with 1..9 
            ($MenuOptions.Length + [ConsoleKey]::NumPad1.value__ -gt $key.value__)) { 
                $highlighted = $key.value__ - [ConsoleKey]::NumPad1.value__ 
        }
    }While($key -ne [ConsoleKey]::Enter -and $key -ne [ConsoleKey]::Escape )
    If($key -eq [ConsoleKey]::Enter){ $MenuOptions[$highlighted] }
}

<#
Shows an ascii menu: highlight with up/down arrows, select with space bar and choose with [Enter]. 
┌─Select with spacebar┐
│√first               │
│ second option       │
│√third               │
└─────────────────────┘
#>
function Show-MultiSelectMenu ([array]$MenuOptions, [string]$Title ='Select with spacebar', $border = '┌─┐│└┘'){
    $maxLength = ($MenuOptions | Measure-Object -Maximum -Property Length).Maximum + 1 #get longest string length, +1 padding
    If($maxLength -lt $Title.Length){$maxLength = $Title.Length + 1}
    $highlighted = 0 
    $selected = New-Object bool[] $MenuOptions.Length #defaults to $false
    $MenuTop = [Console]::CursorTop
    Do{
        [Console]::CursorTop = $MenuTop
        Write-Host "$($border[0])$($border[1])$($Title.PadRight($maxLength,$border[1]))$($border[2])" #top border: ┌─Title─┐
        for ($i = 0; $i -lt $MenuOptions.Length;$i++) {#draw the menu
            If($selected[$i]){ Write-Host "$($border[3])√" -NoNewLine }else{ Write-Host "$($border[3]) " -NoNewLine }
            if ($i -eq $highlighted) {
                Write-Host ([string]$MenuOptions[$i]).PadRight($maxLength,' ') -fore ([Console]::BackgroundColor) -back ([Console]::ForegroundColor) -NoNewline
            } else {
                Write-Host ([string]$MenuOptions[$i]).PadRight($maxLength,' ') -fore ([Console]::ForegroundColor) -back ([Console]::BackgroundColor) -NoNewline
            }
            Write-Host $border[3]
        }
        Write-Host "$($border[4])$($border[1])$([string]$border[1] * ($maxLength))$($border[5])"
        $key = [Console]::ReadKey($true).Key 
        If ($key -eq [ConsoleKey]::Spacebar) {$selected[$highlighted] = !$selected[$highlighted] }
        If ($key -eq [ConsoleKey]::UpArrow -and $highlighted -gt 0 ) {$highlighted--}
        If ($key -eq [ConsoleKey]::DownArrow -and $highlighted -lt $MenuOptions.Length - 1) {$highlighted++}
        If ((1..9).Contains($key.value__ - [ConsoleKey]::NumPad0.value__) -and 
            ($MenuOptions.Length + [ConsoleKey]::NumPad1.value__ -gt $key.value__)) { 
                $highlighted = $key.value__ - [ConsoleKey]::NumPad1.value__ #change highlight with 1..9 
        }
    }While(! @([ConsoleKey]::Enter, [ConsoleKey]::Escape ).Contains($key)) #stop if Enter or Esc
    If($key -eq [ConsoleKey]::Enter){ #return the menu options that are selected
        $MenuOptions | %{$i=0}{#TIL: foreach can have a 'begin' scriptbock that's executed only once
            If($selected[$i]){$_}
            $i++
        }
    }
}

Show-SimpleMenu @('first','second option','third') #-border '╔═╗║╚╝'
Show-MultiSelectMenu @('first','second, much longer option','third') #-border '╔═╗║╚╝'
