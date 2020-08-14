<#
.SYNOPSIS

.DESCRIPTION

#>

param(
    [Parameter(mandatory = $true)]
    [string]$TenantName,

    [Parameter(mandatory = $true)]
    [string]$WVDHostPoolName,

    [Parameter(mandatory = $true)]
    [string]$WVDHostPoolRGName,

    [Parameter(mandatory = $true)]
    [string]$WVDTenantAdminUN,

    [Parameter(mandatory = $true)]
    [securestring]$WVDTenantAdminPW,

    [Parameter(mandatory = $false)]
    [switch]$isServicePrincipal,

    [Parameter(Mandatory = $false)]
    [string]$AadTenantId
)

function Write-Log { 
    [CmdletBinding()] 
    param ( 
        [Parameter(Mandatory = $false)] 
        [string]$Message,
        [Parameter(Mandatory = $false)] 
        [string]$Error 
    ) 
     
    try { 
        $DateTime = Get-Date -Format 'MM-dd-yy HH:mm:ss'
        $Invocation = "$($MyInvocation.MyCommand.Source):$($MyInvocation.ScriptLineNumber)" 
        if ($Message) {
            Add-Content -Value "$DateTime - $Invocation - $Message" -Path "$WVDMigrateLogPath\ScriptLog.log" 
        }
        else {
            Add-Content -Value "$DateTime - $Invocation - $Error" -Path "$WVDMigrateLogPath\ScriptLog.log" 
        }
    } 
    catch { 
        Write-Error $_.Exception.Message 
    } 
}

function Install-AzModule {
    Install-PackageProvider NuGet -Force
    Set-PSRepository PSGallery -InstallationPolicy Trusted
    try {
        Install-Module -Name Az -AllowClobber -Scope CurrentUser
        Write-Log -Message "Installed Az PowerShell modules successfully"
    }
    catch {
        Write-Log -Message "Unable to install Az PowerShell modules successfully"
    }    
}

# Get Start Time
$startDTM = (Get-Date)
Write-Log -Message "Starting WVD Migration on Host"

#Collect VM Info
$hostVMname = $env:computername
$hostVMdomain = $env:USERDNSDOMAIN

#Check for Prerequsites
If (-not(Get-InstalledModule Microsoft.RDInfra.RDPowerShell -ErrorAction silentlycontinue)) {
    Install-AzModule
}
else {
    Write-Log "Az Powershell Modules Previously Installed on Machine"
}

#Creating Directory Structure
$WVDMigrateLogPath = "c:\WVDMigrate\logs"
$WVDMigrateInfraPath = "C:\WVDMigrate\Infra"
$infraURI = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv"
try {
    New-Item -Path $WVDMigrateLogPath -ItemType Directory -Force
    New-Item -Path $WVDMigrateInfraPath -ItemType Directory -Force
    Write-Log -Message "Created Directory Structure for Assets and Logging"
}
catch {
    Write-Log -Message "Unable to Create Directory Structure for Assets and Logging"
}

#Download Current Version of WVD Agent 
$AssetstartDTM = (Get-Date)
Invoke-WebRequest -Uri $infraURI -OutFile "$WVDMigrateInfraPath\Microsoft.RDInfra.RDAgent.Installer-x64.msi"
Write-Log -Message "Downloaded RDInfra Agent"
$AssetendDTM = (Get-Date)
Write-Log -Message "Asset Download Time: $(($AssetendDTM-$AssetstartDTM).totalseconds) seconds"

#Connect to Azure
$Securepass = ConvertTo-SecureString -String $WVDTenantAdminPW -AsPlainText -Force
$Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($WVDTenantAdminUN, $Securepass)
if ($isServicePrincipal) {
    $authentication = Connect-AzAccount -Credential $Credentials -ServicePrincipal -TenantId $AadTenantId 
}
else {
    $authentication = Connect-AzAccount -Credential $Credentials
}

if ($authentication) {
    Write-Log -Message "Azure Powershell Authentication successfully Completed. Result: `
$obj"  
}
else {
    Write-Log -Error "Azure Powershell Authentication Failed, Error: `
$obj"
}

#Get ARM WVD Registration Info
$HPRegInfo = $null
try {
    $HPRegInfo = Get-AzWvdRegistrationInfo -ResourceGroupName $WVDHostPoolRGName -HostPoolName $WVDHostPoolName
    if (($HPRegInfo.Token.Length) -lt 5) {
        $HPRegInfo = New-AzWvdRegistrationInfo -ResourceGroupName $WVDHostPoolRGName -HostPoolName $WVDHostPoolName -ExpirationTime $((get-date).ToUniversalTime().AddDays(1).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ'))
        Write-Log -Message "Created new WVD RegistrationInfo into variable 'HPRegInfo': $HPRegInfo" 
    }
    else {
        Write-Log -Message "Exported WVD RegistrationInfo into variable 'HPRegInfo': $HPRegInfo"    
    }
}
catch {
    $HPRegInfo = New-AzWvdRegistrationInfo -ResourceGroupName $WVDHostPoolRGName -HostPoolName $WVDHostPoolName -ExpirationTime $((get-date).ToUniversalTime().AddDays(1).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ'))
    Write-Log -Message "Created new WVD RegistrationInfo into variable 'HPRegInfo': $HPRegInfo"
}

#Remove Installed versions of WVD Agent 
Write-Log -Message "Uninstalling any previous versions of RDInfra Agent on VM"
$RDInfraApps = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -eq "Remote Desktop Services Infrastructure Agent"}
foreach($app in $RDInfraApps){
 Write-Log -Message "Uninstalling Infra Agent $app.Version"
 $app.Uninstall()
}

#Install New WVD Agent
$AgentInstaller = (dir $WVDMigrateInfraPath\ -Filter *.msi | Select-Object).FullName
$RegistrationToken = $HPRegInfo.Token
Write-Log -Message "Starting install of $AgentInstaller"
$agent_deploy_status = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $AgentInstaller", "/quiet", "/qn", "/norestart", "/passive", "REGISTRATIONTOKEN=$RegistrationToken", "/l* $WVDMigrateLogPath\AgentInstall.txt" -Wait -Passthru
$sts = $agent_deploy_status.ExitCode
Write-Log -Message "Installing RD Infra Agent on VM Complete. Exit code=$sts"

# Get End Time
$endDTM = (Get-Date)
Write-Log -Message "WVD Migration on $hostVMname Finished"
# Echo Time elapsed
Write-Log -Message "Elapsed Time: $(($endDTM-$startDTM).totalseconds) seconds"