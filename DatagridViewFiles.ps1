[reflection.assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
[reflection.assembly]::LoadWithPartialName("System.Drawing") | Out-Null
$list = New-Object System.collections.ArrayList
$BaseFolder = "c:\users\$($env:UserName)\Favorites"
$allFiles = Get-ChildItem $BaseFolder -Recurse 
$files = $allFiles  | Select @{n='Folder';e={$_.DirectoryName.Replace($BaseFolder, ".")}}, Name, LastWriteTime, Length | Sort Folder, Name #| Group -Property Folder #-AsHashTable -AsString
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
$Script:dataGridView.add_CellPainting({ Param($sender,$e)     
    Write-host "Painting [$($e.columnIndex),$($e.rowIndex)] : current value: $($Script:dataGridView[$e.columnIndex,$e.rowIndex].Value)" 
    $e.AdvancedBorderStyle.Bottom = [System.Windows.Forms.DataGridViewAdvancedCellBorderStyle]::None
    $e.AdvancedBorderStyle.Top = $Script:dataGridView.AdvancedCellBorderStyle.Top
    Try{
        If( ($e.rowIndex -gt 1)  ){ #-and ($e.colIndex -gt 0)
            $thisCell = $Script:dataGridView[$e.columnIndex,$e.rowIndex]
            $prevCell = $Script:dataGridView[$e.columnIndex,($e.rowIndex - 1)]
            If (($prevCell -ne $null) -and ($thisCell.Value -eq $prevCell.Value)){
                $e.AdvancedBorderStyle.Top = [System.Windows.Forms.DataGridViewAdvancedCellBorderStyle]::None
                $Script:dataGridView[$e.columnIndex,$e.rowIndex].Style.ForeColor = [System.Drawing.Color]::Transparent
            }
        }
    }Catch{
        Write-Error $_.Exception.Message
    } 
})
#$Script:dataGridView.add_DatasourceChanged({ AutoResizeColumns $frm.Controls["dg"] } )
#$Script:dataGridView.add_VisibleChanged({ AutoResizeColumns $frm.Controls["dg"] } )
$form.Controls.Add($Script:dataGridView)
$form.ShowDialog()