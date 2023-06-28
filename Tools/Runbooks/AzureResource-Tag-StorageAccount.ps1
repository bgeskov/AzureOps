# Code running on Azure Automation Account

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
$AzResTagMonitorEmpty = @{"cleanup"="Monitor-Empty"}
$AzResTagMonitorLowUse = @{"cleanup"="Monitor-LowUse"}

# Set a date value 7 days back
$StartDate = $(get-date).AddDays(-7)

# Get all subscriptions that is enabled
$Subs = Get-AzSubscription | Where-Object State -eq Enabled

# Filter out Subscriptions with names like these
$SkipSubs = @('Azure Pass*','*Active Directory','MSDN*')

$SkipSubsId = foreach ($SkipSub in $SkipSubs) {
    $($Subs | where-object {$_.Name -like $SkipSub}).Id
}

# Loop though Subcriptions that are not on the skip list
foreach ($sub in $Subs | Where-Object Id -notin $SkipSubsId) {

    # Set the current subscription to the context
    $sub | Set-AzContext

    # Get all storage accounts
    $AzStorageAccounts = Get-AzStorageAccount

    # Loop through found storage accounts 
    foreach ($StorageAccount in $AzStorageAccounts) {

        # Create a Powershell Object to store values for later sorting
        $obj = "" | Select-Object Share,Container,Queue,Table

        # Set Storage context
        $ctx = $StorageAccount.Context
        
        # Try get storage share
        try {
            $AzSS = Get-AzStorageShare -Context $ctx -ErrorAction Stop #| Select-Object -First 5

            # Check if there is one
            if ($AzSS) {
                $obj.Share = $true
            } else {
                $obj.Share = $false
            }
        }
        catch {
            $obj.Share = "Error"
        }

        # Try get storage container
        try {
            $AzSC = Get-AzStorageContainer -Context $ctx -ErrorAction Stop | Select-Object -First 5

            # Check if there is one
            if ($AzSC) {
                $obj.Container = $true
            } else {
                $obj.Container = $false
            }
        }
        catch {
            $obj.Container = "Error"
        }
        
        # Try get storage Queue
        try {
            $AzSQ = Get-AzStorageQueue -Context $ctx -ErrorAction Stop | Select-Object -First 5

            # Check if there is one
            if ($AzSQ) {
                $obj.Queue = $true
            } else {
                $obj.Queue = $false
            }
        }
        catch {
            $obj.Queue = "Error"
        }
        
        # Try get storage Table
        try {
            $AzST = Get-AzStorageTable -Context $ctx -ErrorAction Stop  | Select-Object -First 5

            # Check if there is one
            if ($AzST) {
                $obj.Table = $true
            } else {
                $obj.Table = $false
            }
        }
        catch {
            $obj.Table = "Error"
        }

        # Create a Powershell Object to store values for later sorting
        $IOobj = "" | Select-Object StoredDataNow,StoredDataMax,StoredDataMin,StoredDataAvg,EgressMax,EgressMin,EgressAvg,IngressMax,IngressMin,IngressAvg
        
        # Measure UsedCapacity over 7 days
        $dataCapData = Get-AzMetric -ResourceId $StorageAccount.id -MetricName "UsedCapacity" -StartTime $StartDate -InformationAction SilentlyContinue -WarningAction SilentlyContinue
        
        # Store the data in custom object
        $IOobj.StoredDataMax = $($dataCapData.Data.Average | Measure-Object -Maximum).Maximum
        $IOobj.StoredDataMin = $($dataCapData.Data.Average | Measure-Object -Minimum).Minimum
        $IOobj.StoredDataAvg = $($dataCapData.Data.Average | Measure-Object -Average).Average

        # Measure UsedCapacity over 2 hours = To get the storage data now
        $dataCapData = Get-AzMetric -ResourceId $StorageAccount.id -MetricName "UsedCapacity" -StartTime $(get-date).AddHours(-2) -InformationAction SilentlyContinue -WarningAction SilentlyContinue

        # Store the data in custom object
        $IOobj.StoredDataNow = $($dataCapData.Data | Select-Object -Last 1).Average

        # Filter out from stored data
        if(($IOobj.StoredDataNow -lt 4000000) -and ($IOobj.StoredDataMax -lt 4000000) -and ($IOobj.StoredDataNow -ne $null)) {

            # Measure Egress over 7 days
            $dataEgress = Get-AzMetric -ResourceId $StorageAccount.id -MetricName "Egress" -StartTime $StartDate -TimeGrain 00:01:00 -InformationAction SilentlyContinue -WarningAction SilentlyContinue
            
            # Store the data in custom object
            $IOobj.EgressMax = $($dataEgress.Data.Total | Measure-Object -Maximum).Maximum
            $IOobj.EgressMin = $($dataEgress.Data.Total | Measure-Object -Minimum).Minimum
            $IOobj.EgressAvg = $($dataEgress.Data.Total | Measure-Object -Average).Average
            
            # Filter out from Egress data
            if (($IOobj.EgressMax -lt 7000) -and ($IOobj.EgressMin -eq 0) -and ($IOobj.EgressAvg -lt 200)) {
                
                # Measure Ingress over 7 days
                $dataIngress = Get-AzMetric -ResourceId $StorageAccount.id -MetricName "Ingress" -StartTime $StartDate -TimeGrain 00:01:00 -InformationAction SilentlyContinue -WarningAction SilentlyContinue
        
                # Store the data in custom object
                $IOobj.IngressMax = $($dataIngress.Data.Total | Measure-Object -Maximum).Maximum
                $IOobj.IngressMin = $($dataIngress.Data.Total | Measure-Object -Minimum).Minimum
                $IOobj.IngressAvg = $($dataIngress.Data.Total | Measure-Object -Average).Average

                # Filter out from Ingress data
                if (($IOobj.IngressMax -lt 70000) -and ($IOobj.IngressMin -eq 0) -and ($IOobj.IngressAvg -lt 750)) {
                    
                    # Filter if there is a place to store data
                    if ($obj.Share -eq $false -and $obj.Container -eq $false -and $obj.Queue -eq $false -and $obj.Table -eq $false ) {
                        # If there is not a cleanup tag
                        if(!$StorageAccount.tags.ContainsKey("cleanup")) {
                            write-host $obj.StorageAccountName -BackgroundColor Yellow
                            Update-AzTag -ResourceId $StorageAccount.Id -tag $AzResTagMonitorEmpty -Operation Merge
                        }
                    } else {
                        # If there is not a cleanup tag
                        if(!$StorageAccount.tags.ContainsKey("cleanup")) {
                            write-host $obj.StorageAccountName -BackgroundColor Green
                            Update-AzTag -ResourceId $StorageAccount.Id -tag $AzResTagMonitorLowUse -Operation Merge
                        }
                    }
                }
            }
        }        
    }
}
