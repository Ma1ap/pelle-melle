$test = '172.5.1.50'
# If ($test -match "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}" ) {Write-Host 'IP Address Detected'}
# If ($test -match "172.5.\d{1,3}\.\d{1,3}" ) {Write-Host 'IP Address Detected'}
if ($test -match "(172.5.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b)") {Write-Host 'IP Address Detected'}
else {Write-Host 'Computer Name Detected'}


