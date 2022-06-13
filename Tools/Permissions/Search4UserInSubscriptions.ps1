# Insert a usermail to search for permissions in Azure subscriptions
$Collection = New-Object System.Collections.ArrayList

$Usermail = "" # Insert Usermail to search for

$AzureSubscriptions = Search-AzGraph -Query "resourcecontainers | where type == 'microsoft.resources/subscriptions'" -First 1000

foreach ($Subscription in $AzureSubscriptions) {
    
    $SubId = $Subscription.subscriptionId
    $roles = Get-AzRoleAssignment -Scope "/subscriptions/$SubId" -WarningAction SilentlyContinue | Where-Object {($_.SignInName -eq $Usermail) -and ($_.Scope -notlike "/providers*")}
    foreach ($role in $roles) {
        
        $obj = [PSCustomObject]@{
            Subscription = $Subscription.name
            Role = $role.RoleDefinitionName
            DisplayName = $role.DisplayName
            SignInName = $role.SignInName
            Type = $role.ObjectType
            Scope = $role.Scope -replace "/subscriptions/$SubId",""
            RawScope = $role.Scope
        }
        
        $Collection.Add($obj)

    }

}

$date = get-date -Format "ddMMyyyy"
$endPath = "c:\temp\$Usermail-$date.xml"

$Collection | Export-Clixml -Path $endPath