<#
    A script and someday true module for Carbon Black commands and functions.

    Not a true module at the moment, but working towards it.
#>


# Module scoped variables
$Script:Token = $null

$ApiHost = 'https://api-prod05.conferdeploy.net/integrationServices/v3'

# This function is needed since sometimes the Cb Defense API returns JSON keys in a different order
function Sort-Members{
    param(
        $Object
    )

    $ReturnObject = @()

    # Loop in case its an array, if not, this will process once
    ForEach($SubObject in $Object){
        $SubObject = $SubObject | Select -Property ($SubObject | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | Sort)

        # Run each member through a sort in case its a sub-array or similar
        ForEach($Member in ($SubObject | Get-Member -MemberType NoteProperty)){
            If($SubObject.$($Member.Name) -is [array]){
                [array]$SubObject.$($Member.Name) = Sort-Members -Object $SubObject.$($Member.Name)
            }Else{
                $SubObject.$($Member.Name) = Sort-Members -Object $SubObject.$($Member.Name)
            }

        }

        $ReturnObject += $SubObject
    }

    return $ReturnObject
}


# Used to make sure JSON files are at least syntactically correct
function Test-JsonFile{
    param(
        [string]$JsonFile
    )

    try{
        $PilotList = Get-Content $JsonFile | ConvertFrom-Json
        Write-Output "$JsonFile was found and has valid JSON"
    }catch{
        Write-Output "$JsonFile contains syntax errors and is not valid JSON, exiting with error"
        exit 1
    }
}

<#
    Aggregates Cb policies that are saved as JSON files.  Makes it easier to
    split into different logical buckets.
#>
function Get-CbPolicyListFromFile{
    param(
        [string]$PolicyPath
    )

    $PolicyList = @()

    ForEach($File in (Get-ChildItem -Path $PolicyPath)){
        If($File.Name -match '.json'){
            $PolicyList += Sort-Members -Object ((Get-Content $File.FullName) | ConvertFrom-Json)
        }
    }

    return $PolicyList
}


# Wrapper for Cb API calls
function Invoke-CbApi{
    param(
        [string]$Command,
        [ValidateSet('Get','Delete','Post','Put','Patch')]
        [string]$Method='Get',
        [string]$JsonBody
    )

    If($Script:Token -eq $null){
        # Place code here to get your token from a secrets tool and API
        $Script:Token = 'ABC\123'
    }

    If($JsonBody -and $Method){
        return Invoke-WebRequest -UseBasicParsing -Uri "$ApiHost/$Command" -Headers @{'X-Auth-Token'=$Token;'Content-Type'='application/json'} -Method $Method -Body $JsonBody
    }Else{
        return Invoke-WebRequest -UseBasicParsing -Uri "$ApiHost/$Command" -Headers @{'X-Auth-Token'=$Token} -Method $Method
    }
}


function Get-CbDeviceList{
    return (Invoke-CbApi -Command 'device').Content | ConvertFrom-Json | Select -ExpandProperty Results
}


function Get-CbPolicyList{
    return (Invoke-CbApi -Command 'policy').Content | ConvertFrom-Json | Select -ExpandProperty Results
}


function Assign-CbDeviceToPolicy{
    param(
        [int]$DeviceId,
        [string]$PolicyName
    )

    return Invoke-CbApi -Command "device/$DeviceId" -Method Patch -JsonBody ('{"policyName": "' + $PolicyName + '"}')
}