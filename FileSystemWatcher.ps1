#monitors the user's desktop and reports any changed or deleted files
$EventsToMonitor = @('Changed', 'Deleted'), #valid values: Created,Changed,Renamed,Deleted
try {
  $watcher = New-Object IO.FileSystemWatcher -Property @{
    Path = [Environment]::GetFolderPath('Desktop')
    Filter = '*' #the file mask 
    IncludeSubdirectories = $true
    NotifyFilter = @([IO.NotifyFilters]::Security, [IO.NotifyFilters]::LastWrite) #valid values: Attributes,CreationTime,DirectoryName,FileName,LastAccess,LastWrite,Security,Size
    EnableRaisingEvents = $true
  }

  $EventsToMonitor | %{ $handlers += Register-ObjectEvent -InputObject $watcher -EventName $_ -Action {
    Write-Host "`n[$($event.SourceEventArgs.ChangeType)] $($event | ConvertTo-Json -Depth 5)"
  } }

  Write-Warning "FileSystemWatcher is monitoring $($watcher.NotifyFilter) events for $($watcher.Path)"
  do{
    Wait-Event -Timeout 1
    Write-Host "." -NoNewline     # write a dot to indicate we are still monitoring
  } while ($true)# the loop runs forever until you hit CTRL+C    
}finally{#release the watcher and free its memory
  $handlers | %{Unregister-Event -SourceIdentifier $_.Name }
  $handlers | Remove-Job
  $watcher.Dispose() 
  Write-Warning 'FileSystemWatcher removed.'
}
