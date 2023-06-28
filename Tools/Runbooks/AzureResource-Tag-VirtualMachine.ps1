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
$AzResTagMonitorLowUse = @{"cleanup"="Monitor-LowUse"}

# Create a -7 days date value
$StartDate7 = $(get-date).AddDays(-7)

# Get Subscription where state is Enabled
$Subs = Get-AzSubscription | Where-Object State -eq Enabled

# Skip list Subscriptions with names
$SkipSubs = @('Azure Pass*','*Active Directory','MSDN*')

# Loop through skip subs id
$SkipSubsId = foreach ($SkipSub in $SkipSubs) {
    $($Subs | where-object {$_.Name -like $SkipSub}).Id
}

# Loop through subs that is not in skip list
foreach ($sub in $Subs | Where-Object Id -notin $SkipSubsId) {

    # Set the current subscription to the context
    $sub | Set-AzContext

    # Get VM's that is running
    $VMs = get-AzVM -Status | Where-Object {$_.PowerState -eq "VM running"}

    # Loop through the VM's
    foreach ($VM in $VMs) {

        # Create custom object
        $VMobj = "" | Select-Object CPU7max, CPU7min, CPU7avg

        # Get VM metrics over 7 days
        $VMdataCPU = Get-AzMetric -ResourceId $VM.Id -MetricName "Percentage CPU" -StartTime $StartDate7 -TimeGrain 00:01:00 -InformationAction SilentlyContinue -WarningAction SilentlyContinue
        
        $VMobj.CPU7max = $($VMdataCPU.Data.Average | Measure-Object -Maximum).Maximum
        $VMobj.CPU7min = $($VMdataCPU.Data.Average | Measure-Object -Minimum).Minimum
        $VMobj.CPU7avg = $($VMdataCPU.Data.Average | Measure-Object -Average).Average

        # if VM CPU average is under 10 
        if ($VMobj.CPU7avg -lt 10) {

            # If VM not allready contains cleanup tag
            if(!$VM.tags.ContainsKey("cleanup")) {

                # Set tag on low usage VM
                Update-AzTag -ResourceId $VM.Id -tag $AzResTagMonitorLowUse -Operation Merge
            }
            
        }

    }
        
}