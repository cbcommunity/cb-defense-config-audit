<#
    Deploy stuff goes here
#>

Import-Module .\Module\CarbonBlack.ps1

Write-Output 'Starting policy deployment...'

Write-Output 'Getting policy information...'
$ActualPolicyList = Get-CbPolicyList
$DesiredPolicyList = Get-CbPolicyListFromFile -PolicyPath '.\Policies'

Write-Output 'Checking for missing or updated policies...'
ForEach($Policy in $DesiredPolicyList){
    $ActualPolicy = $null
    $ActualPolicy = $ActualPolicyList | Where name -eq $Policy.name
    If($ActualPolicy){
        $CompareActualPolicy = (Sort-Members -Object $ActualPolicy | Select-Object -Property * -ExcludeProperty id,latestRevision | ConvertTo-Json -Depth 100).Split([Environment]::NewLine)
        $ComparePolicy = (Sort-Members -Object $Policy | ConvertTo-Json -Depth 100).Split([Environment]::NewLine)
        $Results = $null
        $Results = Compare-Object $CompareActualPolicy $ComparePolicy
        If($Results){
            Write-Output "Found $($Policy.name) with requested changes"
            $Policy | Add-Member -MemberType NoteProperty -Name id -Value $ActualPolicy.id
            $UpdatePolicy = New-Object -TypeName PSObject -Property @{ 'policyInfo' = $Policy} | ConvertTo-Json -Depth 100
            Invoke-CbApi -Token $Token -Command "policy/$($ActualPolicy.id)" -Method Put -JsonBody $UpdatePolicy
        }
    }Else{
        Write-Output "Could not find a policy in CB named $($Policy.name)"
        Write-Output "Creating a policy named $($Policy.name)"
        $PostPolicy = New-Object -TypeName PSObject -Property @{ 'policyInfo' = $Policy} | ConvertTo-Json -Depth 100
        $PostPolicy
        Invoke-CbApi -Command 'policy' -Method Post -JsonBody $PostPolicy
    }
}

Write-Output 'Done checking for missing or updated policies.'

Write-Output 'Refreshing policy information...'
$ActualPolicyList = (Invoke-CbApi -Command 'policy').Content | ConvertFrom-Json | Select -ExpandProperty Results

Write-Output 'Checking for policies to delete...'
ForEach($Policy in $ActualPolicyList){
    $DesiredPolicy = $null
    $DesiredPolicy = $DesiredPolicyList | Where name -eq $Policy.name
    If($DesiredPolicy){
        #Write-Output "Found $($Policy.name)"
    }Else{
        Write-Output "Could not find a policy in the desired policy list named $($Policy.name)"
        Write-Output "Deleting the policy named $($Policy.name)"
        Invoke-CbApi -Command "policy/$($Policy.id)" -Method Delete
    }
}