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


#Global variables
#OS Server Name
$dbserver = $env:computername
#Current Directory
$actual_dir=Get-Location

#Function to validate Directories name.
function dir_eval {
    param ([string]$Dir)
    if (-not (Test-DbaPath -SqlInstance localhost -Path $Dir)) {
        try {
            New-DbaDirectory -SqlInstance localhost -Path $Dir
            "Successfully created directory '$Dir'."
        }
        catch {
            Write-Error -Message "Unable to create directory '$Dir'. Error was: $_" -ErrorAction Stop
        }
    }
    else    {
        "Directory already existed"
    }    
}

function menu_cons{
    param (
        [string]$Title = 'My Menu'
    )
    Clear-host
    Write-Host "===================== $Title ====================="
    Write-Host "[1] Validate your hardware"
    Write-Host "[2] Test GCP location for Backups"
    Write-Host "[3] Configure the Windows page file"
    Write-Host "[4] Test Instant File Initialization (IFI)"
    Write-Host "[5] Configure SQL Server Max Memory"
    Write-Host "[6] Set the default database path"
    Write-Host "[7] Continue...."
    
    Write-Host "[Q] Press the option number or 'Q' to quit."
}

############################ Principal Code ############################
do
{
    menu_cons -Title "SQL Server Standard Setup"
    $UserInput = Read-Host "Please make a selection"
    switch($UserInput)
        {
        ##############[1] Validate your hardware
        '1' {
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
            }
        
        ##############[2] Test GCP location for Backups
        '2' {
                #Variable inicialization
                #$jsonUni: Drive letter for json File
                #$jsonDir: Directory name where locate json file
                #$jsonurl: Full URL - Directory where locate json file

                while (!$jsonUni) 
                {
                    $jsonUni = Read-Host -Prompt 'Input your drive letter to store service account json file (e.g. D)'
                }
                $jsonDir = 'jsonFiles'
                $jsonurl = -join($jsonUni,':\',$jsonDir,'\')

                dir_eval $jsonurl

                #Get the service account's json file coppied into the server
                gsutil cp gs://ti-sql-01/jsonfiles/dbbackup-user@ti-ca-infrastructure.json $jsonurl

                #$jsonurlfull: Full url direcory where is located the json file
                $jsonurlfull = -join($jsonurl,'\','dbbackup-user@ti-ca-infrastructure.json')

                #Authenticate the Service Account
                gcloud auth activate-service-account --key-file=$jsonurlfull

                #Create a file to test the transfer
                #Variable inicialization
                while (!$bkpUni) 
                {
                    $bkpUni = Read-Host -Prompt 'Input your drive letter to store backups (e.g. D)'
                }

                $bkpDir = $dbserver
                $bkpurl = -join($bkpUni,':\',$bkpDir,'\')

                dir_eval $bkpurl

                New-Item -Path $bkpurl\testtransfer.txt -Force -itemtype file -ErrorAction Stop | Out-Null 

                try 
                {
                    gsutil -m -o GSUtil:parallel_composite_upload_threshold=50M mv -r -n $bkpurl\testtransfer.txt gs://ti-sql-02/Backups/Current/$bkpDir/
                }
                catch 
                {
                    Write-Error -Message "Unable to transfer to '$bkpurl'. Error was: $_" -ErrorAction Stop
                }
            }
        
        '3' {
                Get-DbaPageFileSetting -ComputerName localhost | Out-GridView
            }

        '4' {
                Invoke-Sqlcmd -ConnectionTimeout 0 -Database master -InputFile IFI-Testing.sql -QueryTimeout 0 -ServerInstance localhost | Out-GridView
            }

        '5' {
                Set-Location $actual_dir
                Test-DbaMaxMemory -SqlInstance localhost | Out-GridView
            }

        '6' {
                Get-DbaDefaultPath -SqlInstance localhost | Out-GridView

                $datDirConf = Read-Host -Prompt 'Do you need to set up these directories right now (N (Default) or Y)'

                if ($datDirConf -eq 'Y')
                {
                    $datDir = Read-Host -Prompt 'Input your Data directory (D:\Data)'
                    $logDir = Read-Host -Prompt 'Input your Log directory (F:\Log)'
                    $BkpDir = Read-Host -Prompt 'Input your Backup directory (I:\Backup)'
                    dir_eval $datDir
                    dir_eval $logDir
                    dir_eval $BkpDir

                    Invoke-Sqlcmd -ConnectionTimeout 0 -Database DBAdmin -InputFile setdefaultpathdb.sql -QueryTimeout 0 -ServerInstance localhost
                    Invoke-Sqlcmd -ConnectionTimeout 0 -Database DBAdmin -Query "exec set_defaultpathdb @what='D' @dir='D:\Data';" -QueryTimeout 0 -ServerInstance localhost

                }
                else
                {
                    Write-Host ""
                    Write-Host "Action skipped"
                    Write-Host ""
                }
            }

        '7' {
                
            }

        '8' {
                
            }

        }
    pause
}
until ($UserInput -eq 'q')