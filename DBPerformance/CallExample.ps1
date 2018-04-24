.".\getPerfCounters.ps1"
$start = Get-Date

#Get-Counter -ListSet *SQL*  | Select-Object CounterSetName, CounterSetType, Description, Paths
$outfile = "C:\temp\logs\perfmo2n.csv"
#$Servers = get-content "C:\temp\Logs\servers.txt"
$Servers = "sql2016VM"
GetPerfCounters -outfile $outfile -Servers $Servers
$end = Get-Date
$elapsed = $end.ToString("yyyyMMddHHmmssss") - $start.ToString("yyyyMMddHHmmssss")

Write-Host "Time elapsed $elapsed seconds"

Get-Date -format "yyyy-MM-d HH:mm:ss:ff"