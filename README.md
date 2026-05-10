```markdown
# Azure Enterprise IaC Platform

![Terraform Version](https://img.shields.io/badge/Terraform-%3E%3D%201.2.0-623CE4?logo=terraform)
![Azure Provider](https://img.shields.io/badge/azurerm-~%3E%203.0-0078D4?logo=microsoftazure)
![Platform](https://img.shields.io/badge/Platform-Azure-blue)
![Architecture](https://img.shields.io/badge/Architecture-Data--Driven-success)

## Overview

The Azure Enterprise IaC Platform is a highly scalable, data-driven Infrastructure-as-Code (IaC) framework built with Terraform. It is designed to provision, manage, and govern enterprise-grade Azure landing zones and workload environments. 

Rather than relying on deeply nested, hardcoded `tfvars` files, this platform abstracts infrastructure configuration into centralized CSV data dictionaries. This allows infrastructure engineers and developers to provision complex topologies (Networking, Compute, Security, DNS) simply by updating spreadsheet data, while the underlying Terraform engine enforces strict architectural patterns and enterprise naming conventions.

## Core Design Principles

1. **Data-Driven Execution:** All resources (Resource Groups, VNets, Subnets, VMs, NSGs) are generated dynamically via CSV ingestion and HCL `for_each` mapping.
2. **Built-in Governance:** Terraform `lifecycle` preconditions act as a gatekeeper, intercepting and blocking any deployment that violates the enterprise naming convention (e.g., `vnt-<3char>-<u|p><ia|ie|mgmt>-<2digits>`).
3. **Zero-Cycle Dependencies:** Decoupled modules (Network, Compute, Security) use explicit `depends_on` blocks and output mapping to prevent ARM locking collisions and race conditions during concurrent provisioning.
4. **Idempotent Bootstrapping:** Support for robust OS-level configuration via Custom Script Extensions, ensuring VMs are fully operational and attached to Private DNS upon launch.

## Repository Structure

```text
.
├── environment/
│   ├── uat/                  # Lower environment execution root
│   │   ├── data/             # 📁 Centralized CSV Data Dictionaries
│   │   │   ├── Bastion.csv
│   │   │   ├── NatGateway.csv
│   │   │   ├── PrivateDnsZone.csv
│   │   │   ├── SecurityGroup.csv
│   │   │   ├── Subnet.csv
│   │   │   ├── VirtualMachine.csv
│   │   │   └── VirtualNetwork.csv
│   │   ├── scripts/          # OS Bootstrap Scripts (Bash/PowerShell)
│   │   ├── locals.tf         # Logic Engine: CSV ingestion and data transformation
│   │   ├── main.tf           # Module invocation and dependency injection
│   │   ├── variables.tf      # Global environment variables
│   │   └── versions.tf       # Provider constraints
│   └── prod/                 # Production environment execution root
└── modules/                  # 🧩 Reusable Terraform Modules
    ├── compute/              # Linux/Windows Virtual Machines & Managed Disks
    ├── network/              # VNets, Subnets, Route Tables, NAT, Private DNS
    ├── resourcegroup/        # Baseline Resource Group provisioning
    └── security/             # NSGs, Security Rules, Azure Bastion

```

## Features Supported

* **Networking:** Hub-and-Spoke compatible Virtual Networks, Subnet delegation, NAT Gateways, and Route Tables (UDRs) for Virtual Appliance routing.
* **Compute:** Dynamic provisioning of Linux (Ubuntu) and Windows Server VMs, automatic Managed Data Disk attachment, and custom bootstrapping. Handles Azure vs. internal OS NetBIOS naming constraints natively.
* **Security:** Network Security Groups, granular port-level rules, and Azure Bastion (Developer/Standard) deployment for secure, public-IP-free management access.
* **Private Link DNS:** Automated Private DNS Zone creation and Virtual Network Link injection for PaaS isolation.

## Prerequisites

* [Terraform](https://www.terraform.io/downloads.html) >= 1.2.0
* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
* Active Azure Subscription with `Contributor` or `Owner` RBAC permissions.

## Getting Started

### 1. Authentication

Authenticate your local session with Azure:

```bash
az login
az account set --subscription "<YOUR_SUBSCRIPTION_ID>"

```

### 2. Configure Data Dictionaries

Navigate to your target environment (e.g., `environment/uat/data/`). Modify the CSV files to define your desired infrastructure state.

*Example: Adding a Virtual Machine (`VirtualMachine.csv`)*

```csv
ResourceType,ProjectCode,Environment,Zone,Tier,Purpose,Indexing,ResourceGroup,SubnetName,OS,AzureVMSeries,AvailabilityZone,DiskType,OSStorageGB,DataStorageGB,ImagePublisher,ImageOffer,ImageSKU,ImageVersion
vm,prj,u,ia,wet,app,01,rsg-prj-uia-01,sub-prj-uia-wet-vms01,Linux,Standard_D2s_v3,1,Premium_LRS,128,256,Canonical,ubuntu-24_04-lts,server,latest

```

### 3. Initialize and Deploy

Navigate to the root of the environment you wish to deploy and initialize the Terraform backend:

```bash
cd environment/uat
terraform init

```

Generate an execution plan to validate your CSV data against the enterprise `lifecycle` constraints:

```bash
terraform plan -out=tfplan

```

Apply the configuration:

```bash
terraform apply tfplan

```

## Operational Guidelines

### Stateful Module Separation

To prevent the "Operation Preempted" API error common in Azure ARM deployments, this platform utilizes strict modular boundary crossing.

* The `Security` module will not execute until the `Network` module has fully released its locks on VNet and Subnet resources.
* The `Compute` module Custom Script Extensions explicitly wait for Managed Disks to initialize before executing.

### Handling Headless Script Execution

Windows Bootstrap scripts (`windows_bootstrap.ps1`) executed via the Azure VM Agent must run silently. Interactive output streams (such as `Write-Progress` or `refreshenv`) will be serialized as CLIXML errors and trigger a `VMExtensionProvisioningError`. Ensure all custom OS scripts set `$ProgressPreference = "SilentlyContinue"` and handle `$env:Path` injections manually.

## Contributing

1. Create a feature branch from `main` (`git checkout -b feature/new-module`).
2. Make your module or configuration changes.
3. Validate syntax using `terraform fmt` and `terraform validate`.
4. Submit a Pull Request for peer review. Direct commits to `main` are restricted.

```

```
