#Uses WPF to display a grouped datagrid - expand/collapse a folder
$FormWidth = 1100
$FormHeight = 600 
$xaml =@"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        x:Name="Window_GuiManagement" Title="Favorites" WindowStartupLocation = "CenterScreen" 
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
                                        <Expander IsExpanded="True" >
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

$folder = "c:\users\$($env:UserName)\Favorites\Links"
$FilesArray = (Get-ChildItem $folder -Recurse -File | Select @{n='Folder';e={$_.DirectoryName -replace [regex]::Escape($folder), "."}}, Name, LastWriteTime, Length | Sort Folder, Name)
[System.Windows.Data.ListCollectionView] $cv = [System.Windows.Data.ListCollectionView]$FilesArray
$cv.GroupDescriptions.Add((new-object System.Windows.Data.PropertyGroupDescription "Folder"))
$DG.ItemsSource = $cv

$Form.ShowDialog() | out-null