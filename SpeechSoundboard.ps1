#demonstrates speech synthesis with a simple sound board of common phrases
Param($WordList = @( # & in front of a letter allows saying "H&ello" with Alt-E, if Alt-E is not already assigned. 
        "H&ello", "&Hi", "&Goodbye", "I don't &understand", "I don't &know", "&Wait", "&Yes", "&No", "&OK"
    )
)
Add-Type -AssemblyName System.Speech
$Synth = New-Object System.Speech.Synthesis.SpeechSynthesizer -Property @{rate = -1; volume = 100} 

Add-Type -AssemblyName System.Windows.Forms
$form1 = New-Object System.Windows.Forms.form -Property @{ShowInTaskbar = $True; WindowState = "Normal"}
$top = 5
$WordList|%{
    $btn = New-Object System.Windows.Forms.Button -property @{Text = $_; Top = $top}
    $btn.add_Click({$Synth.Speak($this.Text.Replace('&',''))})
    $form1.Controls.Add($btn)
    $top += $btn.Height + 5
    $form1.Height = $top + 40 
}
[void][System.Windows.Forms.Application]::Run($form1)
