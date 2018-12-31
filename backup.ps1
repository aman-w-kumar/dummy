	<#
	.Description
script creates new snapshot and delete old snapshots which age is longer than 7 days.
#>
[cmdletbinding()]
Param(
    [string] [Parameter(Mandatory=$true,position=0)]$resourceGroupName,
    [string] [Parameter(Mandatory=$true,position=1)]$automationAccountName,
    [string] [Parameter(Mandatory=$true,position=2)]$storageAccountName,
    [string] [Parameter(Mandatory=$true,position=3)]$filesharename
        )
begin {
            ### initialization variables

        $timestamp = $(get-date -UFormat %Y/%m/%d_%H:%M:%S)
       "---------------------------------------------------------------------------------------------------"
       "[$timestamp] Function started "
       "---------------------------------------------------------------------------------------------------"
        $ErrorActionPreference = 'Stop'
        $date = get-date
           
        #$lastdate = $date.adddays(-7)
        $lastdate = $date.addhours(-0)
       # $logfile = https://vdatadomain.file.core.windows.net/logshare

try {
    $servicePrincipalConnection = Get-AutomationConnection -Name 'AzureRunAsConnection'  
    "Logging in to Azure..."
     $credentials = Get-AutomationPSCredential -Name 'AzureCredential'
     add-AzureRmAccount -Credential $credentials
    
    #Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -verbose 
     $storageAcct = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -ErrorAction Stop
     $storagecontext = ($storageAcct).Context
     $share = Get-AzureStorageShare -Context $storagecontext -Name $filesharename -ErrorAction Stop
     $snapshot = $share.Snapshot()
     #$snapshotname = $snapshot.name + $timestamp
     #Get-AzureStorageFile -Share $snapshot.Name
     $listofsnapshots = Get-AzureStorageShare -Context $storageContext | Where-Object { $_.Name -eq $filesharename -and $_.IsSnapshot -eq $true }
     #$listofsnapshots | Select-Object Name, SnapShotTime,IsSnapshot
     ###################count the snapshots age > 7 days #################  should be -lt operator
     $oldsnapshots = @($listofsnapshots | Where-Object { $_.SnapshotTime -lt $lastdate})
     if ($oldsnapshots -ne 'null')
     {
          foreach($oldsnapshot in $oldsnapshots)
          {
          #$oldsnapshot
          "----------------------------------------------------------------"
          $removesnapshots = Remove-AzureStorageShare -Share $oldsnapshot -verbose -WhatIf
          
              } #for each
       Write-Verbose "snapshot removed $removesnapshots "
     }#if
} #try

catch {
    $ErrorMessage = $_.Exception.Message
    "[$timestamp] [Error] at line $($_.InvocationInfo.ScriptLineNumber): $ErrorMessage" 

 }
 
 
}
end {
         "---------------------------------------------------------------------------------------------------"
         "[$timestamp] Function Ended "
         
         "---------------------------------------------------------------------------------------------------"
}
