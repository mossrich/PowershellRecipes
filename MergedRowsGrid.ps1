Param([string] $BaseFolder = "c:\users\$($env:UserName)\Favorites")
@('System.Windows.Forms','System.Drawing') | %{ [reflection.assembly]::LoadWithPartialName($_) | Out-Null}
$Script:CurrentFolder = $BaseFolder
$Script:LastFolder = ""

Function FillDatagrid(){
    If($Script:CurrentFolder -ne $Script:LastFolder){
        $Script:CurrentFiles = (Get-ChildItem $Script:CurrentFolder -Recurse -File | 
            Select @{n='Folder';e={$_.DirectoryName -replace [regex]::Escape($BaseFolder), "."}}, Name, LastWriteTime, Length | Sort Folder, Name) 
        $Script:LastFolder = $Script:CurrentFolder 
    }
    $Script:dataGridView.DataSource = [System.collections.ArrayList] ($Script:CurrentFiles);
    $Script:dataGridView.Refresh()
}

[int]$FormWidth = 1200; [int]$FormHeight = 600 #TODO: store these in registry on form-resize event and read here
$Script:form = New-Object System.Windows.Forms.Form -Property @{ Size = "$FormWidth,$FormHeight";Text = $BaseFolder}
$Script:timer = New-Object System.Windows.Forms.Timer -Property @{Interval = 1000 #wait 1000 ms after updating folder name before refresh grid
    add_Tick = {$Script:timer.Stop(); FillDatagrid } #stop ticking and filll datagrid - we only want one event per update
} 
$txtFolder =  New-Object System.Windows.Forms.TextBox -Property @{Name="txtFolder"; Text=$BaseFolder; Anchor="Top,Left,Right" #TODO: Multi-line https://stackoverflow.com/questions/73110/how-can-i-show-scrollbars-on-a-system-windows-forms-textbox-only-when-the-text-d
    Size = New-Object System.Drawing.Size(($FormWidth / 2),$txtFolder.Size.Height)
    add_TextChanged= { Param([System.Windows.Forms.TextBox]$sender, $e)
        $Script:timer.Stop() #stop any pending update - the text box is changed
        If($sender.Text.TrimEnd('\') -ne $Script:CurrentFolder.TrimEnd('\')){ #adding a \ to the end of a folder name is still the same folder on disk, but resolves differently
            If(-not (Test-Path $sender.Text)){$sender.ForeColor = "Red";return} #set text red and abort
            $sender.ForeColor = "Black" #Write-Host "Starting Timer BaseFolder: $BaseFolder Text: $($sender.Text)" 
            $Script:CurrentFolder = $sender.Text.TrimEnd('\')
            $Script:timer.Start() #update grid after tick - prevents too many updates for valid folders
        }
    }
}

$Script:dataGridView = New-Object System.Windows.Forms.DataGridView -Property @{ #need a handle to this at the script level so we don't have to look it up from form.controls['DG']
    Name = 'DG'; Anchor = 'Left,Right,Top,Bottom'; AutoSizeColumnsMode = 'AllCells';AutoSizeRowsMode = 'None' #[System.Windows.Forms.DataGridViewAutoSizeColumnMode]::AllCells - doesn't work
    Size = New-Object System.Drawing.Size(($FormWidth - 30),($FormHeight - $txtFolder.Size.Height - 50)) 
    Location = New-Object System.Drawing.Point(0,($txtFolder.Size.Height))
    #Merge Rows on Cell Paint event
    add_CellPainting = {Param([Windows.Forms.DataGridView] $sender, [Windows.Forms.DataGridViewCellPaintingEventArgs] $e)  #merge rows
        $e.AdvancedBorderStyle.Bottom = [Windows.Forms.DataGridViewAdvancedCellBorderStyle]::None #TODO: set cell template with these borders - need to create an inherited dgview
        Try{
            If(($e.rowIndex -le 0 ) -or ($e.columnIndex -lt 0)){ return }
            $thisCell = $sender[$e.columnIndex,$e.rowIndex]
            $prevCell = $sender[$e.columnIndex,($e.rowIndex - 1)]
            If (($thisCell.Value -eq $prevCell.Value  -and $prevCell.Displayed)){ #hide value if same as prev, and prev is on screen
                $e.AdvancedBorderStyle.Top = [System.Windows.Forms.DataGridViewAdvancedCellBorderStyle]::None
                $sender[$e.columnIndex,$e.rowIndex].Style.ForeColor = [System.Drawing.Color]::Transparent
            }Else{
                $e.AdvancedBorderStyle.Top = $sender.AdvancedCellBorderStyle.Top
                $sender[$e.columnIndex,$e.rowIndex].Style.ForeColor = $sender.DefaultCellStyle.ForeColor
            }
        }Catch{#prevents showing a dialog for every cell if there are errors. 
            Write-host "Painting [$($e.columnIndex),$($e.rowIndex)] : current value: $($sender[$e.columnIndex,$e.rowIndex].Value)" 
            Write-Error $_.Exception.Message
        } 
    }
    add_CellValueChanged = { Param([System.Object]$sender,[System.Windows.Forms.DataGridViewCellEventArgs]$e) 
        #TODO - what should be done with edited cells?  
    }
}

FillDatagrid
$Script:dataGridView.RowTemplate.Height = ($Script:dataGridView.RowTemplate.Height - 4) #shrink default height by 4 pixels  #$Script:dataGridView.DefaultCellStyle.Padding = 0  #already default
[void] $Script:form.Controls.AddRange(@($txtFolder,$Script:dataGridView))
[void] $Script:form.ShowDialog()
