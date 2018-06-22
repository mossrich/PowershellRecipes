Function DecodeJwtAccessToken([string]$token){#condensed from https://www.michev.info/Blog/Post/2140/decode-jwt-access-and-id-tokens-via-powershell
    if (!$token.Contains(".") -or !$token.StartsWith("eyJ")) { Write-Error "Invalid token" -ErrorAction Stop } #Per https://tools.ietf.org/html/rfc7519  - Access and ID tokens are fine, Refresh tokens will not work
    $header =  $token.Split(".")[0] 
    $payload = $token.Split(".")[1] 
    While($header.Length %4){$header += "=" }#pad until length divisible by 4
    While($payload.Length %4){$payload += "=" }
    Write-Verbose "Header: $($token.Split(".")[0])`nPadded:$Header`nPayload: $($token.Split(".")[1]) `nPadded:  $payload"
    $decoded = [pscustomobject]@{
        Header = ([System.Text.Encoding]::ASCII.GetString([system.convert]::FromBase64String($header)) | ConvertFrom-Json);
        PayLoad = ([System.Text.Encoding]::ASCII.GetString([system.convert]::FromBase64String($payload)) | ConvertFrom-Json);
    }
    $decoded.Payload | Get-Member -MemberType NoteProperty | %{ #convert Unix times to local
        If(@("exp","auth_time","nbf","iat").Contains($_.Name)){
           $decoded.Payload."$($_.Name)" = ([datetime]"1/1/1970").AddSeconds([int] $decoded.Payload."$($_.Name)").ToLocalTime() 
        }
    }
    $decoded
}
