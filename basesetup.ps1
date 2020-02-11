##Most installation files if not downloaded should be found here:  E:\Installation files



#########################################################################################################################################

Rename-Computer -NewName "IDSDEV"
#modification adapteur de DHCP a IP fix - DNS,  gateway  , etc
cls
$adapter = Get-NetAdapter -Name Ethernet*
New-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -IPAddress 192.168.250.100 -PrefixLength 24 -DefaultGateway 192.168.250.3
Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses ("172.20.8.9","172.16.4.3","172.20.8.116","172.16.4.12")
#########################################################################################################################################


#########################################################################################################################################
# Install choco from Internet
# need to close and reOpen ISE

cLs
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))



#choco installed product here
#Nuget
choco install nuget.commandline
################### INSTALLATION agentransack ###################### 
$products= @("agentransack","filezilla","notepadplusplus","7zip","googlechrome") 
Foreach ($product in $products)
{
Write-Output "Starting Install of $product"
choco install $product  -force -y
if ($lastexitcode -ne "0")
{
	throw "There was an error installing $product"
}
Write-Output "Install of $product Finished"
}


#########################################################################################################################################
#choco installed product here
#Nuget
choco install nuget.commandline
################### INSTALLATION agentransack ###################### 
Write-Output "Starting Install of agentransack"
choco install agentransack  -force -y
if ($lastexitcode -ne "0")
{
	throw "There was an error installing agentransack"
}
Write-Output "Install of agentransack Finished"

################### INSTALLATION ncftp ###################### 
Write-Output "Starting Install of ncftp"
choco install ncftp -force -y
if ($lastexitcode -ne "0")
{
	throw "There was an error installing ncftp"
}
Write-Output "Install of ncftp Finished"



################### INSTALLATION filezilla ###################### 
Write-Output "Starting Install of filezilla"
choco install filezilla -force -y
if ($lastexitcode -ne "0")
{
	throw "There was an error installing filezilla"
}
Write-Output "Install of filezilla Finished"


################### INSTALLATION Upack ###################### 
Write-Output "Starting Install of Upack"
choco install upack -version 1.0.1 -force -y
if ($lastexitcode -ne "0")
{
	throw "There was an error installing Upack"
}
Write-Output "Install of Upack Finished"

################### INSTALLATION NotePad++ ######################
Write-Output "Starting Install of Notepad ++"
choco install notepadplusplus -force -y
if ($lastexitcode -ne "0")
{
	throw "There was an error installing NotePad ++"
}
Write-Output "Install of Notepad ++ Finished"

################### INSTALLATION 7zip ######################
Write-Output "Starting Install of 7zip"
choco install 7zip -force -y
if ($lastexitcode -ne "0")
{
	throw "There was an error installing 7zip"
}
Write-Output "Install of 7zip Finished"

################### INSTALLATION Google Chrome ######################
Write-Output "Starting Install of Google Chrome "
choco install  googlechrome -force -y
if ($lastexitcode -ne "0")
{
	throw "There was an error installing Google Chrome "
}
Write-Output "Install of Google Chrome  Finished"

################### Creation of temp folder to Download Source ######################
$tempFolder = "C:\Temp"
if (-Not (Test-path $tempFolder))
{
	New-Item $tempFolder -type Directory -Force
}

#########################################################################################################################################





#########################################################################################################################################
#Installation AD  dev.uni.

Install-windowsfeature AD-domain-services
Import-Module ADDSDeployment
Install-ADDSForest -CreateDnsDelegation:$false -DatabasePath "C:\Windows\NTDS" -DomainMode Win2012R2 -DomainName "dev.uni" -DomainNetbiosName "devuni" -ForestMode Win2012R2 -InstallDns:$true -LogPath "C:\Windows\NTDS" -NoRebootOnCompletion:$false -SysvolPath "C:\Windows\SYSVOL" -Force:$true 

Add-DnsServerPrimaryZone -DynamicUpdate Secure -NetworkId ‘192.168.250.0/24’ -ReplicationScope Domain


# Installation outils admin
Import-Module ServerManager
Add-WindowsFeature RSAT-ADDS-Tools

#reset des DNS apres la mise en place de AD
$adapter = Get-NetAdapter -Name Ethernet*
Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses ("192.168.250.100","172.20.8.9","172.16.4.3","172.20.8.116","172.16.4.12")

closing firewalls
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False


Install-WindowsFeature -Name FS-DFS-Namespace -IncludeManagementTools

#Create the SMB share folders:
mkdir  "D:\DFSRoots"
Mkdir "D:\DFSRoots\Production$"
Mkdir "D:\DFSRoots\Production$\ITOperations"
#Create the shares
New-SMBShare -Name "Production$" -Path "D:\DFSRoots\Production$" -FullAccess "Everyone"

#Create the DFS Root
New-DfsnRoot -Path \\dev.uni\production$ -TargetPath \\Idsdev\Production$ -Type DomainV2
  
#variables env Itoperation

[Environment]::SetEnvironmentVariable("ItOperations_Path", "\\$env:UserDnsDomain\production$\ITOperations", "Machine")




################### CONFIGURATION FEATURE WINDOWS ######################

Configuration Features    
{        
	Import-DscResource –ModuleName 'PSDesiredStateConfiguration'	
	Node localhost
	{
		WindowsFeature Framework
		{          
			Name= "Net-Framework-Core"
			Ensure = "Present"
		}
		WindowsFeature Web-Mgmt-Console
		{          
			Name= "Web-Mgmt-Console"
			Ensure = "Present"
		}
		WindowsFeature NET45 {
           Name = 'NET-Framework-45-Core'
           Ensure = 'Present'
		}
        WindowsFeature AD-PowerShell
		{          
			Name= "RSAT-AD-PowerShell"
			Ensure = "Present"
		}
	}
}

 $config = Features
 Start-DscConfiguration -path $config.psparentpath -wait -Verbose -force
 
# download SSMS from https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms
# Install SSMS-Setup-ENU.exe




################### CONFIGURATION CACHED CREDENTIALS DEV ONLY ######################
#Put your user here   $PSPuser  $Pass
$PSPuser = "PSP\Mapril"
$Pass = "Audrey1968"
$domain = $env:UserDnsDomain
$UserDomain = $env:USERDOMAIN
        
		Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
		Install-Module CredentialManager -force
		New-StoredCredential -Target "nuget.investpsp.ca" -UserName $PSPuser -Password $Pass -Type DomainPassword -Persist LocalMachine
		New-StoredCredential -Target "alm.investpsp.ca" -UserName $PSPuser -Password $Pass -Type DomainPassword -Persist LocalMachin
		New-StoredCredential -Target "docker.investpsp.ca" -UserName $PSPuser -Password $Pass -Type DomainPassword -Persist LocalMachin
     		New-StoredCredential -Target "172.20.8.108" -UserName $PSPuser -Password $Pass -Type DomainPassword -Persist LocalMachine
		New-StoredCredential -Target "172.20.8.108" -UserName $PSPuser -Password $Pass -Type Generic -Persist LocalMachine
		New-StoredCredential -Target "tfsfileshare.psp.int" -UserName $PSPuser -Password $Pass -Type DomainPassword -Persist LocalMachine
		New-StoredCredential -Target "tfsfileshare.psp.int" -UserName $PSPuser -Password $Pass -Type Generic -Persist LocalMachine



#########################################################################################################################################
# installtion des packaage ssdt, dacfx,...

Write-Output "Starting Download of SSDT from Proget"
upack.exe install SSDT --source=http://nuget.investpsp.ca/upack/IdsDevSupportUniversal --target=.\SSDT --overwrite
if ($lastexitcode -ne "0")
{
	throw "There was an error downloading SSDT package from Proget"
}
else
{
	Write-Output "Download of SSDT finished"
}

Write-output "Starting Download of DacFX from Proget"
upack.exe install DacFX --source=http://nuget.investpsp.ca/upack/IdsDevSupportUniversal --target=$GuidPath\DacFX --overwrite
if ($lastexitcode -ne "0")
{
	throw "There was an error downloading DacFX package from Proget"
}
else
{
	Write-Output "Download of Dacfx Finished"
}



################### INSTALLATION DACFX ######################
try
{
	Write-output "Starting the Installation of Dacfx x64"
	Start-Process $GuidPath\DacFX\x64\DacFramework.msi /passive -Wait
	Write-output "Installation of Dacfx x64 Finished"
}
catch
{
	throw "There was an error installing Dacfx x64"
}

try
{
	Write-output "Starting the Installation of Dacfx x86"
	Start-Process $GuidPath\DacFX\x86\DacFramework.msi /passive -Wait
	Write-output "Installation of Dacfx x86 Finished"
}
catch
{
	throw "There was an error installing Dacfx x86"
}

################### INSTALLATION SSDT ######################
try
{
	Write-output "Starting Installation of SSDT"
	Start-Process $GuidPath\SSDT\SSDTSETUP.EXE -argumentlist "INSTALLALL /passive /norestart" -Wait -NoNewWindow
}
catch
{
	throw "Installation of SSDT failed with error: $_"
}

#########################################################################################################################################
# Installation Microsoft® SQL Server® 2016 Feature Pack

################### INSTALLATION VISUAL STUDIO 2015 ######################
# copy $/src_ALM/Sources/Tfs/BuildServerInstall/Main/Tools/InstallationFiles to a sub directory of where your are running these scripts

$InstallationPath2015 = "D:\Program Files (x86)\Microsoft Visual Studio 14.0"
$ProductKey2015 = "DF8W3-WNYBK-CFVWC-WRJPY-F9CF7"
$Args = "/passive /CustomInstallPath $InstallationPath2015 /Productkey $ProductKey2015 /norestart"
Start-Process .\InstallationFiles\VS2015-Enterprise-Update3.exe -argumentlist $Args -Wait

################### INSTALLATION Microsoft Analysis Services ######################
Install-Package Microsoft.AnalysisServices.Server -Version 13.0.1601.5 -Source http://nuget.investpsp.ca/nuget/IdsDevSupportNuget/


################### copier des WEbApp ver srepertoire de Visual studio 2017 ######################
#Copier le folder C:\Program Files (x86)\MSBuild\Microsoft\VisualStudio\v14.0\WebApplication
#Vers C:\Program Files (x86)\MSBuild\Microsoft\VisualStudio\v15.0\WebApplication
$fromdir = "C:\Program Files (x86)\MSBuild\Microsoft\VisualStudio\v14.0\WebApplications"
$tocreate = "C:\Program Files (x86)\MSBuild\Microsoft\VisualStudio\v15.0\WebApplications"
$todir = "C:\Program Files (x86)\MSBuild\Microsoft\VisualStudio\v15.0"

if (-Not (Test-path $tocreate))
{
	New-Item $tocreate -type Directory -Force
}
Copy-Item $fromdir -Destination $todir -recurse

################### pour Livraison d une Image ######################
# 
#
$RemDirs =@("D:\DeployTest","D:\PackageTest","D:\PowershellTest", "D:\TestDir")
Foreach ($Remdir in $REmdirs) {
if(Test-Path $Remdir)
	{
		Remove-Item $Remdir\*.* -Force -Recurse
	}
	New-Item $RemDir -ItemType Directory
}


# modification clef de registre execution policy a Bypass
$RegistryPath = "HKLM:SOFTWARE\Policies\Microsoft\Windows\PowerShell"
$KeyName = "ExecutionPolicy"
$KeyValue = "Bypass"
New-ItemProperty -Path $RegistryPath -Name $KeyName -Value $KeyValue -PropertyType String -Force

################### Powershell pour Azure ######################
# 
#
Install-Module -Name AzureRM -AllowClobber
Import-Module -Name AzureRM