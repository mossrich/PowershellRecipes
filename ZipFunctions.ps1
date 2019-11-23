@( 'System.IO.Compression','System.IO.Compression.FileSystem') | % { [void][System.Reflection.Assembly]::LoadWithPartialName($_) }

function Add-ZipEntry([string] $ZipFilePath, [string] $EntryPath, [byte[]] $Content){
    $FileStream = New-Object IO.FileStream($ZipFilePath, [IO.FileMode]::Open)
    $ZipArchive = New-Object IO.Compression.ZipArchive($FileStream, [IO.Compression.ZipArchiveMode]::Update)
    $Entry = $ZipArchive.CreateEntry($EntryPath)
    $WriteStream = New-Object System.IO.StreamWriter($Entry.Open())
    $WriteStream.Write($Content,0,$Content.Length)
    $WriteStream.Flush()
    $WriteStream.Dispose()
    $ZipArchive.Dispose()
    $FileStream.Close()
    $FileStream.Dispose()
}

function Get-ZipEntryContent([string] $ZipFilePath, [string] $EntryPath){#returns the bytes of the first matching entry 
    $FileStream = New-Object IO.FileStream($ZipFilePath, [IO.FileMode]::Open)
    $ZipArchive = New-Object IO.Compression.ZipArchive($FileStream, [IO.Compression.ZipArchiveMode]::Read)
    $buf = New-Object byte[] (0) #return an empty byte array if not found
    $ZipArchive.GetEntry($EntryPath) | ?{$_} | %{ #GetEntry returns first matching entry or null if there is no match
        $buf = New-Object byte[] ($_.Length)
        Write-Verbose "     reading: $($_.Name)"
        $_.Open().Read($buf,0,$buf.Length)
    }
    $ZipArchive.Dispose()
    $FileStream.Close()
    $FileStream.Dispose()
    return $buf 
}

function Delete-ZipEntries([string] $ZipFilePath, [string] $WildcardNamesToDelete){#will delete all 
    $FileStream = New-Object IO.FileStream($ZipFilePath, [IO.FileMode]::Open)
    $ZipArchive    = New-Object IO.Compression.ZipArchive($FileStream, [IO.Compression.ZipArchiveMode]::Update)
    ($zip.Entries | ? { $_.Name -like $WildcardNamesToDelete }) | % { 
        Write-Verbose "     Deleting: $($_.Name)"
        $_.Delete() 
    }
    $ZipArchive.Dispose()
    $FileStream.Close()
    $FileStream.Dispose()
}

$zipPath = 'C:\temp\temp.zip'
$fileInZip = 'folder/temp.csv'

$OldContent = ([Text.Encoding]::ASCII).GetString((Get-ZipEntryContent -ZipFilePath $zipPath -EntryPath $fileInZip)) 
$NewContent = $OldContent.Replace('FIND THIS','REPLACE WITH THIS')

Delete-ZipEntries $zipPath -WildcardNamesToDelete '*.csv'
Add-ZipEntry -ZipFilePath $zipPath -EntryPath $fileInZip -Content ([Text.Encoding]::ASCII).GetBytes($NewContent)
