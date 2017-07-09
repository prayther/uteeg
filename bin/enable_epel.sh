#!/bin/bash -x

cd "${BASH_SOURCE%/*}"
source ../etc/virt-inst.cfg
source ../etc/enable_epel.cfg
source ../etc/install-configure-satellite.cfg

#exec >> ../log/enable_epel.log 2>&1

# Setup EPEL
hammer product create --organization ${ORG} --name EPEL7

hammer repository create --name=EPEL7 --organization=${ORG} --product=EPEL7 --content-type='yum' --publish-via-http=true --url=${URL}/katello-export/redhat-Default_Organization_View-v1.0/redhat/Library/custom/EPEL7/EPEL_7_-_x86_64/
# Then we can sync all repositories that we've enable
for i in $(hammer --csv repository list --organization=${ORG} | grep -i "EPEL7" | awk -F, {'print $1'} | grep -vi '^ID'); do hammer repository synchronize --id ${i} --organization=${ORG}; done

# Put pulic mirror back to sync latest
hammer repository update --url ${URL_EPEL} --organization "${ORG}" --product EPEL7
for i in $(hammer --csv repository list --organization=${ORG} | grep -i "EPEL7" | awk -F, {'print $1'} | grep -vi '^ID'); do hammer repository synchronize --id ${i} --organization=${ORG}; done

###########################
#cleanup and add to epel, check_mk
###########################
#Create a content view for EPEL 7 x86_64e:
hammer content-view create --name='CV_EPEL7' --organization=${ORG}
for i in $(hammer --csv repository list --organization=${ORG} | grep "EPEL7" | awk -F, {'print $1'} | grep -vi '^ID'); do hammer content-view add-repository --name='CV_EPEL7' --organization=${ORG} --repository-id=${i}; done
for i in $(hammer --csv repository list --organization=${ORG} | grep "EPEL7" | awk -F, {'print $1'} | grep -vi '^ID'); do hammer content-view add-repository --name='CV_EPEL7' --organization=${ORG} --repository-id=${i}; done

#Publish the content views to Library:
hammer content-view publish --name="CV_EPEL7" --organization=${ORG} #--async

# then run cv_promote.sh

