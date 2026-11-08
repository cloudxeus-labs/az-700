# ---------
# Variables
# ---------
$DomainName = "corp.<your-domain>"     # Recommended: subdomain for labs
$NetBIOS    = "<YOUR-NETBIOS-NAME>"   # 15 characters at most
$SafeModePW = ConvertTo-SecureString "<your-safe-mode-password>" -AsPlainText -Force

# -----------------------------
# Install AD DS + DNS features
# -----------------------------
Install-WindowsFeature AD-Domain-Services,DNS -IncludeManagementTools

# -----------------------------
# Promote server to Domain Controller (new forest)
# -----------------------------
Import-Module ADDSDeployment

Install-ADDSForest `
  -DomainName $DomainName `
  -DomainNetbiosName $NetBIOS `
  -InstallDns `
  -SafeModeAdministratorPassword $SafeModePW `
  -Force `
  -NoRebootOnCompletion:$false
