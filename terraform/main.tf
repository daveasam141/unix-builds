data "vsphere_datacenter" "datacenter" {
  name = "HAVEN"
}

data "vsphere_datastore" "datastore" {
  name          = "datastore1"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = "haven-cluster-1"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network" {
  name          = "VM Network"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

resource "vsphere_virtual_machine" "vm" {
  name             = "ubuntu-vm"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = 1
  memory           = 8192
  guest_id         = "ubuntu64Guest"

  scsi_type = "lsilogic"

  network_interface {
    network_id = data.vsphere_network.network.id
  }

  disk {
    label       = "Hard Disk 1"
    size        = 20
    unit_number = 0
  }

  cdrom {
    datastore_id = data.vsphere_datastore.datastore.id
    path         = "iso/ubuntu-24.04.2-live-server-amd64.iso"
  }
}