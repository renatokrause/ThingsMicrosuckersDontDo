# ATENTION: Run from broker server

# ATENTION: EDIT THIS
$CollectionName = "CollectionName"
$FSProfileList = "server1.f.q.d.n", "server2.f.q.d.n"

$SleepTime = 15 #in seconds

$ReportPath = "c:\temp"

#Get all SMB files opened and get all RD VHDX file paths
$VHDXFilePaths = Invoke-Command -ComputerName $FSProfileList -ScriptBlock { 
    $SMBFiles = Get-SmbOpenFile 
    foreach ($SMBFile in $SMBFiles) {
        if ($SMBFile.Path -match ".*VDIPool.*") { #                                                                 <<<<<<<---------- COLOCAR EXPRESSAO REGULAR PARA IDENTIFICAR VDIPool
            New-Object -TypeName PSCustomObject -Property @{VHDXFilePath=$SMBFile.Path}
        }
    }
}

#Get SID from path and sAMAccountName from AD. Then verify sessions and close orphans
$result = foreach ($VHDXFilePath in $VHDXFilePaths) {
    $SID = $VHDXFilePath.Substring( 0 , 10 ) #                                                                 <<<<<<<---------- acertar substring begin,len para extrair exatamente o SID
    $sAMAccountName = (Get-ADUser -Filter {sAMAccountName -eq $SID}).sAMAccountName #                              <<<<<<<---------- acertar o filtro para filtrar o usuario por SID

    #Verify any type of session
    $Sessions = Get-RDUserSession -ConnectionBroker $ActiveBroker -CollectionName $CollectionName | Where-Object {$_.SessionState -eq 'STATE_DISCONNECTED' -AND $_.HostServer -match $server.Server} # <<<<<<<---------- acertar o filtro para filtrar o usuario em qualquer sessionstate
    if ($Sessions) { #                                                                                             <<<<<<<---------- testar pra ver se esse if funciona
        #Close SMB
        Invoke-Command -ComputerName $FSProfileList -ScriptBlock { 
            param($SID)
            if ($SID) {
                Get-SmbOpenFile | Where-Object -Property ShareRelativePath -Match $SID | Close-SmbOpenFile -Force
            }
        } -ArgumentList $SID
    }

    New-Object -TypeName PSCustomObject -Property @{Broker=$ActiveBroker; VHDXFilePath=$VHDXFilePath.Path; UserSID=$SID; sAMAccountName=$sAMAccountName}
}
$ReportFilePath = $ReportPath + "\ReportRDCloseForgottenVHDX$(Get-Date -Format "-yyyy-MM-d-HH-mm-ss").csv"
$result | Export-Csv -Path $ReportFilePath -NoTypeInformation -Force
