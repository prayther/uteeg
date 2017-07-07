#!/bin/bash -x

cd "${BASH_SOURCE%/*}"
source ../etc/virt-inst.cfg
source ../etc/install-configure-satellite.cfg

exec >> ../log/check_mk.log 2>&1

exit 1

# Configure all the Check_MK stuff in satellite
hammer product create \
  --organization redhat \
  --name Check_MK
#chcon -t httpd_sys_content_t apps/check_mk/check-mk-raw-1.4.0p7-el7-54.x86_64.rpm # change selinux context on the repo
hammer repository create \
  --name='Check_MK' \
  --organization=redhat \
  --product='Check_MK' \
  --content-type='yum' \
  --publish-via-http=true \
  --url=http://10.0.0.1/ks/apps/check_mk

#Create a content view for Check_MK:
hammer content-view create \
  --name='CV_Check_MK' \
  --organization=redhat
for i in $(hammer \
                   --csv repository list \
                   --organization=redhat | grep "Check_MK" | awk -F, {'print $1'} | grep -vi '^ID')
  do hammer content-view add-repository \
                                        --name='CV_Check_MK' \
                                        --organization=redhat \
                                        --repository-id=${i}
done

#Publish the content views to Library:
hammer content-view publish --name="CV_Check_MK" --organization=redhat #--async


COMP_RHEL7=$(hammer content-view version list  --organization=redhat  --content-view CV_RHEL7_Core | awk '/CV_RHEL7_Core/ {print $1}')
COMP_Check_MK=$(hammer content-view version list  --organization=redhat  --content-view CV_Check_MK | awk '/CV_Check_MK/ {print $1}')
# CCVs would contain the RHEL 7 Core Server.
#hammer content-view create --organization=redhat --name="CCV_RHEL7_Server" --composite  --component-ids="${COMP_RHEL7}" --description="Combines RHEL 7 with Basic Core Server"
#hammer content-view publish --name="CCV_RHEL7_Server" --organization=redhat --async

# CCVs would contain the Check_MK application and RHEL 7 Core Server.
hammer content-view create --organization=redhat --name="CCV_Check_MK" --composite  --component-ids="${COMP_RHEL7},${COMP_Check_MK}" --description="Combines RHEL 7 with the Check_MK application"
hammer content-view publish --name="CCV_Check_MK" --organization=redhat #--async

