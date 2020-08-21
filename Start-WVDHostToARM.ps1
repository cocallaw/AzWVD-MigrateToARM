<#
.SYNOPSIS

.DESCRIPTION

#>

param(
    
    [Parameter(mandatory = $true, ParameterSetName='UpdateOnly')]
    [Parameter(mandatory = $true, ParameterSetName='PreStageOnly')]
    [string]$WVDHostPoolRGName,

    [Parameter(mandatory = $true, ParameterSetName='UpdateOnly')]
    [Parameter(mandatory = $true,ParameterSetName='PreStageOnly')]
    [string]$WVDHostPoolName,

    [Parameter(mandatory = $true, ParameterSetName='UpdateOnly')]
    [Parameter(mandatory = $true,ParameterSetName='PreStageOnly')]
    [string]$HostVMRG,

    [Parameter(mandatory = $false, ParameterSetName='UpdateOnly')]
    [Parameter(mandatory = $false,ParameterSetName='PreStageOnly')]
    [string]$HostVMName,

    [Parameter(mandatory = $false, ParameterSetName='PreStageOnly')]
    [switch]$PreStageOnly,

    [Parameter(mandatory = $false, ParameterSetName='UpdateOnly')]
    [switch]$UpdateOnly
)

$LoadScriptPath = ".\VMScripts\Load-WVDAgents.ps1"
$UpdateScriptPath = ".\VMScripts\Update-WVDAgents.ps1"
$OperationsScriptPath = ".\VMScripts\Run-WVDHostOperations.ps1"

#Get VMs that are to be updated 
if (($HostVMName.Length -eq 0)) {
    $HVM = Get-AzVM -ResourceGroupName $HostVMRG
    Write-Host "The following VMs will be updated"
    foreach ($H in $HVM) {
        $H.Name
    }
}
elseif (($HostVMName.Length -gt 0)) {
    $HVM = Get-AzVM -ResourceGroupName $HostVMRG -Name $HostVMName
    Write-Host "The VM" $HVM.Name "will be updated"
}

#Get the Host Pool Access Token 
$HPRegInfo = $null
Write-Host "Collecting WVD Registration Info for Host Pool" $WVDHostPoolName 
try {
    $HPRegInfo = Get-AzWvdRegistrationInfo -ResourceGroupName $WVDHostPoolRGName -HostPoolName $WVDHostPoolName
    if (($HPRegInfo.Token.Length) -lt 5) {
        $HPRegInfo = New-AzWvdRegistrationInfo -ResourceGroupName $WVDHostPoolRGName -HostPoolName $WVDHostPoolName -ExpirationTime $((get-date).ToUniversalTime().AddDays(1).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ'))
        Write-Host "Created new WVD Host Pool Access Token" 
    }
    else {
        Write-Host "Exported WVD Host Pool Access Token"    
    }
}
catch {
    $HPRegInfo = New-AzWvdRegistrationInfo -ResourceGroupName $WVDHostPoolRGName -HostPoolName $WVDHostPoolName -ExpirationTime $((get-date).ToUniversalTime().AddDays(1).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ'))
    Write-Host "Created new WVD Host Pool Access Token"
}

if ($PreStageOnly) {
    foreach ($H in $HVM) {
        Write-Host "Downloading Current WVD Agent to" $H.Name "the agent will not be installed" 
        try {
            $s = Invoke-AzVMRunCommand -ResourceGroupName $H.ResourceGroupName -VMName $H.Name-CommandId 'RunPowerShellScript' -ScriptPath $OperationsScriptPath -Parameter @{HostPoolToken = $Token; PreStageOnly = $true }
            $s.Value[0].Message
        }
        catch {
            Write-Host "There was an issue attempting to download the latest WVD agent to the VM" $H.Name
        }
    }
}
elseif ($UpdateOnly) {
    try {
        foreach ($H in $HVM) {
            Write-Host "Updating WVD Host" $H.Name "to host pool" $WVDHostPoolName 
            $s = Invoke-AzVMRunCommand -ResourceGroupName $H.ResourceGroupName -VMName $H.Name-CommandId 'RunPowerShellScript' -ScriptPath $OperationsScriptPath -Parameter @{HostPoolToken = $Token; UpdateOnly = $true }
            $s.Value[0].Message
        }
        Write-Host "Restarting WVD Host" $H.Name
        Restart-AzVM -ResourceGroupName $H.ResourceGroupName -Name $H.Name
    }
    catch {
        Write-Host "There was an issue attempting update the VM" $H.Name
    }
}
else {
    try {
        foreach ($H in $HVM) {
            Write-Host "Updating WVD Host" $H.Name "to host pool" $WVDHostPoolName 
            $s = Invoke-AzVMRunCommand -ResourceGroupName $H.ResourceGroupName -VMName $H.Name-CommandId 'RunPowerShellScript' -ScriptPath $OperationsScriptPath -Parameter @{HostPoolToken = $Token; FullMigration = $true }
            $s.Value[0].Message
        }
        Write-Host "Restarting WVD Host" $H.Name
        Restart-AzVM -ResourceGroupName $H.ResourceGroupName -Name $H.Name
    }
    catch {
        Write-Host "There was an issue attempting update the VM" $H.Name
    }

}
