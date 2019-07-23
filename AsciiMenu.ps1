<#
Shows an ASCII Box menu: highlight with up/down arrows or 1..9, or first letter of option. 
┌─Select with spacebar─┐
│√first                │
│ second               │
│√third                │
└──────────────────────┘
Note that ReadKey (required for up/down arrows) doesn't work in ISE. There is no graceful downgrade for this script. 
#>
function Show-BoxMenu (
        [string[]] $Options, # the list of options to choose
        [bool[]] $Selected = (New-Object bool[] $Options.Length ), #initially selected state of options
        [int] $Highlighted = 0, #initially highlighted option
        [switch] $MultiSelect, #If specified space bar selects. Otherwise only the highlighted choice is returned
        [switch] $Expand, #If specified the title will be on its own row and the menu will be as wide as the console
        [string] $Border = '┌─┐│└┘├─┤', # '╔═╗║╚╝╟─╢' or '+-+|+++-+' also works 
        [string] $Title = $(If($MultiSelect){'Select with spacebar'} Else {'Choose an option'}), #
        [string] $Marker = $(If($MultiSelect){'√ '} Else {''}) #this string appears before a selected option
  ){
    $Width = ($Options + (,$Title) | Measure-Object -Maximum -Property Length).Maximum + ($Marker.Length * 2) #number of chars between | and | 
    If($Expand) {$Width = [Math]::Max( $Width, [Console]::WindowWidth - 2) } # -2: leave space for border 
    If($Selected.Length -lt $Options.Length){$Selected += (New-Object bool[] ($Options.Length - $Selected.Length)) } #pad $Selected to $Options.length
    $MenuTop = [Console]::CursorTop
    Do{
        [Console]::CursorTop = $MenuTop
        $LeftPad = [Math]::Max($Marker.Length,[math]::Floor(($Width-$Title.Length)/2)) # Left padding centers the title
        If($Expand){ #draw a title bar as wide as the console, on its own row
            $EOL = "`r" #If line extends to far right of console, an extra line break will be inserted - leave it off 
            Write-Host "$($Border[0])$([string]$Border[1] * ($Width))$($Border[2])$EOL" -NoNewline                    # ┌───────┐
            Write-Host "$($Border[3])$(((' ' * $LeftPad) + $Title).PadRight($Width,' '))$($Border[3])$EOL" -NoNewline # │ Title │
            Write-Host "$($Border[6])$([string]$Border[7] * ($Width))$($Border[8])$EOL" -NoNewline                    # ├───────┤
        }Else{ #Draw a narrow menu with $Title in the middle of the frame top 
            $EOL = "`r`n" #A CR/LF is necessary except when the line is [Console]::WindowWidth long
            Write-Host "$($Border[0])$((([string]$Border[1] * $LeftPad) + $Title).PadRight($Width,$Border[1]))$($Border[2])$EOL" -NoNewline # ┌─Title─┐
        }
        for ($i = 0; $i -lt $Options.Length;$i++) {#draw the menu options
            Write-Host "$($Border[3])$(If($Selected[$i]){$Marker}else{' ' * $Marker.length})" -NoNewLine 
            if ($i -eq $Highlighted) { #print in reverse video
                Write-Host ([string]$Options[$i]).PadRight($Width - $marker.Length,' ') -fore ([Console]::BackgroundColor) -back ([Console]::ForegroundColor) -NoNewline
            } else { 
                Write-Host ([string]$Options[$i]).PadRight($Width - $marker.Length,' ') -NoNewline
            }
            Write-Host "$($Border[3])$EOL" -NoNewline
        }
        Write-Host "$($Border[4])$([string]$Border[1] * ($Width))$($Border[5])" # bottom of frame └──────┘
        $key = [Console]::ReadKey($true)
        If ($key.Key -eq [ConsoleKey]::Spacebar) {$Selected[$Highlighted] = !$Selected[$Highlighted]; If($Highlighted -lt $Options.Length - 1){$Highlighted++} }
        ElseIf ($key.Key -eq [ConsoleKey]::UpArrow -and $Highlighted -gt 0 ) {$Highlighted--}
        ElseIf ($key.Key -eq [ConsoleKey]::DownArrow -and $Highlighted -lt $Options.Length - 1) {$Highlighted++}
        ElseIf ( (1..9 -join '').contains($key.KeyChar) -and $Options.Length -ge [int]::Parse($key.KeyChar)) { $Highlighted = [int]::Parse($key.KeyChar) - 1 }#change highlight with 1..9 
        Else { 
            (([math]::min($Highlighted + 1, $Options.Length) .. $Options.Length) + (0 .. ($Highlighted - 1))) | %{ #cycle from highlighted + 1 to end, and restart
                If($Options[$_] -and $Options[$_].StartsWith($key.KeyChar) ){$Highlighted = $_; Continue} #if letter matches first letter, highlight 
            }
        }
    }While(! @([ConsoleKey]::Enter, [ConsoleKey]::Escape ).Contains($key.Key)) #stop if Enter or Esc
    If($key.Key-eq [ConsoleKey]::Enter){ #return the options that are selected
        If($MultiSelect){
            $Options | %{$i=0}{ If($Selected[$i++]){$_} } #TIL: foreach can have a 'begin' scriptbock that's executed only once
        }Else{
            $Options[$Highlighted]
        }
    }
}
#Backward compatibility:
Function Show-SimpleMenu([array]$Options, [string]$Title ='Choose an option',$border = '┌─┐│└┘',[int]$highlighted = 0){ Show-BoxMenu -Options $Options -Title $Title -Border $border -Highlighted $highlighted }
function Show-MultiSelectMenu ([array]$Options, [string]$Title ='Select with spacebar', $border = '┌─┐│└┘',
            $highlighted = 0, $selected = (New-Object bool[] $Options.Length ) ){ Show-BoxMenu -Options $Options -Title $Title -Border $border -Highlighted $highlighted -Selected $selected -MultiSelect}

$lowASCIIBorder = '+-+|+++-+' #are there any consoles or fonts where ASCII box borders won't show?
$doubleBorder =   '╔═╗║╚╝╟─╢'
Show-SimpleMenu @('first','second option','third','fourth','fifth') -border $doubleBorder
Show-MultiSelectMenu @('first','second','third','fourth','fifth')  -selected @($true,$false,$true) 
Show-MultiSelectMenu (Get-ChildItem -Path . -Directory | Select-Object -ExpandProperty FullName)  -selected @($true,$false,$true) 
Show-BoxMenu @('first','second, very long option','third','fourth','fifth') -border $doubleBorder -Expand 
Show-BoxMenu @('first','second option','third','fourth','fifth')  -selected @($true,$false,$true) -MultiSelect 
Show-BoxMenu (Get-ChildItem -Path . -Directory | Select-Object -ExpandProperty FullName)  -selected @($true,$false,$true) -MultiSelect -Expand
