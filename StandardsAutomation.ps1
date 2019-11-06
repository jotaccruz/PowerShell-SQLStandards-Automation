#Major Powershell Supported Version: 4
#$PSVersionTable.PSVersion

#Required Modules
#dbatools - https://dbatools.io/zip
#Git - [Install-Module posh-git -Scope CurrentUser -Force] (optional)
#sp_whoisactive - [git clone https://github.com/amachanic/sp_whoisactive.git]
#git clone 

#Using Command Prompt (Admin) run
#gcloud components update
#gcloud auth login [Follows the steps showed]

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
    Write-Host "[A] Disks"
    Write-Host "[B] GCP Communication"
    Write-Host "[C] Windows page file"
    Write-Host "[D] IFI Testing"
    Write-Host "[E] SQL Server Max Memory"
    Write-Host "[F] Default database path"
    Write-Host "[G] DBAdmin"
    Write-Host "[H] Database Services Info"
    Write-Host "[I] Database toolkit install"
    Write-Host "[J] Instance Settings (RConn,BkCompress)"
    Write-Host "[K] Server Name"
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
        'A' {
                Clear-Host
                Write-Host ""
                Write-Host "Please take care about the following specs:"
                Write-Host ""
                Write-Host "- Get the right-sized operating system drive"
                Write-Host "- Provision storage for the OS and for SQL Server"
                Write-Host "- Provision storage for Backups"
                Write-Host "- Format the drives with 64 K allocation block size"
                Write-Host ""

                try {
                    Get-DbaDiskSpace | Out-GridView
                    }
                catch
                    {
                    Write-Error -Message "Unable to get Disk information. Error was: $_" -ErrorAction Stop
                    }

                $shell = new-object -comobject "WScript.Shell"
                $choice = $shell.popup("Remember 64K BlockSize for data and log. Do you need format a drive?",0,"Drive Format",4+32)

                if( $choice -eq 6 )
                {
                    $msg = 'Do you need to format another drive '
                    do {
                        $response = 1

                        if ($response -eq 1) {
                            Write-Host ""
                            $DriveFormat = Read-Host "Enter the drive letter (e.g. D)"
                            Format-Volume -DriveLetter $DriveFormat -AllocationUnitSize 65536 -FileSystem NTFS -Confirm:$false -Force
                        }
                        Write-Host ""
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
        'B' {
                #Variable inicialization
                #$jsonUni: Drive letter for json File
                #$jsonDir: Directory name where locate json file
                #$jsonurl: Full URL - Directory where locate json file

                Clear-Host
                Write-Host ""
                Write-Host "GCP Communication"
                Write-Host ""
                
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
        'C' {
                #Write-Host ""
                Write-Host "Windows Page File Setting"
                Write-Host ""
                Get-DbaPageFileSetting -ComputerName $dbserver | Out-GridView
            }

         ##############[3] IFI Setting
        'D' {
                #Write-Host ""
                Write-Host "IFI Testing"
                Write-Host ""
                Invoke-Sqlcmd -ConnectionTimeout 0 -Database master -InputFile IFI-Testing.sql -QueryTimeout 0 -ServerInstance $dbserver | Out-GridView
            }

         ##############[3] Memory Setting
        'E' {
                #Write-Host ""
                Write-Host "SQL Server Max Memory"
                Write-Host ""
                Set-Location $actual_dir
                Test-DbaMaxMemory -SqlInstance $dbserver | Out-GridView
            }

         ##############[3] Defaulth db path
        'F' {
                #Write-Host ""
                Write-Host "Default database path"
                Write-Host ""
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
        'G' {
                Invoke-Sqlcmd -ConnectionTimeout 0 -Database master -InputFile DBAdmin-Create.sql -QueryTimeout 0 -ServerInstance $dbserver
            }

         ##############[3] Database services
        'H' {
                Get-DbaService -ComputerName $dbserver | Out-GridView
            }

         ##############[3] IFI setting
        'I' {
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

        'J' {
                Write-Host ""
                Write-Host "Instance Settings...."
                Write-Host ""
                Invoke-Sqlcmd -ConnectionTimeout 0 -Database DBAdmin -InputFile Configuration-Update.sql -QueryTimeout 0 -ServerInstance $dbserver
                Write-Host ""
                Write-Host "...."
                Write-Host ""
            }
        }
    pause
}
until ($UserInput -eq 'q')
clear