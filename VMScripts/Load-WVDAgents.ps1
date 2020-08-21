$WVDMigrateInfraPath = "C:\WVDMigrate\Infra"
$infraURI = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv"

try {
    New-Item -Path $WVDMigrateInfraPath -ItemType Directory -Force
    Write-Host "Created Directory Structure for WVD Agent"
}
catch {
    Write-Host "Unable to Create Directory Structure WVD Agent"
}

#Download Current Version of WVD Agent 
$AssetstartDTM = (Get-Date)
Invoke-WebRequest -Uri $infraURI -OutFile "$WVDMigrateInfraPath\Microsoft.RDInfra.RDAgent.Installer-x64.msi"
Write-Host "Downloaded RDInfra Agent"
$AssetendDTM = (Get-Date)
Write-Host "Agent Download Time: $(($AssetendDTM-$AssetstartDTM).totalseconds) seconds"