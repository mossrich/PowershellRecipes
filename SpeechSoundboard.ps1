#demonstrates speech synthesis with a simple sound board of common phrases
Param($WordList = @( # & in front of a letter allows saying "H&ello" with Alt-E, if Alt-E is not already assigned. 
        "H&ello", "&Hi", "&Goodbye", "I don't &understand", "I don't &know", "I don't &think so","&Wait", "&Yes", "&No", "&OK"
    )
)
Add-Type -AssemblyName System.Speech
$Synth = New-Object System.Speech.Synthesis.SpeechSynthesizer -Property @{rate = -1; volume = 100} 

Add-Type -AssemblyName System.Windows.Forms
$form1 = New-Object System.Windows.Forms.form -Property @{ShowInTaskbar = $True; WindowState = "Normal"}
$TextBox = New-Object System.Windows.Forms.textbox -Property @{Width = $form1.Width -20}
$TextBox.add_KeyUp({param($sender,[System.Windows.Forms.KeyEventArgs] $e );
    If($e.KeyValue -eq [System.Windows.Forms.Keys]::Return){$Synth.Speak($this.Text);$this.Text=""}})
$form1.Controls.Add($TextBox)
$top = $TextBox.Height + 5 
$left = 2
$WordList|%{
    $btn = New-Object System.Windows.Forms.Button -property @{Text = $_; Top = $top; Left = $left}
    $btn.add_Click({$Synth.Speak($this.Text.Replace('&',''))})
    $form1.Controls.Add($btn)
    $left += $btn.Width + 5 
    If($left + $btn.Width + 10 -gt $form1.Width){
        $top += $btn.Height + 5
        $left = 2
        $form1.Height = $Top + (($btn.Height + 5) * 2) + 20 
    }
}
[void][System.Windows.Forms.Application]::Run($form1)
