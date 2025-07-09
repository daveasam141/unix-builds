# Steps to set up and use terraform to create a machine on vmware 

## Install cloud-init ubuntu image 
wget https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img

## Convert image to to vmdk 
qemu-img convert -f qcow2 -O vmdk -o adapter_type=lsilogic,subformat=monolithicFlat \
  ubuntu-24.04-server-cloudimg-amd64.img \
  ubuntu-24.04-cloudimg.vmdk

##
1.	In vSphere:
	•	Go to VMs and Templates
	•	Create a New Virtual Machine
	•	Select:
	•	Compatibility: Latest
	•	OS Type: Linux → Ubuntu 64-bit
	•	CPU & RAM: 2 vCPU, 2GB+ RAM
	•	SCSI Controller: LSI Logic or VMware Paravirtual
	•	Disk: Do not create a disk yet
	2.	After VM is created:
	•	Right-click → Edit Settings
	•	Remove any default hard disk
	•	Click Add → Hard Disk → Use an existing virtual disk
	•	Upload your ubuntu-24.04-cloudimg.vmdk file to the VM’s datastore
	•	Attach that VMDK as the boot disk
	3.	Add a CD-ROM device (for optional cloud-init ISO or config)
	4.	Set Firmware to EFI
	5.	Enable “Boot Delay” to access BIOS if needed

## Install genisoimage on redhat vm to use for config with cloud-init vmdk 
sudo dnf install genisoimage 

### Create user-data file
#cloud-config
users:
  - name: ubuntu
    shell: /bin/bash
    groups: [sudo]
    lock_passwd: false
    passwd: "$6$TMRaOShE4lqQaTFa$3zagpAHkVcUQR4bn61Mrfddy5WrxaPxXaqELbuIBeUKYvAxUMfKLw7IiCeCOZbDQd2lJDECD0mCG8LNeGUjd9."
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
ssh_pwauth: true
disable_root: true

### create meta-data file 
instance-id: ubuntu-template
local-hostname: ubuntu-template

### generate iso with both files 
genisoimage -output cloud-init.iso \
  -volid cidata -joliet -rock \
  user-data meta-data

mkisofs -output cloud-init.iso \
  -volid cidata -joliet -rock \
  user-data meta-data

### Upload the cloud-init iso to the datastore of vm and mount the boot up vm 
use user and password defined in user-data to login to box

## Install vmware tools(if not present)
sudo apt update
sudo apt install open-vm-tools cloud-init
sudo apt install -y util-linux

## Configure cloud-init to use the guestinfo datasource 
echo 'datasource_list: [VMware, NoCloud]' | sudo tee /etc/cloud/cloud.cfg.d/90_dpkg.cfg

## Poweroff vm tand convert to template 
sudo shutdown now 

## Create cloud init/user-data to be used withb terraform 

## Use template with terraform 
  extra_config = {
    "guestinfo.userdata"          = base64encode(file("cloud-init/user-data"))
    "guestinfo.userdata.encoding" = "base64"
    "guestinfo.metadata"          = base64encode(file("cloud-init/meta-data"))
    "guestinfo.metadata.encoding" = "base64"
  }
}



#### Set env variables 
##  Powershell
$env:TF_VAR_vsphere_user = "administrator@vsphere.local"
$env:TF_VAR_vsphere_password = "MySecurePassword123!"

## Bash/Linux 
export TF_VAR_vsphere_user="administrator@vsphere.local"
export TF_VAR_vsphere_password="MySecurePassword123!"
export TF_VAR_vsphere_server="x.x.x.x"

## for debugging
export TF_LOG=TRACE
export TF_LOG_PATH=terraform-debug.log