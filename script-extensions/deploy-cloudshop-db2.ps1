param($domain, $user, $password, $dbsource, $sqlConfigUrl)

$logs    = "C:\Logs"
$data    = "C:\Data"
$backups = "C:\Backup" 
$script  = "C:\Script" 

[system.io.directory]::CreateDirectory($logs)
[system.io.directory]::CreateDirectory($data)
[system.io.directory]::CreateDirectory($backups)
[system.io.directory]::CreateDirectory($script)
[system.io.directory]::CreateDirectory("C:\SQLDATA")

$sqlaccount = "NT Service\MSSQLSERVER"
$localadmins = "BUILTIN\Administrators"
secedit /export /cfg C:\secexport.txt /areas USER_RIGHTS
$line = Get-Content C:\secexport.txt | Select-String 'SeManageVolumePrivilege'
(Get-Content C:\secexport.txt).Replace($line,"$line,$sqlaccount,$localadmins") | Out-File C:\secimport.txt
secedit /configure /db secedit.sdb /cfg C:\secimport.txt /overwrite /areas USER_RIGHTS /quiet

$splitpath = $sqlConfigUrl.Split("/")
$fileName = $splitpath[$splitpath.Length-1]
$destinationPath = "$script\configure-sql2.ps1"
# Download config script
(New-Object Net.WebClient).DownloadFile($sqlConfigUrl,$destinationPath);

# Get the Adventure works database backup 
# Only download on the first sql server
$dbdestination = "C:\SQLDATA\AdventureWorks.bak"
# Invoke-WebRequest $dbsource -OutFile $dbdestination

# Add a 5 min delay to accommodate drift in SQL image configuration. 
Start-Sleep -s 300

$password =  ConvertTo-SecureString "$password" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("$env:COMPUTERNAME\$user", $password)

Enable-PSRemoting -force
Set-NetFirewallRule -Name "WINRM-HTTP-In-TCP-PUBLIC" -RemoteAddress Any
Invoke-Command -FilePath $destinationPath -Credential $credential -ComputerName $env:COMPUTERNAME -ArgumentList "Password", $password
Disable-PSRemoting -Force

New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action allow 
New-NetFirewallRule -DisplayName "SQL AG Endpoint" -Direction Inbound -Protocol TCP -LocalPort 5022 -Action allow 
New-NetFirewallRule -DisplayName "SQL AG Load Balancer Probe Port" -Direction Inbound -Protocol TCP -LocalPort 59999 -Action allow 

# Disable IE Enhanced Security Configuration
$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"

New-Item -Path $adminKey -Force
New-Item -Path $UserKey -Force
New-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
New-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0

$HKLM = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\1"
$HKCU = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\1"
Set-ItemProperty -Path $HKLM -Name "1803" -Value 0
Set-ItemProperty -Path $HKCU -Name "1803" -Value 0
$HKLM = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2"
$HKCU = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\2"
Set-ItemProperty -Path $HKLM -Name "1803" -Value 0
Set-ItemProperty -Path $HKCU -Name "1803" -Value 0
$HKLM = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3"
$HKCU = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3"
Set-ItemProperty -Path $HKLM -Name "1803" -Value 0
Set-ItemProperty -Path $HKCU -Name "1803" -Value 0
$HKLM = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\4"
$HKCU = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\4"
Set-ItemProperty -Path $HKLM -Name "1803" -Value 0
Set-ItemProperty -Path $HKCU -Name "1803" -Value 0
$HKLM = "HKLM:\Software\Microsoft\Internet Explorer\Security"
New-ItemProperty -Path $HKLM -Name "DisableSecuritySettingsCheck" -Value 1 -PropertyType DWORD

Stop-Process -Name Explorer
Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green

# Install Chrome
$Path = $env:TEMP; 
$Installer = "chrome_installer.exe"
Invoke-WebRequest "http://dl.google.com/chrome/install/375.126/chrome_installer.exe" -OutFile $Path\$Installer
Start-Process -FilePath $Path\$Installer -Args "/silent /install" -Verb RunAs -Wait
Remove-Item $Path\$Installer

#Join Domain
$spassword =  ConvertTo-SecureString "demo@pass123" -AsPlainText -Force
$domCredential = New-Object System.Management.Automation.PSCredential("$domain\$user", $spassword)
Add-Computer -DomainName "$domain" -Credential $domCredential -Restart -Force
