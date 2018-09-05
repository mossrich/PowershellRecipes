Param(
    [switch] $Reauthorize  #a refresh token will be used to retrieve a new accesstoken, unless this switch is present or there is no refresh token configured. ReAuthorize to switch profiles. 
)

Function GetConfig($Path = ".\GDataClient.json"){
    <#ScopeLists from https://developers.google.com/photos/library/guides/authentication-authorization
    https://www.googleapis.com/auth/photoslibrary.readonly Read access only. List items from the library and all albums, access all media items and list albums owned by the user, including those which have been shared with them. For albums shared by the user, share properties  are only returned if the .sharing scope has also been granted. The ShareInfo property for albums and the contributorInfo for mediaItems is only available if the .sharing scope has also been granted. For more information, see Share media.
    https://www.googleapis.com/auth/photoslibrary.appendonly Write access only. Acess to upload bytes, create media items, create albums, and add enrichments. Only allows new media to be created in the user's library and in albums created by the app.
    https://www.googleapis.com/auth/photoslibrary.readonly.appcreateddata  Read access to media items and albums created by the developer. For more information, see Access media items and List library contents, albums, and media items. Intended to be requested together with the .appendonly scope.
    https://www.googleapis.com/auth/photoslibrary Access to both the .appendonly and .readonly scopes. Doesn't include .sharing. 
    https://www.googleapis.com/auth/photoslibrary.sharing Access to sharing calls. Access to create an album, share it, upload media items to it, and join a shared album.
    https://www.googleapis.com/auth/photoslibrary.location Not yet available. Access to location information for media items. 
    #>
    #default - these values will not work. Edit GDataClient.json file and add application settings.   

    $DefaultJSON = @"
            {"installed":{
	         "client_id":"xxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com",
	         "project_id":"xxxx-xxxxxxxx-123456",
	         "auth_uri":"https://accounts.google.com/o/oauth2/auth",
	         "token_uri":"https://accounts.google.com/o/oauth2/token",
	         "auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs",
	         "client_secret":"xxxxxxxxxxxxxxxxxxxxxxxx",
	         "redirect_uris":["urn:ietf:wg:oauth:2.0:oob","http://localhost"]
	         },
	         "RefreshToken":  "",
	         "LastMediaItemsSync":  "",
             "ListenerPort": 58544,
	         "ScopeList": "openid%20profile%20https://www.googleapis.com/auth/calendar%20https://www.googleapis.com/auth/photoslibrary.readonly%20https://www.googleapis.com/auth/photoslibrary.sharing%20https://picasaweb.google.com/data/"      
            }
"@
    If(!(Test-Path $path)){$DefaultJSON | Set-Content $Path } #create the file if it doesn't exist
    $JSON = Get-Content $Path | Out-String
    Return $JSON | ConvertFrom-Json 
}

Function GetAuthorization ( $ClientID = $config.installed.client_id,$ClientSecret = $config.installed.client_secret,$authorizationEndpoint = $config.installed.auth_uri,
 $tokenEndpoint = $config.installed.token_uri,$ListenerPort=$config.ListenerPort, $scope=$config.ScopeList 
){ #request an authorization code from Google so the application can get data: opens a browser at the authurl, and a listener on the loopback port to get querystring variables from the authurl redirect. 
    $buffer = New-Object Byte[] 32 #reusable buffer for random bytes
    (New-Object System.Security.Cryptography.RNGCryptoServiceProvider).GetBytes($buffer) #initialize the random byte array with a random number generator
    $state = [System.Convert]::ToBase64String($buffer).Replace("+", "-").Replace("/", "_").Replace("=", "")  #URL friendly B64 Random byte array
    (New-Object System.Security.Cryptography.RNGCryptoServiceProvider).GetBytes($buffer) #re-initialize the array 
    $code_verifier = [System.Convert]::ToBase64String($buffer).Replace("+", "-").Replace("/", "_").Replace("=", "")  #URL friendly B64 Random byte array
    $sha256ByteArray = (New-Object System.Security.Cryptography.SHA256Managed).ComputeHash(([System.Text.Encoding]::ASCII).GetBytes($code_verifier)) #sha256 hash of $code_verifier byte array 
    $code_challenge = [System.Convert]::ToBase64String($sha256ByteArray).Replace("+", "-").Replace("/", "_").Replace("=", "") #URL friendly B64 byte array of hash
    $redirectURI = "http://{0}:{1}/" -f [System.Net.IPAddress]::Loopback, $ListenerPort
    $http = New-Object System.Net.HttpListener 
    $http.Prefixes.Add($redirectURI)
    $http.Start() #Run this script as admin the first time, or add the listener port (eg: 58544) UrlAcl in an Admin prompt:   netsh http add urlacl url="http://127.0.0.1:58544/" user="Everyone"
    $authorizationRequest = $authorizationEndpoint + "?response_type=code&scope=$scope&redirect_uri=$([System.Uri]::EscapeDataString($redirectURI))" + 
        "&client_id=$ClientID&state=$state&code_challenge=$code_challenge&code_challenge_method=S256"
    [System.Diagnostics.Process]::Start($authorizationRequest) #opens a browser window with the AuthorizeURL that requests permission and redirects back to localhost with a *code* in the querystring. Can/should we do this with IE automation?
    $context = $http.GetContext() #Need to use GetContextAsync? 
    $responseBytes = ([System.Text.Encoding]::ASCII).GetBytes("<html><head><meta http-equiv='refresh' content='10;url=https://google.com'></head><body>Please return to the app.</body></html>")
    $context.Response.ContentLength64 = $responseBytes.Length
    $context.Response.OutputStream.Write($responseBytes,0,$responseBytes.Length)
    $context.Response.OutputStream.Close()
    $http.Stop()
    $http.Close()     #TODO: clean up urlacl default port in an admin window after authorization is complete:  netsh http delete urlacl url="http://127.0.0.1:58544/" 
    $code = $context.Request.QueryString.Get("code")
    $incoming_state = $context.Request.QueryString.Get("state")
    $context.Request.QueryString | %{Write-Host ("$_={0}" -f $context.Request.QueryString.Get($_))}
    If($incoming_state -ne $state) { Write-Error "Invalid incoming state"}
    Return [pscustomobject]@{code=$code; code_verifier=$code_verifier;redirect_uri=$redirectURI}
}

Function Set-SessionDataFolder{#TODO: what happens for accesstoken timeout?
    If($global:accessToken){
        Try{
            $userInfo = Invoke-WebRequest -Uri "https://www.googleapis.com/oauth2/v3/userinfo" -Method Get -ContentType "application/x-www-form-urlencoded" -Headers @{"Authorization" = "Bearer $AccessToken"}
            #set up folder for user based on $userInfo
            $sub = ($userInfo.Content | ConvertFrom-Json).sub
            $Global:DataFolder = ".\GDataClient.$sub\"
            If(!(Test-Path $Global:DataFolder)){New-Item $Global:DataFolder -ItemType Directory}
            $userInfo.Content | Set-Content "$Global:DataFolder\UserInfo.json"
            Return "Authenticated"
        }Catch{}
    }
}

Function Set-SessionAccessToken{ #gets a current Access Token from the token_uri
    If(($config.RefreshToken.Length -eq 0) -or $Reauthorize){ #Re-authorize and get a new refresh token if never authorized or if the switch is present
        $authcode = GetAuthorization
        $tokenRequestBody = "code=$($authcode.code)&redirect_uri=$([System.Uri]::EscapeDataString($authcode.redirect_uri))&client_id=$($config.installed.client_id)&code_verifier=$($authcode.code_verifier)" + 
            "&client_secret=$($config.installed.client_secret)&scope=&grant_type=authorization_code" 
        $TokenResponse = Invoke-WebRequest -Uri $config.installed.token_uri -Method Post -ContentType "application/x-www-form-urlencoded" -Body $tokenRequestBody -Headers @{"Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"}
        $global:accessToken = ($TokenResponse | ConvertFrom-Json).access_token
        $config.RefreshToken = ($TokenResponse | ConvertFrom-Json).refresh_token 
        #persist the refresh token to config
        $config | ConvertTo-Json -Depth 6 | Set-Content .\GdataClient.json
    }Else{ #retrieve a current auth token from the configured refresh token
        $tokenRequestBody = "client_id=$($config.installed.client_id)&client_secret=$($config.installed.client_secret)&scope=&grant_type=refresh_token&refresh_token=$($config.RefreshToken)"    
        $TokenResponse = Invoke-WebRequest -Uri $config.installed.token_uri -Method Post -ContentType "application/x-www-form-urlencoded" -Body $tokenRequestBody -Headers @{"Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"}
        $global:accessToken = ($TokenResponse | ConvertFrom-Json).access_token
    }
}

Function Get-PagedCollection($PagedDataUri="https://photoslibrary.googleapis.com/v1/albums",$ResponseCollectionName = 'albums', 
    $RequestBody = '', $pageSize = 50, $retry = 3){#Pagination:  https://developers.google.com/photos/library/guides/list
    $collection = @()
    Do{ #issue request 
        $PagedDataResponse = $null
        $uri = $PagedDataUri + $( If($NextPageToken){"?pageToken=$NextPageToken"} <#Else {"?pageSize=$pageSize"}#> ) #PageSize is not working
        $retries = 0 
        While(($retries -lt $retry) -and ($PagedDataResponse -eq $null)){ #sometimes paged albums return 401 unauthorized
            Try {
                If($RequestBody.Length -gt 0){
                    $PagedDataResponse = Invoke-WebRequest -Uri $Uri -Method Post -Body $RequestBody -ContentType "application/json" -Headers @{"Authorization" = "Bearer $global:AccessToken"}
                }Else{
                    $PagedDataResponse = Invoke-WebRequest -Uri $Uri -Method Get -ContentType "application/x-www-form-urlencoded" -Headers @{"Authorization" = "Bearer $global:AccessToken"}
                }
            }catch{
                $retries += 1
                Write-Warning "Request $retries for $Uri failed"
                Write-Warning $_.Exception 
                Sleep 2
            }
        }
        If($PagedDataResponse){
            $content = ($PagedDataResponse.Content | ConvertFrom-Json)
            Write-Host "Retrieved $($content.($ResponseCollectionName).Count) $ResponseCollectionName"
            $NextPageToken = If($content.nextPageToken){$content.nextPageToken}Else{$null}
            $Collection += $content.($ResponseCollectionName) 
        }Else{
            Throw "Failed to retrieve $uri"
        }
    }While($NextPageToken)
    $Collection | Sort id
}

Function Get-NewMediaItemList($NewerThanOrOn = (Get-Date), $OlderThan = (get-date).AddDays(1), 
    $Uri = "https://photoslibrary.googleapis.com/v1/mediaItems:search", $ResponseCollectionName = 'mediaItems', $pageSize = 50, $retry = 3){
$filter = @"
 {"pageSize": 10,"filters":{"dateFilter":{
       "ranges":[ {"startDate": {$('"day":{0},"month":{1},"year":{2}' -f $NewerThanOrOn.Day,$NewerThanOrOn.Month,$NewerThanOrOn.Year )},  
                   "endDate": {$('"day":{0},"month":{1},"year":{2}' -f $OlderThan.Day,$OlderThan.Month,$OlderThan.Year )}} ]
     }
   }
 }
"@
    Write-Host "Filter $filter"
    Return Get-PagedCollection -PagedDataUri $Uri -RequestBody $filter -ResponseCollectionName $ResponseCollectionName
}
#https://content-photoslibrary.googleapis.com/v1/mediaItems:search?alt=json&key=AIzaSyD-a9IF8KKYgoC3cpgS-Al7hLQDbugrDcw



Push-Location $PSScriptRoot
$Global:config = GetConfig .\GdataClient.json
Set-SessionAccessToken 
Set-SessionDataFolder
If(!$Global:config.LastMediaItemsSync){ #if we haven't synchronized mediaItems
    Get-PagedCollection 'https://photoslibrary.googleapis.com/v1/albums' 'albums' | ConvertTo-Json | Set-Content "$Global:DataFolder\albums.json"
    Get-PagedCollection 'https://photoslibrary.googleapis.com/v1/sharedAlbums' 'sharedAlbums' | ConvertTo-Json | Set-Content "$Global:DataFolder\sharedAlbums.json"
    Get-PagedCollection 'https://photoslibrary.googleapis.com/v1/mediaItems' 'mediaItems' -pageSize 200 | ConvertTo-Json | Set-Content "$Global:DataFolder\mediaItems.json"
}Else{#synch again 
    $mediaItemsCollection = get-Content "$Global:DataFolder\mediaItems.json" | ConvertFrom-Json
    $newMediaItemsCollection = Get-NewMediaItemList -NewerThanOrOn ([datetime]::Parse($Global:config.LastMediaItemsSync))
    $newMediaItemsCollection.Count
    #TODO: add non-matched new items to the collection, and store it, then store the LastMediaItemsSync
    #$newMediaItemsCollection | Compare-Object $mediaItemsCollection -PassThru -Property id -ExcludeDifferent -IncludeEqual
    #TODO: remove deleted items from the collection, then the filesystem
    #TODO: download each image/video that doesn't exist in the filesystem
}



#TODO: Write the local album cache if absent or older than server 
#$AlbumlistGPhotos.Content | Set-Content "$DataFolder\AlbumList.json" #TODO: check for newer on server


<#Picasa API - returns XML by default and has querystring filters in the querystring
Album list      GET https://picasaweb.google.com/data/feed/api/user/default 
Album contents  GET https://picasaweb.google.com/data/entry/api/user/default/albumid/{id}
#$AlbumlistPicasa = Invoke-WebRequest -Uri "https://picasaweb.google.com/data/" -Method Get -ContentType "application/x-www-form-urlencoded" -Headers @{"Authorization" = "Bearer " + $AccessToken}
GET /data/feed/api/user/$sub?alt=json&kind=photo&fields=entry[xs:dateTime(published)>=xs:dateTime('2018-01-01T00:00:00')] 
#>

#TODO: Download images from each album - with datestamp, contributor as file name 
#TODO: Download images not in an album
#TODO: Allow sorting into albums locally
#TODO: Synch changes to GPhotos server
#    - delete from local and server 
#    - add to album
#    - Rename local and server
