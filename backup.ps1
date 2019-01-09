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
       "[$timestamp] Script started "
       "---------------------------------------------------------------------------------------------------"
        $ErrorActionPreference = 'Stop'
        $date = get-date
        $retention = Get-AutomationVariable -Name 'retention'
        $lastdate = $date.adddays(-$retention)
try {
     "Logging in to Azure..."
     $SubId = Get-AutomationVariable -Name 'subID'
     $tenantID = Get-AutomationVariable -Name 'tenantID' 
     $credentials = Get-AutomationPSCredential -Name 'AzureCredential' 
     $account = add-AzureRmAccount -Credential $credentials -SubscriptionId $SubId -Tenantid $TenantID 
     $storageAcct = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -ErrorAction Stop
     $storagecontext = ($storageAcct).Context
     $share = Get-AzureStorageShare -Context $storagecontext -Name $filesharename -ErrorAction Stop
     $snapshot = $share.Snapshot()

     $listofsnapshots = Get-AzureStorageShare -Context $storageContext | Where-Object { $_.Name -eq $filesharename -and $_.IsSnapshot -eq $true }
     $listofsnapshots | Select-Object Name, SnapShotTime,IsSnapshot
     $oldsnapshots = @($listofsnapshots | Where-Object { $_.SnapshotTime -lt $lastdate})
     if (!$oldsnapshots)
     {
         "No snapshot found older than $retention days"
     }
          else 
          {
          "removing old snapshots"
                    foreach($oldsnapshot in $oldsnapshots)
          {
                  $oldsnapshot | Select-Object Name, SnapShotTime,IsSnapshot
                  Remove-AzureStorageShare -Share $oldsnapshot -verbose
                        } 
           
     }
} 
catch {
    $ErrorMessage = $_.Exception.Message
    "[$timestamp] [Error] at line $($_.InvocationInfo.ScriptLineNumber): $ErrorMessage" 

 }
 
 
}
end {
         "---------------------------------------------------------------------------------------------------"
         "[$timestamp] Script Ended "
         
         "---------------------------------------------------------------------------------------------------"
}
