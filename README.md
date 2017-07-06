virt-install (libvirt/KVM) Kickstart

virt-inst.sh is the main script. Modify the script to reflect the directroy, /var/www/html/ks and web server.
This script creates a uniq ks.cfg file each time it runs and point KVM/libvirt virt-install program to use the ks.cfs file.

./virt-install <name> <disc MB> <mem> <vcpu>

This directory needs to be in an httpd DocumentRoot suggest default /var/www/html/ks.
The whole directory is important. /var/www/html/ks/[iso,manifest,post,partitions,packages,network]

The kickstart file is embedded in virt-inst.sh and is written to a temp name_date.cfg file for the actual kickstart.

The kickstart is started by virt-install as a parameter for creating the libvirt VM.

The post,partitions,packages,network dirs contain files that are named by the <name> var in the command when the script is run.
They are setup in kickstart with %include statements and are put on the VM being provisioned with curl.

The heavy lifting is then done with <name>.sh that is copied to /root dir to be run manually. Did this instead of messing with rc.local and fighting $ in variables from getting mucked up.

Turn this into automated provisioning with a real config management tool. Ansible, puppet.
