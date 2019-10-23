#!/bin/bash

# Utility script to update the ansible repo with the latest (x86_86) templates and image
# streams from several github repos
#
# This script should be run from openshift-ansible/roles/openshift_examples

XPAAS_VERSION=ose-v1.4.18
RHDS_6_TAG=6.4.12.GA
RHIPS_6_TAG=6.4.12.GA
RHDM_7_TAG=7.4.1.GA
RHPAM_7_TAG=7.4.1.GA
DG_VERSION=7.3-v1.0
ORIGIN_VERSION=${1:-v3.11}
ORIGIN_BRANCH=${2:-release-3.11}
RHAMP_TAG=2.0.0.GA
EXAMPLES_BASE=$(pwd)/files/examples/x86_64
find ${EXAMPLES_BASE} -name '*.json' -delete
TEMP=`mktemp -d`
pushd $TEMP

if [ ! -d "${EXAMPLES_BASE}" ]; then
  mkdir -p ${EXAMPLES_BASE}
fi
wget https://github.com/openshift/origin/archive/${ORIGIN_BRANCH}.zip -O origin.zip
wget https://github.com/jboss-fuse/application-templates/archive/GA.zip -O fis-GA.zip
wget https://github.com/jboss-openshift/application-templates/archive/${XPAAS_VERSION}.zip -O application-templates-master.zip
wget https://github.com/jboss-container-images/rhdm-7-openshift-image/archive/${RHDM_7_TAG}.zip -O rhdm-templates.zip
wget https://github.com/jboss-container-images/rhpam-7-openshift-image/archive/${RHPAM_7_TAG}.zip -O rhpam-templates.zip
wget https://github.com/jboss-container-images/jboss-decisionserver-6-openshift-image/archive/${RHDS_6_TAG}.zip -O rhds-templates.zip
wget https://github.com/jboss-container-images/jboss-processserver-6-openshift-image/archive/${RHIPS_6_TAG}.zip -O rhips-templates.zip
wget https://github.com/3scale/rhamp-openshift-templates/archive/${RHAMP_TAG}.zip -O amp.zip
wget https://github.com/jboss-container-images/jboss-datagrid-7-openshift-image/archive/${DG_VERSION}.zip -O dg-application-templates.zip
unzip origin.zip
unzip application-templates-master.zip
unzip rhdm-templates.zip
unzip rhpam-templates.zip
unzip rhds-templates.zip
unzip rhips-templates.zip
unzip fis-GA.zip
unzip amp.zip
unzip dg-application-templates.zip
mv origin-${ORIGIN_BRANCH}/examples/db-templates/*.{yaml,json} ${EXAMPLES_BASE}/db-templates/
mv origin-${ORIGIN_BRANCH}/examples/quickstarts/*.{yaml,json} ${EXAMPLES_BASE}/quickstart-templates/
mv origin-${ORIGIN_BRANCH}/examples/jenkins/jenkins-*template.json ${EXAMPLES_BASE}/quickstart-templates/
mv origin-${ORIGIN_BRANCH}/examples/image-streams/*.{yaml,json} ${EXAMPLES_BASE}/image-streams/
mv application-templates-${XPAAS_VERSION}/jboss-image-streams.json ${EXAMPLES_BASE}/xpaas-streams/
mv rhdm-7-openshift-image-${RHDM_7_TAG}/rhdm74-image-streams.yaml ${EXAMPLES_BASE}/xpaas-streams/
mv rhpam-7-openshift-image-${RHPAM_7_TAG}/rhpam74-image-streams.yaml ${EXAMPLES_BASE}/xpaas-streams/
mv jboss-decisionserver-6-openshift-image-${RHDS_6_TAG}/templates/decisionserver64-image-stream.json ${EXAMPLES_BASE}/xpaas-streams/
mv jboss-processserver-6-openshift-image-${RHIPS_6_TAG}/templates/processserver64-image-stream.json ${EXAMPLES_BASE}/xpaas-streams/
mv jboss-datagrid-7-openshift-image-${DG_VERSION}/templates/datagrid73-image-stream.json ${EXAMPLES_BASE}/xpaas-streams/
# fis content from jboss-fuse/application-templates-GA would collide with jboss-openshift/application-templates
# as soon as they use the same branch/tag names
mv application-templates-GA/fis-image-streams.json ${EXAMPLES_BASE}/xpaas-streams/fis-image-streams.json
mv application-templates-GA/quickstarts/*.{yaml,json} ${EXAMPLES_BASE}/xpaas-templates/
mv application-templates-GA/fis-console-namespace-template.json application-templates-GA/fis-console-cluster-template.json ${EXAMPLES_BASE}/xpaas-templates/
mv application-templates-GA/fuse-apicurito.yml ${EXAMPLES_BASE}/xpaas-templates/
find application-templates-${XPAAS_VERSION}/ -name '*.json' ! -wholename '*secret*' ! -wholename '*demo*' ! -wholename '*image-stream.json' ! -name '*processserver6*' ! -name '*decisionserver6*' -exec mv {} ${EXAMPLES_BASE}/xpaas-templates/ \;
find application-templates-${XPAAS_VERSION}/ -name '*image-stream.json' ! -name '*processserver6*-image-stream*' ! -name '*decisionserver6*-image-stream*' -exec mv {} ${EXAMPLES_BASE}/xpaas-streams/ \;
find rhdm-7-openshift-image-${RHDM_7_TAG}/templates -name '*.yaml' -exec mv {} ${EXAMPLES_BASE}/xpaas-templates/ \;
find rhpam-7-openshift-image-${RHPAM_7_TAG}/templates -name '*.yaml' -exec mv {} ${EXAMPLES_BASE}/xpaas-templates/ \;
find jboss-decisionserver-6-openshift-image-${RHDS_6_TAG}/templates/ -name '*.json' ! -name '*image-stream*'  -exec mv -v {} ${EXAMPLES_BASE}/xpaas-templates/ \;
find jboss-processserver-6-openshift-image-${RHIPS_6_TAG}/templates/ -name '*.json' ! -name '*image-stream*'  -exec mv -v {} ${EXAMPLES_BASE}/xpaas-templates/ \;
find 3scale-amp-openshift-templates-${RHAMP_TAG}/ -name '*.yml' -exec mv {} ${EXAMPLES_BASE}/quickstart-templates/ \;
find jboss-datagrid-7-openshift-image-${DG_VERSION}/templates/ -name '*.json' -exec mv {} ${EXAMPLES_BASE}/xpaas-templates/ \;
find jboss-datagrid-7-openshift-image-${DG_VERSION}/services/ -name '*.yaml' -exec mv {} ${EXAMPLES_BASE}/xpaas-templates/ \;
popd

wget https://raw.githubusercontent.com/redhat-developer/s2i-dotnetcore/master/dotnet_imagestreams.json         -O ${EXAMPLES_BASE}/image-streams/dotnet_imagestreams.json
wget https://raw.githubusercontent.com/redhat-developer/s2i-dotnetcore/master/dotnet_imagestreams_centos.json         -O ${EXAMPLES_BASE}/image-streams/dotnet_imagestreams_centos.json
wget https://raw.githubusercontent.com/redhat-developer/s2i-dotnetcore/master/templates/dotnet-example.json           -O ${EXAMPLES_BASE}/quickstart-templates/dotnet-example.json
wget https://raw.githubusercontent.com/redhat-developer/s2i-dotnetcore/master/templates/dotnet-pgsql-persistent.json    -O ${EXAMPLES_BASE}/quickstart-templates/dotnet-pgsql-persistent.json
wget https://raw.githubusercontent.com/redhat-developer/s2i-dotnetcore/master/templates/dotnet-runtime-example.json    -O ${EXAMPLES_BASE}/quickstart-templates/dotnet-runtime-example.json

git diff files/examples
