	<#
	.Description
script creates new snapshot and delete old snapshots which age is longer than 7 days.
#>
[cmdletbinding()]
Param(
    [string] [Parameter(Mandatory=$false,position=0)]$resourceGroupName,
    [string] [Parameter(Mandatory=$false,position=1)]$automationAccountName,
    [string] [Parameter(Mandatory=$false,position=2)]$storageAccountName,
    [string] [Parameter(Mandatory=$false,position=3)]$filesharename
        )
begin {
            ### initialization variables

        $timestamp = $(get-date -UFormat %Y/%m/%d_%H:%M:%S)
       "---------------------------------------------------------------------------------------------------"
       "[$timestamp] Script started "
       "---------------------------------------------------------------------------------------------------"
        $ErrorActionPreference = 'Stop'
        $date = get-date
           
        $lastdate = $date.adddays(-7)
       
       

try {
    $servicePrincipalConnection = Get-AutomationConnection -Name 'AzureRunAsConnection'  
    "Logging in to Azure..."
    $TenantID = $servicePrincipalConnection.TenantId
    $ApplicationId = $servicePrincipalConnection.ApplicationId
    $CertificateThumbprint = $servicePrincipalConnection.CertificateThumbprint
    $account = add-AzureRmAccount `
        -ServicePrincipal  `
        -TenantId $TenantID `
        -ApplicationId $ApplicationId `
        -CertificateThumbprint $CertificateThumbprint 
   
     $storageAcct = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -ErrorAction Stop
     $storagecontext = ($storageAcct).Context
     $share = Get-AzureStorageShare -Context $storagecontext -Name $filesharename -ErrorAction Stop
     $snapshot = $share.Snapshot()

     $listofsnapshots = Get-AzureStorageShare -Context $storageContext | Where-Object { $_.Name -eq $filesharename -and $_.IsSnapshot -eq $true }
     $listofsnapshots | Select-Object Name, SnapShotTime,IsSnapshot
     $oldsnapshots = @($listofsnapshots | Where-Object { $_.SnapshotTime -lt $lastdate})
     if (!$oldsnapshots)
     {
         "No snapshot found older than 7 days"
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
