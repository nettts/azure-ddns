$dnsZone = 'YOUR DNS ZONE'
$hostname = 'YOUR DNS RECORD'
$enableIpv6 = $true

Write-Host "Setting authentication..`t" -ForegroundColor White -NoNewline

$appID = 'YOUR APP ID'
$appSecret = 'YOUR APP SECRET'
$subscriptionID = 'YOUR SUBSCRIPTION'
$tenantID = 'YOUR TENANT ID'
$resourceGroup = 'YOUR RESOURCE GROUP NAME'

$SecurePassword = $appSecret | ConvertTo-SecureString -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential `
-argumentlist $appID, $SecurePassword
Write-Host "OK" -ForegroundColor Green

Write-Host "Authenticating to Azure..`t" -ForegroundColor White -NoNewline
Login-AzureRmAccount -ServicePrincipal -Credential $cred -TenantId $tenantID -Subscription $subscriptionID
Write-Host "OK" -ForegroundColor Green

Write-Host "Resolving dynamic IPv4..`t`t" -ForegroundColor White -NoNewline
$dynamicIPv4 = Invoke-WebRequest 'http://whatismyip.akamai.com/' | select Content
Write-Host $dynamicIPv4.Content -ForegroundColor Green

Write-Host "Resolving current IPv4 in DNS..`t" -ForegroundColor White -NoNewline

$rsv4 = Get-AzureRmDnsRecordSet -Name $hostname -ZoneName $dnsZone -ResourceGroupName $resourceGroup -RecordType A
Write-Host $rsv4.Records.IPv4Address -ForegroundColor Green

if (-Not ($dynamicIPv4.Content -eq $rsv4.Records)) {
Write-Host "Updating IPv4 to DNS.. " -ForegroundColor White -NoNewline
$rsv4.Records[0].Ipv4Address = $dynamicIPv4.Content
Set-AzureRmDnsRecordSet -RecordSet $rs
Write-Host "OK" -ForegroundColor Green

}else {
Write-Host "IPv4 hasn't changed -- no need to update." -ForegroundColor White

}

if ($enableIpv6 -eq $true) {
  Write-Host "Resolving dynamic IPv6..`t`t" -ForegroundColor White -NoNewline
  $dynamicIPv6 = Invoke-WebRequest 'http://ipv6.whatismyip.akamai.com/' | select Content
  Write-Host $dynamicIPv6.Content -ForegroundColor Green
  
  Write-Host "Resolving current IPv6 in DNS..`t" -ForegroundColor White -NoNewline
  
  $rsv6 = Get-AzureRmDnsRecordSet -Name $hostname -ZoneName $dnsZone -ResourceGroupName $resourceGroup -RecordType AAAA
  Write-Host $rsv6.Records.IPv6Address -ForegroundColor Green

  if (-Not ($dynamicIPv6.Content -eq $rsv6.Records)) {
    Write-Host "Updating IPv6 to DNS.. " -ForegroundColor White -NoNewline
    $rsv6.Records[0].Ipv6Address = $dynamicIPv6.Content
    Set-AzureRmDnsRecordSet -RecordSet $rsv6
    Write-Host "OK" -ForegroundColor Green
  
  }else {
    Write-Host "IPv6 hasn't changed -- no need to update." -ForegroundColor White
  }
}
