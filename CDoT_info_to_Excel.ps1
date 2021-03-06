<#
	.NOTES
	===========================================================================
	 Created by:   	Kumar Challa
	===========================================================================
	.DESCRIPTION
		A script to export NetApp cluster details to an Excel file.
		Pre-requisites:
		1.	Store encrypted password securely in a text file
				read-host -assecurestring | convertfrom-securestring  | Set-Content -Path "D:\Scripts\Projects\Storage\creds.txt"
		2.	Coltroller list to be listed in the file:
				$controller_list (In this case d:\Scripts\Projects\Storage\system_list.txt)
		3.	The "ImportExcel" PowerShell module has to be installed for this script to work. The module can be found here:
				https://github.com/RamblingCookieMonster/ImportExcel
		 	Or, it can be installed using the following command if using PowerShell V5 or above
				"Install-Module -Name ImportExcel"
#>

# 	Initialization
set-location c:\scripts\
import-module dataontap
import-module importexcel


# 	File Locations
$report_folder 		= "c:\Scripts\"

# 	Credentials
$mycreds_c = $(IMPORT-CLIXML "C:\Scripts\creds.xml")

#	Get list of controllers
[string[]]$controllers = "controller1";"controller2";"controller3"

#	Testing


# 	Functions
function get-share_info
{
    $mixedshares = @()
    $mixed = @()
    $shares = Get-NcCifsShare | Where-Object{ $_.Path -ne "/" }
    foreach ($share in $shares)
    {
        $mixed = New-Object PSObject
        Add-Member -InputObject $mixed -MemberType NoteProperty -Name "ShareName" 	-Value $share.sharename
        Add-Member -InputObject $mixed -MemberType NoteProperty -Name "Volume" 		-Value $share.volume
        Add-Member -InputObject $mixed -MemberType NoteProperty -Name "Vserver" 	-Value $share.vserver
        Add-Member -InputObject $mixed -MemberType NoteProperty -Name "Comment" 	-Value $share.comment
        Add-Member -InputObject $mixed -MemberType NoteProperty -Name "Path" 		-Value $share.path
        Add-Member -InputObject $mixed -MemberType NoteProperty -Name "ACL" 		-Value ($share.acl | out-string).Trim()
        $mixedshares += $mixed
    }
    $mixedshares
    return
}


#	Main Block
$date = Get-Date -format MM.dd.yy
clear-host
Write-Host "===================================================================="
Write-Host "Information is gathered from the following NetApp systems:"
$controllers
Write-Host "===================================================================="
foreach ($controller in $controllers)
{
    $cluster_details = @()
    Connect-NcController -Name $controller -Credential $mycreds_c | Out-Null
    Write-Host "Connected to " -NoNewline
    Write-Host -ForegroundColor yellow "$controller" -NoNewline
    Write-Host " Gathering Information..."
    $cluster_details = @{
        Volumes   	  = { Get-NcVol  | select Name, Vserver, Aggregate, JunctionPath, Used, State, Dedupe, @{Name="Export Policy"; Expression={ $_.VolumeExportAttributes.Policy } } | sort Name}
        Aggregates 	  = { Get-NcAggr | select AggregateName, Nodes, State, Used, Volumes, Disks, RaidType, RaidSize | sort AggregateName}
        Nodes	  	  = { Get-NcNode | select Node, IsNodeHealthy, IsNodeClusterEligible, IsEpsilonNode, NodeLocation, NodeModel, NodeNvramId, NodeSerialNumber, NodeStorageConfiguration, NodeSystemId, NodeUptimeTS, ProductVersion, NodeVendor, NvramBatteryStatus, NodeUuid, NodeOwner, EnvFailedFanMessage, EnvFailedPowerSupplyMessage | sort Node }
        Shares	      = { get-share_info }
        Exports	      = { Get-NcExportRule | select RuleIndex, ClientMatch, Protocol, RoRule, RwRule, PolicyName | sort PolicyName, RuleIndex }
        SVMs		  = { Get-NcVserver | sort vserver, vservertype }
        Network	      = { Get-NcNetInterface | select Vserver, InterfaceName, FirewallPolicy, OpStatus, Address, DataProtocols, @{ Name = "DNS Name"; Expression= { [System.Net.Dns]::GetHostByAddress($ipAddress).Hostname } } | sort Vserver, InterfaceName }
        SnapMirror 	  = { Get-NcSnapmirror }
        VLAN          = { Get-NcNetPortVlan }
        RoutingTable  = { Get-NcNetRoute }
        LIFRoutes     = { Get-NcNetRouteLif }
        IfGroups      = { Get-NcNetPortIfgrp | select Node, IfgrpName, Ports, Mode, DistributionFunction | sort node, IfgrpName }

    }
    Write-Host "Generating Excel file for $controller at location " -NoNewline
    Write-Host -ForegroundColor Green "$report_folder$date`_$controller.xlsx"
    Export-MultipleExcelSheets -Show -AutoSize "$report_folder$date`_$controller.xlsx" $cluster_details
    Write-Host "Done!"
    Start-Sleep -Seconds 2
}

Write-Host "Press any key to continue..."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
