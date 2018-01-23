$choices = [System.Management.Automation.Host.ChoiceDescription[]](
    (new-Object System.Management.Automation.Host.ChoiceDescription "&Restart","Restart"), #Label,HelpMessage
    (new-Object System.Management.Automation.Host.ChoiceDescription "&ShutDown","Shutdown")
)
$answer =  $Host.ui.PromptForChoice("Choose Action","What do you want to do?",$choices,0)

switch ($answer){
    0 {"You chose $($choices[$answer].Label)"; break}
    1 {"You chose $($choices[$answer].Label)"; break}
}
