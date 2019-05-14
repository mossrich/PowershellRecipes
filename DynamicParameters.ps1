function Test-DynamicValidateSet { #Original:  https://martin77s.wordpress.com/2014/06/09/dynamic-validateset-in-a-dynamic-parameter/
    [CmdletBinding()]
    Param(# Any other parameters can go here
    ) 
    DynamicParam {
        $ParameterName = 'Path' 
        $arrSet = Get-ChildItem -Path . -Directory | Select-Object -ExpandProperty FullName
        $RuntimeParameterDictionary = New-Object Management.Automation.RuntimeDefinedParameterDictionary 
        $RuntimeParameterDictionary.Add($ParameterName, (New-Object Management.Automation.RuntimeDefinedParameter($ParameterName, [string], @( #attributes
              (New-Object Management.Automation.ParameterAttribute -Property @{Mandatory = $true; Position = 1}), 
              (New-Object Management.Automation.ValidateSetAttribute($arrSet)) 
        ))))
        <# doesn't work
        return ( New-Object Management.Automation.RuntimeDefinedParameterDictionary @{"$ParameterName" = (New-Object Management.Automation.RuntimeDefinedParameter($ParameterName, [string], @( #attributes
              (New-Object Management.Automation.ParameterAttribute -Property @{Mandatory = $true; Position = 1}), 
              (New-Object Management.Automation.ValidateSetAttribute($arrSet)) 
        )))} )
        #>
        return $RuntimeParameterDictionary
    }
    begin {        
        $Path = $PsBoundParameters[$ParameterName] # Bind the parameter to a friendly variable
    }
    process {# Your code goes here
        dir -Path $Path 
    }
}
