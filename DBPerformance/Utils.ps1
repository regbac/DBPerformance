
#."C:\temp\dbperformance\OSCounters.ps1"
# ."C:\temp\dbperformance\SSASCountersMD.ps1"
# ."C:\temp\dbperformance\SSASCountersTabular.ps1"
."C:\temp\dbperformance\SSISCounters.ps1"
."C:\temp\dbperformance\SSRSCounters.ps1"
#."C:\temp\dbperformance\SQLCounters.ps1"
function Global:GetOSCounter {
    [CmdletBinding()]            
    Param             
    (
        [Parameter(Position = 0, mandatory = $true)][string] $ComputerName,
        [Parameter(Position = 1, mandatory = $true)][int] $ID
    )#End Param
    Begin {
        Write-Log -Level Info -Message "Getting OS Counters for Server $ComputerName"
    } 
    Process {
        try {
            ."C:\temp\dbperformance\OSCounters.ps1"
            (Get-Counter -ComputerName $ComputerName -Counter (Convert-HString -HString $OSCounters)).counterSamples | ForEach-Object {$path = $_.path 
                New-Object PSObject -Property @{
                    ID           = $ID;
                    computerName = $ComputerName;
                    Category     = "OS";
                    Counter      = ($path -split "\\")[-2, -1] -join "-" ;
                    Item         = $_.InstanceName ;
                    Value        = [Math]::Round($_.CookedValue, 2) 
                    #datetime=(Get-Date -format "yyyy-MM-d hh:mm:ss tt") 
                    datetime     = (Get-Date -format "yyyy-MM-d HH:mm:ss") 
                } 
            }
            Write-Log -Message "Added OSCounters to result file for Server $ComputerName" -Level Info
        }
        catch {
            Write-Log -Level Error -Message "$_"
        }
     
    }
}
function Global:GetSQLCounter {
    [CmdletBinding()]            
    Param             
    (
        [Parameter(Position = 0, mandatory = $true)][string] $ComputerName,
        [Parameter(Position = 1, mandatory = $true)][System.Collections.Generic.List[String]] $Services,
        [Parameter(Position = 2, mandatory = $true)][int] $ID
    )#End Param
    Begin {
        
    } 
    Process {
        $services = $services| Where-Object {$_ -like "MSSQLSERVER" -or $_ -like 'MSSQL$*'}
        foreach ($Instance in $Services) {
            if ($Instance -like "MSSQLSERVER") {
                ."C:\temp\dbperformance\SQLCounters.ps1"
                $SQLCounters = $SQLCounters -replace '£InstanceName', 'SQLServer'
            }
            else {
                ."C:\temp\dbperformance\SQLCounters.ps1"
                $SQLCounters = $SQLCounters -replace '£InstanceName', $Instance
            }
            
            Write-Log -Level Info -Message "Getting SQL Counters for Server $ComputerName "

            try {
                (Get-Counter -ComputerName $ComputerName -Counter (Convert-HString -HString $SQLCounters)).counterSamples | ForEach-Object {$path = $_.path 
                    New-Object PSObject -Property @{
                        ID           = $ID;
                        computerName = $ComputerName;
                        Category     = "SQL";
                        Counter      = ($path -split "\\")[-2, -1] -join "-" ;
                        Item         = $_.InstanceName ;
                        Value        = [Math]::Round($_.CookedValue, 2) 
                        #datetime=(Get-Date -format "yyyy-MM-d hh:mm:ss tt") 
                        datetime     = (Get-Date -format "yyyy-MM-d HH:mm:ss")
                    } 
                }
                Write-Log -Message "Added SQLCounters to result file for Server $ComputerName and $Instance" -Level Info
                
            }
            catch {
                Write-Log -Level Error -Message "$_"    
            }
            
        }
    }
}
function Global:GetSSASCounter {
    [CmdletBinding()]            
    Param             
    (
        [Parameter(Position = 0, mandatory = $true)][string] $ComputerName,
        [Parameter(Position = 1, mandatory = $true)][System.Collections.Generic.List[String]] $Services,
        [Parameter(Position = 2, mandatory = $true)][int] $ID
    )#End Param
    Begin {
        
    } 
    Process {
        #"MSOLAP$TAB MSSQLServerOLAPService"
        $services = $services| Where-Object {$_ -like "*OLAP*"}
        foreach ($ASInstance in $Services) {
            $loadAssembly = [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.AnalysisServices")
            $svr = New-Object Microsoft.AnalysisServices.Server
            $ssasNamedInstance_Flag = $false
            #find named instance  
            if ($ASInstance -like "MSOLAP$*") {
                $ssasInstanceName = $ASInstance.Split("$")[1]
                $svr.Connect("$ComputerName\$ssasInstanceName")
                $ssasNamedInstance_Flag = $true
            }
            else {
                $svr.Connect("$ComputerName")
            }
            $ssasServerMode = $svr.ServerMode
            $ssasVersion = $svr.Version
            
            Write-Log -Level Info -Message "Getting SSAS Counters for Server $ComputerName , $ssasServerMode version $ssasVersion"

            if ($ssasNamedInstance_Flag) {
                $ssas_PrfCtr_base = "MSOLAP`$$($ssasInstanceName)" 
            }
            else {
                $ssas_PrfCtr_base = "MSAS$($ssasVersion.substring(0,2))"
            }
            if ($ssasServerMode -eq "Multidimensional") {
                ."C:\temp\dbperformance\SSASCountersMD.ps1"
                $SSASCounters = $SSASCountersMD -replace '£ssas_PrfCtr_base', $ssas_PrfCtr_base
                $Category = "SSASMD"
            }
            else {
                ."C:\temp\dbperformance\SSASCountersTabular.ps1"
                $SSASCounters = $SSASCountersTabular -replace '£ssas_PrfCtr_base', $ssas_PrfCtr_base
                $Category = "SSASTAB"
            }
            try {
                (Get-Counter -ComputerName $ComputerName -Counter (Convert-HString -HString $SSASCounters)).counterSamples | ForEach-Object { 
                    $path = $_.path
                    New-Object PSObject -Property @{
                        ID           = $ID;
                        computerName = $ComputerName;
                        Category     = $Category;
                        Counter      = ($path -split "\\")[-2, -1] -join "-" ;
                        Item         = $_.InstanceName ;
                        Value        = [Math]::Round($_.CookedValue, 2) 
                        #datetime=(Get-Date -format "yyyy-MM-d hh:mm:ss tt") 
                        datetime     = (Get-Date -format "yyyy-MM-d HH:mm:ss") 
                    }
                } 
                Write-Log -Message "Added SSASCounters to result file for Server $ComputerName and $ASInstance" -Level Info
               
            }
            catch {
                Write-Log -Level Error -Message "$_"
            }
        }
    }
}
function Global:GetSSISCounter {
    [CmdletBinding()]            
    Param             
    (
        [Parameter(Position = 0, mandatory = $true)][string] $ComputerName,
        [Parameter(Position = 1, mandatory = $true)][System.Collections.Generic.List[String]] $ssisVersion,
        [Parameter(Position = 2, mandatory = $true)][int] $ID
    )#End Param
    Begin {
        Write-Log -Level Info -Message "Getting SSIS Counters for Server $ComputerName , version $ssisVersion"
    } 
    Process {
        foreach ($ssis in $ssisVersion) {
            switch ( $ssis ) {
                "100" { $result = '10.0'    }
                "110" { $result = '11.0'    }
                "120" { $result = '12.0'   }
                "130" { $result = '13.0' }
                "140" { $result = '14.0'  }
        
            }
            $ssis = $result
            $SSISCounters = $SSISCountersAllVersions -replace '£SSISVersion', $ssis
        
            try {
                (Get-Counter -ComputerName $ComputerName -Counter (Convert-HString -HString $SSISCounters)).counterSamples | ForEach-Object {$path = $_.path 
                    New-Object PSObject -Property @{
                        ID           = $ID;
                        computerName = $ComputerName;
                        Category     = "SSIS";
                        Counter      = ($path -split "\\")[-2, -1] -join "-" ;
                        Item         = $_.InstanceName ;
                        Value        = [Math]::Round($_.CookedValue, 2) 
                        #datetime=(Get-Date -format "yyyy-MM-d hh:mm:ss tt") 
                        datetime     = (Get-Date -format "yyyy-MM-d HH:mm:ss") 
                    } 
                }
                Write-Log -Message "Added SSISCounters to result file for Server $ComputerName version $ssis" -Level Info
            
            }
            catch {
                Write-Log -Level Error -Message "$_"
            }
        }
     
    }
}
function Global:GetSSRSCounter {
    [CmdletBinding()]            
    Param             
    (
        [Parameter(Position = 0, mandatory = $true)][string] $ComputerName,
        [Parameter(Position = 1, mandatory = $true)][int] $ID
    )#End Param
    Begin {
        Write-Log -Level Info -Message "Getting SSRS Counters for Server $ComputerName"
    } 
    Process {
        
        #$SSRSCounters = $SSRSCountersAllVersions -replace '£SSRSVersion', $ssisVersion
        
        try {
            (Get-Counter -ComputerName $ComputerName -Counter (Convert-HString -HString $SSRSCounters)).counterSamples | ForEach-Object {$path = $_.path 
                New-Object PSObject -Property @{
                    ID           = $ID;
                    computerName = $ComputerName;
                    Category     = "SSRS";
                    Counter      = ($path -split "\\")[-2, -1] -join "-" ;
                    Item         = $_.InstanceName ;
                    Value        = [Math]::Round($_.CookedValue, 2) 
                    #datetime=(Get-Date -format "yyyy-MM-d hh:mm:ss tt") 
                    datetime     = (Get-Date -format "yyyy-MM-d HH:mm:ss")
                } 
            }
            Write-Log -Message "Added SSRSCounters to result file for Server $ComputerName" -Level Info
        }
        catch {
            Write-Log -Level Error -Message "$_"
        }
     
    }
}
function Global:Convert-HString {      
    [CmdletBinding()]            
    Param             
    (
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [String]$HString
    )#End Param
    
    Begin {
        #Write-Log -Level Info -Message "Converting $HString"
    }#Begin
    Process {
        $HString -split "`n" | ForEach-Object {
        
            $ComputerName = $_.trim()
            if ($ComputerName -notmatch "#") {
                $ComputerName
            }    
            
            
        }
    }#Process
    End {
        # Nothing to do here.
    }#End
    
}#Convert-HString
    
function Global:Write-Log { 
    [CmdletBinding()] 
    Param 
    ( 
        [Parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)] 
        [ValidateNotNullOrEmpty()] 
        [Alias("LogContent")] 
        [string]$Message, 
 
        [Parameter(Mandatory = $false)] 
        [Alias('LogPath')] 
        [string]$Path = 'C:\temp\Logs\GetCounter.log', 
         
        [Parameter(Mandatory = $false)] 
        [ValidateSet("Error", "Warn", "Info")] 
        [string]$Level = "Info"
    ) 
 
    Begin {} 
    Process { 
        # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path. 
        if (!(Test-Path $Path)) { 
            Write-Verbose "Creating $Path." 
            [void](New-Item $Path -ItemType File -Force)
        } 
    
        # Format Date for our Log File 
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss:ff" 
 
        # Write message to error, warning, or verbose pipeline and specify $LevelText 
        switch ($Level) { 
            'Error' { 
                $LevelText = 'ERROR:' 
            } 
            'Warn' { 
                $LevelText = 'WARNING:' 
            } 
            'Info' { 
                $LevelText = 'INFO:' 
            } 
        } 
         
        "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append
    } 
    
    End {
        #Write-Host $LevelText $Message
    } 
}
function Export-CsvFile {
    [CmdletBinding(DefaultParameterSetName = 'Delimiter',
        SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [System.Management.Automation.PSObject]
        ${InputObject},
    
        [Parameter(Mandatory = $true, Position = 0)]
        [Alias('PSPath')]
        [System.String]
        ${Path},
    
        #region -Append 
        [Switch]
        ${Append},
        #endregion 
    
        [Switch]
        ${Force},
    
        [Switch]
        ${NoClobber},
    
        [ValidateSet('Unicode', 'UTF7', 'UTF8', 'ASCII', 'UTF32', 'BigEndianUnicode', 'Default', 'OEM')]
        [System.String]
        ${Encoding},
    
        [Parameter(ParameterSetName = 'Delimiter', Position = 1)]
        [ValidateNotNull()]
        [System.Char]
        ${Delimiter},
    
        [Parameter(ParameterSetName = 'UseCulture')]
        [Switch]
        ${UseCulture},
    
        [Alias('NTI')]
        [Switch]
        ${NoTypeInformation})
    
    begin {
        # This variable will tell us whether we actually need to append
        # to existing file
        $AppendMode = $false
    
        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Export-Csv',
                [System.Management.Automation.CommandTypes]::Cmdlet)
            
            
            #String variable to become the target command line
            $scriptCmdPipeline = ''
    
            # Add new parameter handling
            #region Dmitry: Process and remove the Append parameter if it is present
            if ($Append) {
      
                $PSBoundParameters.Remove('Append') | Out-Null
        
                if ($Path) {
                    if (Test-Path $Path) {        
                        # Need to construct new command line
                        $AppendMode = $true
        
                        if ($Encoding.Length -eq 0) {
                            # ASCII is default encoding for Export-CSV
                            $Encoding = 'ASCII'
                        }
        
                        # For Append we use ConvertTo-CSV instead of Export
                        $scriptCmdPipeline += 'ConvertTo-Csv -NoTypeInformation '
        
                        # Inherit other CSV convertion parameters
                        if ( $UseCulture ) {
                            $scriptCmdPipeline += ' -UseCulture '
                        }
                        if ( $Delimiter ) {
                            $scriptCmdPipeline += " -Delimiter '$Delimiter' "
                        } 
        
                        # Skip the first line (the one with the property names) 
                        $scriptCmdPipeline += ' | Foreach-Object {$start=$true}'
                        $scriptCmdPipeline += '{if ($start) {$start=$false} else {$_}} '
        
                        # Add file output
                        $scriptCmdPipeline += " | Out-File -FilePath '$Path' -Encoding '$Encoding' -Append "
        
                        if ($Force) {
                            $scriptCmdPipeline += ' -Force'
                        }
    
                        if ($NoClobber) {
                            $scriptCmdPipeline += ' -NoClobber'
                        }   
                    }
                }
            } 
      
      
            $scriptCmd = {& $wrappedCmd @PSBoundParameters }
    
            if ( $AppendMode ) {
                # redefine command line
                $scriptCmd = $ExecutionContext.InvokeCommand.NewScriptBlock(
                    $scriptCmdPipeline
                )
            }
            else {
                # execute Export-CSV as we got it because
                # either -Append is missing or file does not exist
                $scriptCmd = $ExecutionContext.InvokeCommand.NewScriptBlock(
                    [string]$scriptCmd
                )
            }
            # standard pipeline initialization
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)

        }
        catch {
            throw
        }
    
    }

    process {
        try {
            $steppablePipeline.Process($_)
        }
        catch {
            throw
        }
    }

    end {
        try {
            $steppablePipeline.End()
        }
        catch {
            throw
        }
    }

}
