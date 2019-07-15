param($password)
$dbdestination = "C:\SQLDATA\AdventureWorks.bak"
# Setup the data, backup and log directories as well as mixed mode authentication
Import-Module "sqlps" -DisableNameChecking
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")
$sqlesq = new-object ('Microsoft.SqlServer.Management.Smo.Server') Localhost
$sqlesq.Settings.LoginMode = [Microsoft.SqlServer.Management.Smo.ServerLoginMode]::Mixed
$sqlesq.Settings.DefaultFile = $data
$sqlesq.Settings.DefaultLog = $logs
$sqlesq.Settings.BackupDirectory = $backups
$sqlesq.Alter() 

# Restart the SQL Server service
Restart-Service -Name "MSSQLSERVER" -Force

# Make sure SQL has time to restart
Start-Sleep -s 120

# Re-enable the sa account and set a new password to enable login
Invoke-Sqlcmd -ServerInstance Localhost -Database "master" -Query "ALTER LOGIN sa ENABLE" 
Invoke-Sqlcmd -ServerInstance Localhost -Database "master" -Query "ALTER LOGIN sa WITH PASSWORD = 'demo@pass123'"
Invoke-Sqlcmd -ServerInstance Localhost -Database "master" -Query "CREATE LOGIN [BUILTIN\Administrators] FROM WINDOWS"
Invoke-Sqlcmd -ServerInstance Localhost -Database "master" -Query "ALTER SERVER ROLE sysadmin ADD MEMBER [BUILTIN\Administrators]"

