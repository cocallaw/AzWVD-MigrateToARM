# AzWVD-MigrateToARM

The scripts that are contained in this repo help automate the process of migrating/updating your WVD host pool VMs to Spring Update 2020 with ARM integration. 

In order to run the scripts you must have a current version of Azure Powershell installed that supports the [Az.DesktopVirtualization commands](https://docs.microsoft.com/en-us/powershell/module/az.desktopvirtualization/?view=azps-4.5.0), and permissions to create and interact with Windows Virtual Desktop. 

#

| Prameter | Type | Required | Description |
| ----------- | ----------- | ----------- |----------- |
| WVDHostPoolRGName | String | Yes | Name of Resource Group containing destination WVD Host Pool |
| WVDHostPoolName | String | Yes | Name of the destination WVD Host Pool |
| HostVMRG | String | Yes | Name of Resource Group containing WVD Hosts to update |
| HostVMName | String | No | Name of single WVD Host to update. If not specified script will select all VMs in the Resource Group defined by the `-HostVMRG` parameter |
| PreStageOnly | Switch || If specified will only stage the VM by downloading current agent to C:\WVDMigrate directory on VM |
| UpdateOnly | Switch || If specified will only update the VM WVD Host Pool registration. VM should be prestaged first with `-PreStageOnly` switch |