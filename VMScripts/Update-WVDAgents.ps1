param(
    [Parameter(mandatory = $true)]
    [string]$HostPoolToken
)

$WVDMigrateInfraPath = "C:\WVDMigrate\Infra"

#Remove Installed versions of WVD Agent 
Write-Log -Message "Uninstalling any previous versions of RDInfra Agent on VM"
$RDInfraApps = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq "Remote Desktop Services Infrastructure Agent" }
foreach ($app in $RDInfraApps) {
    Write-Log -Message "Uninstalling Infra Agent $app.Version"
    $app.Uninstall()
}

$AgentInstaller = (dir $WVDMigrateInfraPath\ -Filter *.msi | Select-Object).FullName
$RegistrationToken = $HostPoolToken
Write-Host "Starting install of $AgentInstaller"
$agent_deploy_status = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $AgentInstaller", "/quiet", "/qn", "/norestart", "/passive", "REGISTRATIONTOKEN=$RegistrationToken", "/l* $WVDMigrateInfraPath\AgentInstall.txt" -Wait -Passthru
$sts = $agent_deploy_status.ExitCode
Write-Host "Installing RD Infra Agent on VM Complete. Exit code=$sts"