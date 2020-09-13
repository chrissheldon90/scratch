function Retrieve-NestedValue()
{
    [CmdletBinding()]
    param (
        [Parameter()][object]$object,
        [Parameter()][string]$key
    )
    $ErrorActionPreference = "Stop"
    $keySplit = ($key).Split("/")
    $objectConverted = $object | ConvertFrom-Json
    $value = "`$objectConverted"
    foreach($keyName in $keySplit) {
        
        $memberCheck = (Invoke-Expression $value) | Get-Member $keyName
        if(!$memberCheck) {
            Write-Error "There is no key: $keyName"
        }
        $value += ".$keyName"
        $valueExpression = Invoke-Expression $value
        if(!$valueExpression) {
            Write-Error "There is no key or value for key: $keyName"
        }
    }
    $valueExpression
}

Retrieve-NestedValue -object '{"a":{"b":{"c":"d"}}}' -key 'a/b/c'
