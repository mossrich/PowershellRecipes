[reflection.assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
[reflection.assembly]::LoadWithPartialName("System.Drawing") | Out-Null

Function NewForm([string] $Name="NewForm", [string]$Text="Title Bar Text", 
  [System.Drawing.Size] $ClientSize = (New-Object System.Drawing.Size(1000,600))){
    $InitialWindowState = New-Object System.Windows.Forms.FormWindowState
    $frm = New-Object System.Windows.Forms.Form
    $frm.Text = $Text
    $frm.Name = $Name
    $frm.DataBindings.DefaultDataSourceUpdateMode = 0 
    $frm.ClientSize = $ClientSize
    return $frm
 }

Function NewButton([string] $Name="NewButton", [string]$Text="Button Text", [System.Drawing.Point] $Location, 
 [System.Drawing.Size] $Size = (New-Object System.Drawing.Size(155,23)), [string] $Anchor = "Left,Top", [int] $TabIndex=0){
    $btn = New-Object System.Windows.Forms.Button
    $btn.Name = $Name
    $btn.Text = $Text
    $btn.TabIndex = $TabIndex
    $btn.Size = $Size
    $btn.Location = $Location
    $btn.UseVisualStyleBackColor = $true
    $btn.DataBindings.DefaultDataSourceUpdateMode = 0 
    $btn.Anchor = $Anchor
    #$btn.add_Click($btnClose_OnClick)
    return $btn
 }
 
 Function NewLabel([string] $Name="NewLabel", [string]$Text="Label Text", [System.Drawing.Point] $Location, 
 [System.Drawing.Size] $Size = (New-Object System.Drawing.Size(155,23)), [string] $Anchor = "Left,Top", [int] $TabIndex=0){
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Name = $Name
    $lbl.Text = $Text
    $lbl.TabIndex = $TabIndex
    $lbl.Size = $Size
    $lbl.Location = $Location
    $lbl.Anchor = $Anchor
    $lbl.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",9.75,2,3,0)
    $lbl.ForeColor = [System.Drawing.Color]::FromArgb(255,0,102,204)
    return $lbl
 }

 Function NewDataGridView([string] $Name="NewDataGridView", [System.Drawing.Point] $Location, 
 [System.Drawing.Size] $Size, [string] $Anchor = "Left,Right,Top,Bottom", [int] $TabIndex=0){
    $dg = New-Object System.Windows.Forms.DataGridView -Property (@{'Name'=$Name; 'Anchor'=$Anchor; 'Location'=$Location; 'Size'=$Size; 'TabIndex'=$TabIndex })
    #$dg.AllowUserToDeleteRows = $true
    $dg.DataBindings.DefaultDataSourceUpdateMode = 0 
    $dg.DataMember = ""
    $dg.AutoSize = $true
    return $dg
}

 Function NewDataGrid([string] $Name="NewDataGrid", [System.Drawing.Point] $Location, 
 [System.Drawing.Size] $Size, [string] $Anchor = "Left,Right,Top,Bottom", [int] $TabIndex=0){
    $dg = New-Object System.Windows.Forms.DataGrid -Property (@{'Name'=$Name; 'Anchor'=$Anchor; 'Location'=$Location; 'Size'=$Size; 'TabIndex'=$TabIndex })
    #$dg.AllowUserToDeleteRows = $true
    $dg.DataBindings.DefaultDataSourceUpdateMode = 0 
    $dg.DataMember = ""
    $dg.HeaderForeColor = [System.Drawing.Color]::FromArgb(255,0,0,0)
    $dg.AllowSorting = $true
    $dg.AutoSize = $true 
    <# Trying to register VisibleChanged event - not working yet. 
    Register-ObjectEvent -InputObject $dg -EventName "VisibleChanged" -Action {   Write-Host $Sender      }
    $dg.add_VisibleChanged({ 
        Write-Host $sender
        #$DGForEvent = $dg.Container.Controls[$Name] # the instance on the form  #doesn't work - $dg is not instantiated here
        #AutoResizeColumns $DGForEvent
    } )#> 
    return $dg
}
Function AutoResizeColumns([System.Windows.Forms.DataGrid] $dg1){ #http://www.hanselman.com/blog/HowDoIAutomaticallySizeAutosizeColumnsInAWinFormsDataGrid.aspx  https://www.codeproject.com/articles/5429/auto-sizing-datagrid
    #[type] $T = $dg1.GetType()  #.GetMethod("ColAutoResize",[System.Reflection.BindingFlags]::NonPublic)$dg1.GetType() is a Control, not a DG
    #[System.Reflection.BindingFlags] $F = 'static','nonpublic','instance' # [System.Reflection.BindingFlags]::NonPublic
    #[System.Reflection.MethodInfo] $M = $T.GetMethod("ColAutoResize",  $F) # also null[System.Windows.Forms.DataGrid].GetMethod('ColAutoResize',[System.Reflection.BindingFlags]::NonPublic)
    $ColAutoResizeMethod = $dg1.GetType().GetMethod('ColAutoResize',('static','nonpublic','instance') ) #get the private method
    If($ColAutoResizeMethod) { 
        For ([int]$i = $dg1.FirstVisibleColumn; $i -le $dg1.VisibleColumnCount; $i++){
            $ColAutoResizeMethod.Invoke($dg1, $i) | Out-Null 
        }
    }
}

#Sample App - Task Manager


Function GetProcessInfo([object] $dg1){ #Function GetProcessInfo([System.Windows.Forms.DataGrid] $dg1){
    $array = New-Object System.Collections.ArrayList
    $Script:procInfo = Get-Process | Select Id, Name, Path, Descriptions, VM, WS, CPU, Company | Sort -Property Name
    $array.AddRange($Script:procInfo)
    $dg1.DataSource = $array
    #$dg1.PreferedColumnWidth = ($dg1.InnerWidth / $dg1.Columns.Count )
    $dg1.Refresh() | Out-Null
}
Function GetProcessInfoArrayList(){
    $array = New-Object System.Collections.ArrayList
    $Script:procInfo = Get-Process | Select Id, Name, Path, Descriptions, VM, WS, CPU, Company | Sort -Property Name
    $array.AddRange($procInfo)
    $array
}
 
$frm = (NewForm "frm" "Processes" (New-Object System.Drawing.Size(1000,600)) )
$frm.Controls.Add((NewButton "btnEnd" "End Task"  (New-Object System.Drawing.Point(13,13))) )
$frm.Controls.Add((NewButton "btnRefresh" "Refresh"  (New-Object System.Drawing.Point(173,13))) )
$frm.Controls["btnEnd"].add_Click({
    $SelectedRow = $frm.Controls["dg"].CurrentRowIndex
    If(($procID = $script:procInfo[$SelectedRow].Id)){ 
        Stop-Process -Id $procID -Confirm
        GetProcessInfo $frm.Controls["dg"]
    }
})
$frm.Controls["btnRefresh"].add_Click({GetProcessInfo $frm.Controls["dg"];  })

$script:DG1 = (NewDataGrid "dg" (New-Object System.Drawing.Point(13,46))  (New-Object System.Drawing.Size(980,550)) )
$frm.Controls.Add($script:DG1)
$script:DG1.add_DatasourceChanged({ AutoResizeColumns $frm.Controls["dg"] } )
$script:DG1.add_VisibleChanged({ AutoResizeColumns $frm.Controls["dg"] } )
GetProcessInfo $script:DG1
#$script:DG1.DataSource =  GetProcessInfoArrayList 
#$script:DG1.Refresh() | Out-Null #grid is empty!

$frm.ShowDialog() | Out-Null
