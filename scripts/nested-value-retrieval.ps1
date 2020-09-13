function Retrieve-NestedValue()
{
    [CmdletBinding()]
    param (
        [Parameter()][object]$object,
        [Parameter()][string]$key
    )
    $keySplit = ($key).Split("/")
    $objectConverted = $object | ConvertFrom-Json
    $value = "`$objectConverted"
    foreach($keyName in $keySplit) {
        $value += ".$keyName"
        $valueExpression = Invoke-Expression $value
        if(!$valueExpression) {
            Write-Error "There is no key or value for key: $keyName"
        }
    }
    $valueExpression
}

Retrieve-NestedValue -object '{"a":{"b":{"c":"d"}}}' -key 'a/b/c'

# $object = '{"a":{"b":{"c":"d"}}}'
# $key = "a/b/c"
