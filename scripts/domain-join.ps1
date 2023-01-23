$DomainDNSName = (Get-SSMParameter -Name /dev/DomainDNSName -Region us-east-2).Value
Write-Output $DomainDNSName
# Formatting AD Admin User to proper format for JoinDomain DSC Resources in this Script
$DomainAdmin = 'Domain\User' -replace 'Domain',$DomainDNSName -replace 'User',$Admin.Username
Write-Output $DomainAdmin
$Admin = ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId ADAdminSecrets).SecretString
Write-Output $Admin
$AdminUser = $DomainDNSName + '\' + $Admin.username
# Creating Credential Object for Administrator
$Credentials = (New-Object PSCredential($AdminUser,(ConvertTo-SecureString $Admin.Password -AsPlainText -Force)))
Write-Output $Credentials
# Getting the DSC Cert Encryption Thumbprint to Secure the MOF File
$DscCertThumbprint = (get-childitem -path cert:\LocalMachine\My | where { $_.subject -eq "CN=AWSQSDscEncryptCert" }).Thumbprint
Write-Output $DscCertThumbprint
# Getting the Name Tag of the Instance
$NameTag = (Get-EC2Tag -Filter @{ Name="resource-id";Values=(Invoke-RestMethod -Method Get -Uri http://169.254.169.254/latest/meta-data/instance-id)}| Where-Object { $_.Key -eq "Name" })
$NewName = $NameTag.Value
Add-Computer -DomainName $DomainDNSName -Credential $Credentials -force -verbose -restart
