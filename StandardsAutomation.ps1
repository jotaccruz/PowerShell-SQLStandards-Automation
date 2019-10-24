#Required Modules
#Please verify Powershell version 6. [https://github.com/PowerShell/PowerShell/releases/tag/v6.2.3]
#Please verify dbatools. [Install-Module dbatools -force]
#Please verify GraphicalTools. [Install-Module Microsoft.PowerShell.GraphicalTools]
#Please verify StoragePre2K12. [Install-Module -Name StoragePre2K12]

#Using Command Prompt (Admin) run
#gcloud components update
#gcloud auth login [Follows the steps showed]

#$PSVersionTable.PSVersion 6.0 [pwsh.exe]
#$env:PSModulePath

#function Start-PSAdmin {Start-Process PowerShell -Verb RunAs}

#Class to validate Directories name.
function dir_eval {
    param ([string]$Dir)
    if (-not (Test-Path -LiteralPath $Dir)) {
        try {
            New-DbaDirectory -SqlInstance localhost -Path $Dir
        }
        catch {
            Write-Error -Message "Unable to create directory '$Dir'. Error was: $_" -ErrorAction Stop
        }
        "Successfully created directory '$Dir'."
    }
    else    {
        "Directory already existed"
    }    
}

#Global variables
#OS Server Name
$dbserver = $env:computername

Write-Host ""
Write-Host "SQL Server Standards Automation"
Write-Host ""
Write-Host "Please get sure the proper driver configuration"
Write-Host ""
Write-Host "2.1 Get the right-sized operating system drive"
Write-Host "2.2 Provision storage for the OS and for SQL Server"
Write-Host "2.3 Provision storage for Backups"
Write-Host "4.1 Format the drives with 64 K allocation blocks"
Write-Host ""

try {
    Get-DbaDiskSpace | Out-GridView
    }
catch
    {
    Write-Error -Message "Unable to get Disk information. Error was: $_" -ErrorAction Stop
    }

#Format-Volume -DriveLetter D -AllocationUnitSize 65536 -FileSystem NTFS

Read-Host -Prompt "Press Enter to continue or CTRL+C to quit"

Write-Host ""
Write-Host "2.3 Test Secundary location for Backups"
Write-Host ""

#Variable inicialization
#$jsonUni: Drive letter for json File
#$jsonDir: Directory name where locate json file
#$jsonurl: Full URL - Directory where locate json file

$jsonUni = Read-Host -Prompt 'Input your drive letter to store service account json file (F Default)'
$jsonDir = 'jsonFiles'
$jsonurl = -join($jsonUni,':\',$jsonDir)

dir_eval Dir $jsonurl

#Get the service account's json file coppied into the server
gsutil cp gs://ti-sql-01/jsonfiles/dbbackup-user@ti-ca-infrastructure.json $jsonurl

#$jsonurlfull: Full url direcory where is located the json file
$jsonurlfull = -join($jsonurl,'\','dbbackup-user@ti-ca-infrastructure.json')

#Authenticate the Service Account
gcloud auth activate-service-account --key-file=$jsonurlfull

#Create a file to test the transfer
#Variable inicialization
$bkpUni = Read-Host -Prompt 'Input your drive letter to store backups (D: Default)'
$bkpDir = $dbserver
$bkpurl = -join($bkpUni,'\',$bkpDir)

dir_eval Dir $bkpurl

New-Item -Path $bkpurl\testtransfer.txt -itemtype file -ErrorAction Stop | Out-Null #-Force

try {
gsutil -m -o GSUtil:parallel_composite_upload_threshold=50M mv -r -n $bkpurl\testtransfer.txt gs://ti-sql-02/Backups/Current/$bkpDir/
}
    catch {
        Write-Error -Message "Unable to transfer to '$bkpurl'. Error was: $_" -ErrorAction Stop
    }


Write-Host ""
Write-Host "3.3 Configure the Windows page file"
Write-Host ""

Read-Host -Prompt "Press Enter to continue or CTRL+C to quit"
Get-DbaPageFileSetting -ComputerName localhost


Write-Host ""
Write-Host "6.3 Test Instant File Initialization (IFI)"
Write-Host ""

Read-Host -Prompt "Press Enter to continue or CTRL+C to quit"
Invoke-Sqlcmd -ConnectionTimeout 0 -Database master -InputFile IFI-Testing.sql -QueryTimeout 0 -ServerInstance localhost

Write-Host ""
Write-Host "6.7 Configure SQL Server Max Memory"
Write-Host ""

Test-DbaMaxMemory -SqlInstance localhost
Read-Host -Prompt "Press Enter to continue or CTRL+C to quit"


Write-Host ""
Write-Host "6.8 Set the default database path"
Write-Host ""

Get-DbaDefaultPath -SqlInstance localhost

$datDirConf = Read-Host -Prompt 'Do you need to set up these directories right now (N (Default) or Y)'

if ($datDirConf -eq 'Y'){
$datDir = Read-Host -Prompt 'Input your Data directory (D:\Data)'
$logDir = Read-Host -Prompt 'Input your Log directory (F:\Log)'
$BkpDir = Read-Host -Prompt 'Input your Backup directory (I:\Backup)'
}

#Read-Host -Prompt "Press Enter to continue or CTRL+C to quit"

dir_eval Dir $datDir
dir_eval Dir $logDir
dir_eval Dir $BkpDir