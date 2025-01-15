## Assign app permissions to another app
## This script will search for an application and then search for another application that you want to assign permissions to. It will then list the permissions that the selected application has and ask you to select a permission to assign to the first application. It will then assign the permission to the first application.
# doc: https://learn.microsoft.com/en-us/powershell/microsoftgraph/tutorial-grant-app-only-api-permissions?view=graph-powershell-1.0


Connect-MgGraph -Scopes "Application.ReadWrite.All", "AppRoleAssignment.ReadWrite.All"

$searchApp = Read-Host = "Enter the what the application name starts with"

$searchvalue = "startswith(DisplayName,'$searchApp')"

[array]$SPS = Get-MgServicePrincipal -Filter $searchvalue

### select the application from a list
# list the applications found with numbers in front of them
$SPS | ForEach-Object -Begin { $i = 1 } -Process { Write-Host "$i. $($_.DisplayName)"; $i++ }

# ask the user to select an application
$selection = Read-Host "Select an application by number"

# get the selected application
$selectedApp = $SPS[$selection - 1]

# write out the selected application
write-host $selectedApp.DisplayName -ForegroundColor Green
sleep 1

# search for the application that you want to delegate permissions to
$searchApp = Read-Host "Enter the what the application name starts with you want permissions from"
$searchvalue = "startswith(DisplayName,'$searchApp')"
[array]$permissionsSPS = Get-MgServicePrincipal -Filter $searchvalue

# list the applications found with numbers in front of them
$permissionsSPS | ForEach-Object -Begin { $i = 1 } -Process { Write-Host "$i. $($_.DisplayName)"; $i++ }

# ask the user to select an application
$selection = Read-Host "Select an application by number"

# get the selected application
$selectedPermissionsApp = $permissionsSPS[$selection - 1]

# write out the selected application
write-host $selectedPermissionsApp.DisplayName -ForegroundColor Green
sleep 1

# list the permissions that the selected application has
$selectedPermissionsApp.AppRoles | Select-Object AllowedMemberTypes, value, description | Sort-Object type, value | format-table

# list the permissions that the selected application has with numbers in front of them and select value and type
$selectedPermissionsApp.AppRoles | ForEach-Object -Begin { $i = 1 } -Process { Write-Host "$i. $($_.AllowedMemberTypes) : $($_.value)"; $i++ }

# ask the user to select a permission
$selection = Read-Host "Select a permission by number"

# get the selected permission
$selectedPermission = $selectedPermissionsApp.AppRoles[$selection - 1]

# write out the selected permission
write-host $selectedPermission.value -ForegroundColor Green
sleep 1

# assign the permission to the application
$params = @{
    PrincipalId = $selectedApp.Id
    ResourceId = $selectedPermissionsApp.Id
    AppRoleId = $selectedPermission.Id
}

New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $selectedPermissionsApp.Id -BodyParameter $params | 
    Format-List Id, AppRoleId, CreatedDateTime, PrincipalDisplayName, PrincipalId, PrincipalType, ResourceDisplayName


