#Required Modules
#Please verify 
#dbatools - [Install-Module dbatools -force]
#Git - [Install-Module posh-git -Scope CurrentUser -Force] (optional)
#sp_whoisactive - [git clone https://github.com/amachanic/sp_whoisactive.git]
#git clone 

#Using Command Prompt (Admin) run
#gcloud components update
#gcloud auth login [Follows the steps showed]

#$PSVersionTable.PSVersion
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
    if (-not (Test-DbaPath -SqlInstance $dbserver -Path $Dir)) {
        try {
            New-DbaDirectory -SqlInstance $dbserver -Path $Dir
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
    Write-Host ""
    Write-Host "[1] Validate your hardware"
    Write-Host "[2] Test GCP location for Backups"
    Write-Host "[3] Configure the Windows page file"
    Write-Host "[4] Test Instant File Initialization (IFI)"
    Write-Host "[5] Configure SQL Server Max Memory"
    Write-Host "[6] Set the default database path"
    Write-Host "[7] Install DBAdmin"
    Write-Host "[8] Restart the database Service"
    Write-Host "[9] Install Database toolkit"
    Write-Host "[A] Instance Settings (RConn,BChecksum,AgentXps)"
    Write-Host ""
    Write-Host "[Q] Press the option number or 'Q' to quit."
    Write-Host ""
}


############################ Principal Code ############################
do
{
    menu_cons -Title "TELUS - SQL Server Standard Setup"
    $UserInput = Read-Host "Please make a selection"
    switch($UserInput)
        {
        ##############[1] Validate your hardware
        '1' {
                Clear-Host
                Write-Host ""
                Write-Host "Please take care about the following specs:"
                Write-Host ""
                Write-Host "1. Get the right-sized operating system drive"
                Write-Host "2. Provision storage for the OS and for SQL Server"
                Write-Host "3. Provision storage for Backups"
                Write-Host "4. Format the drives with 64 K allocation blocks"
                Write-Host ""

                try {
                    Get-DbaDiskSpace | Out-GridView
                    }
                catch
                    {
                    Write-Error -Message "Unable to get Disk information. Error was: $_" -ErrorAction Stop
                    }

                $shell = new-object -comobject "WScript.Shell"
                $choice = $shell.popup("Do you need format a drive?",0,"Drive Format",4+32)

                if( $choice -eq 6 )
                {
                    $msg = 'Do you want to continue '
                    do {
                        $response = 1

                        if ($response -eq 1) {
                            $DriveFormat = Read-Host "Enter the drive letter (e.g. D)"
                            Format-Volume -DriveLetter $DriveFormat -AllocationUnitSize 65536 -FileSystem NTFS -Confirm:$false -Force
                        }

                        choice /c yn /m $msg
                        $response = $LASTEXITCODE

                    } until ($response -eq 2)
                    
                    #$
                    #do
                    #{
                    #    
                    #    pause
                    #    $UserInputFormat = Read-Host "Enter the drive letter: (e.g. D) or [S] to exit:"
                    #}
                    #until ($UserInputFormat -eq 's')
                }
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
                Write-Host ""
            }
 
         ##############[3] Page File Setting
        '3' {
                Get-DbaPageFileSetting -ComputerName $dbserver | Out-GridView
            }

         ##############[3] IFI Setting
        '4' {
                Invoke-Sqlcmd -ConnectionTimeout 0 -Database master -InputFile IFI-Testing.sql -QueryTimeout 0 -ServerInstance $dbserver | Out-GridView
            }

         ##############[3] Memory Setting
        '5' {
                Set-Location $actual_dir
                Test-DbaMaxMemory -SqlInstance $dbserver | Out-GridView
            }

         ##############[3] Defaulth db path
        '6' {
                Get-DbaDefaultPath -SqlInstance $dbserver | Out-GridView

                $datDirConf = Read-Host -Prompt 'Do you need to set up these directories right now (N (Default) or Y)'

                if ($datDirConf -eq 'Y')
                {
                    $datDir = Read-Host -Prompt 'Input your Data directory (D:\Data)'
                    $logDir = Read-Host -Prompt 'Input your Log directory (F:\Log)'
                    $BkpDir = Read-Host -Prompt 'Input your Backup directory (I:\Backup)'
                    dir_eval $datDir
                    dir_eval $logDir
                    dir_eval $BkpDir

                    Invoke-Sqlcmd -ConnectionTimeout 0 -Database DBAdmin -InputFile Setdefaultpathdb-Create.sql -QueryTimeout 0 -ServerInstance $dbserver
                    Invoke-Sqlcmd -ConnectionTimeout 0 -Database DBAdmin -Query "exec set_defaultpathdb @what = N'D', @dir = N'$datDir';" -QueryTimeout 0 -ServerInstance $dbserver
                    Invoke-Sqlcmd -ConnectionTimeout 0 -Database DBAdmin -Query "exec set_defaultpathdb @what = N'L', @dir = N'$logDir';" -QueryTimeout 0 -ServerInstance $dbserver
                    Invoke-Sqlcmd -ConnectionTimeout 0 -Database DBAdmin -Query "exec set_defaultpathdb @what = N'B', @dir = N'$BkpDir';" -QueryTimeout 0 -ServerInstance $dbserver

                    Write-Host "Don't forget this setting requires Restart MSSQL Service"
                }
                else
                {
                    Write-Host ""
                    Write-Host "Action skipped"
                    Write-Host ""
                }
            }

         ##############[3] Database Admin creation
        '7' {
                Invoke-Sqlcmd -ConnectionTimeout 0 -Database master -InputFile DBAdmin-Create.sql -QueryTimeout 0 -ServerInstance $dbserver
            }

         ##############[3] Database services
        '8' {
                Get-DbaService -ComputerName $dbserver | Out-GridView
            }

         ##############[3] IFI setting
        '9' {
                Write-Host ""
                Write-Host "Installing sp_whoisactive...."
                Write-Host ""
                Invoke-Sqlcmd -ConnectionTimeout 0 -Database DBAdmin -InputFile who_is_active.sql -QueryTimeout 0 -ServerInstance $dbserver
                Write-Host ""
                Write-Host "Configuring Database Mail...."
                Write-Host ""
                Invoke-Sqlcmd -ConnectionTimeout 0 -Database DBAdmin -InputFile DBmail-Enable.sql -QueryTimeout 0 -ServerInstance $dbserver
                Invoke-Sqlcmd -ConnectionTimeout 0 -Database DBAdmin -InputFile DBmail-Config.sql -QueryTimeout 0 -ServerInstance $dbserver
                Invoke-Sqlcmd -ConnectionTimeout 0 -Database DBAdmin -InputFile FailsafeOperator-On.sql -QueryTimeout 0 -ServerInstance $dbserver
                Write-Host ""
                Write-Host "Installing Alerts...."
                Write-Host ""
                Invoke-Sqlcmd -ConnectionTimeout 0 -Database DBAdmin -InputFile Operator-Create.sql -QueryTimeout 0 -ServerInstance $dbserver
                Invoke-Sqlcmd -ConnectionTimeout 0 -Database DBAdmin -InputFile Alerts-Create.sql -QueryTimeout 0 -ServerInstance $dbserver

            }

        'A' {
                Write-Host ""
                Write-Host "Instance Settings...."
                Write-Host ""
                Invoke-Sqlcmd -ConnectionTimeout 0 -Database DBAdmin -InputFile Alerts-Create.sql -QueryTimeout 0 -ServerInstance $dbserver
                Write-Host ""
                Write-Host "...."
                Write-Host ""
            }
        }
    pause
}
until ($UserInput -eq 'q')
clear