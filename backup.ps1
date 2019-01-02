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
        $lastdate = $date.addhours(-7)
try {
     "Logging in to Azure..."
     $tenantID = Get-AutomationVariable -Name 'tenantID' 
     $credentials = Get-AutomationPSCredential -Name 'AzureCredential' $subscriptionID
     add-AzureRmAccount -Credential $credentials -TenantId $tenantID
     $storageAcct = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -ErrorAction Stop
     $storagecontext = ($storageAcct).Context
     $share = Get-AzureStorageShare -Context $storagecontext -Name $filesharename -ErrorAction Stop
     $snapshot = $share.Snapshot()
     $listofsnapshots = Get-AzureStorageShare -Context $storageContext | Where-Object { $_.Name -eq $filesharename -and $_.IsSnapshot -eq $true }
     $oldsnapshots = @($listofsnapshots | Where-Object { $_.SnapshotTime -lt $lastdate})
     if ($oldsnapshots -ne 'null')
     {
          foreach($oldsnapshot in $oldsnapshots)
          {
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
         "[$timestamp] script Ended "
         
         "---------------------------------------------------------------------------------------------------"
}
