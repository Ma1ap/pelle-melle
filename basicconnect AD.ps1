Install-Module -Name MSonline
connect-msolservice -credential $msolcred



Set-MsolDirSyncEnabled -EnableDirSync $false
(Get-MSOLCompanyInformation).DirectorySynchronizationEnabled
