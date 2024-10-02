#Shows a list of user SQL databases for the local connection in a ComboBox
#Choose a database from the drop-down and all the tables with data will be listed. 
#Double-click a table and the top 100 rows will be shown in the grid
Param(
    $DBScript = "SELECT name FROM master.sys.databases WHERE name NOT IN ('master','tempdb','model','msdb')",
    $TableListScript = @"
        USE {0}
        SELECT '{0}.' + s.NAME + '.[' + t.Name + '] (' + CONVERT(varchar(50),p.rows) + ')' [Name] 
        FROM sys.tables t JOIN sys.indexes i ON t.OBJECT_ID = i.object_id JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id LEFT OUTER JOIN sys.schemas s ON t.schema_id = s.schema_id 
        WHERE t.NAME NOT LIKE 'dt%' AND t.is_ms_shipped = 0 AND i.OBJECT_ID > 255 {1} GROUP BY s.Name, t.Name, p.Rows ORDER BY s.Name, t.Name
"@,
    $TableContentScript = "SELECT TOP ({0}) * FROM {1} ORDER BY 1",
    $ConnectionString = 'Data Source=.;Integrated Security=SSPI;',#TODO: get connections from SSMS MRU
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
Function FillTableList(){
    If($ExcludeEmptyCheckBox.Checked){$Filter = " AND p.rows>0 "} Else {$Filter= ""}
    $TableList.Datasource = [Collections.ArrayList]((RunSqlQuery ($TableListScript -f $DBCombo.Text,$Filter))[0].Rows | %{$_.Name })  
}

$frm = New-Object Windows.Forms.Form -Property @{Text = 'SQL DB Browser';Size = '1200,800';add_Shown={$DBCombo.Focus(); FillTableList}}#TODO: raise selection changed event
$SplitContainerAll = New-Object Windows.Forms.SplitContainer -Property @{Dock='Fill';Orientation='Horizontal';} 
$SplitContainerTop = New-Object Windows.Forms.SplitContainer -Property @{Dock='Fill';Orientation='Horizontal';SplitterDistance = 15;FixedPanel = 'Panel1'} 
$SplitContainerMiddle = New-Object Windows.Forms.SplitContainer -Property @{Dock='Fill';Orientation='Vertical';} 

$DBCombo = New-Object Windows.Forms.ComboBox -Property @{Size='330,20';Location='0,0'
    DataSource = [Collections.ArrayList]((RunSqlQuery $DBScript)[0].Rows | %{$_.Name })
    add_SelectedIndexChanged = { FillTableList }
}
$RunButton = New-Object Windows.Forms.Button -Property @{Size='40,20';Location='530,0';Text='&Run'; #Run with Alt-R
    add_Click = { 
        If($SqlTextBox.SelectionLength -gt 0){$SQL=$SqlTextBox.SelectedText} Else {$SQL=$SqlTextBox.Text} 
        $dg.DataSource = (RunSqlQuery $SQL)[0]  
    } 
}
$ExcludeEmptyCheckBox = New-Object Windows.Forms.CheckBox -Property @{Checked=$true;Location='350,0';Size='100,30';Text = 'Exclude Empty'
    add_Click = {$DBCombo.Focus(); FillTableList}
}
$TableList = New-Object Windows.Forms.ListBox -Property @{ScrollAlwaysVisible=$true;Location='0,0';Dock='Fill'
    add_SelectedIndexChanged = {$SqlTextBox.Text = ($TableContentScript -f $DefaultMaxRows, $TableList.SelectedValue.Split('(')[0] ) }
    add_DoubleClick = {$RunButton.PerformClick() }
}
$SqlTextBox = New-Object Windows.Forms.TextBox -Property @{ScrollBars='Vertical';Multiline=$true;Dock='Fill';#Location='0,0';
    add_KeyUp = {Param($sender,[Windows.Forms.KeyEventArgs]$e) 
        If($e -eq [Windows.Forms.Keys]::F5){ $tbl = RunSqlQuery $SqlTextBox.Text;  $dg.DataSource = $tbl[0]} 
    }
}
$dg = New-Object Windows.Forms.DataGridView -Property @{Dock='Fill';
     <# Uncomment to use the simpler DataGrid - it needs auto-resizing to be useful. 
     AllowSorting=$true;HeaderForeColor=[Drawing.Color]::FromArgb(255,0,0,0)
     add_DatasourceChanged = { Param ($sender, $e)  # auto-resize columns - http://www.hanselman.com/blog/HowDoIAutomaticallySizeAutosizeColumnsInAWinFormsDataGrid.aspx  https://www.codeproject.com/articles/5429/auto-sizing-datagrid
         $ColAutoResizeMethod = $sender.GetType().GetMethod('ColAutoResize',('static','nonpublic','instance') ) #get the private method
         For ([int]$i = $sender.FirstVisibleColumn; $i -lt $sender.VisibleColumnCount; $i++){ $ColAutoResizeMethod.Invoke($sender, $i) | Out-Null }
     }#>
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
[windows.forms.application]::run($frm)
