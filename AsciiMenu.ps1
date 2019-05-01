<# Shows an ascii menu: highlight with up/down arrows or 1..9, or first letter of option and choose with [Enter]. 
┌Choose an option┐
│first           │
│second option   │
│third           │
└────────────────┘
#>
function Show-SimpleMenu ([array]$Options, [string]$Title ='Choose an option',$border = '┌─┐│└┘',$highlighted = 0){
    $maxLength = ($Options | Measure-Object -Maximum -Property Length).Maximum #get longest string length
    If($maxLength -lt $Title.Length){$maxLength = $Title.Length}
    $MenuTop = [Console]::CursorTop
    Do{
        [Console]::CursorTop = $MenuTop
        #Left-align title: Write-Host "$($border[0])$($Title.PadRight($maxLength,$border[1]))$($border[2])" #top border: ┌Title─┐
        $LeftPad = [string]$border[1] * [Math]::Max(0,[math]::Floor(($maxlength-$Title.Length)/2)) 
        Write-Host "$($border[0])$(($LeftPad + $Title).PadRight($maxLength,$border[1]))$($border[2])"
        for ($i = 0; $i -lt $Options.Length;$i++) {
            Write-Host $border[3] -NoNewLine
            if ($i -eq $highlighted) {
                Write-Host ([string]$Options[$i]).PadRight($maxLength,' ') -fore ([Console]::BackgroundColor) -back ([Console]::ForegroundColor) -NoNewline
            } else {
                Write-Host ([string]$Options[$i]).PadRight($maxLength,' ') -fore ([Console]::ForegroundColor) -back ([Console]::BackgroundColor) -NoNewline
            }
            Write-Host $border[3] 
        }
        Write-Host "$($border[4])$([string]$border[1] * $maxLength)$($border[5])" #bottom border:└─┘
        $key = [Console]::ReadKey($true).Key
        If ($key -eq [ConsoleKey]::UpArrow -and $highlighted -gt 0 ) {$highlighted--}
        If ($key -eq [ConsoleKey]::DownArrow -and $highlighted -lt $Options.Length - 1) {$highlighted++}
        If ((1..9).Contains($key.value__ - [ConsoleKey]::NumPad0.value__) -and #change highlight with 1..9 
            ($Options.Length + [ConsoleKey]::NumPad1.value__ -gt $key.value__)) { 
                $highlighted = $key.value__ - [ConsoleKey]::NumPad1.value__ 
        }
    }While($key -ne [ConsoleKey]::Enter -and $key -ne [ConsoleKey]::Escape )
    If($key -eq [ConsoleKey]::Enter){ $Options[$highlighted] }
}

<#
Shows an ascii menu: highlight with up/down arrows, select with space bar and choose with [Enter]. 
┌─Select with spacebar─┐
│√first                │
│ second option        │
│√third                │
└──────────────────────┘
#>
function Show-MultiSelectMenu ([array]$Options, [string]$Title ='Select with spacebar', $border = '┌─┐│└┘',
            $highlighted = 0, $selected = (New-Object bool[] $Options.Length ) ){
    $maxLength = ($Options | Measure-Object -Maximum -Property Length).Maximum + 1 #get longest string length, +padding for √ 
    If($maxLength -lt $Title.Length + 2){$maxLength = $Title.Length + 1}
    $MenuTop = [Console]::CursorTop
    Do{
        [Console]::CursorTop = $MenuTop
        $LeftPad = [string]$border[1] * [Math]::Max(1,[math]::Floor(($maxlength-$Title.Length)/2)) #Centered, at least one border ─
        Write-Host "$($border[0])$(($LeftPad + $Title).PadRight($maxLength + 1,$border[1]))$($border[2])" #top border: ┌─Title─┐
        for ($i = 0; $i -lt $Options.Length;$i++) {#draw the menu
            If($selected[$i]){ Write-Host "$($border[3])√" -NoNewLine }else{ Write-Host "$($border[3]) " -NoNewLine }
            if ($i -eq $highlighted) {
                Write-Host ([string]$Options[$i]).PadRight($maxLength,' ') -fore ([Console]::BackgroundColor) -back ([Console]::ForegroundColor) -NoNewline
            } else {
                Write-Host ([string]$Options[$i]).PadRight($maxLength,' ') -fore ([Console]::ForegroundColor) -back ([Console]::BackgroundColor) -NoNewline
            }
            Write-Host $border[3]
        }
        Write-Host "$($border[4])$($border[1])$([string]$border[1] * ($maxLength))$($border[5])"
        $key = [Console]::ReadKey($true).Key 
        If ($key -eq [ConsoleKey]::Spacebar) {$selected[$highlighted] = !$selected[$highlighted] }
        If ($key -eq [ConsoleKey]::UpArrow -and $highlighted -gt 0 ) {$highlighted--}
        If ($key -eq [ConsoleKey]::DownArrow -and $highlighted -lt $Options.Length - 1) {$highlighted++}
        If ((1..9).Contains($key.value__ - [ConsoleKey]::NumPad0.value__) -and 
            ($Options.Length + [ConsoleKey]::NumPad1.value__ -gt $key.value__)) { 
                $highlighted = $key.value__ - [ConsoleKey]::NumPad1.value__ #change highlight with 1..9 
        }
    }While(! @([ConsoleKey]::Enter, [ConsoleKey]::Escape ).Contains($key)) #stop if Enter or Esc
    If($key -eq [ConsoleKey]::Enter){ #return the menu options that are selected
        $Options | %{$i=0}{ If($selected[$i++]){$_} } #TIL: foreach can have a 'begin' scriptbock that's executed only once
    }
}
$doubleBorder = '╔═╗║╚╝'
Show-SimpleMenu @('first','second longer option','third') -border $doubleBorder
Show-MultiSelectMenu @('first','second','third')  -selected @($true,$false,$true) #if $selected is shorter than $options, throws error selecting the last
