## RHEL 7 basic repos from local for speed, then again changing to internet sources to get updated.

hammer organization update \
  --name redhat \
  --redhat-repository-url http://10.0.0.1/ks/katello-export/redhat-Default_Organization_View-v1.0/redhat/Library/
hammer repository-set enable \
  --organization redhat \
  --product 'Red Hat Enterprise Linux Server' \
  --basearch='x86_64' \
  --releasever='7Server' \
  --name 'Red Hat Enterprise Linux 7 Server (Kickstart)'
hammer repository-set enable \
  --organization redhat \
  --product 'Red Hat Enterprise Linux Server' \
  --basearch='x86_64' \
  --releasever='7Server' \
  --name 'Red Hat Enterprise Linux 7 Server (RPMs)'
# can't use releasesever on this one.
#hammer repository-set enable --organization redhat --product 'Red Hat Enterprise Linux Server' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Linux 7 Server - Extras (RPMs)'
hammer repository-set enable \
  --organization redhat \
  --product 'Red Hat Enterprise Linux Server' \
  --basearch='x86_64' \
  --name 'Red Hat Enterprise Linux 7 Server - Extras (RPMs)'
hammer repository-set enable \
  --organization redhat \
  --product 'Red Hat Enterprise Linux Server' \
  --basearch='x86_64' \
  --releasever='7Server' \
  --name 'Red Hat Enterprise Linux 7 Server - Optional (RPMs)'
hammer repository-set enable \
  --organization redhat \
  --product 'Red Hat Enterprise Linux Server' \
  --basearch='x86_64' \
  --releasever='7Server' \
  --name 'RHN Tools for Red Hat Enterprise Linux 7 Server (RPMs)'
hammer product create \
  --organization redhat \
  --name EPEL7
#hammer repository update --url 'http://10.0.0.1/ks/katello-export/redhat-Default_Organization_View-v1.0/redhat/Library/custom/EPEL7/EPEL_7_-_x86_64/' --organization redhat --product EPEL7
#hammer repository create --name='EPEL 7 - x86_64' --organization=redhat --product='EPEL7' --content-type='yum' --publish-via-http=true --url=http://dl.fedoraproject.org/pub/epel/7/x86_64/
hammer repository create \
  --name='EPEL 7 - x86_64' \
  --organization=redhat \
  --product='EPEL7' \
  --content-type='yum' \
  --publish-via-http=true \
  --url=http://10.0.0.1/ks/katello-export/redhat-Default_Organization_View-v1.0/redhat/Library/custom/EPEL7/EPEL_7_-_x86_64/
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

