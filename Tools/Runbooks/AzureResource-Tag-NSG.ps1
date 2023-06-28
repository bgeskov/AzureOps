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
$AzResTagUnattached = @{"cleanup"="Unattached"}
$AzResTagMonitor = @{"cleanup"="Monitor"}

# Query Network Security Group with no attached Network Interface and no cleanup tag assigned
$AzureResources = Search-AzGraph -Query "where type == 'microsoft.network/networksecuritygroups' and properties.networkInterfaces == '' and tags.cleanup==''" -First 1000

# Loop through resources and tag them with Unattached
foreach ($CurrentAzRes in $AzureResources) {
    #### DEBUG - Write-host what resource it has found ####
    # write-host $CurrentAzRes.Name -BackgroundColor Yellow

    # Update Resource Tag
    Update-AzTag -ResourceId $CurrentAzRes.id -tag $AzResTagUnattached -Operation Merge
}

# Query Network Security Group with attached Network Interface and cleanup tag assigned
$AzureResources = Search-AzGraph -Query "where type == 'microsoft.network/networksecuritygroups' and properties.networkInterfaces != '' and tags.cleanup=~'unattached'" -First 1000

# Loop through resources and tag them with Monitor 
foreach ($CurrentAzRes in $AzureResources) {
    #### DEBUG - Write-host what resource it has found ####
    # write-host $AzRes.Name -BackgroundColor Blue

    # Update Resource Tag
    Update-AzTag -ResourceId $CurrentAzRes.id -tag $AzResTagMonitor -Operation Replace
}
