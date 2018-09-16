Function Get-ID3v1([string]$path = ""){#Parses the last 128 bytes from an MP3 file 
    $buf = New-Object byte[] (128)
    $strm = [System.IO.File]::OpenRead($path)
    $strm.Seek( - ($buf.Length), [System.IO.SeekOrigin]::End) | Out-Null
    $strm.Read($buf,0,$buf.Length) | Out-Null
    $strm.Close()
    $st = ([System.Text.Encoding]::ASCII).GetString($buf)
    If($st.Substring(0,3).Trim() -ne 'TAG'){Throw "No ID3 tag found"}
    $ID3v1 = [ordered]@{}
    $ID3v1['Path'] = $path
    $ID3v1['Title'] = $st.Substring(3,30).Trim()
    $ID3v1['Artist'] = $st.Substring(33,30).Trim()
    $ID3v1['Album'] = $st.Substring(63,30).Trim()
    $ID3v1['Year'] = $st.Substring(93,4).Trim()
    If($buf[125] -eq 0){
        $ID3v1['Comment'] = $st.Substring(97,28).Trim()
        $ID3v1['Track'] = $buf[126]
    }Else{
        $ID3v1['Comment'] = $st.Substring(97,30).Trim()
        $ID3v1['Track'] = ""
    }
    $ID3v1['Genre'] = $buf[127]
    $ID3v1
}

#Set the specified ID3v1 properties of a file by writing the last 128 bytes
Function Set-ID3v1( #All parameters except path are optional, they will not change if not specified. 
  [string]$path, #Full path to the file to be updated
  [string]$Title = '[Not Specified]',
  [string]$Artist  = '[Not Specified]',
  [string]$Album = '[Not Specified]',
  [string]$Year = '[Not Specified]',
  [string]$Comment = '[Not Specified]',
  [int]$Track = -1,
  [int]$Genre = -1, 
  [bool]$BackDate=$true){#Preserve modification date, but add a minute to indicate it's newer than duplicates
    $CurrentModified = (Get-ChildItem $path).LastWriteTime    
    Try{
        $enc = [System.Text.Encoding]::ASCII #Probably wrong, but works occasionally. See https://stackoverflow.com/questions/9857727/text-encoding-in-id3v2-3-tags
        $currentID3Bytes = New-Object byte[] (128)
        $ReadStrm = [System.IO.File]::OpenRead($path)
        $ReadStrm.Seek( - ($currentID3Bytes.Length), [System.IO.SeekOrigin]::End) | Out-Null
        $ReadStrm.Read($currentID3Bytes,0,$currentID3Bytes.Length) | Out-Null
        $ReadStrm.Close()
        $strm = [System.IO.File]::OpenWrite($path) 
        $strm.Seek(-128,'End') | Out-Null #Basic ID3v1 info is 128 bytes from EOF
        If($enc.GetString($currentID3Bytes[0..2]) -eq  'TAG'){$strm.Seek(3,'Current') | Out-Null}#skip over 'TAG' to get to the good stuff
         Else {Throw "No existing ID3 found"} 
        If($Title -eq '[Not Specified]'){ $strm.Seek(30,'Current') | Out-Null} #Skip over
         Else{ $strm.Write($enc.GetBytes($Title.PadRight(30,' ').Substring(0,30)),0,30)  } #if specified, write 30 space-padded bytes to the stream
        If($Artist -eq '[Not Specified]'){ $strm.Seek(30,'Current') | Out-Null} 
         Else {$strm.Write($enc.GetBytes($Artist.PadRight(30,' ').Substring(0,30)),0,30) }
        If($Album -eq '[Not Specified]'){ $strm.Seek(30,'Current') | Out-Null} 
         Else{$strm.Write($enc.GetBytes($Album.PadRight(30,' ').Substring(0,30)),0,30)  }
        If($Year -eq '[Not Specified]'){ $strm.Seek(4,'Current') | Out-Null} 
         Else {$strm.Write($enc.GetBytes($Year.PadRight(4,' ').Substring(0,4)),0,4) }
        #HACK: assumes there is a track and truncates comment to 28 chars - fails to overwrite last bytes if track is not set and previous comment was 30 chars
        If($Comment -eq '[Not Specified]'){ $strm.Seek(28,'Current') | Out-Null} 
         Else {$strm.Write($enc.GetBytes($Comment.PadRight(28,' ').Substring(0,28)),0,28)  }
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
    If($BackDate){(Get-ChildItem $path).LastWriteTime = $CurrentModified.AddMinutes(1)}
}

$path = Get-ChildItem (Join-path $env:USERPROFILE "*.mp3") -Recurse | Select -First 1
Set-ID3v1 -path $path -Genre 12
Get-ID3v1 $path
