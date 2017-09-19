#Cache show
$cache_names = "ad-to-netbios-domain","netbios-to-ad-domain","ems-delivery","log-duplicate","name-to-sid","sid-to-name","schannel-key","username-to-creds","ad-sid-to-local-membership","nis-group-membership","ldap-groupid-to-name","ldap-groupname-to-id","ldap-username-to-creds","ldap-userid-to-creds","ldap-userid-to-name","nis-groupname-to-id","nis-groupid-to-name","nis-username-to-creds","nis-userid-to-creds","groupname-to-info","groupid-to-name","userid-to-name","username-to-info","ldap-netgroupname-to-members","ldap-groupname-to-info-batch","ldap-username-to-info-batch","name-mapping-windows-to-unix"
foreach ($cache in $cache_names){
	Write-output "`n$cache"
	$ret = Invoke-NcSsh "set -privilege diag -confirmations off; secd cache show-config -node nac-sim04-01 -cache-name $cache" | Out-String
	(Write-Output $ret).Split("`n") | Select-String -Pattern "Current"
	#$ret
}

#Clear Cache
if($global:CurrentNcController -eq "CONTROLLER_NAME"){
$cache_names = "ad-to-netbios-domain","netbios-to-ad-domain","ems-delivery","log-duplicate","name-to-sid","sid-to-name","schannel-key","username-to-creds","ad-sid-to-local-membership","nis-group-membership","ldap-groupid-to-name","ldap-groupname-to-id","ldap-username-to-creds","ldap-userid-to-creds","ldap-userid-to-name","nis-groupname-to-id","nis-groupid-to-name","nis-username-to-creds","nis-userid-to-creds","groupname-to-info","groupid-to-name","userid-to-name","username-to-info","ldap-netgroupname-to-members","ldap-groupname-to-info-batch","ldap-username-to-info-batch","name-mapping-windows-to-unix"
foreach ($cache in $cache_names){
	Invoke-NcSsh "set -privilege diag -confirmations off; secd cache clear -vserver nac-sim04-svm01  -node nac-sim04-01 -cache-name $cache" | Out-Null
	Write-Host "cleared $cache "
	}
}
else {Write-Host "Not a sim!!!`nUse `"Connect-NcController CONTROLLER_NAME`" to connect to sim and try again"}

# clear-host
#Connect-NcController CONTROLLER_NAME | select name,address,version
#$Comp = $global:CurrentNcController.Address.IPAddressToString
#$test = (Test-Connection -ComputerName $comp -Count 5  | measure-Object -Property ResponseTime -Average).average 
#$response = ($test -as [int] ) 

$sw_base = [Diagnostics.Stopwatch]::StartNew()
	1..5 | % {get-nctime | out-null }
$sw_base.Stop()
$time_base = $sw_base.Elapsed.TotalSeconds/5
$time_base_total = $sw_base.Elapsed.TotalSeconds

#Query time measurement
$users = "USER_NAME"
$user_number = $users.Length
$sw = [Diagnostics.Stopwatch]::StartNew()
#1..10 | % {Invoke-NcSsh "set -privilege diag -confirmations off; diag secd authentication show-creds -node nac-sim04-01 -vserver nac-sim04-svm01 -unix-user-name USER_NAME"}
foreach ($user in $users){
	#Invoke-NcSsh "set -privilege diag -confirmations off; diag secd authentication translate -node nac-sim04-01 -vserver nac-sim04-svm01 -unix-user-name $user" | out-null
	Invoke-NcSsh "set -privilege diag -confirmations off; diag secd authentication show-creds -node nac-sim04-01 -vserver nac-sim04-svm01 -unix-user-name $user -list-name true -list-id true" | out-null
	#Invoke-NcSsh "set -privilege diag -confirmations off; getxxbyyy getpwbyname -node nac-sim04-01 -vserver nac-sim04-svm01 -username $user" | out-null
}
#Invoke-NcSsh "set -privilege diag -confirmations off; getxxbyyy getpwbyname -node nac-sim04-01 -vserver nac-sim04-svm01  -show-source true -username USER_NAME"
$sw.Stop()
$time = $sw.Elapsed.TotalSeconds/$user_number
$time_total = $sw.Elapsed.TotalSeconds
$ldap_time = $time - $time_base
$ldap_time = [math]::round($ldap_time,3)
$time_total= [math]::round($time_total,3)
#write-host "Ping Time for $comp is $response ms"       
#Write-host "Average Total Time: $time Seconds"
#write-host "Total Baseline Time: $time_base_total Seconds"
#Write-host "Average Baseline Time: $time_base Seconds"
write-host  "Total LDAP lookup time for $user_number users:`t`t$time_total Seconds"       
Write-host  "Average LDAP Lookup Time/user:`t`t`t$ldap_time Seconds"
