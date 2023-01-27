Function DecodeJwtAccessToken([string]$token){#condensed from https://www.michev.info/Blog/Post/2140/decode-jwt-access-and-id-tokens-via-powershell
    if (!$token.Contains(".") -or !$token.StartsWith("eyJ")) { Write-Error "Invalid token" -ErrorAction Stop } #Per https://tools.ietf.org/html/rfc7519  - Access and ID tokens are fine, Refresh tokens will not work
    $decoded = $token.Split(".")[0..1]|%{#there's a third segment that's invalid Base64 in my samples
        While($_.Length %4){$_ += "=" }#pad each until length divisible by 4 to make valid Base64
        [Text.Encoding]::ASCII.GetString([Convert]::FromBase64String($_)) | ConvertFrom-Json
    }
    $decoded[1] | Get-Member -MemberType NoteProperty | ? {$_.Name -in @("exp","auth_time","nbf","iat")} | %{ #convert Unix times to local
        $decoded[1]."$($_.Name)" = ([datetime]"1/1/1970").AddSeconds([int] $decoded[1]."$($_.Name)").ToLocalTime() 
    }
    [pscustomobject]@{Header = $decoded[0];PayLoad = $decoded[1]}
}
