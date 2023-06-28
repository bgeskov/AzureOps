# Code running on Azure Automation Account
# Module added:
## Az.ResourceGraph

# Try to login as system identity
try
{
    "Logging in to Azure..."
    Connect-AzAccount -Identity
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

# Create Standard tags
$AzResTagUnused = @{"cleanup"="Unused"}
$AzResTagMonitor = @{"cleanup"="Monitor"}

# Query virtual network with no cleanup tag assigned
$AzureResources = Search-AzGraph -Query "where type == 'microsoft.network/virtualnetworks' and tags.cleanup==''" -First 1000

# Loop through resources and tag them with Unused
foreach ($CurrentAzRes in $AzureResources) {

    if(!$CurrentAzRes.properties.subnets.properties.ipConfigurations) {
        #### DEBUG - Write-host what resource it has found ####
        # write-host $CurrentAzRes.Name -BackgroundColor Yellow

        # Update Resource Tag
        Update-AzTag -ResourceId $CurrentAzRes.id -tag $AzResTagUnused -Operation Merge
    }
}

# Query virtual network with cleanup tag assigned
$AzureResources = Search-AzGraph -Query "where type == 'microsoft.network/virtualnetworks' and tags.cleanup=~'unused'" -First 1000

# Loop through resources and tag them with Monitor 
foreach ($CurrentAzRes in $AzureResources) {

    if($CurrentAzRes.properties.subnets.properties.ipConfigurations) {
        #### DEBUG - Write-host what resource it has found ####
        # write-host $AzRes.Name -BackgroundColor Blue

        # Update Resource Tag
        Update-AzTag -ResourceId $CurrentAzRes.id -tag $AzResTagMonitor -Operation Replace
    }
}
