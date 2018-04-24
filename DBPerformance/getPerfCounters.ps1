#Set-ExecutionPolicy RemoteSigned 
#Clear-Host
."C:\temp\dbperformance\Utils.ps1"

function GetPerfCounters {
    [CmdletBinding()]            
    Param             
    (
        [Parameter(Position = 0, mandatory = $true)][string] $outfile,
        [Parameter(Position = 1, mandatory = $true)][System.Collections.Generic.List[string]] $Servers
    )#End Param
    Begin {
        Write-Log -Level Info -Message "Getting Counters for Server $ComputerName"
    } 
    Process {
        
        $Service_list = "MsDtsServer*", "MSSQLSERVER", "*OLAP*", "ReportServer", 'MSSQL$*'

        foreach ($ComputerName in $Servers) {
            Try {
                $services = Get-Service -computername $ComputerName -Name $Service_list 
                Write-Log -Level Info -Message "Found $services on $Computername"

                #Generating unique ID in file for grouping
                $dt = Get-Date("1-1-2018")
                $dtu = Get-Date
                $dtr = $dtu.ToString("yyyyMMddHHmmss") - $dt.ToString("yyyyMMddHHmmss")
                $RndID = $dtr 

       
                #getting perf counters for OS
                $d = GetOSCounter -ComputerName $ComputerName -ID $RndID |Select-Object ID, computerName, Category, Counter, Item, Value, datetime -ErrorAction Stop
                $d |Export-CsvFile -notype $outfile -Append -ErrorAction Stop
        
                #getting performance counters for SQL
                if ($services.Name -like "MSSQLSERVER" -or $services.Name -like 'MSSQL$*') {
                     #$d = GetSQLCounter -ComputerName $ComputerName -Services $services.Name -ID $RndID |Select-Object ID, computerName, Category,  Counter, Item, Value, datetime -ErrorAction Stop
                     #$d |Export-CsvFile -notype $outfile -Append -ErrorAction Stop
                }
                #getting performance counters for SSAS
                if ($services.Name -like "*OLAP*") {
                    $d = GetSSASCounter -ComputerName $ComputerName -Services $services.Name -ID $RndID |Select-Object ID, computerName, Category, Counter, Item, Value, datetime -ErrorAction Stop
                    $d |Export-CsvFile -notype $outfile -Append -ErrorAction Stop
                }

                if ($services.Name -like "MsDtsServer*") {
                    $ssisVersion = ($services.Name | Where-Object {$_ -like "MsDtsServer*"}).Replace("MsDtsServer", "")
                     $d = GetSSISCounter -ComputerName $ComputerName -ssisVersion $ssisVersion -ID $RndID |Select-Object ID, computerName, Category, Counter, Item, Value, datetime -ErrorAction Stop
                     $d |Export-CsvFile -notype $outfile -Append -ErrorAction Stop
                }
        
                if ($services.Name -like "ReportServer*") {
                    $d = GetSSRSCounter -ComputerName $ComputerName -ID $RndID |Select-Object ID, computerName, Category, Counter, Item, Value, datetime -ErrorAction Stop
                    $d |Export-CsvFile -notype $outfile -Append -ErrorAction Stop
                }
            }
            Catch {
                Write-Log -Level Error -Message "$_"
            }
        }
    }
}
