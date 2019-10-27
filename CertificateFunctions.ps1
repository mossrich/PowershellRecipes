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

Function Get-CredentialsFromAppPool([string] $AppPoolWithIdentity = 'Configuration'){#retrieves service account credential from IIS App Pool
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
        Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit #restart as admin if not started as admin 
    }
    Push-Location $env:TEMP
    $UserName = cmd.exe /q /c "$env:windir\system32\inetsrv\appcmd.exe list apppool `"$AppPoolWithIdentity`" /text:ProcessModel.UserName"
    $Password = cmd.exe /q /c "$env:windir\system32\inetsrv\appcmd.exe list apppool `"$AppPoolWithIdentity`" /text:ProcessModel.Password"
    If(!$UserName) {Throw "No identity found for App Pool: $AppPoolWithIdentity"}
    Pop-Location 
    Return New-Object System.Management.Automation.PSCredential($UserName,(ConvertTo-SecureString $Password -AsPlainText -Force))
}

Function Get-CertFromUserStore(
    [pscredential] $UserCredential,
    [string] $SubjectSearchString = 'CN=*',
    $CertificatePath = 'Cert:\CurrentUser\My'
  ){
    $job = Start-Job -Credential $UserCredential -ArgumentList $CertificatePath,$SubjectSearchString -ScriptBlock { Param([string] $CertPath, [string] $CertSubject)
        Get-ChildItem -Path $CertPath | Where {$_.Subject -like $CertSubject -and $_.NotAfter -ge [datetime]::Now}
    }
    $job | Wait-Job | Out-Null
    $out = ($job | Receive-Job)
    $job | Remove-Job
    Return $out
}

Get-CertFromUserStore (Get-CredentialsFromAppPool)
<#
$thumbprint = GetCertThumbprintFromStore -CertStoreName "Cert:\LocalMachine\My"
$cert = (Get-ChildItem -path Cert: -Recurse | ? {$_.Thumbprint -eq $thumbprint})
$cert | select * | Format-List
#>
