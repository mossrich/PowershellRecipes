Param([string] $BaseFolder = "c:\users\$($env:UserName)\Favorites")
[reflection.assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
[reflection.assembly]::LoadWithPartialName("System.Drawing") | Out-Null
$Script:CurrentFolder = $BaseFolder
$FilesToJSON = {Param ($folder = $Script:CurrentFolder);Get-ChildItem $folder -Recurse -File| Select @{n='Folder';e={$_.DirectoryName -replace [regex]::Escape($folder), "."}}, Name, LastWriteTime, Length | Sort Folder, Name | ConvertTo-Json}
$Script:CurrentJSON = & $FilesToJSON #store files as JSON for smaller memory footprint

[int]$FormWidth = 1100; [int]$FormHeight = 600 #TODO: store these in registry on form-resize event and read here
$Script:form = New-Object System.Windows.Forms.Form -Property @{Size = New-Object System.Drawing.Size($FormWidth,$FormHeight);Text = $BaseFolder}

$Script:timer = New-Object System.Windows.Forms.Timer -Property @{Interval = 1000} #wait 1000 ms after updating folder name before refresh grid 
$Script:timer.add_Tick({
    $Script:timer.Stop();#stop ticking - we only want one event per update
    $Script:CurrentJSON = & $FilesToJSON -folder $Script:CurrentFolder
    $Script:dataGridView.DataSource = [System.collections.ArrayList] ($Script:CurrentJSON | ConvertFrom-Json);
    $Script:dataGridView.Refresh()
}) 

$txtFolder =  New-Object System.Windows.Forms.TextBox -Property @{Name="txtFolder"; Text=$BaseFolder; Anchor="Top,Left,Right"}  #TODO: Multi-line https://stackoverflow.com/questions/73110/how-can-i-show-scrollbars-on-a-system-windows-forms-textbox-only-when-the-text-d
$txtFolder.add_TextChanged({Param([System.Windows.Forms.TextBox]$sender, $e)
    $Script:timer.Stop() #stop any pending update - the text box is changed
    If($sender.Text.TrimEnd('\') -ne $Script:CurrentFolder.TrimEnd('\')){ #adding a \ to the end of a folder name is still the same folder on disk, but resolves differently
        If(-not (Test-Path $sender.Text)){$sender.ForeColor = "Red";return} #set text red and abort
        $sender.ForeColor = "Black" #Write-Host "Starting Timer BaseFolder: $BaseFolder Text: $($sender.Text)" 
        $Script:CurrentFolder = $sender.Text.TrimEnd('\')
        $Script:timer.Start() #update grid after tick - prevents too many updates for valid folders
    }
})

$Script:dataGridView = New-Object System.Windows.Forms.DataGridView -Property @{ #need a handle to this at the script level so we don't have to look it up from form.controls['DG']
    Name = "DG"  
    Anchor = "Left,Right,Top,Bottom"
    AutoSizeColumnsMode = "AllCells" #[System.Windows.Forms.DataGridViewAutoSizeColumnMode]::AllCells - doesn't work
    AutoSizeRowsMode = "None"
    DataSource = [System.collections.ArrayList] ((& $FilesToJSON) | ConvertFrom-Json)  # https://docs.microsoft.com/en-us/dotnet/framework/winforms/controls/differences-between-the-windows-forms-datagridview-and-datagrid-controls    The only feature that is available in the DataGrid control that is not available in the DataGridView control is the hierarchical display of information from two related tables in a single control.
    Size = New-Object System.Drawing.Size(($FormWidth - 30),($FormHeight - $txtFolder.Size.Height - 50)) 
    Location = New-Object System.Drawing.Point(0,($txtFolder.Size.Height))
}
#add checkbox and set styles for this instance
$Script:dataGridView.Columns.Add( (New-Object System.Windows.Forms.DataGridViewCheckBoxColumn -Property @{Name = 'Check'}) ) #TODO: Add combobox? https://stackoverflow.com/questions/17354173/datagridview-convert-textboxcolumn-to-comboboxcolumn
$Script:dataGridView.RowTemplate.Height = ($Script:dataGridView.RowTemplate.Height - 4) #shrink default height by 4 pixels  #$Script:dataGridView.DefaultCellStyle.Padding = 0  #already default
$txtFolder.Size = New-Object System.Drawing.Size(($FormWidth / 2),$txtFolder.Size.Height)
#$Script:dataGridView.AdvancedCellBorderStyle = New-Object System.Windows.Forms.DataGridViewAdvancedBorderStyle -Property @{Bottom = [System.Windows.Forms.DataGridViewAdvancedCellBorderStyle]::NoneTop = $Script:dataGridView.AdvancedCellBorderStyle.Top} #read only property

$Script:dataGridView.add_CellPainting({#Merge rows
    Param([System.Windows.Forms.DataGridView] $sender, [System.Windows.Forms.DataGridViewCellPaintingEventArgs] $e)  
    $e.AdvancedBorderStyle.Bottom = [System.Windows.Forms.DataGridViewAdvancedCellBorderStyle]::None #TODO: set cell template with these borders - need to create an inherited dgview
    $e.AdvancedBorderStyle.Top = $sender.AdvancedCellBorderStyle.Top
    Try{
        If(($e.rowIndex -le 0 ) -or ($e.columnIndex -le 0)){ return }
        $thisCell = $sender[$e.columnIndex,$e.rowIndex]
        $prevCell = $sender[$e.columnIndex,($e.rowIndex - 1)]
        If (($thisCell.Value -eq $prevCell.Value )){ #hide if same as last ($prevCell -ne $null) -and 
            $e.AdvancedBorderStyle.Top = [System.Windows.Forms.DataGridViewAdvancedCellBorderStyle]::None
            $sender[$e.columnIndex,$e.rowIndex].Style.ForeColor = [System.Drawing.Color]::Transparent
        }
    }Catch{#prevents showing a dialog for every cell if there are errors. 
        Write-host "Painting [$($e.columnIndex),$($e.rowIndex)] : current value: $($sender[$e.columnIndex,$e.rowIndex].Value)" 
        Write-Error $_.Exception.Message
    } 
})

$Script:dataGridView.add_CellValueChanged({ Param([System.Object]$sender,[System.Windows.Forms.DataGridViewCellEventArgs]$e) #TODO: collect changes 
    
})

$Script:form.Controls.Add($txtFolder)
$Script:form.Controls.Add($Script:dataGridView)
$Script:form.ShowDialog()