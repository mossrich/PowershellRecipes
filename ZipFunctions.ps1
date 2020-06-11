@( 'System.IO.Compression','System.IO.Compression.FileSystem') | % { [void][System.Reflection.Assembly]::LoadWithPartialName($_) }

function Get-ZipEntryContent(#returns the bytes of the first matching entry 
  [string] $ZipFilePath, #optional - specify a ZipStream or path 
  [IO.Stream] $ZipStream = (New-Object IO.FileStream($ZipFilePath, [IO.FileMode]::Open)),
  [string] $EntryPath){
    $ZipArchive = New-Object IO.Compression.ZipArchive($ZipStream, [IO.Compression.ZipArchiveMode]::Read)
    $buf = New-Object byte[] (0) #return an empty byte array if not found
    $ZipArchive.GetEntry($EntryPath) | ?{$_} | %{ #GetEntry returns first matching entry or null if there is no match
        $buf = New-Object byte[] ($_.Length)
        Write-Verbose "     reading: $($_.Name)"
        $_.Open().Read($buf,0,$buf.Length)
    }
    $ZipArchive.Dispose()
    $ZipStream.Close()
    $ZipStream.Dispose()
    return $buf 
}

function Delete-ZipEntries(
  [string] $ZipFilePath, #optional - specify a ZipStream or path 
  [IO.Stream] $ZipStream = (New-Object IO.FileStream($ZipFilePath, [IO.FileMode]::Open)),
  [string] $WildcardNamesToDelete){
    $ZipArchive = New-Object IO.Compression.ZipArchive($ZipStream, [IO.Compression.ZipArchiveMode]::Read)
    ($zip.Entries | ? { $_.Name -like $WildcardNamesToDelete }) | % { 
        Write-Verbose "     Deleting: $($_.Name)"
        $_.Delete() 
    }
    $ZipArchive.Dispose()
    $ZipStream.Close()
    $ZipStream.Dispose()
}

function Add-ZipEntry(#Adds an entry to the $ZipStream. Sample call: Add-ZipEntry -ZipFilePath "$PSScriptRoot\temp.zip" -EntryPath Test.xml -Content ([text.encoding]::UTF8.GetBytes("Testing"))
  [string] $ZipFilePath, #optional - specify a ZipStream or path 
  [IO.Stream] $ZipStream = (New-Object IO.FileStream($ZipFilePath, [IO.FileMode]::OpenOrCreate)),
  [string] $EntryPath, 
  [byte[]] $Content, 
  [switch] $OverWrite, #if specified, will not create a second copy of an existing entry 
  [switch] $PassThru ){#return a copy of $ZipStream
    $ZipArchive = New-Object IO.Compression.ZipArchive($ZipStream, [IO.Compression.ZipArchiveMode]::Update, $true)
    $ExistingEntry = $ZipArchive.GetEntry($EntryPath) | ?{$_} 
    If($OverWrite -and $ExistingEntry){
        Write-Verbose "    deleting existing $($ExistingEntry.FullName)"
        $ExistingEntry.Delete()
    }
    $Entry = $ZipArchive.CreateEntry($EntryPath)
    $WriteStream = New-Object System.IO.StreamWriter($Entry.Open())
    $WriteStream.Write($Content,0,$Content.Length)
    $WriteStream.Flush()
    $WriteStream.Dispose()
    $ZipArchive.Dispose()
    If($PassThru){
        $OutStream = New-Object System.IO.MemoryStream
        $ZipStream.Seek(0, 'Begin') | Out-Null
        $ZipStream.CopyTo($OutStream)
    }
    $ZipStream.Close()
    $ZipStream.Dispose()
    If($PassThru){$OutStream}
}

$path = "$PSScriptRoot\temp.zip"
Add-ZipEntry  -ZipFilePath $path -EntryPath Test.xml -Content ([text.encoding]::UTF8.GetBytes("<xml><test>1</test>"))
$bytes = Get-ZipEntryContent -ZipStream (New-Object IO.FileStream($path, [IO.FileMode]::Open)) -EntryPath 'Test.xml'
[text.encoding]::UTF8.GetString($bytes)

$NewZipStream = Add-ZipEntry -ZipStream (New-Object IO.MemoryStream) -EntryPath Test.xml -Content ([text.encoding]::UTF8.GetBytes("<xml><test>1</test>")) -PassThru
$bytes = Get-ZipEntryContent -ZipStream $NewZipStream -EntryPath 'Test.xml'
[text.encoding]::UTF8.GetString($bytes)
