clear-host
#Location where command files will be saved
set-location D:\Scripts\eseries
$location = Get-Location
#Checks if there are previous text files in the output location and deletes tham to create new files. It may be a good idea to backup previous files if you need to keep older commands
if(Test-Path -Path .\ControllerA.txt)
    {Remove-Item .\ControllerA.txt}
if(Test-Path -Path .\ControllerB.txt)
    {Remove-Item .\ControllerB.txt}
if(Test-Path -Path .\vol_to_LUN_commands.txt)
    {Remove-Item .\vol_to_LUN_commands.txt}

#LUN Size
$capacity_TB = 5.55
#Number of disk pools to create
$disk_pool_count = "1"
#ESeries controller that owns volumes. This command is to initialize the variable. Actual controller name is enumerated based on the LUN number. Even numbered LUNs going to one controller and odd ones going to the other.
$owner = ""
#eseries host group
$host_group = "Example_host_group"
#Number of LUNs
$LUNCount = "136"

#Count up to LUNcount and create commands for both controllers alternatively. This is done using the modulo operation to check for even or odd value of "i" and create commands accordingly.
for( $i=1; $i -le $LUNCount; $i++){
    if($i % 2 -eq 1 ){
        $owner = "A"
        }
    elseif($_ % 2 -eq 0 ){
        $owner = "B"
        }
    #Construct volume and LUN names with 0 padding to the left
    $volume = $i.ToString("000")
    $LUN = $i.ToString("000")
    #Construct commands and add them to text files. The "append" parameter prevents each iteration from starting a new file and erasing previous iteration's output
    "show `"Creating volume $volume on disk pool Disk_Pool_$disk_pool_count.`";" | out-file Controller$owner.txt -append -noclobber
    "//This command creates volume <$volume> on disk pool <Disk_Pool_$disk_pool_count>." | out-file Controller$owner.txt -append -noclobber
    "create volume diskPool=`"Disk_Pool_$disk_pool_count`" userLabel=`"$volume`" owner=$owner capacity=$capacity_TB TB dataAssurance=enabled mapping=none;" | out-file Controller$owner.txt -append -noclobber
    "show `"Setting additional attributes for volume $volume.`";" | out-file Controller$owner.txt -append -noclobber
    "// Configuration settings that can not be set during Volume creation." | out-file Controller$owner.txt -append -noclobber
    "set volume[`"$volume`"] cacheWithoutBatteryEnabled=false;" | out-file Controller$owner.txt -append -noclobber
    "set volume[`"$volume`"] cacheFlushModifier=5;" | out-file Controller$owner.txt -append -noclobber
    "set volume[`"$volume`"] cacheWithoutBatteryEnabled=false;" | out-file Controller$owner.txt -append -noclobber
    "set volume[`"$volume`"] mirrorEnabled=true;" | out-file Controller$owner.txt -append -noclobber
    "set volume[`"$volume`"] readCacheEnabled=true;" | out-file Controller$owner.txt -append -noclobber
    "set volume[`"$volume`"] writeCacheEnabled=true;" | out-file Controller$owner.txt -append -noclobber
    "set volume[`"$volume`"] mediaScanEnabled=true;" | out-file Controller$owner.txt -append -noclobber
    "set volume[`"$volume`"] redundancyCheckEnabled=false;" | out-file Controller$owner.txt -append -noclobber
    "show `"Creating Volume-to-LUN Mapping for Volume $volume to LUN $LUN under Host $host_group.`";" | out-file vol_to_LUN_commands.txt -append -noclobber
    "set volume [`"$volume`"] logicalUnitNumber=$LUN host=`"$host_group`";" | out-file vol_to_LUN_commands.txt -append -noclobber
}
Write-Output "Files created at $location"
