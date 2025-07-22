Basic Build

sudo apt update
sudo apt upgrade

sudo apt install net-tools traceroute nmap


## disable IPv6
/etc/default/grub
##change to
GRUB_CMDLINE_LINUX_DEFAULT="ipv6.disable=1"
## update grub
sudo update-grub
##ifconfig to verify

