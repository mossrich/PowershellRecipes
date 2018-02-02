Param([string] $BaseFolder = "c:\users\$($env:UserName)\Favorites")

[reflection.assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
[reflection.assembly]::LoadWithPartialName("System.Drawing") | Out-Null
$FilesJSON = (Get-ChildItem $BaseFolder -Recurse | Select @{n='Folder';e={$_.DirectoryName -replace [regex]::Escape($BaseFolder), "."}}, Name, LastWriteTime, Length | Sort Folder, Name | ConvertTo-Json)
[int]$FormWidth = 900; [int]$FormHeight = 600 #TODO: store these in registry on form-resive event and read here

$Script:form = New-Object System.Windows.Forms.Form -Property @{Size = New-Object System.Drawing.Size($FormWidth,$FormHeight)}

$Script:dataGridView = New-Object System.Windows.Forms.DataGridView -Property @{ #need a handle to this at the script level so we don't have to look it up from the form controls
    Name = "DG"  
    Anchor = "Left,Right,Top,Bottom"
    AutoSizeColumnsMode = "AllCells" #[System.Windows.Forms.DataGridViewAutoSizeColumnMode]::AllCells
    AutoSizeRowsMode = "None"
    DataSource = [System.collections.ArrayList] ($FilesJSON | ConvertFrom-Json)
    Size = New-Object System.Drawing.Size(($FormWidth - 30),($FormHeight - 50)) #TODO: make room for other controls above grid
}
#add checkbox and set styles
$Script:dataGridView.Columns.Add( (New-Object System.Windows.Forms.DataGridViewCheckBoxColumn -Property @{Name = 'Check'}) )
$Script:dataGridView.RowTemplate.Height = ($Script:dataGridView.RowTemplate.Height - 4) #shrink default height by 4 pixels  #$Script:dataGridView.DefaultCellStyle.Padding = 0  #already default
#$Script:dataGridView.AdvancedCellBorderStyle = New-Object System.Windows.Forms.DataGridViewAdvancedBorderStyle -Property @{Bottom = [System.Windows.Forms.DataGridViewAdvancedCellBorderStyle]::NoneTop = $Script:dataGridView.AdvancedCellBorderStyle.Top} #read only property

$Script:dataGridView.add_CellPainting({#Merge rows
    Param([System.Windows.Forms.DataGridView]$sender, [System.Windows.Forms.DataGridViewCellPaintingEventArgs] $e)  
    $e.AdvancedBorderStyle.Bottom = [System.Windows.Forms.DataGridViewAdvancedCellBorderStyle]::None #TODO: set cell template with these borders - need to create an inherited dgview
    $e.AdvancedBorderStyle.Top = $Script:dataGridView.AdvancedCellBorderStyle.Top
    Try{
        If(($e.rowIndex -le 0 ) -or ($e.columnIndex -le 0)){ return }
        $thisCell = $Script:dataGridView[$e.columnIndex,$e.rowIndex]
        $prevCell = $Script:dataGridView[$e.columnIndex,($e.rowIndex - 1)]
        If (($thisCell.Value -eq $prevCell.Value )){ #hide if same as last ($prevCell -ne $null) -and 
            $e.AdvancedBorderStyle.Top = [System.Windows.Forms.DataGridViewAdvancedCellBorderStyle]::None
            $Script:dataGridView[$e.columnIndex,$e.rowIndex].Style.ForeColor = [System.Drawing.Color]::Transparent
        }
    }Catch{#prevents showing a dialog for every cell if there are errors. 
        Write-host "Painting [$($e.columnIndex),$($e.rowIndex)] : current value: $($Script:dataGridView[$e.columnIndex,$e.rowIndex].Value)" 
        Write-Error $_.Exception.Message
    } 
})

$Script:dataGridView.add_CellValueChanged({ Param([System.Object]$sender,[System.Windows.Forms.DataGridViewCellEventArgs]$e) #TODO: collect changes 
    
})

$Script:form.Controls.Add($Script:dataGridView)
$Script:form.ShowDialog()
