[reflection.assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
[reflection.assembly]::LoadWithPartialName("System.Drawing") | Out-Null
$BaseFolder = "c:\users\$($env:UserName)\Favorites"
$allFiles = Get-ChildItem $BaseFolder -Recurse 
$files = $allFiles  | Select @{n='Folder';e={$_.DirectoryName.Replace($BaseFolder, ".")}}, Name,LastWriteTime, Length | Sort Folder, Name #| Group -Property Folder #-AsHashTable -AsString

$list = New-Object System.collections.ArrayList
$list.AddRange($files) #$list | Out-GridView
$form = New-Object System.Windows.Forms.Form -Property @{Size = New-Object System.Drawing.Size(900,600)}
$Script:dataGridView = New-Object System.Windows.Forms.DataGridView -Property @{
    Name = "DG"
    #AutoGenerateColumns = $false #for merge(required?)    
    Anchor = "Left,Right,Top,Bottom"
    Size = New-Object System.Drawing.Size(870,550) 
    AutoSizeColumnsMode = "AllCells"
    DataSource = $list
}

$checkCol = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn -Property @{Name = 'Check';Width = 40}
$Script:dataGridView.Columns.Add($checkCol)
$Script:dataGridView.DefaultCellStyle.Padding = 0  
$Script:dataGridView.AutoSizeRowsMode = "None"
$Script:dataGridView.RowTemplate.Height = ($Script:dataGridView.RowTemplate.Height - 4)

$Script:dataGridView.add_CellPainting({ Param($sender,$e) #Merge rows 
    $e.AdvancedBorderStyle.Bottom = [System.Windows.Forms.DataGridViewAdvancedCellBorderStyle]::None
    $e.AdvancedBorderStyle.Top = $Script:dataGridView.AdvancedCellBorderStyle.Top
    Try{
        If( ($e.rowIndex -gt 0)  ){ #-and ($e.colIndex -gt 0)
            $thisCell = $Script:dataGridView[$e.columnIndex,$e.rowIndex]
            $prevCell = $Script:dataGridView[$e.columnIndex,($e.rowIndex - 1)]
            If (($prevCell -ne $null) -and ($thisCell.Value -eq $prevCell.Value )){ #hide if same as last
                $e.AdvancedBorderStyle.Top = [System.Windows.Forms.DataGridViewAdvancedCellBorderStyle]::None
                $Script:dataGridView[$e.columnIndex,$e.rowIndex].Style.ForeColor = [System.Drawing.Color]::Transparent
            }
        }
    }Catch{#prevents showing a dialog for every cell if there are errors. 
        Write-host "Painting [$($e.columnIndex),$($e.rowIndex)] : current value: $($Script:dataGridView[$e.columnIndex,$e.rowIndex].Value)" 
        Write-Error $_.Exception.Message
    } 
})
$form.Controls.Add($Script:dataGridView)
$form.ShowDialog()