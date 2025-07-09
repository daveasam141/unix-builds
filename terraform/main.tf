data "vsphere_datacenter" "datacenter" {
  name = "infra-datacenter"
}

data "vsphere_datastore" "datastore" {
  name          = "kendops-kube-nas-datastore-01"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = "infra-cluster"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network" {
  name          = "VM Network"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_virtual_machine" "template" {
  name          = "test-u-template"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

resource "vsphere_virtual_machine" "vm" {
  name             = "waveform-01"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = 2
  memory           = 4096
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  firmware         = "efi"
  enable_disk_uuid = true

  # Wait for guest net to be ready
  wait_for_guest_net_timeout = 5
  wait_for_guest_ip_timeout  = 5

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = "vmxnet3"
  }

  disk {
    label            = "disk0"
    size             = 20
    thin_provisioned = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }

  # Cloud-init configuration
  extra_config = {
    "guestinfo.userdata"          = base64encode(file("cloud-init/user-data"))
    "guestinfo.userdata.encoding" = "base64"
    "guestinfo.metadata"          = base64encode(file("cloud-init/meta-data"))
    "guestinfo.metadata.encoding" = "base64"
  }
}