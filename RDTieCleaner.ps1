invoke-expression -Command .\RDDisconnectAwayUser.ps1
Start-Sleep -Seconds 1800 # 30 minutes
invoke-expression -Command .\RDCloseForgottenVHDX.ps1
