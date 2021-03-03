$user = 'mossrich'
$repo = 'PowershellRecipes'
$uri = "https://api.github.com/repos/$user/$repo/zipball/"
if(!$cred){$cred = Get-Credential -Message 'Provide GitHub credentials' -UserName $user}
$headers = @{
  "Authorization" = "Basic " + [convert]::ToBase64String([char[]] ($cred.UserName + ':' + $cred.GetNetworkCredential().Password)) 
  "Accept" = "application/vnd.github.v3+json"
}
$response = Invoke-WebRequest -Method Get -Headers $headers -Uri $uri
$filename = $response.headers['content-disposition'].Split('=')[1]

Set-Content -Path (join-path "$HOME\Desktop" $filename) -Encoding byte -Value $response.Content 
