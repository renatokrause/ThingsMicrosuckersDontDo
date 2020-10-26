# ATENTION: Run from broker server

# ATENTION: EDIT THIS
$CollectionName = "CollectionName"
$ReportPath = "c:\temp"

#Get ActiveBroker and all Hyper-V Servers of Cluster
$ThisBroker = (Get-WmiObject Win32_ComputerSystem).Name + "." + (Get-WmiObject Win32_ComputerSystem).Domain
$ActiveBroker = (Get-RDConnectionBrokerHighAvailability -ConnectionBroker $ThisBroker).ActiveManagementServer
$Servers = Get-RDServer -ConnectionBroker $ActiveBroker | Where-Object {$_.Roles -eq "RDS-VIRTUALIZATION"} | sort server

#Force logoff of each user with diconnected state
$result = foreach ($Server In $Servers) {
    $Sessions = Get-RDUserSession -ConnectionBroker $ActiveBroker -CollectionName $CollectionName | Where-Object {$_.SessionState -eq 'STATE_DISCONNECTED' -AND $_.HostServer -match $server.Server}
    foreach ($Session In $Sessions) {
        Invoke-RDUserLogoff -HostServer $Session.HostServer -UnifiedSessionID $Session.UnifiedSessionId -Force
        New-Object -TypeName PSCustomObject -Property @{Broker=$ActiveBroker; RDSVirtualizationServer=$SMBFile.Path; RDUnifiedSessionId=$Session.UnifiedSessionId}
    }   
} 
$ReportFilePath = $ReportPath + "\ReportRDDisconnectAwayUser$(Get-Date -Format "-yyyy-MM-d-HH-mm-ss").csv"
$result | Export-Csv -Path $ReportFilePath -NoTypeInformation -Force
