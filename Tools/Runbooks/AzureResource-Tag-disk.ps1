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

# Query disk resources that is not managedBy anything and has no cleanup tag assigned
$AzureResources = Search-AzGraph -Query "where type == 'microsoft.compute/disks' and tags.cleanup=='' and managedBy == ''" -First 1000

# Loop through resources and tag them with Unattached
foreach ($CurrentAzRes in $AzureResources) {
    #### DEBUG - Write-host what resource it has found ####
    # write-host $CurrentAzRes.Name -BackgroundColor Yellow

    # Update Resource Tag
    Update-AzTag -ResourceId $CurrentAzRes.id -tag $AzResTagUnattached -Operation Merge
}

# Query disk resources that is managedBy anything and has cleanup tag assigned
$AzureResources = Search-AzGraph -Query "where type == 'microsoft.compute/disks' and tags.cleanup=~'unattached' and managedBy != ''" -First 1000

# Loop through resources and tag them with Monitor 
foreach ($CurrentAzRes in $AzureResources) {
    #### DEBUG - Write-host what resource it has found ####
    # write-host $AzRes.Name -BackgroundColor Blue

    # Update Resource Tag
    Update-AzTag -ResourceId $CurrentAzRes.id -tag $AzResTagMonitor -Operation Replace
}