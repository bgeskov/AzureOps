# Application Permissions for Azure AD Applications

using namespace System.Collections

if($SPs -eq $null) {
    $SPs = Get-AzADServicePrincipal
}

$Apps = Get-AzADApplication

$Collection = [ArrayList]::new()

foreach ($App in $Apps) {

    $AppCollection = [ArrayList]::new()

    foreach ($AppResAccess in $App.RequiredResourceAccess) {

        $AppPermissionCollection = [ArrayList]::new()

        $SP = $SPs | Where-Object AppId -eq $AppResAccess.ResourceAppId

        foreach ($AppPermission in $AppResAccess.ResourceAccess) {

            if($AppPermission.Type -eq "Scope") {
                $SPPermission = $SP.Oauth2PermissionScope | Where-Object Id -eq $AppPermission.Id
                $SPType = "Delegated"
            } elseif ($AppPermission.Type -eq "Role") {
                $SPPermission = $SP.AppRole | Where-Object Id -eq $AppPermission.Id
                $SPType = "Application"
            }
            
            $ObjectPermission = [PSCustomObject]@{
                ServiceName = $SP.DisplayName
                Type = $SPType
                Value = $SPPermission.Value
                Displayname = $SPPermission.UserConsentDisplayName
                Description = $SPPermission.AdminConsentDescription
            }

            $AppPermissionCollection.Add($ObjectPermission) | Out-Null

        }

        $AppCollection.Add($AppPermissionCollection)

    }

    $Object = [PSCustomObject]@{
        Name = $App.DisplayName
        Permissions = $AppCollection
    }

    $Collection.Add($Object)
}

