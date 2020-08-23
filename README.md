# AzWVD-MigrateToARM

The PowerShell scripts in this repository automate the process of migrating/updating a WVD Host Pool VM from WVD Classic to [Spring Update 2020](https://azure.microsoft.com/en-us/blog/new-windows-virtual-desktop-capabilities-now-generally-available/)


## Prerequisites 

The following items are required in order to use these scripts to update your WVD Host Pool VMs to Spring Update 2020

* Local Machine with current version of Azure Powershell installed that supports [Az.DesktopVirtualization](https://docs.microsoft.com/en-us/powershell/module/az.desktopvirtualization/?view=azps-4.5.0) commands such as `Get-AzWVDHostPool`
* Azure Account able to connect to Azure via PowerSHell and perform actions against Windows Virtual Desktop Resources
* A destination WVD Host Pool that is created through the [Azure Portal](https://ms.portal.azure.com/#blade/Microsoft_Azure_WVD/WvdManagerMenuBlade/overview) or [Powershell](https://docs.microsoft.com/en-us/powershell/module/az.desktopvirtualization/new-azwvdhostpool?view=azps-4.5.0)


## Start-WVDHostToARM.ps1 Parameters


| Prameter | Type | Required | Description |
| ----------- | ----------- | ----------- |----------- |
| WVDHostPoolRGName | String | Yes | Name of Resource Group containing destination WVD Host Pool |
| WVDHostPoolName | String | Yes | Name of the destination WVD Host Pool |
| HostVMRG | String | Yes | Name of Resource Group containing WVD Hosts to update |
| HostVMName | String | No | Name of single WVD Host to update. If not specified script will select all VMs in the Resource Group defined by the `-HostVMRG` parameter |
| PreStageOnly | Switch | No | If specified will only stage the VM by downloading current agent to C:\WVDMigrate directory on VM |
| UpdateOnly | Switch | No | If specified will only update the VM WVD Host Pool registration. VM should be prestaged first with `-PreStageOnly` switch |