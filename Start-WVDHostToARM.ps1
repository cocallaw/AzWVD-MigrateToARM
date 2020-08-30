<#

.DESCRIPTION
Powershell script to migrate WVD Host Pool VMs from Classic to Spring Update 2020

.LINK
https://github.com/cocallaw/AzWVD-MigrateToARM

#>

param(
    
    [Parameter(mandatory = $true, ParameterSetName = 'UpdateOnly')]
    [Parameter(mandatory = $true, ParameterSetName = 'PreStageOnly')]
    [Parameter(mandatory = $true, ParameterSetName = 'CSVList')]
    [Parameter(mandatory = $true, ParameterSetName = 'CSVListPS')]
    [Parameter(mandatory = $true, ParameterSetName = 'CSVListUD')]
    [Parameter(mandatory = $true, ParameterSetName = 'AllOps')]
    [Parameter(mandatory = $true, ParameterSetName = 'AllOpsCSV')]
    [string]$WVDHostPoolRGName,

    [Parameter(mandatory = $true, ParameterSetName = 'UpdateOnly')]
    [Parameter(mandatory = $true, ParameterSetName = 'PreStageOnly')]
    [Parameter(mandatory = $true, ParameterSetName = 'CSVList')]
    [Parameter(mandatory = $true, ParameterSetName = 'CSVListPS')]
    [Parameter(mandatory = $true, ParameterSetName = 'CSVListUD')]
    [Parameter(mandatory = $true, ParameterSetName = 'AllOps')]
    [Parameter(mandatory = $true, ParameterSetName = 'AllOpsCSV')]
    [string]$WVDHostPoolName,

    [Parameter(mandatory = $true, ParameterSetName = 'HPTKNPS')]
    [Parameter(mandatory = $true, ParameterSetName = 'HPTKNUD')]
    [Parameter(mandatory = $true, ParameterSetName = 'HPTKNCSVPS')]
    [Parameter(mandatory = $true, ParameterSetName = 'HPTKNCSVUD')]
    [Parameter(mandatory = $true, ParameterSetName = 'HPTKNALL')]
    [Parameter(mandatory = $true, ParameterSetName = 'HPTKNALLCSV')]
    [string]$WVDHostPoolTkn,

    [Parameter(mandatory = $true, ParameterSetName = 'UpdateOnly')]
    [Parameter(mandatory = $true, ParameterSetName = 'PreStageOnly')]
    [Parameter(mandatory = $true, ParameterSetName = 'AllOps')]
    [Parameter(mandatory = $true, ParameterSetName = 'HPTKNPS')]
    [Parameter(mandatory = $true, ParameterSetName = 'HPTKNUD')]
    [Parameter(mandatory = $true, ParameterSetName = 'HPTKNALL')]
    [string]$HostVMRG,

    [Parameter(mandatory = $false, ParameterSetName = 'UpdateOnly')]
    [Parameter(mandatory = $false, ParameterSetName = 'PreStageOnly')]
    [Parameter(mandatory = $false, ParameterSetName = 'AllOps')]
    [Parameter(mandatory = $false, ParameterSetName = 'HPTKNPS')]
    [Parameter(mandatory = $false, ParameterSetName = 'HPTKNUD')]
    [Parameter(mandatory = $false, ParameterSetName = 'HPTKNALL')]
    [string]$HostVMName,

    [Parameter(mandatory = $true, ParameterSetName = 'CSVList')]
    [Parameter(mandatory = $true, ParameterSetName = 'CSVListPS')]
    [Parameter(mandatory = $true, ParameterSetName = 'CSVListUD')]
    [Parameter(mandatory = $true, ParameterSetName = 'HPTKNCSVPS')]
    [Parameter(mandatory = $true, ParameterSetName = 'HPTKNCSVUD')]
    [Parameter(mandatory = $true, ParameterSetName = 'HPTKNALLCSV')]
    [Parameter(mandatory = $true, ParameterSetName = 'AllOpsCSV')]
    [string]$HostCSVList,

    [Parameter(mandatory = $true, ParameterSetName = 'PreStageOnly')]
    [Parameter(mandatory = $true, ParameterSetName = 'CSVListPS')]
    [Parameter(mandatory = $true, ParameterSetName = 'HPTKNCSVPS')]
    [Parameter(mandatory = $true, ParameterSetName = 'HPTKNPS')]
    [switch]$PreStageOnly,

    [Parameter(mandatory = $true, ParameterSetName = 'UpdateOnly')]
    [Parameter(mandatory = $true, ParameterSetName = 'CSVListUD')]
    [Parameter(mandatory = $true, ParameterSetName = 'HPTKNCSVUD')]
    [Parameter(mandatory = $true, ParameterSetName = 'HPTKNUD')]
    [switch]$UpdateOnly
)

$OperationsScriptPath = ".\VMScripts\Run-WVDHostOperations.ps1"

#Check for support Az Powershell Version
Write-Host "Checking Powershell for Az.DesktopVirtualization Module"
if (Get-Module -ListAvailable -Name Az.DesktopVirtualization) {
    Write-Host "Az.DesktopVirtualization Module exists"
}
else {
    Write-Host "Az.DesktopVirtualization module not found please update your version of Azure Powershell. More Info: aka.ms/azps"
    break
}

if ($HostCSVList.Length -ne 0) {
    Write-Host "VM selection is being performed by CSV list, checking provided file"
    $tpcsv = Test-Path -Path $HostCSVList -PathType Leaf
    if ($tpcsv) {
        $extn = [IO.Path]::GetExtension($HostCSVList)
        if ($extn -eq ".csv" ) {
            $HVM = Import-Csv -Path $HostCSVList
            Write-Host "The following VMs will be updated"
            foreach ($H in $HVM) {
                Write-Host $H.Name "in Resource Group" $H.ResourceGroupName
            }
        }
        else {
            Write-Host "Host VM List must be a .csv file"
            Write-Host "Please check file type" $HostCSVList
        }
    }
    else {
        Write-Host "Host VM List not found"
        Write-Host "Please check file path" $HostCSVList
    } 
}

if ($HostCSVList.Length -eq 0) {
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
}

#Get the Host Pool Access Token
if (($WVDHostPoolRGName.Length -ne 0) -and ($WVDHostPoolName.Length -ne 0)) {
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
    $Token = $HPRegInfo.Token
}
elseif ((($WVDHostPoolRGName.Length -eq 0) -and ($WVDHostPoolName.Length -eq 0)) -and ($WVDHostPoolTkn.Length -ne 0)) {
    
}


if ($PreStageOnly) {
    foreach ($H in $HVM) {
        Write-Host "Downloading Current WVD Agent to" $H.Name "the agent will not be installed" 
        try {
            $s = Invoke-AzVMRunCommand -ResourceGroupName $H.ResourceGroupName -VMName $H.Name -CommandId 'RunPowerShellScript' -ScriptPath $OperationsScriptPath -Parameter @{HostPoolToken = $Token; PreStageOnly = "T"; UpdateOnly = "F" }
            $s.Value[0].Message
            Write-Host "WVD agent download steps have completed on" $H.Name
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
            $s = Invoke-AzVMRunCommand -ResourceGroupName $H.ResourceGroupName -VMName $H.Name -CommandId 'RunPowerShellScript' -ScriptPath $OperationsScriptPath -Parameter @{HostPoolToken = $Token; PreStageOnly = "F"; UpdateOnly = "T" }
            $s.Value[0].Message
            Write-Host "WVD Host VM configuration steps have completed on" $H.Name
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
            $s = Invoke-AzVMRunCommand -ResourceGroupName $H.ResourceGroupName -VMName $H.Name -CommandId 'RunPowerShellScript' -ScriptPath $OperationsScriptPath -Parameter @{HostPoolToken = $Token; PreStageOnly = "T"; UpdateOnly = "T" }
            $s.Value[0].Message
        }
        Write-Host "Restarting WVD Host" $H.Name
        Restart-AzVM -ResourceGroupName $H.ResourceGroupName -Name $H.Name
    }
    catch {
        Write-Host "There was an issue attempting update the VM" $H.Name
    }

}

