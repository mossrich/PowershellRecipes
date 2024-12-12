#Shows a list of user SQL databases for the local connection in a ComboBox
#Choose a database from the drop-down and all the tables with data will be listed. 
#Double-click a table and the top 100 rows will be shown in the grid with similar cells merged
Param(
    $ConnectionString = 'Data Source=.;Integrated Security=SSPI;',#TODO: get connections from a config file
    $DBScript = "SELECT name FROM master.sys.databases WHERE name NOT IN ('master','tempdb','model','msdb')",
    $TableListScript = @"
        USE {0}
        SELECT '{0}.' + s.NAME + '.[' + t.Name + ']' [TableName], p.Rows, 
         STUFF((SELECT ', ' + COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS C 
         WHERE C.TABLE_SCHEMA = s.Name AND C.TABLE_NAME = t.Name ORDER BY ORDINAL_POSITION FOR XML PATH('')),1,1,'') [Columns]
        FROM sys.tables t JOIN sys.indexes i ON t.OBJECT_ID = i.object_id JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id LEFT OUTER JOIN sys.schemas s ON t.schema_id = s.schema_id 
        WHERE t.NAME NOT LIKE 'dt%' AND t.is_ms_shipped = 0 AND i.OBJECT_ID > 255 {1} GROUP BY s.Name, t.Name, p.Rows ORDER BY 1 
"@,
    $TableContentScript = "SELECT TOP ({0}){1} `r`n FROM {2} ORDER BY 1",
    $DefaultMaxRows = 100 #this can be overridden in the SQL text box
)

@('System.Windows.Forms','System.Drawing','System.Data.SqlClient') | %{[void][reflection.assembly]::LoadWithPartialName($_)}
Function RunSqlQuery($QueryText, $ConnString = $ConnectionString){#Write-Host $QueryText
      $conn = New-Object Data.SqlClient.SqlConnection($ConnString)
      $conn.Open()
      $da = New-Object Data.SqlClient.SqlDataAdapter((New-Object System.Data.SqlClient.SqlCommand($QueryText, $conn)))
      $ds = New-Object Data.DataSet
      [void]$da.Fill($ds)
      $conn.Close()
      return $ds.Tables
}
Function FillListViewFromDataTable([Data.DataTable] $tbl, [Windows.Forms.ListView] $lv){
    $lv.Columns.Clear();$lv.Items.Clear()
    $NumericColumnTypes = 'Decimal','Double','Int16','Int32','Int64','Single','UInt16','UInt32','UInt64' #All Types: Boolean Byte Char DateTime Decimal Double Int16 Int32 Int64 SByte Single String TimeSpan UInt16 UInt32 UInt64 
    $tbl.Columns | %{
        $newCol = $lv.Columns.Add($_.ColumnName)
        If($NumericColumnTypes.Contains($_.DataType.Name)){$NewCol.TextAlign = 'Right'} #Numeric columns will be right-aligned
    }
    Foreach($row in $tbl.Rows){ 
        $LvItem = New-Object Windows.Forms.ListViewItem($row[0])
        1..($row.ItemArray.Count-1) | %{ $LvItem.SubItems.Add($row[$_]) }
        $lv.Items.Add($LvItem)
    }
}
Function FillTableList(){#when a DB is selected fill the list with its tables
    If($ExcludeEmptyCheckBox.Checked){$Filter = " AND p.rows>0 "} Else {$Filter= ""}
    FillListViewFromDataTable (RunSqlQuery ($TableListScript -f $DBCombo.Text,$Filter))[0] $TableList
    $TableList.AutoResizeColumn(0,'ColumnContent')#Resize the TableName column
    If($TableList.Items.Count -ge 0){$TableList.Items[0].Selected = $true;$TableList.Items[0].Focused = $true}
}

$frm = New-Object Windows.Forms.Form -Property @{Text = 'SQL DB Browser';Size = '1200,800';add_Shown={$DBCombo.Focus(); FillTableList}}#TODO: raise selection changed event
$SplitContainerAll = New-Object Windows.Forms.SplitContainer -Property @{Dock='Fill';Orientation='Horizontal';} 
$SplitContainerTop = New-Object Windows.Forms.SplitContainer -Property @{Dock='Fill';Orientation='Horizontal';SplitterDistance = 15;FixedPanel = 'Panel1'} 
$SplitContainerMiddle = New-Object Windows.Forms.SplitContainer -Property @{Dock='Fill';Orientation='Vertical';} 
$DBCombo = New-Object Windows.Forms.ComboBox -Property @{Size='330,20';Location='0,0'
    DataSource = [Collections.ArrayList]((RunSqlQuery $DBScript)[0].Rows | %{$_.Name })
    add_SelectedIndexChanged = { FillTableList }
}
$RunButton = New-Object Windows.Forms.Button -Property @{Size='40,20';Location='600,0';Text='&Run'; #Run with Alt-R
    add_Click = { 
        If($SqlTextBox.SelectionLength -gt 0){$SQL=$SqlTextBox.SelectedText} Else {$SQL=$SqlTextBox.Text} 
        $dg.DataSource = (RunSqlQuery $SQL)[0]   
    } 
}
$ExcludeEmptyCheckBox = New-Object Windows.Forms.CheckBox -Property @{Checked=$true;Location='350,0';Size='100,30';Text = 'Exclude Empty'
    add_Click = {$DBCombo.Focus(); FillTableList}
}
$TableList = New-Object Windows.Forms.ListView -Property @{Location='0,0';Dock='Fill';#MultiColumn = $true;#ScrollAlwaysVisible=$true;
    FullRowSelect = $true;View = 'Detail';GridLines = $true
    add_SelectedIndexChanged = {Param([Windows.Forms.ListView] $sender, $e) 
        If($sender.SelectedItems){
            $SqlTextBox.Text = ($TableContentScript -f $DefaultMaxRows, $sender.SelectedItems[0].SubItems[2].Text, $sender.SelectedItems[0].Text)
        }
    }
    add_DoubleClick = {$RunButton.PerformClick() }
}
$SqlTextBox = New-Object Windows.Forms.TextBox -Property @{ScrollBars='Vertical';Multiline=$true;Dock='Fill';Font='Lucida Console'#Location='0,0';
    add_KeyUp = {Param($sender,[Windows.Forms.KeyEventArgs]$e) 
        If($e.KeyCode -eq [Windows.Forms.Keys]::F5){ $RunButton.PerformClick() } 
    }
}
$dg = New-Object Windows.Forms.DataGridView -Property @{Dock='Fill';
     AutoSizeColumnsMode = 'AllCells';AutoSizeRowsMode = 'None' #$dg.DefaultCellStyle.Padding.All = 0  - doesn't remove padding :(
     add_CellPainting = {Param([Windows.Forms.DataGridView] $sender, [Windows.Forms.DataGridViewCellPaintingEventArgs] $e)  #merge rows
        $e.AdvancedBorderStyle.Bottom = [Windows.Forms.DataGridViewAdvancedCellBorderStyle]::None #TODO: set cell template with these borders - need to create an inherited dgview
        Try{
            If(($e.rowIndex -le 0 ) -or ($e.columnIndex -lt 0)){ return }
            $thisCell = $sender[$e.columnIndex,$e.rowIndex]
            $prevCell = $sender[$e.columnIndex,($e.rowIndex - 1)]
            If (($thisCell.Value -eq $prevCell.Value  -and $prevCell.Displayed)){ #hide value if same as prev, and prev is showing
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
}

$SplitContainerMiddle.Panel1.Controls.Add($TableList)
$SplitContainerMiddle.Panel2.Controls.Add($SqlTextBox)
$SplitContainerTop.Panel1.Controls.AddRange(@($DBCombo,$ExcludeEmptyCheckBox,$RunButton))
$SplitContainerTop.Panel2.Controls.Add($SplitContainerMiddle)
$SplitContainerAll.Panel1.Controls.Add($SplitContainerTop)
$SplitContainerAll.Panel2.Controls.Add($dg)
$frm.Controls.AddRange(@($SplitContainerAll))
$SplitContainerMiddle.SplitterDistance = 600
[windows.forms.application]::run($frm) #$frm.ShowDialog()
