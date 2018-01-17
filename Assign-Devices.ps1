<#
    Device assignment stuff goes here
#>

Import-Module .\Module\CarbonBlack.ps1

# General config
$ProductionPolicyName = 'MyOrg Production'
$TestPolicyName = 'MyOrg Test'

# Set this to your domain
# Hope to get this from Cb Defense itself in the future
$DomainPrefix = 'MYORG'

Write-Output 'Assigning devices to policies...'

Write-Output 'Getting the devices listed in Cb Defense'
$DeviceList = Get-CbDeviceList

Write-Output 'Getting the test device list from test_devices.json'
$TestGroup = Get-Content test_devices.json | ConvertFrom-Json
$TestGroup = $TestGroup | Select -ExpandProperty name

$RevisedTestGroup = @()
ForEach($System in $TestGroup){
    $RevisedTestGroup += $System

    # In most cases the domain will be prefixed on a Windows device name
    $RevisedTestGroup += ($DomainPrefix + '\' + $System)

    # In some cases Macs will have .local appended to their device names
    $RevisedTestGroup += ($System + '.local')
}

# Counters for summary information to quickly glance and make sure everything is ok
$AttemptedTestAssignments = 0
$AttemptedProductionAssignments = 0

Write-Output "Found $($DeviceList.Count) devices to assign"
ForEach($Device in $DeviceList){
    If($RevisedTestGroup -contains $Device.name){
        If($Device.policyName -ne $TestPolicyName){
            Write-Output "$($Device.name) needs to be assigned to the test policy, assigning to $TestPolicyName"
            $Result = Assign-CbDeviceToPolicy -DeviceId $Device.deviceId -PolicyName $TestPolicyName
            $AttemptedTestAssignments++
        }
    }Else{
        If($Device.policyName -ne $ProductionPolicyName){
            Write-Output "$($Device.name) needs to be assigned to the production policy, assigning to $ProductionPolicyName"
            $Result = Assign-CbDeviceToPolicy -DeviceId $Device.deviceId -PolicyName $ProductionPolicyName
            $AttemptedProductionAssignments++
        }
    }
}

Write-Output "Attempted assigning $AttemptedProductionAssignments device(s) to the production policy"
Write-Output "Attempted assigning $AttemptedTestAssignments device(s) to the test policy"
Write-Output 'Remaining devices were already assigned to their desired policies'