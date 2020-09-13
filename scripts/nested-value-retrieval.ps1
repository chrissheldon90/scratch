function Retrieve-NestedValue()
{
    [CmdletBinding()]
    param (
        [Parameter()][object]$object,
        [Parameter()][string]$key
    )
    $keyReplace = ($key).Replace("/",".")
    $objectConverted = $object | ConvertFrom-Json

    $value = Invoke-Expression "`$objectConverted.$keyReplace"
    if(!$value) {
        Write-Host "There is no value for key: $key"
    }
    return $value
}

Retrieve-NestedValue -object '{"a":{"b":{"c":"d"}}}' -key 'a/b/c'

# $object = '{"a":{"b":{"c":"d"}}}'
# $key = "a/b/c"
