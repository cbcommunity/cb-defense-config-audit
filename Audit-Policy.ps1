<#
    Audit stuff goes here
#>

Import-Module .\Module\CarbonBlack.ps1

Write-Output 'Auditing policies...'

Write-Output 'Getting policy information'
$JsonPolicyList = Get-CbPolicyList | Select-Object -Property * -ExcludeProperty id,latestRevision | ConvertTo-Json -Depth 100

Write-Output 'Comparing desired policy list vs the actual policies in Cb Defense that were just exported...'

# Need to resort the keys so they are in the same order.  In some cases the Cb API returns different key orders.
# Planning to use jq in the future instead of the custom sort-members PS function.
$ActualPolicyList = (Sort-Members -Object (Get-CbPolicyList | Select-Object -Property * -ExcludeProperty id,latestRevision) | ConvertTo-Json -Depth 100)

(Get-CbPolicyListFromFile -PolicyPath '.\Policies' | ConvertTo-Json -Depth 100) | Out-File 'desired_policies.json'
$ActualPolicyList | Out-File 'actual_policies.json'

# Create a line number to make it esaier to identify where potential changes were made
$DesiredPolicyText = Get-Content 'desired_policies.json' | %{$i = 1} { New-Object PsObject -Property @{Line=$i;Text=$_}; $i++}
$ActualPolicyText = Get-Content 'actual_policies.json' | %{$i = 1} { New-Object PsObject -Property @{Line=$i;Text=$_}; $i++}

$Results = $null
$Results = Compare-Object $DesiredPolicyText $ActualPolicyText -Property Text -PassThru

If($Results){
    Write-Output 'Differences were found'

    # Make the side indicator obvious and easier to know where the change happened
    For($i = 0;$i -lt $Results.Count;$i++){
        If($Results[$i].SideIndicator -eq '=>'){
            $Results[$i].SideIndicator = 'Actual'
        }ElseIf($Results[$i].SideIndicator -eq '<='){
            $Results[$i].SideIndicator = 'Desired'
        }
    }
    $Results

    Write-Output 'Look at desired_policies.json and actual_policies.json for more information'
}Else{
    Write-Output 'No differences were found'
}