<#
    Test stuff goes here (this script)
    This is for testing things that will cause the remaining steps in the pipeline to fail and
    to ensure any standards are enforced on the configuration files.

    Not for testing if a policy is going to break a system.
#>

Import-Module .\Module\CarbonBlack.ps1

Write-Output 'Starting testing...'

Try{
    $Results = Invoke-CbApi -Command 'device'
    Write-Output 'Successfully accessed the Carbon Black API'
}Catch{
    Write-Output 'Unable to use the Carbon Black API to check for devices.  Failing run.'
    exit 1
}

Write-Output 'Testing JSON policy files for syntax errors...'
ForEach($File in (Get-ChildItem -Path '.\Policies')){
    If($File.Name -match '.json'){
        Test-JsonFile -JsonFile $File.FullName
    }
}
Write-Output 'Policy syntax check complete.'

Write-Output 'Checking any other JSON files for syntax errors...'
ForEach($File in (Get-ChildItem -Path '.\')){
    If($File.Name -match '.json'){
        Test-JsonFile -JsonFile $File.FullName
    }
}
Write-Output 'Remaining JSON file syntax check complete.'