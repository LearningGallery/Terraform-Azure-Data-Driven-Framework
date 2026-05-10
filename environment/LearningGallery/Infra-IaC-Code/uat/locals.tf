locals {
  # Merge context variables into the Enterprise Tagging Standard
  enterprise_tags = {
    ProjectCode        = var.project_code
    Environment        = var.environment == "u" ? "UAT" : "PROD"
    CostCenter         = var.cost_center
    DataClassification = var.data_classification
    ManagedBy          = "Terraform"
    Pipeline           = "GitHubActions"
    # DeploymentDate     = formatdate("YYYY-MM-DD", timestamp())
  }

  # Load CSVs dynamically from the centralized data folder
  rg_csv       = csvdecode(file("./data/ResourceGroup.csv"))
  vnet_csv     = csvdecode(file("./data/VirtualNetwork.csv"))
  nsg_csv      = csvdecode(file("./data/SecurityGroup.csv"))
  rt_csv       = csvdecode(file("./data/RouteTable.csv"))
  pip_csv      = csvdecode(file("./data/PublicIP.csv"))
  subnet_csv   = csvdecode(file("./data/Subnet.csv"))
  natgw_csv    = csvdecode(file("./data/NatGateway.csv"))
  bastion_csv  = csvdecode(file("./data/Bastion.csv"))
  dns_csv = csvdecode(file("./data/PrivateDnsZone.csv"))
  vm_csv = csvdecode(file("./data/VirtualMachine.csv"))

  # Transform into Maps keyed by Resource Name
  rgs = { for row in local.rg_csv : row.ResourceGroupName => row }
  
  vnets = { for row in local.vnet_csv : row.VirtualNetworkName => {
      name                = row.VirtualNetworkName
      resource_group_name = row.ResourceGroup
      address_space       = split(",", replace(replace(row.AddressSpaces, "[", ""), "]", ""))
    }
  }

  nsgs = { for row in local.nsg_csv : row.SecurityGroupName => row... }
  
  nsg_rules = { for row in local.nsg_csv : "${row.SecurityGroupName}-${row.NSGRuleName}" => {
      nsg_name                   = row.SecurityGroupName
      rg_name                    = row.ResourceGroup
      rule_name                  = row.NSGRuleName
      priority                   = tonumber(row.Priority)
      direction                  = row.Direction
      access                     = row.Access
      protocol                   = row.Protocol
      source_port_range          = row.SourcePortRange
      destination_port_range     = row.DestinationPortRange
      source_address_prefix      = replace(replace(row.SourceAddressPrefix, "[", ""), "]", "")
      destination_address_prefix = replace(replace(row.DestinationAddressPrefix, "[", ""), "]", "")
      description                = row.Description
    }
  }

  # Group by Route Table Name
  route_tables = { for row in local.rt_csv : row.RouteTableName => row... }

  # Flatten the Routes
  rt_routes = { for row in local.rt_csv : "${row.RouteTableName}-${row.RouteName}" => {
      rt_name        = row.RouteTableName
      rg_name        = row.ResourceGroup
      route_name     = row.RouteName
      address_prefix = row.AddressPrefix
      next_hop_type  = row.NextHopType
      next_hop_ip    = row.NextHopIpAddress == "None" ? null : row.NextHopIpAddress
    } if row.RouteName != "None"
  }

  pips = { for row in local.pip_csv : row.PublicIPName => row }

  # Map of the DNS Zones
  dns_zones = { for row in local.dns_csv : row.DnsZoneName => row }

  # Flattened Map for VNet Links (Creates a unique key for every Zone+VNet combo)
  dns_links = merge([
    for row in local.dns_csv : {
      for vnet in split(",", replace(replace(row.LinkedVNets, "[", ""), "]", "")) :
      "${row.DnsZoneName}-${vnet}" => {
        zone_name = row.DnsZoneName
        rg_name   = row.ResourceGroup
        vnet_name = vnet
      }
    }
  ]...)

  subnets = { for row in local.subnet_csv :
    (row.SubnetName == "AzureBastionSubnet" ? "${row.SubnetName}-${row.Zone}" : row.SubnetName) => {
      name                 = row.SubnetName
      rg_name              = "rsg-${row.ProjectCode}-${row.Environment}${row.Zone}-${row.Indexing}"
      vnet_name            = "vnt-${row.ProjectCode}-${row.Environment}${row.Zone}-${row.Indexing}"
      address_prefixes     = ["${replace(replace(row.StartingAddress, "[", ""), "]", "")}${row.Size}"]
      nsg_link             = row.NetworkSecurityGroup
      rt_link              = row.RouteTable
      service_endpoints    = row.ServiceEndpoints != "None" ? split(",", row.ServiceEndpoints) : []
    }
  }

  natgws = { for row in local.natgw_csv : row.NATGateWayName => row }
  bastions = { for row in local.bastion_csv : row.BastionName => row }

# Base VM Map with standard naming generated on-the-fly
  all_vms = { for row in local.vm_csv : 
    "${row.ResourceType}-${row.ProjectCode}-${row.Environment}${row.Zone}-${row.Tier}-${row.Purpose}${row.Indexing}" => merge(row, {
      computed_name = "${row.ResourceType}-${row.ProjectCode}-${row.Environment}${row.Zone}-${row.Tier}-${row.Purpose}${row.Indexing}"
    })
  }

  # Split into OS-specific maps for the module
  linux_vms   = { for k, v in local.all_vms : k => v if lower(v.OS) == "linux" }
  windows_vms = { for k, v in local.all_vms : k => v if lower(v.OS) == "windows" }
}