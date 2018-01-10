import-module dataontap
$controllername=Get-Content j:\Scripts\hostlist.txt
Write-Host "Enter a user account with full rights within the NetApp Filer"
$currentcontroller = Connect-NcController $controllername -Credential (Get-Credential -message "Enter credentials for the filer")
Write-Host "Please make a selection:"
Write-Host "1. Identify and export old snapshot information to file"
Write-Host "2. Identify and delete old snapshots"
$choice = Read-Host -Prompt 'Make a choice and enter 1 or 2'

if ($choice -eq 2){
	$maxvolpercentused = Read-Host -Prompt 'Input maximum volume usage %'
	$age = Read-Host -Prompt 'Input age of snapshots in days'
	$maxsnapshotdesiredage = (get-date).adddays(-($age))
	$desiredageformated = Get-Date (Get-Date).AddDays(-($age)) -format D
	Write-Host "Getting NetApp volume snapshot information..."
	$volsnapshots = get-ncvol | get-ncsnapshot
	Write-Host "Getting NetApp volume information..."
	$vollowspace = get-ncvol | where-object {$_.percentageused -gt "$maxvolpercentused"}
	if ($vollowspace -eq $null){
		Write-Host "All volumes have sufficient free space!"
 }

else {
	Write-Host "The following NetApp volumes have low free space, and should be checked."
 	$vollowspace
# 	Read-Host "Press Enter to continue..."
 	Write-Host "Getting volume snapshot information for volumes with low space..."
 	$vollowspace | get-ncsnapshot | sort-object targetname | select-object targetname,name,created,@{Name="TotalGB";expression={$_.total/1GB}}
 }

	Write-Host "Checking for snapshots older than $age days which was $desiredageformated"
	Write-Host "Finding old snapshots..."
	$oldsnapshots = get-ncvol | get-ncsnapshot | where-object {$_.created -lt "$maxsnapshotdesiredage"}

	if ($oldsnapshots -eq $null){
		Write-Host "No old snapshots exist!"
 }

	else {
 		Write-Host "The following snapshots are longer than the identified longest retention period..."
 		$oldsnapshots | select-object targetname,name,created,@{Name="TotalGB";expression={$_.total/1GB}}
 		Read-Host "Press Enter to continue..."
		Write-Host "You will now be asked if you would like to delete each of the above snapshots."
		Write-Host "Note that Yes to All and No to All will not function.."
		Write-Host "If you elect to delete them, it is NON-REVERSIBLE!!!"
		$oldsnapshots | foreach-object {$_ | select-object targetname,name,created,@{Name="TotalGB";expression={$_.total/1GB}} ; $_ | remove-ncsnapshot -confirm:$true}
 	}
}

elseif ($choice -eq 1) {
	$maxvolpercentused = Read-Host -Prompt 'Input maximum volume usage %'
	$age = Read-Host -Prompt 'Input age of snapshots in days'
	$maxsnapshotdesiredage = (get-date).adddays(-($age))
	$desiredageformated = Get-Date (Get-Date).AddDays(-($age)) -format D
	Write-Host "Getting NetApp volume snapshot information..."
	$volsnapshots = get-ncvol | get-ncsnapshot
	Write-Host "Getting NetApp volume information..."
	$vollowspace = get-ncvol | where-object {$_.percentageused -gt "$maxvolpercentused"}

if ($vollowspace -eq $null){
 	Write-Host "All volumes have sufficient free space!"
 }

else {
 	Write-Host "The following NetApp volumes have low free space, and should be checked."
 	$vollowspace
# 	Read-Host "Press Enter to continue..."
 	Write-Host "Getting volume snapshot information for volumes with low space..."
 	$vollowspace | get-ncsnapshot | sort-object targetname | select-object targetname,name,created,@{Name="TotalGB";expression={$_.total/1GB}}
 }
 
Write-Host "Checking for snapshots older than $age days which was $desiredageformated"
Write-Host "Finding old snapshots..."
$oldsnapshots = get-ncvol | get-ncsnapshot | where-object {$_.created -lt "$maxsnapshotdesiredage"}

if ($oldsnapshots -eq $null){
 	Write-Host "No old snapshots exist!"
 }

else {
 	Write-Host "The following snapshots are longer than the identified longest retention period..."
 	$oldsnapshots | select-object targetname,name,created,@{Name="TotalGB";expression={$_.total/1GB}}
 	Write-Host "The following volumes have lower space than the specified threshold of $$maxvolpercentused"
 	$vollowspace
# 	Read-Host "Press Enter to continue..."
	Write-Host "Now saving results to file..."
 	$oldsnapshots | foreach-object {$_ | select-object targetname,name,created,@{Name="TotalGB";expression={$_.total/1GB}} ; $_ | Export-Csv -Path $("c:\scripts\" + $controllername + "_oldsnapshots.csv") -Encoding ascii -NoTypeInformation -force}
 	$vollowspace = get-ncvol | where-object {$_.percentageused -gt "$maxvolpercentused"} | Export-Csv -Path $("c:\scripts\" + $controllername + "_lowspacevols.csv") -Encoding ascii -NoTypeInformation -force}
	Write-Host "Information is saved to file located at: $("c:\scripts\" + $controllername + "_oldsnapshots.csv") and $("c:\scripts\" + $controllername + "_lowspacevols.csv")"
}

else {
	Write-Host "Invalid choice, please enter either 1 or 2"
}

Write-Host "Script completed!"
