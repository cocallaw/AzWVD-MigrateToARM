<#
.SYNOPSIS

.DESCRIPTION

#>

param(
    [Parameter(mandatory = $true)]
    [string]$TenantName,

    [Parameter(mandatory = $true)]
    [string]$NewHostPoolName,

    [Parameter(mandatory = $true)]
    [string]$WVDTenantAdminUN,

    [Parameter(mandatory = $true)]
    [securestring]$WVDTenantAdminPW,

    [Parameter(mandatory = $false)]
    [switch]$isServicePrincipal,

    [Parameter(Mandatory = $false)]
    [string]$AadTenantId
)

#Check for Prerequsites 

#Collect VM Info

#Download Current Version of WVD Agent 

#Remove Installed versions of WVD Agent 