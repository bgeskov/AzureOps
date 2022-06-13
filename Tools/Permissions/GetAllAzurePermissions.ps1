$PermissionsCollection = New-Object System.Collections.ArrayList

# Get all Subscriptions that are Enabled
$AzureSubscriptions = Search-AzGraph -Query "resourcecontainers | where type == 'microsoft.resources/subscriptions' and properties.state == 'Enabled'" -First 1000

# Get all Users that are enabled
$UnlicensedUsers = $(Get-AzureADUser -Filter "AccountEnabled eq true" -All $true ).UserPrincipalname

# Get all Users that are enabled and missins Azure AD Premium P2 Service Plan for Identity Protection
#$UnlicensedUsers = $(Get-AzureADUser -Filter "AccountEnabled eq true" -All $true | Where-Object {$_.AssignedPlans.Serviceplanid -notcontains "eec0eb4f-6444-4f95-aba0-50c24d67f998"}).UserPrincipalname

# Counter for Progress bar
$count = 0
foreach ($Subscription in $AzureSubscriptions) {
    #region Progress bar 
    $count++
    $i = [math]::Round(($count/$AzureSubscriptions.Count)*100)
    $SubName = $Subscription.name
    Write-Progress -Activity "Search in Progress" -Status "$i% Complete: $SubName" -PercentComplete $i
    #endregion
    

    $SubId = $Subscription.subscriptionId
    $Roles = Get-AzRoleAssignment -Scope "/subscriptions/$SubId" -WarningAction SilentlyContinue | Where-Object {($_.scope -notlike "/providers*") -and ($_.objecttype -ne "Unknown") -and ($UnlicensedUsers -contains $_.SignInName)}
    
    foreach ($Role in $Roles) {

        $obj = [PSCustomObject]@{
            Subscription = $Subscription.name
            Role = $role.RoleDefinitionName
            DisplayName = $Role.DisplayName
            SignInName = $Role.SignInName
            Type = $Role.ObjectType
            Scope = $Role.Scope -replace "/subscriptions/$SubId",""
        }
        
        $PermissionsCollection.Add($obj)

    }

}

$PermissionsCollection | export-clixml -path c:\temp\AzurePermissionUsers.xml

