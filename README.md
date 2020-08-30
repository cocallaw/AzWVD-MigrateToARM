# AzWVD-MigrateToARM

The PowerShell scripts in this repository automate the process of migrating/updating a WVD Host Pool VM from WVD Classic to [Spring Update 2020](https://azure.microsoft.com/en-us/blog/new-windows-virtual-desktop-capabilities-now-generally-available/)

## Prerequisites 

The following items are required in order to use these scripts to update your WVD Host Pool VMs to Spring Update 2020

* Local Machine with current version of Azure Powershell installed that supports [Az.DesktopVirtualization](https://docs.microsoft.com/en-us/powershell/module/az.desktopvirtualization/?view=azps-4.5.0) commands such as `Get-AzWVDHostPool`
* Azure Account able to connect to Azure via PowerSHell and perform actions against Windows Virtual Desktop Resources
* A destination WVD Host Pool that is created through the [Azure Portal](https://ms.portal.azure.com/#blade/Microsoft_Azure_WVD/WvdManagerMenuBlade/overview) or [Powershell](https://docs.microsoft.com/en-us/powershell/module/az.desktopvirtualization/new-azwvdhostpool?view=azps-4.5.0)
* Host Pool VMs and Destination Host Pool resources must be located in the same Azure subscription 

## Selecting Host Pool VMs
There are currently three options for specifying what VMs the script will perform operations on. 
* Single VM Selection - To select a single VM to for the script to perform operations against, specify both the `-HostVMRG` and `-HostVMName` parameters 
* Resource Group Selection - To select all the VMs contained within a specific Azure Resource Group only specify the `-HostVMRG` parameter. Any VM in that Resource Group will be selected by the script.
* CSV List Selection - To select multiple VMs from the same or differnt resource groups, utilize the `-HostCSVList` parameter. Specify the file path to the csv file, the template WVDHostList.csv file for column names.
Selection of VMs by using a CSV list is under development to allow for greater control in differnt Azure governance models.

## Script Modes 
* PreStageOnly - If the `-PreStageOnly` parameter is specified the script will only download the latest version of the WVD Infrastructure Agent to the `C:\WVDMigrate` directory that the script creates on the VM.
* UpdateOnly - If the `-UpdateOnly` parameter is specified the script will perform the update/migration process of the WVD Host VM, by utilizing the WVD Infrastructure Agent Located at `C:\WVDMigrate`. This mode requires that prestaging of the VMs has already been performed
* All Operations - If `-PreStageOnly` or `-UpdateOnly` is not specified that script will download the latest agent and update/migrate the VM to the new host pool when run.  

## Host Pool Registration Info 
Registration information is collected by choosing one of two methods
* If the `-WVDHostPoolRGName` and `-WVDHostPoolName` parameters are specified, the script will use that info and the permissions of the current signed in user to collect the registration info
* If `-WVDHostPoolTkn` parameter is specified the provided string will be used as the value for the host pool registration token.

## How to use this tool
1. Download the [latest production release](https://github.com/cocallaw/AzWVD-MigrateToARM/releases) of the scripts to your local machine.
2. Extract the scripts, and in PowerShell navigate to the base direcotry that contains the Start-WVDHostToARM.ps1 script
3. In the same PowerShell session as step 2, connect to your Azure subscription containing the host pool VMs and destination host pool.
4. To start the migration process run the Start-WVDHostToARM.ps1 script using the prefered perameter set.
#### Prestage WVD Hosts Only

`Start-WVDHostToARM.ps1 -WVDHostPoolRGName <String> WVDHostPoolName <String> -HostVMRG <String> [-HostVMName <String>] -PreStageOnly`

OR

`Start-WVDHostToARM.ps1 -WVDHostPoolRGName <String> -WVDHostPoolName <String> -HostCSVList <String> -PreStageOnly`

OR 

`Start-WVDHostToARM.ps1 -WVDHostPoolTkn <String> -HostVMRG <String> [-HostVMName <String>] -PreStageOnly`

OR

`Start-WVDHostToARM.ps1 -WVDHostPoolTkn <String> -HostCSVList <String> -PreStageOnly`

#### Update WVD Hosts Only (requires prestage to have been performed)

`Start-WVDHostToARM.ps1 -WVDHostPoolRGName <String> -WVDHostPoolName <String> -HostVMRG <String> [-HostVMName <String>] -UpdateOnly`

OR 

`Start-WVDHostToARM.ps1 -WVDHostPoolRGName <String> -WVDHostPoolName <String> -HostCSVList <String> -UpdateOnly`

OR 

`Start-WVDHostToARM.ps1 -WVDHostPoolTkn <String> -HostVMRG <String> [-HostVMName <String>] -UpdateOnly`

OR

`Start-WVDHostToARM.ps1 -WVDHostPoolTkn <String> -HostCSVList <String> -UpdateOnly`

#### Perform all operations

`Start-WVDHostToARM.ps1 -WVDHostPoolRGName <String> WVDHostPoolName <String> -HostVMRG <String> [-HostVMName <String>]`

OR

`AzWVD-MigrateToARM\Start-WVDHostToARM.ps1 -WVDHostPoolRGName <String> -WVDHostPoolName <String> -HostCSVList <String>`

OR 

`Start-WVDHostToARM.ps1 -WVDHostPoolTkn <String> -HostVMRG <String> [-HostVMName <String>]`

OR

`Start-WVDHostToARM.ps1 -WVDHostPoolTkn <String> -HostCSVList <String>`

## Start-WVDHostToARM.ps1 Parameters

| Prameter | Type | Description |
| ----------- | ----------- |----------- |
| WVDHostPoolRGName | String | Name of Resource Group containing destination WVD Host Pool |
| WVDHostPoolName | String | Name of the destination WVD Host Pool |
| WVDHostPoolTkn | String | Value of the destination WVD Host Pool registration token |
| HostVMRG | String | Name of Resource Group containing WVD Hosts to update |
| HostVMName | String | Name of single WVD Host to update. If not specified script will select all VMs in the Resource Group defined by the `-HostVMRG` parameter |
| HostCSVList | String | Local file path of WVDHostList.csv file containing VM Names and their corresponding Resource Group Name |
| PreStageOnly | Switch | If specified will only stage the VM by downloading current agent to C:\WVDMigrate directory on VM |
| UpdateOnly | Switch | If specified will only update the VM WVD Host Pool registration. VM should be prestaged first with `-PreStageOnly` switch |
