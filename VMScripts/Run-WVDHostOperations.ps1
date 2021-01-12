param(
    [Parameter(mandatory = $true)]
    [string]$HostPoolToken,

    [Parameter(mandatory = $true)]
    [string]$PreStageOnly,

    [Parameter(mandatory = $true)]
    [string]$UpdateOnly
)
$WVDMigrateInfraPath = "C:\WVDMigrate"
$infraURI = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv"
if ($PreStageOnly -eq "T") {
    #Create folder for agent download
    try {
        New-Item -Path $WVDMigrateInfraPath -ItemType Directory -Force
        Write-Host "Created Directory Structure for WVD Agent"
    }
    catch {
        Write-Host "Unable to Create Directory Structure WVD Agent"
    }
    $AssetstartDTM = (Get-Date)
    #Download Current Version of WVD Agent 
    #Invoke-WebRequest -Uri $infraURI -OutFile "$WVDMigrateInfraPath\Microsoft.RDInfra.RDAgent.Installer-x64.msi"
    Start-BitsTransfer -Source $infraURI -Destination "$WVDMigrateInfraPath\Microsoft.RDInfra.RDAgent.Installer-x64.msi"
    Write-Host "Downloaded RDInfra Agent"
    $AssetendDTM = (Get-Date)
    Write-Host "Agent Download Time: $(($AssetendDTM-$AssetstartDTM).totalseconds) seconds"
}
if ($UpdateOnly -eq "T") {
    $tp = Test-Path -Path "C:\WVDMigrate\Microsoft.RDInfra.RDAgent.Installer-x64.msi" -PathType leaf
    if ($tp -eq $true) {
        Write-Host "WVD Infra Agent Found at" $WVDMigrateInfraPath 
    }
    elseif ($tp -eq $false) {
        Write-Host "WVD Infra Agent Not Found at" $WVDMigrateInfraPath 
        Write-Host "Stopping migration process, please use -PreStageOnly parameter first on VM if using -UpdateOnly parameter"
        break
    }
    #Remove Installed versions of WVD Agent 
    Write-Host "Uninstalling any previous versions of RDInfra Agent on VM"
    $RDInfraApps = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq "Remote Desktop Services Infrastructure Agent" }
    foreach ($app in $RDInfraApps) {
        Write-Host "Uninstalling Infra Agent $app.Version"
        $app.Uninstall()
    }
    $AgentInstaller = (Get-ChildItem $WVDMigrateInfraPath\ -Filter *.msi | Select-Object).FullName
    $RegistrationToken = $HostPoolToken
    Write-Host "Starting install of $AgentInstaller"
    $agent_deploy_status = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $AgentInstaller", "/quiet", "/qn", "/norestart", "/passive", "REGISTRATIONTOKEN=$RegistrationToken", "/l* $WVDMigrateInfraPath\AgentInstall.txt" -Wait -Passthru
    $sts = $agent_deploy_status.ExitCode
    Write-Host "Installing RD Infra Agent on VM Complete. Exit code=$sts"
}