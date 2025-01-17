<#
Shows an ASCII Box menu: highlight with arrow up/down, PgUp/PgDn, 1..9, or first letter of option. 
┌─Select with spacebar─┐
│√first                │
│ second               │
│√third                │
└──────────────────────┘
Note that ReadKey (required for up/down arrows) doesn't work in ISE. There is no graceful downgrade for this script. 
#>
function Show-BoxMenu (
    [string[]] $Options, # the list of options to choose
    [bool[]] $Selected = (New-Object bool[] $Options.Length ), # initially selected state of options
    [int] $Highlighted = 0, # initially highlighted option
    [switch] $MultiSelect, # if specified space bar selects. Otherwise only the highlighted choice is returned
    [switch] $Expand, # if specified the title will be on its own row and the menu will be as wide as the console
    [string] $Border = '┌─┐│└┘├─┤▒', # '╔═╗║╚╝╟─╢╢' or '+-+|+++-++' also works 
    [string] $Title = $(if ($MultiSelect) { 'Select with spacebar' } else { 'Choose an option' }), #
    [string] $Marker = $(if ($MultiSelect) { '√ ' } else { '' }) # this string appears before a selected option
) {
    $Width = ($Options + (, $Title) | Measure-Object -Maximum -Property Length).Maximum + ($Marker.Length * 2) # number of chars between | and | 
    if ($Selected.Length -lt $Options.Length) { $Selected += (New-Object bool[] ($Options.Length - $Selected.Length)) } # pad $Selected to $Options.length
    $FirstShowingOption = 0 
    $ScrollThumbIndex = -1 
    $firstDraw = $true
    do {
        # == Redraw complete menu from CursorTop ==

        $MaxOptionsToShow = [Console]::WindowHeight - 3 - $(if ($Expand) { 2 } else { 0 }) # can only show as many options as unused screen rows - recalculate if resized 
        $menuHeight = [Math]::Min($Options.Length, $MaxOptionsToShow)
        $titleHeight = 2

        if ($Expand) { $Width = [Math]::Max( $Width, [Console]::WindowWidth - 2); $titleHeight =4 } # -2: leave space for border 
        if ($firstDraw) { 
            $firstDraw = $false 
        }
        else { 
            [Console]::CursorTop -= ($menuHeight + $titleHeight) 
        }
        $LeftPad = [Math]::Max($Marker.Length, [math]::Floor(($Width - $Title.Length) / 2)) # Left padding centers the title
        if ($Expand) {
            # Draw a title bar as wide as the console, on its own row
            $EOL = "`r`n" # if line extends to far right of console, an extra line break will be inserted - leave it off 
            Write-Host "$($Border[0])$([string]$Border[1] * ($Width))$($Border[2])$EOL" -NoNewline                    # ┌───────┐
            Write-Host "$($Border[3])$(((' ' * $LeftPad) + $Title).PadRight($Width,' '))$($Border[3])$EOL" -NoNewline # │ Title │
            Write-Host "$($Border[6])$([string]$Border[7] * ($Width))$($Border[8])$EOL" -NoNewline                    # ├───────┤
        }
        else {
            # Draw a narrow menu with $Title in the middle of the frame top 
            $EOL = "`r`n" #A CR/LF is necessary except when the line is [Console]::WindowWidth long
            Write-Host "$($Border[0])$((([string]$Border[1] * $LeftPad) + $Title).PadRight($Width,$Border[1]))$($Border[2])$EOL" -NoNewline # ┌─Title─┐
        }
        for ($i = $FirstShowingOption; $i -lt $menuHeight ; $i++) {
            # Draw as many menu options as will fit on the screen, starting from $TopOpt
            Write-Host "$($Border[3])$(if($Selected[$i]){$Marker}else{' ' * $Marker.length})" -NoNewLine 
            if ($i -eq $Highlighted) {
                # Print in reverse video
                Write-Host ([string]$Options[$i]).PadRight($Width - $marker.Length, ' ') -fore ([Console]::BackgroundColor) -back ([Console]::ForegroundColor) -NoNewline
            }
            else { 
                Write-Host ([string]$Options[$i]).PadRight($Width - $marker.Length, ' ') -NoNewline
            }
            Write-Host "$(if($ScrollThumbIndex -eq $i){$Border[9]}else{$Border[3]})$EOL" -NoNewline
        }
        $Status = if ($MultiSelect) { '{0}/{1}' -f ($Selected | ? { $_ -eq $true }).Count, $Options.Length }else { '' }  #Debug# -  'Th:' + $ScrollThumbIndex + ' F:' + $FirstShowingOption + ' L:' + $Options.Length  + ' M:' + $MaxOptionsToShow
        Write-Host "$($Border[4])$($Status.PadLeft($Width,$Border[1]))$($Border[5])$EOL" -NoNewline # bottom of frame    └───────2/20┘  
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq [ConsoleKey]::Spacebar) { $Selected[$Highlighted] = !$Selected[$Highlighted]; if ($Highlighted -lt $Options.Length - 1) { $Highlighted++ } }
        elseIf ($key.Key -eq [ConsoleKey]::UpArrow  ) { $Highlighted = [math]::Max($Highlighted - 1, 0); }
        elseIf ($key.Key -eq [ConsoleKey]::DownArrow) { $Highlighted = [math]::Min($Highlighted + 1, $Options.Length - 1); }
        elseIf ($key.Key -eq [ConsoleKey]::PageUp   ) { $Highlighted = [math]::Max($Highlighted - $MaxOptionsToShow, 0); $FirstShowingOption = [math]::Max($FirstShowingOption - $MaxOptionsToShow, 0) }
        elseIf ($key.Key -eq [ConsoleKey]::PageDown ) { $Highlighted = [math]::Min($Highlighted + $MaxOptionsToShow, $Options.Length - 1); $FirstShowingOption = [math]::Min($FirstShowingOption + $MaxOptionsToShow, $Options.Length - $MaxOptionsToShow) }
        elseIf ( (1..9 -join '').contains($key.KeyChar) -and $Options.Length -ge [int]::Parse($key.KeyChar)) { $Highlighted = [int]::Parse($key.KeyChar) - 1 } # change highlight with 1..9 
        else { 
            (([math]::min($Highlighted + 1, $Options.Length) .. $Options.Length) + (0 .. ($Highlighted - 1))) | % { # cycle from highlighted + 1 to end, and restart
                if ($Options[$_] -and $Options[$_].StartsWith($key.KeyChar) ) { $Highlighted = $_; Continue } # if letter matches first letter, highlight 
            }
        }
        if ($Highlighted -ge ($MaxOptionsToShow + $FirstShowingOption)) { $FirstShowingOption++ } # scroll if at bottom
        if ($Highlighted -lt $FirstShowingOption) { $FirstShowingOption-- } # scroll if at top 
        if ($MaxOptionsToShow -lt $Options.Length) { $ScrollThumbIndex = [math]::Min($Options.Length - 1, [math]::Ceiling(($FirstShowingOption / ($Options.Length - $MaxOptionsToShow)) * $MaxOptionsToShow) + $FirstShowingOption) }
    } While (! @([ConsoleKey]::Enter, [ConsoleKey]::Escape ).Contains($key.Key)) # stop if Enter or Esc
    if ($key.Key -eq [ConsoleKey]::Enter) {
        # Return the options that are selected
        if ($MultiSelect) {
            $Options | % { $i = 0 } { if ($Selected[$i++]) { $_ } } # TIL: foreach can have a 'begin' scriptbock that's executed only once
        }
        else {
            $Options[$Highlighted]
        }
    }
}
# Backward compatibility:
Function Show-SimpleMenu([array]$Options, [string]$Title = 'Choose an option', $border = '┌─┐│└┘', [int]$highlighted = 0) { Show-BoxMenu -Options $Options -Title $Title -Border $border -Highlighted $highlighted }
function Show-MultiSelectMenu ([array]$Options, [string]$Title = 'Select with spacebar', $border = '┌─┐│└┘',
    $highlighted = 0, $selected = (New-Object bool[] $Options.Length ) ) { Show-BoxMenu -Options $Options -Title $Title -Border $border -Highlighted $highlighted -Selected $selected -MultiSelect }

$lowASCIIBorder = '+-+|+++-+=' #are there any consoles or fonts where ASCII box borders won't show?
$doubleBorder = '╔═╗║╚╝╟─╢▒'
#Show-SimpleMenu @('first','second option','third','fourth','fifth') -border $doubleBorder
#Show-MultiSelectMenu @('first','second','third','fourth','fifth')  -selected @($true,$false,$true) 
#Show-MultiSelectMenu (Get-ChildItem -Path . -Directory | Select-Object -ExpandProperty FullName)  -selected @($true,$false,$true) 
Show-BoxMenu @('first','second, very long option','third','fourth','fifth') -border $doubleBorder -MultiSelect -Expand 
#Show-BoxMenu @('first', 'second option', 'third', 'fourth', 'fifth')  -selected @($true, $false, $true) -MultiSelect 
#Show-BoxMenu (Get-ChildItem -Path . -file | Select-Object -ExpandProperty FullName)  -selected @($true,$false,$true) -MultiSelect -Expand 
