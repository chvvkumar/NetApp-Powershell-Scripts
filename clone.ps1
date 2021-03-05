$vserver = "svm01"
$parent_volume = "original"
$clone_old = "clone_1"
$clone_export_policy = "clonepolicy"
$snapshot = "snapshot1"
$environment = "dev"


# Get parent and clone details
$parent_volume = Get-NcVol -Name $parent_volume
$clone_volume  = Get-NcVol -Name $clone_old

# Create rename string
$datenow = (get-date).ToUniversalTime().ToString('yyyyMMddHHmm')

# Select environment to clone to
switch ($environment) {
    "snd" { $clone_export_policy = "snd" }
    "dev" { $clone_export_policy = "dev" }
    "tst" { $clone_export_policy = "tst" }
    default {  throw "Invalid Environment Provided."}
}
# name for existing clone to be renamed
$clone_old_renamed = "offlined_$($datenow)_$(($clone_volume).name)"

# Unmount existing clone
Dismount-NcVol -Name $clone_old -VserverContext $vserver | Out-Null
Write-Host "Dismounted: "$($clone_old)""

# rename old cloned volume and offline it
Rename-NcVol -Name $clone_old  $clone_old_renamed -VserverContext $vserver | Out-Null
Write-Host "Renamed: $($clone_old) to: $($(get-ncvol $clone_old_renamed).name)"

Set-NcVol -VserverContext $vserver -Name $clone_old_renamed -Offline | Out-Null
Write-Host "Offlined: $($clone_old_renamed). Current Status: $($(get-ncvol $clone_old_renamed).State)"

# clone original volume
New-NcVolClone -ParentVolume $parent_volume -CloneVolume $clone_old -ParentSnapshot $snapshot -Vserver $vserver | Out-Null
Write-Host "Cloning parent volume: $($parent_volume) to new volume: $($clone_old)"

# mount new clone to old junction path
Mount-NcVol -Name $clone_volume -JunctionPath $clone_volume.JunctionPath -VserverContext $vserver | Out-Null
Write-Host "Mounted new clone to junction-path: $(get-ncvol $clone_volume).JunctionPath"

# modify export policy
Update-NcVol -query @{name="$clone_old"} -Attributes @{volumeexportattributes=@{policy="$clone_export_policy"}} | Out-Null
Write-Host "Modified export policy of: $($clone_old) to: $(get-ncvol $clone_volume).VolumeExportAttributes.Policy"
