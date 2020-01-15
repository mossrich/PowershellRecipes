param( #Character replacement encryption - rotate by 13 - https://en.wikipedia.org/wiki/ROT13
    $StringToEncode = 'This is a sample string that will be rot13 encoded.'
)
($StringToEncode.ToCharArray() | %{ 
    [char]([int] $_ + [int]$(Switch -Regex ($_){'[A-M]'{13} '[N-Z]'{-13}}))
}) -join ''
