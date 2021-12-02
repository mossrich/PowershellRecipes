#Sends $FileSpecs files to a zip archive if they match $Filter - deleting the original if $DeleteAfterArchiving is true. 
#Files that have already been archived will be ignored. 
param (
   [string] $ParentFolder = "$PSScriptRoot", #Files will be stored in the zip with path relative to this folder
   [string[]] $FileSpecs = @("*.log","*.txt","*.svclog","*.log.*"), 
   $Filter = { $_.LastWriteTime -lt (Get-Date).AddDays(-7)}, #a Where-Object function - default = older than 7 days
   [string] $ZipPath = "$PSScriptRoot\archive-$(get-date -f yyyy-MM).zip", #create one archive per run-month - it may contain older files 
   [System.IO.Compression.CompressionLevel]$CompressionLevel = [System.IO.Compression.CompressionLevel]::Optimal, 
   [switch] $DeleteAfterArchiving = $true,
   [switch] $Verbose = $true,
   [switch] $Recurse = $true
)
@( 'System.IO.Compression','System.IO.Compression.FileSystem') | % { [void][System.Reflection.Assembly]::LoadWithPartialName($_) }
Push-Location $ParentFolder #change to the folder so we can get relative path
$FileList = (Get-ChildItem $FileSpecs -File -Recurse:$Recurse  | Where-Object $Filter) #CreateEntryFromFile raises UnauthorizedAccessException if item is a directory
$totalcount = $FileList.Count
$countdown = $totalcount
$skipped = @()
Try{
    $WriteArchive = [IO.Compression.ZipFile]::Open( $ZipPath, [System.IO.Compression.ZipArchiveMode]::Update)
    ForEach ($File in $FileList){
        Write-Progress -Activity "Archiving files" -Status  "Archiving file $($totalcount - $countdown) of $totalcount : $($File.Name)"  -PercentComplete (($totalcount - $countdown)/$totalcount * 100)
        $ArchivedFile = $null
        $RelativePath = (Resolve-Path -LiteralPath "$($File.FullName)" -Relative) -replace '^.\\'
        $AlreadyArchivedFile = ($WriteArchive.Entries | Where-Object {#zip will store multiple copies of the exact same file - prevent this by checking if already archived. 
                (($_.FullName -eq $RelativePath) -and ($_.Length -eq $File.Length) )  -and 
                ([math]::Abs(($_.LastWriteTime.UtcDateTime - $File.LastWriteTimeUtc).Seconds) -le 2) #ZipFileExtensions timestamps are only precise within 2 seconds. 
            })     
        If($AlreadyArchivedFile -eq $null){
            If($Verbose){Write-Host "Archiving $RelativePath $($File.LastWriteTimeUtc -f "yyyyMMdd-HHmmss") $($File.Length)" }
            Try{
                $ArchivedFile = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($WriteArchive, $File.FullName, $RelativePath, $CompressionLevel)
            }Catch{
                Write-Warning  "$($File.FullName) could not be archived. `n $($_.Exception.Message)"  
                $skipped += [psobject]@{Path=$file.FullName; Reason=$_.Exception.Message}
            }
            If($File.LastWriteTime.IsDaylightSavingTime() -and $ArchivedFile){#HACK: fix for buggy date - adds an hour inside archive when the zipped file was created during PDT (files created during PST are not affected).  Not sure how to introduce DST attribute to file date in the archive. 
                $entry = $WriteArchive.GetEntry($RelativePath)    
                $entry.LastWriteTime = ($File.LastWriteTime.ToLocalTime() - (New-TimeSpan -Hours 1)) #TODO: This is better, but maybe not fully correct. Does it work in all time zones?
            }
        }Else{#Write-Warning "$($File.FullName) is already archived$(If($DeleteAfterArchiving){' and will be deleted.'}Else{'. No action taken.'})" 
            Write-Warning "$($File.FullName) is already archived - No action taken." 
            $skipped += [psobject]@{Path=$file.FullName; Reason="Already archived"}
        }
        If((($ArchivedFile -ne $null) -and ($ArchivedFile.FullName -eq $RelativePath)) -and $DeleteAfterArchiving) { #delete original if it's been successfully archived. 
            Try {
                Remove-Item $File.FullName -Verbose:$Verbose
            }Catch{
                Write-Warning "$($File.FullName) could not be deleted. `n $($_.Exception.Message)"
            }
        } 
        $countdown = $countdown -1
    }
}Catch [Exception]{
    Write-Error $_.Exception
}Finally{
    $WriteArchive.Dispose() #close the zip file so it can be read later 
    Write-Host "Sent $($totalcount - $countdown - $($skipped.Count)) of $totalcount files to archive: $ZipPath"
    $skipped | Format-Table -Autosize -Wrap
}
Pop-Location
