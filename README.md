virt-install (libvirt/KVM) Kickstart

Purpose:
Rapidly deploy Satellite and other things on a libvirt test bed. Mine is a laptop.
Using dnf install virt-install virt-manager. Deploy Satellite 6.2.x fully configured in ~45 minutes.
Save time by using local media to install RHEL and Satellite. The first time you pull repositories from cdn.redhat.com, export them to your same httpd server used for kickstart.

Run virt-inst.sh <vmname> <disc in GB> <vcpus> <mem> (virt-inst.sh satellite 300 4 6144).
1 Creates a libvirt vm.
2 Registers to CDN.
3 Installs Satellite from DVD.
4 Patches the RHEL and Satellite.
5 Configures Satellite.
6 Enables and imports repositories from local repo on httpd.
7 Switches CDN URL back to https://cdn.redhat.com and pulls in deltas.
8 Creates, Domain, Subnet, Lifecycles, Content Hosts, Content Views, Promote Content Views, Activation Keys, Host Groups, Sync Plan, Compute Resource, virt-who configured to libvirt.
9 Script to export repositories to local httpd.
10 Script to Create New Host with Satellite using boot media.

virt-inst.sh is the main script. There is a config file in etc. Take a look and modify accordingly.
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

Requirements:
You need a libvirt/KVM machine (I use a laptop or single box at home), it will serve as a Kickstart server. It helps speed up the process if you supply a Red Hat Satellite dvd as well as a RHEL dvd.
