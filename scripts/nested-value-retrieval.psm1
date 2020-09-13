function Retrieve-NestedValue()
{
    [CmdletBinding()]
    param (
        [Parameter()][object]$object,
        [Parameter()][object]$keys
    )
    foreach($key in $keys)
    {
        $keySplit = ($key).Split("/")
        $objectConverted = $object | ConvertFrom-Json
        $value = "`$objectConverted"
        foreach($keyName in $keySplit) {
            
            $memberCheck = (Invoke-Expression $value) | Get-Member $keyName
            $value += ".$keyName"
            $valueExpression = Invoke-Expression $value
            if(!$memberCheck) {
                Write-Error "There is no key: $keyName"
            } elseif(!$valueExpression) {
                Write-Error "There is no key or value for key: $keyName"
            }
        }
        Write-Host $keyName":" $valueExpression
    }
}

#Example - Retrieve-NestedValue -object '{"a":{"b":{"c":"d"}}}' -keys @('a/b','a/b/c')
