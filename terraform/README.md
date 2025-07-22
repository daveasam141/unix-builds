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

## Proper user-data config on template
# Backup the current file
sudo cp /etc/cloud/cloud.cfg /etc/cloud/cloud.cfg.backup

# Create a proper cloud-init system configuration
sudo tee /etc/cloud/cloud.cfg << 'EOF'
# Cloud-init system configuration
datasource_list: [VMware, OVF, None]

preserve_hostname: false
manage_etc_hosts: true

users:
  - default

disable_root: true
ssh_pwauth: true

cloud_init_modules:
  - migrator
  - seed_random
  - bootcmd
  - write-files
  - growpart
  - resizefs
  - set_hostname
  - update_hostname
  - update_etc_hosts
  - ca-certs
  - rsyslog
  - users-groups
  - ssh

cloud_config_modules:
  - emit_upstart
  - snap
  - ssh-import-id
  - locale
  - set-passwords
  - grub-dpkg
  - apt-pipelining
  - apt-configure
  - ntp
  - timezone
  - disable-ec2-metadata
  - runcmd
  - byobu

cloud_final_modules:
  - package-update-upgrade-install
  - fan
  - landscape
  - lxd
  - ubuntu-drivers
  - puppet
  - chef
  - mcollective
  - salt-minion
  - rightscale_userdata
  - scripts-vendor
  - scripts-per-once
  - scripts-per-boot
  - scripts-per-instance
  - scripts-user
  - ssh-authkey-fingerprints
  - keys-to-console
  - phone-home
  - final-message
  - power-state-change

system_info:
  default_user:
    name: ubuntu
    lock_passwd: True
    gecos: Ubuntu
    groups: [adm, audio, cdrom, dialout, dip, floppy, lxd, netdev, plugdev, sudo, video]
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    shell: /bin/bash
  package_mirrors:
    - arches: [amd64, i386]
      failsafe:
        primary: http://archive.ubuntu.com/ubuntu
        security: http://security.ubuntu.com/ubuntu
  ssh_svcname: ssh
EOF

## Configure cloud-init to use the guestinfo datasource 
echo 'datasource_list: [VMware, NoCloud]' | sudo tee /etc/cloud/cloud.cfg.d/90_dpkg.cfg

## enable All cloud-init services
# Enable all cloud-init services
sudo systemctl enable cloud-init-local
sudo systemctl enable cloud-init
sudo systemctl enable cloud-config
sudo systemctl enable cloud-final

# Verify they're enabled
sudo systemctl is-enabled cloud-init-local
sudo systemctl is-enabled cloud-init
sudo systemctl is-enabled cloud-config
sudo systemctl is-enabled cloud-final

## Make sure ssh allow pubkey and password auth

# Stop cloud-init services
sudo systemctl stop cloud-init-local cloud-init cloud-config cloud-final

# Remove any existing cloud-init data
sudo rm -rf /var/lib/cloud/instance/
sudo rm -rf /var/lib/cloud/instances/*
sudo rm -rf /var/lib/cloud/data/
sudo rm -rf /var/lib/cloud/sem/

# Remove cloud-init logs
sudo rm -f /var/log/cloud-init*.log

# Remove any existing netplan cloud-init config
sudo rm -f /etc/netplan/50-cloud-init.yaml

## Clean machine identity
# Clear machine ID (important for cloning)
sudo truncate -s 0 /etc/machine-id
sudo rm -f /var/lib/dbus/machine-id

# Clear network interface persistence
sudo rm -f /etc/udev/rules.d/70-persistent-net.rules

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


###### INstalling from scratch 
## ubuntu vm 2 cpu, 50GB thin provisioned ubuntu iso 

## update system 
sudo apt update && sudo apt upgrade 

## install essential packages 
sudo apt install -y cloud-init open-vm-tools open-vm-tools-dev curl wget

## Configure cloud -init datasources 
sudo tee /etc/cloud/cloud.cfg.d/90_dpkg.cfg << 'EOF'
datasource_list: [VMware, OVF, None]
EOF

## configure main cloud-init datasources 
sudo tee /etc/cloud/cloud.cfg << 'EOF'
# Cloud-init configuration for VMware template
datasource_list: [VMware, OVF, None]

preserve_hostname: false
manage_etc_hosts: true

users:
  - default

disable_root: true
ssh_pwauth: true

# Modules that run in the 'init' stage
cloud_init_modules:
  - migrator
  - seed_random
  - bootcmd
  - write-files
  - growpart
  - resizefs
  - set_hostname
  - update_hostname
  - update_etc_hosts
  - ca-certs
  - rsyslog
  - users-groups
  - ssh

# Modules that run in the 'config' stage  
cloud_config_modules:
  - locale
  - set-passwords
  - apt-configure
  - ntp
  - timezone
  - disable-ec2-metadata
  - runcmd

# Modules that run in the 'final' stage
cloud_final_modules:
  - scripts-vendor
  - scripts-per-once
  - scripts-per-boot
  - scripts-per-instance
  - scripts-user
  - final-message

system_info:
  default_user:
    name: ubuntu
    lock_passwd: True
    gecos: Ubuntu
    groups: [adm, audio, cdrom, dialout, dip, floppy, lxd, netdev, plugdev, sudo, video]
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    shell: /bin/bash
  package_mirrors:
    - arches: [amd64, i386]
      failsafe:
        primary: http://archive.ubuntu.com/ubuntu
        security: http://security.ubuntu.com/ubuntu
  ssh_svcname: ssh
EOF


## Enable cloud-init services 
sudo systemctl enable cloud-init-local
sudo systemctl enable cloud-init
sudo systemctl enable cloud-config
sudo systemctl enable cloud-final

## configure vmware tools 
sudo systemctl status open-vm-tools
sudo systemctl enable open-vm-tools

## Test vmware communication 
sudo vmware-rpctool "info-get tools.version.status" 2>/dev/null || echo "Communication test complete"

## Prepare the system 
# Clean package cache
sudo apt autoremove -y
sudo apt autoclean

# Clean logs
sudo truncate -s 0 /var/log/*log
sudo find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;

# Clean cloud-init data
sudo cloud-init clean --logs --seed

# Clean machine identity
sudo truncate -s 0 /etc/machine-id
sudo rm -f /var/lib/dbus/machine-id

# Clean network interface persistence
sudo rm -f /etc/udev/rules.d/70-persistent-net.rules

# Clean SSH host keys (will be regenerated)
sudo rm -f /etc/ssh/ssh_host_*

# Clean user history
history -c
sudo rm -f /home/ubuntu/.bash_history
sudo rm -f /root/.bash_history

# Clean temporary files
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*



