<# Retrieve Specific MetaData Information - Instructions
1. Login to the instance you want to retrieve metadata for
2. Copy this and 'nested-value-retrieval.psm1' to a scripts folder.
3. Open a terminal (Powershell Core is required)
4. Run Powershell Core (psm1.exe)
5. Set the $key variable to the key of the metadata key you want to retrieve (If this is a nested value use /) - Example 'compute/securityProfile/secureBootEnabled"
6. Run this script
#>

$key = "compute/securityProfile/secureBootEnabled"
import-module ./scripts/nested-value-retrieval.psm1
$metadata = Invoke-RestMethod -Method GET -Uri "http://169.254.169.254/metadata/instance?api-version=2019-03-11" -Headers @{"Metadata"="True"}
Retrieve-NestedValue -object $metadata -key $key