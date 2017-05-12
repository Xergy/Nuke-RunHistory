Function Nuke-RunHistory {
    [CmdletBinding()]
    
    ##New Help
	
    Param
    (
     [string]$DaysToSave = 4
    )

    Process{
 
        $TimeZone = Get-WmiObject Win32_TimeZone 
        $UTCOffset =  if ((get-date).IsDaylightSavingTime()) {($TimeZone.Bias)/60 + 1} Else {($TimeZone.Bias)/60}
        $SaveTillDateTime = (get-date).AddDays(-$DaysToSave)

        #This could take a while
        $Runs = Get-WmiObject -ComputerName . -NameSpace 'root/MicrosoftIdentityIntegrationServer' -Query "Select RunStartTime From MIIS_RunHistory"

        $runStartTimes = @()

        foreach ($Run in $Runs) {		
	        $row = New-Object -Type PSObject -Property @{
	   	        runStartTimeString = $Run.RunStartTime
                runStartTimeLocal = ([datetime]($Run.RunStartTime)).AddHours($UTCOffset)
		        runStartTime = [datetime]($Run.RunStartTime)
                runDeleteWatermark = ([datetime]($Run.RunStartTime)).AddMinutes(1)
	        }
            $runStartTimes += $row
        }
        
        $ToDeleteRunHistories = $runStartTimes | Where-Object {$_.runStartTime -lt $SaveTillDateTime.ToUniversalTime()  } | Sort-Object -Property runStartTime 
            
        $SyncServer =  get-wmiobject -class "MIIS_SERVER" -namespace "root\MicrosoftIdentityIntegrationServer" -computer .

        foreach ($ToDeleteRunHistory in $ToDeleteRunHistories) {

            $SyncServer.ClearRuns($ToDeleteRunHistory.runDeleteWatermark).ReturnValue | out-null
        }
    }

}

Nuke-RunHistory -DaysToSave 4
