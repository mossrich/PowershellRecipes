#Gets item properties from Shell.Application COM Object - those that will be visible in Windows Explorer 
Param(
    $FolderName = 'C:\Windows\Fonts',
    $ItemName = 'Arial',
    $PropertyName = 'Font style' #$null #Get all properties
)
$ns =  (New-Object -ComObject Shell.Application).NameSpace($FolderName); 
$PropertyList = $(#the list of properties this folder supports in the shell (usually a superset of the properties shown in UI) 
    $i=0
    do { #assumes that all properties are contiguous and start with 0 
        [pscustomobject]@{index=$i; name=$ns.GetDetailsOf($ns.Items,$i++)} 
    } while ($ns.GetDetailsOf($ns.Items,$i)) 
)
$item = $ns.ParseName($ItemName) # Items() | ?{ $_.Name -eq $ItemName} #look up by name 
$PropertyList | ? {$PropertyName -eq $null -or $_.name -eq $PropertyName}| %{ #iterate through all properties in the namespace, and get values for the item
    [pscustomobject] @{
        ItemName = $item.Name
        Index = $_.index
        PropertyName = $_.name
        Value = $ns.GetDetailsOf($item,$_.index)
    }
}
$item.Verbs() | Format-Table
