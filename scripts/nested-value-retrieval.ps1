function Retrieve-NestedValue($object, $valueName)
{
    $valueNameReplace = ($valueName).Replace("/",".")
    $objectConverted = $object | ConvertFrom-Json
    Invoke-Expression "`$objectConverted.$valueNameReplace"
}

Retrieve-NestedValue '{"a":{"b":{"c":"d"}}}' 'a/b/c'

# $object = '{"a":{"b":{"c":"d"}}}'
# $valueName = "a/b/c"
