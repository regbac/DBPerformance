# DBPerformance
This is a set of scripts to assess performance for SQL environment for SQL, SSIS, SSAS and SSRS



PowerShell statements for generating data:

Prerequisite: 
All processes must be executed with administrative privilege. 
Extract the zip DBPerformance.zip to C:\Temp\ 
Use an existing SQL Server domain\<Technical_Acount> with admin privilege to access all SQL Servers remote. 
Use the SQL Server Proxy credentials for executing Powershell scripts from SQL Server Agent.  
Create files from Server01.txt – Server0x.txt, it’s recommended only to insert 8-10 productions servers in each file to have the best sample rate. 
Create the same amount of SQL Server Agent Jobs, as the number of server__.txt files. 
ex. “01 Collect SQL Server Perfmond Counters” to “ <x> Collect SQL Server Perfmond Counters”.  

Example: 
SQL Agent Job name, 01 Collect SQL Server Perfmond Counters 
  
Configure each job: 
In the SQL Server Agent Job step properties, and add the below script. 
Run as: <the SQL Server Proxy credentials already created> 
Note: each job has individual .csv and .txt filenames. 

    "c:\temp\dbperformance\getPerfCounters.ps1"  
    $outfile = "C:\temp\logs\perfmon<01>.csv"  
    Servers = get-content "C:\temp\Logs\servers<01>.txt" 
    GetPerfCounters -outfile $outfile -Servers $Servers  

The sequence for SQL Server Job Schedule, execute jobs each 2½ min in the collect period. 
