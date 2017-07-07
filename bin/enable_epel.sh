#!/bin/bash -x

cd "${BASH_SOURCE%/*}"
#source ../etc/virt-inst.cfg
source ../etc/enable_epel.cfg
#source ../etc/install-configure-satellite.cfg

exec >> ../log/enable_epel.log 2>&1

# Setup EPEL
hammer product create \
  --organization redhat \
  --name ${NAME_EPEL7}

hammer repository create \
  --name=${NAME_EPEL7} \
  --organization=redhat \
  --product=${NAME_EPEL7} \
  --content-type='yum' \
  --publish-via-http=true \
  --url=${URL}/katello-export/redhat-Default_Organization_View-v1.0/redhat/Library/custom/${NAME_EPEL7}/${NAME_EPEL7}
# Then we can sync all repositories that we've enable
for i in $(hammer --csv repository list --organization=${ORG} | grep -i "${PRODUCT_VER}" | awk -F, {'print $1'} | grep -vi '^ID'); do hammer repository synchronize --id ${i} --organization=${ORG}; done

# Put pulic mirror back to sync latest
hammer repository update --url ${URL_EPEL} --organization redhat --product ${NAME_EPEL7}
for i in $(hammer --csv repository list --organization=${ORG} | grep -i "${PRODUCT_VER}" | awk -F, {'print $1'} | grep -vi '^ID'); do hammer repository synchronize --id ${i} --organization=${ORG}; done
# then run cv_promote.sh

