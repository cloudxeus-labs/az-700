# AZ-700 course code

Code for the Cloudxeus course **AZ-700: Designing and Implementing Microsoft Azure Networking
Solutions**. Each folder is one section of the course, and each folder inside it is one lab, under the
same names you see in the videos.

| Section | Labs |
|---|---|
| 02. Design, implement, and manage connectivity services | Virtual Network Peering, Site-to-Site VPN, Azure DNS Private Resolver |
| 03. Design and implement application delivery services | Azure Load Balancer, Azure Global Load Balancer, Azure Application Gateway (scale set and multiple sites), Azure Traffic Manager |
| 04. Design and implement private access to Azure services | Virtual network service endpoints, Azure Private Link Service, Azure Web App virtual network integration |
| 05. Design and implement Azure network security services | Network Security Groups, Web Application Firewall on Azure Application Gateway, Azure Firewall |

## Before you start

You need:

- An Azure subscription
- The [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli), signed in with `az login`,
  with Bicep (`az bicep install`)

## Deploy a lab

Most labs are a `main.bicep` template with one or more `.bicepparam` files, one per environment or
region (`main-dev`, `main-tst`, `main-secondary` …). Deploy each parameter file the video uses into a
resource group:

```bash
cd "03. Design and implement application delivery services/01. Lab - Azure Load Balancer - Standard SKU - Setup"
az group create --name <your-resource-group> --location eastus
az deployment group create --resource-group <your-resource-group> --parameters main-dev.bicepparam
```

- The templates deploy into the resource group's region, except where the parameter file sets
  `location` (the secondary region in the global labs).
- The other files are used on the virtual machines the labs create, as shown in the videos:
  - `setup.ps1` turns a Windows Server VM into a domain controller.
  - `nginx-images.sh` and `nginx-videos.sh` set up the Application Gateway's backend web servers.
  - `index.html` is the page for the multi-site Application Gateway's web app.
  - `init.sql` holds the commands for the web app's MySQL server, run one at a time.
  - `index.php` is the web app that reads from that database.

## Use your own values

The videos show the instructor's passwords and domain names. Here, those are placeholders. Replace
them before you deploy or run a file, including the angle brackets:

| Placeholder | Replace with |
|---|---|
| `<your-vm-password>` | A password for the VMs' admin account: 12 to 123 characters, with three of these: a lowercase letter, an uppercase letter, a digit, a special character |
| `<your-db-password>` | A password for the MySQL user `dbadmin`. Use the same one in `init.sql` and `index.php`, or set `DB_PASS` in the web app's settings |
| `<your-domain>`, `<YOUR-NETBIOS-NAME>` | The Active Directory domain to create (such as `corp.example.com`) and its short name (such as `CORP`, 15 characters at most) |
| `<your-safe-mode-password>` | The domain controller's Directory Services Restore Mode password |
| `your-domain.com` | The domain your multi-site Application Gateway listens for |
| `<your-resource-group>` | Your resource group's name |

## Keep your passwords safe

**Never commit or share a file with a real password in it.** Some of these labs give VMs public IP
addresses. Anyone who has the password can sign in to them and run up charges on your
Azure subscription.

- Before you commit or push your own copy, set your passwords back to the placeholders.
- If a password does get out, change it on the VM straight away, or delete the lab's resources.
- `.env` is already in `.gitignore`. Don't remove it.

## Azure costs

These labs create Azure resources that cost money while they exist, especially VPN gateways, Azure
Firewall, Application Gateway and virtual machines. Delete what you created when you finish, usually
by deleting its resource group:

```bash
az group delete --name <your-resource-group>
```

## License

[MIT](LICENSE). The code is provided as is, as learning material.
