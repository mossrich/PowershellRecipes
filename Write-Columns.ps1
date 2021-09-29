Function Write-Columns(
#Converts an array of columns with rows delimited by CRLF to an array of rows with cells padded to the width of the column    
    [string[]]$Columns, #an array of strings representing each column's contents
    [string] $RowDelim = "`r`n", #input rows will be split with this delimiter
    [string] $ColDelim = "│"  # alt-179, the vertical line box character.  This character will divide the output columns
){
    $SplitColumns = ($Columns | %{[PSCustomObject]@{Rows=($_ -split $RowDelim);Width=0}}) 
    $SplitColumns | %{$RowCount=0}{
        $_.Width = ($_.Rows | Measure-Object -Maximum -Property Length).Maximum
        If($_.Rows.Count -gt $RowCount){$RowCount = $_.Rows.Count}
    }
    $SplitColumns | %{#Pad rows in each column to the maximum
        For($r = $_.Rows.Count;$r -lt $rowcount; $r++){
            $_.Rows += ""
        }
    }
    For($r = 0;$r -lt $rowcount; $r++){
        ($SplitColumns | %{$_.Rows[$r].PadRight($_.Width," ")}) -join $ColDelim
    }
}


$Columns = @"
column 1
this is a longer line
shorter line
"@,
@"
column 2
this is the longest line
col 2 line 2
col 2 line 3
col 2 line 4
col 2 line 5
"@,
@"
column 3
col 3 line 2
col 3 line 3
col 3 line 4
"@ 

Write-Columns $Columns

<#output: 

column 1             │column 2                │column 3    
this is a longer line│this is the longest line│col 3 line 2
shorter line         │col 2 line 2            │col 3 line 3
                     │col 2 line 3            │col 3 line 4
                     │col 2 line 4            │            
                     │col 2 line 5            │            
#>
