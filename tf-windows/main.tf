# # Data sources
# data "vsphere_datacenter" "dc" {
#   name = "HAVEN"
# }

# data "vsphere_datastore" "datastore" {
#   name          = "datastore1"
#   datacenter_id = data.vsphere_datacenter.dc.id
# }

# data "vsphere_compute_cluster" "cluster" {
#   name          = "haven-cluster-1"
#   datacenter_id = data.vsphere_datacenter.dc.id
# }

# # First network 
# data "vsphere_network" "production_network" {
#   name          = "VM Network" # Your production network name
#   datacenter_id = data.vsphere_datacenter.dc.id
# }

# # Second network 
# data "vsphere_network" "management_network" {
#   name          = "VM Network" # Your management network name
#   datacenter_id = data.vsphere_datacenter.dc.id
# }

# data "vsphere_virtual_machine" "template" {
#   name          = "windows-vm"
#   datacenter_id = data.vsphere_datacenter.dc.id
# }

# # Reference existing folder
# data "vsphere_folder" "existing_folder" {
#   path = "haven-test-01"
# }

# # Virtual Machine with dual NICs
# resource "vsphere_virtual_machine" "windows_vm" {
#   name             = "windows-server-012"
#   resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
#   datastore_id     = data.vsphere_datastore.datastore.id
#   folder           = data.vsphere_folder.existing_folder.path

#   num_cpus  = 4
#   memory    = 8192
#   guest_id  = data.vsphere_virtual_machine.template.guest_id
#   scsi_type = data.vsphere_virtual_machine.template.scsi_type
#   firmware  = "efi"
#   # First NIC - Production Network
#   network_interface {
#     network_id   = data.vsphere_network.production_network.id
#     adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
#   }

#   # # Second NIC - Management Network  
#   # network_interface {
#   #   network_id   = data.vsphere_network.management_network.id
#   #   adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
#   # }

#   disk {
#     label            = "disk0"
#     size             = max(100, data.vsphere_virtual_machine.template.disks.0.size)
#     eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
#     thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
#   }

#   clone {
#     template_uuid = data.vsphere_virtual_machine.template.id

#     customize {
#       timeout = 20

#       windows_options {
#         computer_name    = "WIN-SRV-01"
#         admin_password   = var.admin_password
#         time_zone        = 35 # Eastern Standard Time
#         auto_logon       = true
#         auto_logon_count = 1

#         # # Domain join configuration 
#         # join_domain           = var.domain_name
#         # domain_admin_user     = var.domain_admin_user
#         # domain_admin_password = var.domain_admin_password
#         workgroup = "WORKGROUP"
#       }

#       # Configure first NIC (Production Network)
#       network_interface {
#         ipv4_address = "192.168.1.30" # Production network IP
#         ipv4_netmask = 24
#       }

#       # # Configure second NIC (Management Network)
#       # network_interface {
#       #   ipv4_address = "10.1.1.29" # Management network IP
#       #   ipv4_netmask = 24
#       # }

#       # Primary gateway (usually production network)
#       ipv4_gateway    = "192.168.1.1"
#       dns_server_list = ["192.168.1.170", "8.8.8.8"] # Domain controllers
#       dns_suffix_list = [var.domain_name]
#     }
#   }
# }


# output "vm_folder_path" {
#   description = "VM folder path"
#   value       = data.vsphere_folder.existing_folder.path
# }

# Data sources
data "vsphere_datacenter" "dc" {
  name = "HAVEN"
}

data "vsphere_datastore" "datastore" {
  name          = "datastore1"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = "haven-cluster-1"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "production_network" {
  name          = "VM Network"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "management_network" {
  name          = "VM Network"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = "windows-vm"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_folder" "existing_folder" {
  path = "haven-test-01"
}

# Virtual Machine
resource "vsphere_virtual_machine" "windows_vm" {
  name             = "windows-server-01"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = data.vsphere_folder.existing_folder.path

  num_cpus  = 4
  memory    = 8192
  guest_id  = data.vsphere_virtual_machine.template.guest_id
  scsi_type = data.vsphere_virtual_machine.template.scsi_type
  firmware  = "efi"

  # First NIC - Production Network
  network_interface {
    network_id   = data.vsphere_network.production_network.id
    adapter_type = "vmxnet3"
  }

  # # Second NIC - Management Network
  # network_interface {
  #   network_id   = data.vsphere_network.management_network.id
  #   adapter_type = "vmxnet3"
  # }

  # Force network adapters to stay connected
  # extra_config = {
  #   "ethernet0.startConnected"                = "true"
  #   "ethernet0.connectable.allowGuestControl" = "false"
  #   "ethernet1.startConnected"                = "true"
  #   "ethernet1.connectable.allowGuestControl" = "false"
  # }

  disk {
    label            = "disk0"
    size             = 40
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      timeout = 200

      windows_options {
        computer_name         = "WIN-SRV-01"
        admin_password        = var.admin_password
        join_domain           = var.domain_name
        domain_admin_user     = var.domain_admin_user
        domain_admin_password = var.domain_admin_password
        time_zone             = 35 ### remember to change this 
        auto_logon            = true
        auto_logon_count      = 1
      }

      # Configure first NIC (Production Network)
      network_interface {
        ipv4_address = "192.168.1.129"
        ipv4_netmask = 24
      }

      # # Configure second NIC (Management Network)
      # network_interface {
      #   ipv4_address = "10.10.200.50"
      #   ipv4_netmask = 24
      # }

      ipv4_gateway    = "192.168.100.1"
      dns_server_list = ["192.168.1.170", "8.8.8.8"]
      dns_suffix_list = [var.domain_name]
    }
  }

  wait_for_guest_net_timeout = 60
  wait_for_guest_ip_timeout  = 60
}

# # Outputs
# output "vm_production_ip" {
#   description = "Production NIC IP address"
#   value       = "192.168.100.50"
# }

# output "vm_management_ip" {
#   description = "Management NIC IP address"
#   value       = "10.10.200.50"
# }

output "vm_folder_path" {
  description = "VM folder path"
  value       = data.vsphere_folder.existing_folder.path
}