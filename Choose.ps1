#inspired by https://stackoverflow.com/questions/26386267/is-there-a-one-liner-for-using-default-values-with-read-host
'Default Value' | %{If($Entry = Read-Host "Enter a value ($_)"){$Entry}Else{$_}} #returns user entry or 'Default Value' if user hit [Enter] 

'google.com' | %{(Read-Host "Host name ($_)").Trim(),$_} | ?{$_} | Select -First 1 #same as above, but no intermediate $Entry variable

'google.com' | %{(Read-Host "Host Name ($_)"),$_ -match '\S'|Select -First 1} 

'google.com' | %{@((Read-Host "Host Name: ($_)"),$_ -match '\S')[0]} #shorter using array syntax instead of Select-Object

$choices = [Management.Automation.Host.ChoiceDescription[]](
    (New-Object Management.Automation.Host.ChoiceDescription "&localhost","127.0.0.1"), #Label,HelpMessage
    (New-Object Management.Automation.Host.ChoiceDescription "&Google","www.google.com")
)
$Chosen = $choices[$Host.ui.PromptForChoice("Choose host","What host do you want to use?",$choices,0)].HelpMessage
Write-Host $Chosen

<#
switch ($answer){
    0 {"You chose $($choices[$answer].Label)"; break}
    1 {"You chose $($choices[$answer].Label)"; break}
}
#>
