Param(
   [Parameter(Mandatory=$True, HelpMessage=" Cluster name or IP Address")]
   [String]$Cluster,

   [Parameter(Mandatory=$True, HelpMessage=" vserver name")]
   [String]$vserver,
   
   [Parameter(Mandatory=$True, HelpMessage=" Parent volume name")]
   [String]$parent_volume,
   
   [Parameter(Mandatory=$True, HelpMessage=" Clone volume name")]
   [String]$clone_old,
   
   [Parameter(Mandatory=$True, HelpMessage=" Clone Export Policy")]
   [String]$clone_export_policy,
   
   [Parameter(Mandatory=$True, HelpMessage=" Snapshot Name")]
   [String]$snapshot,
   
   [Parameter(Mandatory=$True, HelpMessage="Environment to Refresh (Only enter snd/dev/tst")]
   [ValidateSet("snd","dev","tst")]
   [String]$environment,
   
   [Parameter(Mandatory=$True, HelpMessage="The Credential to connect to the cluster")]
   [System.Management.Automation.PSCredential]$Credential   
)
#'------------------------------------------------------------------------------
#'Import the PSTK.
#'------------------------------------------------------------------------------
[String]$moduleName = "DataONTAP"
Try{
   Import-Module -Name $moduleName
   Write-Host "Imported module ""$moduleName"""
}Catch{
   Write-Warning -Message $("Failed importing module ""$moduleName"". Error " + $_.Exception.Message)
   Break;
}
#'------------------------------------------------------------------------------
#'Connect to the cluster.
#'------------------------------------------------------------------------------
Try{
   Connect-NcController -Name $Cluster -HTTPS -Credential $Credential -ErrorAction Stop | Out-Null
   Write-Host "Connected to cluster ""$Cluster"""
}Catch{
   Write-Warning -Message $("Failed connecting to cluster ""$Cluster"". Error " + $_.Exception.Message)
   Break;
}


$parent_volume = Get-NcVol -Name $parent_volume
$clone_volume  = Get-NcVol -Name $clone_old
$datenow = (get-date).ToUniversalTime().ToString('yyyyMMddHHmm')
switch ($environment) {
    "snd" { $clone_export_policy = "snd" }
    "dev" { $clone_export_policy = "dev" }
    "tst" { $clone_export_policy = "tst" }
    default {  throw "Invalid Environment Provided"}
}
# name for existing clone to be renamed
$clone_old_renamed = "offlined_$($datenow)_$clone_old"

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
