$ResourceGroupName = " "
#Get the VM Resources
$HVM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name " "

foreach ($H in $HVM) {
    $ARMTag = "NWM_ARM_HOST_POOL "
    $ClassicTags = @('NWM_HOST_POOL', 'NWM_TENANT', 'NWM_TENANT_GROUP')
    $MissingTags = $false
    $HTagVM = Get-AzTag -ResourceId $H.Id
    $HTagOS = Get-AzTag -ResourceId ((Get-AzDisk -ResourceGroupName $H.ResourceGroupName -DiskName $H.StorageProfile.OsDisk.Name).Id)
    
    #Check that Tags Exist
    foreach ($CT in $ClassicTags) {
        if ($HTagVM.Properties.TagsProperty.ContainsKey($CT)) {
            Write-Host "Tag" $CT "Was Found on VM" $H.Name
            if ($HTagOS.Properties.TagsProperty.ContainsKey($CT)) {
                Write-Host "Tag" $CT "Was Found on OS Disk" $H.StorageProfile.OsDisk.Name
            } 
        }
        else {
            Write-Host "Tag" $CT "Was NOT Found on VM" $H.Name "Resources"
            $MissingTags = $true
        }
    }

    #Update Tags on VM and OS Disk Resources
    if (!$MissingTags) {
        Write-Host "Updating Tags On Resources for" $H.Name
        $HTagVM.Properties.TagsProperty
        $HTagOS.Properties.TagsProperty
        #Out With The Old
        foreach ($CT in $ClassicTags) {
            $HTagVM.Properties.TagsProperty.Remove($CT)
            $HTagOS.Properties.TagsProperty.Remove($CT)
        }
        #In With The New
        $HTagVM.Properties.TagsProperty.Add($ARMTag, "Value")

    }
    elseif ($MissingTags) {
        Write-Host "Proper tags are missing on resources for" $H.Name
        Write-Host "Please Check the Tags and then manualy update the VM"
    }

}


