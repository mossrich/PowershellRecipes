<# Shows an ascii menu: highlight with up/down arrows or 1..9, or first letter of option and choose with [Enter]. 
┌Choose an option┐
│first           │
│second option   │
│third           │
└────────────────┘
Note that ReadKey (required for up/down arrows) doesn't work in ISE. There is no graceful downgrade for this script. 
#>
function Show-SimpleMenu ([array]$Options, [string]$Title ='Choose an option',$border = '┌─┐│└┘',[int]$highlighted = 0){
    $maxLength = ($Options + (,$Title) | Measure -Max -Prop Length).Maximum #number of chars between | and | 
    $MenuTop = [Console]::CursorTop
    Do{
        [Console]::CursorTop = $MenuTop
        $LeftPad = [string]$border[1] * [Math]::Max(0,[math]::Floor(($maxlength-$Title.Length)/2)) #gets the left padding required to center the title
        Write-Host "$($border[0])$(($LeftPad + $Title).PadRight($maxLength,$border[1]))$($border[2])" # #top border: ┌Title─┐   left-aligned: Write-Host "$($border[0])$($Title.PadRight($maxLength,$border[1]))$($border[2])" 
        for ($i = 0; $i -lt $Options.Length;$i++) {
            Write-Host $border[3] -NoNewLine
            if ($i -eq $highlighted) {
                Write-Host ([string]$Options[$i]).PadRight($maxLength,' ') -fore ([Console]::BackgroundColor) -back ([Console]::ForegroundColor) -NoNewline
            } else {
                Write-Host ([string]$Options[$i]).PadRight($maxLength,' ') -NoNewline
            }
            Write-Host $border[3]
        }
        Write-Host "$($border[4])$([string]$border[1] * $maxLength)$($border[5])" #bottom border:└─┘
        $key = [Console]::ReadKey($true)
        If ($key.Key -eq [ConsoleKey]::UpArrow -and $highlighted -gt 0 ) {$highlighted--}
        ElseIf ($key.Key -eq [ConsoleKey]::DownArrow -and $highlighted -lt $Options.Length - 1) {$highlighted++}
        ElseIf ( (1..9 -join '').contains($key.KeyChar) -and $Options.Length -ge [int]::Parse($key.KeyChar)) { $highlighted = [int]::Parse($key.KeyChar) - 1 }#change highlight with 1..9 
        Else { 
            (([math]::min($highlighted + 1, $Options.Length) .. $Options.Length) + (0 .. ($highlighted - 1))) | %{ #cycle from highlighted + 1 to end, and restart
                If($Options[$_] -and $Options[$_].StartsWith($key.KeyChar) ){$highlighted = $_; Continue} #if letter matches first letter, highlight 
            }
        }
    }While( -not ([ConsoleKey]::Enter,[ConsoleKey]::Escape).Contains($key.Key) )
    If($Key.Key -eq [ConsoleKey]::Enter){ $Options[$highlighted] }
}

<#
Shows an ascii menu: highlight with up/down arrows or 1..9, or first letter of option. Select with space bar and choose with [Enter]. 
┌─Select with spacebar─┐
│√first                │
│ second               │
│√third                │
└──────────────────────┘
#>
function Show-MultiSelectMenu ([array]$Options, [string]$Title ='Select with spacebar', $border = '┌─┐│└┘',
            $highlighted = 0, $selected = (New-Object bool[] $Options.Length ) ){
    $maxLength = ($Options + (,$Title) | Measure -Max -Prop Length).Maximum + 1 #get longest string length, +padding for √ 
    If($Selected.Length -lt $Options.Length){$Selected += (New-Object bool[] ($Options.Length - $Selected.Length)) } #pad $Selected to $Options.length
    $MenuTop = [Console]::CursorTop
    Do{
        [Console]::CursorTop = $MenuTop
        $LeftPad = [string]$border[1] * [Math]::Max(1,[math]::Floor(($maxlength-$Title.Length)/2)) #Centered, at least one border ─
        Write-Host "$($border[0])$(($LeftPad + $Title).PadRight($maxLength + 1,$border[1]))$($border[2])" #top border: ┌─Title─┐
        for ($i = 0; $i -lt $Options.Length;$i++) {#draw the menu
            Write-Host "$($border[3])$(If($selected[$i]){"√"}else{" "})" -NoNewLine
            if ($i -eq $highlighted) {
                Write-Host ([string]$Options[$i]).PadRight($maxLength,' ') -fore ([Console]::BackgroundColor) -back ([Console]::ForegroundColor) -NoNewline
            } else {
                Write-Host ([string]$Options[$i]).PadRight($maxLength,' ') -NoNewline
            }
            Write-Host $border[3]
        }
        Write-Host "$($border[4])$($border[1])$([string]$border[1] * ($maxLength))$($border[5])"
        $key = [Console]::ReadKey($true)
        If ($key.Key -eq [ConsoleKey]::Spacebar) {$Selected[$Highlighted] = !$Selected[$Highlighted]; If($Highlighted -lt $Options.Length - 1){$Highlighted++} }
        ElseIf ($key.Key -eq [ConsoleKey]::UpArrow -and $highlighted -gt 0 ) {$highlighted--}
        ElseIf ($key.Key -eq [ConsoleKey]::DownArrow -and $highlighted -lt $Options.Length - 1) {$highlighted++}
        ElseIf ( (1..9 -join '').contains($key.KeyChar) -and $Options.Length -ge [int]::Parse($key.KeyChar)) { $highlighted = [int]::Parse($key.KeyChar) - 1 }#change highlight with 1..9 
        Else { 
            (([math]::min($highlighted + 1, $Options.Length) .. $Options.Length) + (0 .. ($highlighted - 1))) | %{ #cycle from highlighted + 1 to end, and restart
                If($Options[$_] -and $Options[$_].StartsWith($key.KeyChar) ){$highlighted = $_; Continue} #if letter matches first letter, highlight 
            }
        }
    }While(! @([ConsoleKey]::Enter, [ConsoleKey]::Escape ).Contains($key.Key)) #stop if Enter or Esc
    If($key.Key-eq [ConsoleKey]::Enter){ #return the menu options that are selected
        $Options | %{$i=0}{ If($selected[$i++]){$_} } #TIL: foreach can have a 'begin' scriptbock that's executed only once
    }
}
$lowASCIIBorder = '+-+|++' #are there any consoles or fonts where ASCII box borders won't show?
$doubleBorder = '╔═╗║╚╝'
Show-SimpleMenu @('first','second option','third','fourth','fifth') -border $doubleBorder
Show-MultiSelectMenu @('first','second','third','fourth','fifth')  -selected @($true,$false,$true) 
Show-MultiSelectMenu (Get-ChildItem -Path . -Directory | Select-Object -ExpandProperty FullName)  -selected @($true,$false,$true) 
