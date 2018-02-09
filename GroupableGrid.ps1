#Uses WPF to display a grouped datagrid - allows user to expand/collapse a group (group=folder if the default $datalist is used)
param(
    $RootFolder = "c:\users\$($env:UserName)", 
    [Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    $DataList = (Get-ChildItem $RootFolder -Recurse -File -ErrorAction ignore | Select @{n='Folder';e={$_.DirectoryName -replace [regex]::Escape($RootFolder), "."}}, Name, LastWriteTime, Length | Sort Folder, Name),
    [string] $GroupColumn = ($DataList | Get-Member -MemberType NoteProperty | Select -First 1).Name, #first column name - whatever you group by should be sorted first
    [string] $Title = "$RootFolder",
    [string] $StartExpanded = "False",
    $FormWidth = 1100,
    $FormHeight = 600 
)
$xaml =@"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        x:Name="Window_GuiManagement" Title="$Title" WindowStartupLocation = "CenterScreen" 
        Width = "$FormWidth" Height = "$FormHeight" Visibility="Visible" WindowStyle="ToolWindow" ResizeMode="CanResize" Topmost="True">
    <Grid>
        <DataGrid x:Name="DGItems" Margin="10,10,10,0" VerticalAlignment="Top" SelectionMode="Single" AlternationCount="1" AutoGenerateColumns="True">
            <DataGrid.GroupStyle>
                <GroupStyle>
                    <GroupStyle.ContainerStyle>
                        <Style TargetType="{x:Type GroupItem}">
                            <Setter Property="Template">
                                <Setter.Value>
                                    <ControlTemplate TargetType="{x:Type GroupItem}">
                                        <Expander IsExpanded="$StartExpanded" >
                                            <Expander.Header>
                                                <DockPanel>
                                                    <TextBlock Text="{Binding Path=Name}" />
                                                </DockPanel>
                                            </Expander.Header>
                                            <Expander.Content>
                                                <ItemsPresenter />
                                            </Expander.Content>
                                        </Expander>
                                    </ControlTemplate>
                                </Setter.Value>
                            </Setter>
                        </Style>
                    </GroupStyle.ContainerStyle>
                </GroupStyle>
            </DataGrid.GroupStyle>
        </DataGrid>
    </Grid>
</Window>
"@
#Add-Type –assemblyName WindowsBase  #Add-Type –assemblyName PresentationCore  #[reflection.assembly]::LoadWithPartialName("System.Windows.Controls") #[reflection.assembly]::LoadWithPartialName("System..Collections.Generic") 
Add-Type -AssemblyName presentationframework
[reflection.assembly]::LoadWithPartialName("System.Windows.Data") #| Out-Null

$reader = (New-Object System.Xml.XmlNodeReader ([xml] $xaml))
[System.Windows.Window] $Form = [Windows.Markup.XamlReader]::Load( $reader )
[System.Windows.Controls.DataGrid] $DG = $Form.FindName("DGItems")

[System.Windows.Data.ListCollectionView] $cv = [System.Windows.Data.ListCollectionView]$DataList
$cv.GroupDescriptions.Add((new-object System.Windows.Data.PropertyGroupDescription $GroupColumn))
$DG.ItemsSource = $cv

$DG.add_Loaded({param([System.Windows.Controls.DataGrid]$sender, $e) #hide grouped column - TODO: allow regrouping
    ForEach($col in $sender.Columns) { 
        $col.Visibility = If($col.Header -eq $GroupColumn){ [System.Windows.Visibility]::Hidden } else { [System.Windows.Visibility]::Visible }
    }
})
$Form.ShowDialog() | out-null