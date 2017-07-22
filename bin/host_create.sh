#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root

cd "${BASH_SOURCE%/*}"
source ../etc/install-configure-satellite.cfg
source ../etc/virt-inst.cfg
source ../etc/register_cdn.cfg
source ../etc/ak_create.cfg

#exec >> ../log/host_create.log 2>&1

#!/bin/bash

# Make sure you have credentials set in /home/<user>/.hammer/cli_config.yml
# Content should look like this:
#
# :foreman:
# :host: 'https://satellite.myredfedora.com/'
# :username: 'username'
# :password: 'passwor'


# Setting variables

vmname="$1"
vmip="$2"
#datastore="$3"

# Functions

#function datast () {
## For this function to function, you will need to create a 'viewer' account on your Satellite 6 install.
## Also to display the json information in a readable format you'll need python, the json.tool module should come with it.
# USER="admin"
# PASS="password"
# FOREMAN_URL="https://$(hostname)/api"
#
# stores=$(curl -s -H "Accept:application/json" \
# -k -u $USER:$PASS \
# $FOREMAN_URL/compute_resources/1/available_storage_domains | python -m json.tool \
# )
#
# echo "${stores}"
#}

### Script start ###
#
# If not all arguments are set, the script will get and output the freespace in the datastores
#

#if [ "${datastore}" == "" ]; then
# echo ''
# echo ''
# echo 'Usage: ./$0 <vmname> <mgt ip address> <datastore>'
# echo ''
# echo ''
# echo '--- Checking datastore availability ---'
# echo ''
# datast
# echo ''
# exit
#fi


# Replace with line below to enable troubleshooting
# hammer -d host create \
# Edit all settings below, read all lines carefully.
# Everything prepended with an ! should be changed to
# either a variable you can create or something appropriate for your environment.
# Also please mind that I used some defaults you might want to change.


hammer host create \
--name "${vmname}" \
--environment !System_Environment \
--organization !YourOrg \
--location-id !NumeralLocationId \
--lifecycle-environment !Your_Lifecycle_Environment \
--hostgroup !Host_Group \
--operatingsystem "!RHEL X.X" \
--architecture "!x86_64" \
--domain-id !Numeral_domain_Id \
--subnet !Subnet_Name \
--ip "${vmip}" \
--compute-resource-id !Numeral_compute_Resource_Id \
--provision-method !build or image \
--content-view !Your_Content_View \
--compute-attributes "cpus=1,corespersocket=1,cluster=!YourCluster,path=!/Datacenters/YourOrg/Linux/SomeSubFolder,guest_id=!rhel7_64Guest,memory_mb=1024,start=1,scsi_controller_type=ParaVirtualSCSIController" \
--interface "primary=true,managed=true,provision=true,execution=true,compute_type=VirtualVmxnet3,type=interface,compute_network=!YourNetwork,_destroy=0,virtual=0" \
--build !true \
--volume "datastore="${datastore}",thin=true,eager_zero=false,size_gb=20G" \
--compute-profile-id 1 \
--ask-root-password no 
