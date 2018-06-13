function GetCertThumbprintFromStore{#Get a single matching cert, an exception if no match, or prompt if multiple 
  param(
    [string] $CertStoreName = "Cert:\LocalMachine\My",
    $CertWhereFilter = {$_.Subject -like "*localhost*" -and $_.NotAfter -gt (Get-Date)}
  )
  [System.Security.Cryptography.X509Certificates.X509Certificate[]] $MatchingCerts = (Get-ChildItem $CertStoreName -Recurse | ? $CertWhereFilter)
  If($MatchingCerts.Count -eq 0){
    Throw "No certs found in $CertStoreName matching $CertWhereFilter"
  }ElseIf($MatchingCerts.Count -eq 1){
    Return $MatchingCerts[0]
  }Else{
    $choices = New-Object System.Collections.ObjectModel.Collection[System.Management.Automation.Host.ChoiceDescription]
    For($i=0; $i -lt $MatchingCerts.Count; $i++){
        $choices.Add( (New-Object System.Management.Automation.Host.ChoiceDescription "&$i) $($MatchingCerts[$i].FriendlyName) $($MatchingCerts[$i].Subject)", $MatchingCerts[$i].Thumbprint)  ) 
    }
    Return $choices[$Host.UI.PromptForChoice("Multiple certificates found in $CertStoreName matching $CertWhereFilter",`
        "Choose a certificate", $choices, 0)].HelpMessage
  }
} 



$thumbprint = GetCertThumbprintFromStore -CertStoreName "Cert:\LocalMachine\My"
$cert = (Get-ChildItem -path Cert: -Recurse | ? {$_.Thumbprint -eq $thumbprint})
$cert | select * | Format-List
