#shows a gridview with the files most recently used in Powershell ISE and allows you to select the ones to reload 
[xml] $config = Get-Content "$env:LocalAppData\microsoft_corporation\powershell_ise.exe_StrongName_lw2v2vm3wmtzzpebq33gybmeoxukb04w\3.0.0.0\user.config"
psedit ( $config.SelectNodes('//setting[@name="MRU"]').value.ArrayOfString.string  | Out-GridView -PassThru )
