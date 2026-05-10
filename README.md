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
