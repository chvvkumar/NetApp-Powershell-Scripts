if( $Host -and $Host.UI -and $Host.UI.RawUI ) {
  $rawUI = $Host.UI.RawUI
  $oldSize = $rawUI.BufferSize
  $typeName = $oldSize.GetType( ).FullName
  $newSize = New-Object $typeName (500, $oldSize.Height)
  $rawUI.BufferSize = $newSize
}
set-location C:\ | Out-Null
import-module dataontap | Out-Null
Set-ExecutionPolicy Unrestricted -force | Out-Null
$secpasswd  = ConvertTo-SecureString PASSWORD -AsPlainText -Force
$mycreds_c = New-Object System.Management.Automation.PSCredential -Argumentlist "admin",$secpasswd 
Connect-NcController -Name CONTROLLER_IP_NAME -Credential $mycreds_c  | Out-Null

function Get-UnixDate ($UnixDate) {
   [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($UnixDate))
}

$mirrors = @() | Out-Null

Get-NcSnapmirror -Destination SVM_NAME: | %{ 
    $sm = "" | Select "Date","Source","Destination","Progress","State","Current Lag Time","Last Transfer Size","Last Transfer Time","Status"

    $sm.Date = Get-Date -Format g
    $sm.Source = $_.SourceLocation
    $sm.Destination = $_.DestinationLocation
    $sm.Status = $_.Status
	$sm.Progress = ConvertTo-FormattedNumber $_.SnapshotProgress Datasize "0.0" 
    $lastTransferTime = Get-UnixDate -UnixDate $_.LastTransferEndTimestamp
    $lagTime = New-TimeSpan -Start $lastTransferTime -End (Get-Date)

    $sm."Current Lag Time" = '{0} days, {1} hrs, {2} mins, {3} secs' -f $lagTime.Days, $lagTime.Hours, $lagTime.Minutes, $lagTime.Seconds
    $sm."Last Transfer Size" = ConvertTo-FormattedNumber $_.lasttransfersize Datasize "0.0"

    $transferTime = New-TimeSpan -Seconds $_.LastTransferDuration
    $sm."Last Transfer Time" = '{0} days, {1} hrs, {2} mins, {3} secs' -f $transferTime.days, $transferTime.Hours, $transferTime.Minutes, $transferTime.Seconds
    $sm.State = $_.MirrorState

    $mirrors += $sm

} | Out-Null

$mirrors | ft -AutoSize -HideTableHeaders | out-file FILENAME.txt -encoding ASCII -append -NoClobber 
(gc FILENAME.txt) | ? {$_.trim() -ne "" } | set-content FILENAME.txt
