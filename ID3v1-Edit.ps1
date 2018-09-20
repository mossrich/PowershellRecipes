Function Get-ID3v1(
    [parameter(ValueFromPipeline)]
    [string]$path = ""){#Parses the last 128 bytes from an MP3 file 
    Process{
        $buf = New-Object byte[] (128)
        $strm = [System.IO.File]::OpenRead($path) #https://stackoverflow.com/questions/44462561/system-io-streamreader-vs-get-content-vs-system-io-file
        $strm.Seek( - ($buf.Length), [System.IO.SeekOrigin]::End) | Out-Null #ID3 bytes are at EOF
        $strm.Read($buf,0,$buf.Length) | Out-Null
        $strm.Close()
        $st = ([System.Text.Encoding]::ASCII).GetString($buf)
        If($st.Substring(0,3) -ne 'TAG'){Throw "No ID3v1 tag found in $path"}
        $ID3v1 = [ordered]@{}
        $ID3v1['Path'] = $path
        $ID3v1['Title'] = $st.Substring(3,30)
        $ID3v1['Artist'] = $st.Substring(33,30)
        $ID3v1['Album'] = $st.Substring(63,30)
        $ID3v1['Year'] = $st.Substring(93,4)
        If($buf[125] -eq 0){
            $ID3v1['Comment'] = $st.Substring(97,28)
            $ID3v1['Track'] = $buf[126]
        }Else{
            $ID3v1['Comment'] = $st.Substring(97,30)
            $ID3v1['Track'] = ""
        }
        $ID3v1['Genre'] = $buf[127]
        $ID3v1
    }
}

#Set the specified ID3v1 properties of a file by writing the last 128 bytes
Function Set-ID3v1( #All parameters except path are optional, they will not change if not specified. 
  [string]$path, #Full path to the file to be updated - wildcards not supported because [] are so stinky and it's only supposed to work on one file at a time. 
  [string]$Title = "`0", #a string containing only 0 indicates a parameter not specified. 
  [string]$Artist  = "`0",
  [string]$Album = "`0",
  [string]$Year = "`0",
  [string]$Comment = "`0",
  [int]$Track = -1,
  [int]$Genre = -1, 
  [bool]$BackDate=$true){#Preserve modification date, but add a minute to indicate it's newer than duplicates
    $CurrentModified = (Get-ChildItem -LiteralPath $path).LastWriteTime #use literalpath here to get only one file, even if it has []
    Try{
        $enc = [System.Text.Encoding]::ASCII #Probably wrong, but works occasionally. See https://stackoverflow.com/questions/9857727/text-encoding-in-id3v2-3-tags
        $currentID3Bytes = New-Object byte[] (128)
        $strm = New-Object System.IO.FileStream ($path,[System.IO.FileMode]::Open,[System.IO.FileAccess]::ReadWrite,[System.IO.FileShare]::None)
        $strm.Seek(-128,'End') | Out-Null #Basic ID3v1 info is 128 bytes from EOF
        $strm.Read($currentID3Bytes,0,$currentID3Bytes.Length) | Out-Null
        Write-Host "$path `nCurrentID3: $($enc.GetString($currentID3Bytes))"
        $strm.Seek(-128,'End') | Out-Null #Basic ID3v1 info is 128 bytes from EOF
        If($enc.GetString($currentID3Bytes[0..2]) -ne  'TAG'){
            Write-Warning "No existing ID3v1 found - adding to end of file"
            $strm.Seek(0,'End') 
            $currentID3Bytes = $enc.GetBytes(('TAG' + (' ' * (30 + 30 + 30 + 4 + 30)))) #Add a blank tag to the end of the file
            $currentID3Bytes += 255 #empty Genre
            $strm.Write($currentID3Bytes,0,$currentID3Bytes.length)
            $strm.Flush()
            $Strm.Close()
            $strm = New-Object System.IO.FileStream ($path,[System.IO.FileMode]::Open,[System.IO.FileAccess]::Write,[System.IO.FileShare]::None)
            $strm.Seek(-128,'End') 
        } 
        $strm.Seek(3,'Current') | Out-Null #skip over 'TAG' to get to the good stuff
        If($Title -eq "`0"){ $strm.Seek(30,'Current') | Out-Null} #Skip over
         Else{ $strm.Write($enc.GetBytes($Title.PadRight(30,' ').Substring(0,30)),0,30)  } #if specified, write 30 space-padded bytes to the stream
        If($Artist -eq "`0"){ $strm.Seek(30,'Current') | Out-Null} 
         Else {$strm.Write($enc.GetBytes($Artist.PadRight(30,' ').Substring(0,30)),0,30) }
        If($Album -eq "`0"){ $strm.Seek(30,'Current') | Out-Null} 
         Else{$strm.Write($enc.GetBytes($Album.PadRight(30,' ').Substring(0,30)),0,30)  }
        If($Year -eq "`0"){ $strm.Seek(4,'Current') | Out-Null} 
         Else {$strm.Write($enc.GetBytes($Year.PadRight(4,' ').Substring(0,4)),0,4) }
        If(($Track -ne -1) -or ($currentID3Bytes[125] -eq 0)) {$CommentMaxLen = 28}Else{$CommentMaxLen = 30} #If a Track is specified or present in the file, Comment is 28 chars
        If($Comment -eq "`0"){ $strm.Seek($CommentMaxLen,'Current') | Out-Null} 
         Else {$strm.Write($enc.GetBytes($Comment.PadRight($CommentMaxLen,' ').Substring(0,$CommentMaxLen)),0,$CommentMaxLen)  }
        If($Track -eq -1 ){$strm.Seek(2,'Current') | Out-Null}
         Else{$strm.Write(@(0,$Track),0,2)} #Track, if present, is preceded by a 0-byte to form the last two bytes of Comment
        If($Genre -ne -1){$strm.Write($Genre,0,1) | Out-Null} 
    }Catch{
        Write-Error $_.Exception.Message
    }Finally{
        If($strm){
            $strm.Flush()
            $strm.Close()
        }
    }
    If($BackDate){(Get-ChildItem -LiteralPath $path).LastWriteTime = $CurrentModified.AddMinutes(1)}
}
$path = (Get-ChildItem (Join-path $env:USERPROFILE "*.mp3") -Recurse | Select -First 1).FullName
Get-ID3v1 $path
Set-ID3v1 -path $path -Year 1996
Get-ID3v1 $path
