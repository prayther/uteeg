#!/bin/bash -x

#https://github.com/prayther/uteeg
#http://www.opensourcerers.org/installing-and-configuring-red-hat-satellite-6-via-shell-script/
# mschreie@redhat.com
# setting up  a satellite for demo purposes
# mainly following Adrian Bredshaws awsome book: http://gsw-hammer.documentation.rocks/

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
cd "${BASH_SOURCE%/*}"

logfile="../log/$(basename $0 .sh).log"
donefile="../log/$(basename $0 .sh).done"
touch $logfile
touch $donefile

exec > >(tee -a "$logfile") 2>&1

echo "###INFO: Starting $0"
echo "###INFO: $(date)"

# read configuration (needs to be adopted!)
#. ./satenv.sh
source ../etc/virt-inst.cfg
export HOME=/root


doit() {
        echo "INFO: doit: $@" >&2
        cmd2grep=$(echo "$*" | sed -e 's/\\//' | tr '\n' ' ')
        grep -q "$cmd2grep" $donefile
        if [ $? -eq 0 ] ; then
                echo "INFO: doit: found cmd in donefile - skipping" >&2
        else
                "$@" 2>&1 || {
                        echo "ERROR: cmd was unsuccessfull RC: $? - bailing out" >&2
                        exit 1
                }
                echo "$cmd2grep" >> $donefile
                echo "INFO: doit: cmd finished successfull" >&2
        fi
}

#runs or not based on hostname; ceph-?? gfs-??? sat-???
if [[ $(hostname -s | awk -F"-" '{print $1}') -ne "virt" ]];then
 echo ""
 echo "Need to run this on the 'virt' node"
 echo ""
 exit 1
fi

#if [[ $(hostname -s | awk -F"-" '{print $2}') -ne "admin" ]];then
# echo ""
# echo "Need to run this on the 'admin' node"
# echo ""
# exit 1
#fi

if [[ $(id -u) != "0" ]];then
        echo "Must run as root"
        echo
        exit 1
fi

#https://access.redhat.com/documentation/en-us/openshift_container_platform/3.6/html-single/installation_and_configuration/#install-config-install-rpm-vs-containerized
yum -y install http yum-utils createrepo docker git wget git net-tools bind-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct atomic atomic-openshift-utils

path="/var/www/html/repos/"

mkdir -p ${path}

for repo in \
rhel-7-server-rpms \
rhel-7-server-extras-rpms \
rhel-7-fast-datapath-rpms \
rhel-7-server-ose-3.6-rpms
do
  reposync --gpgcheck -lm --repoid=${repo} --download_path=${path}
  createrepo -v ${path}${repo} -o ${path}${repo}
done

chmod -R +r /var/www/html/repos
restorecon -vR /var/www/html
firewall-cmd --permanent --add-service=http
firewall-cmd --reload

systemctl enable httpd
systemctl start httpd

systemctl start docker

#Pull all of the required OpenShift Container Platform containerized components. Replace <tag> with v3.6.173.0.49 for the latest version.
tag="v3.6.173.0.49"
docker pull registry.access.redhat.com/openshift3/ose-ansible:${tag}
docker pull registry.access.redhat.com/openshift3/ose-cluster-capacity:${tag}
docker pull registry.access.redhat.com/openshift3/ose-deployer:${tag}
docker pull registry.access.redhat.com/openshift3/ose-docker-builder:${tag}
docker pull registry.access.redhat.com/openshift3/ose-docker-registry:${tag}
docker pull registry.access.redhat.com/openshift3/ose-egress-http-proxy:${tag}
docker pull registry.access.redhat.com/openshift3/ose-egress-router:${tag}
docker pull registry.access.redhat.com/openshift3/ose-f5-router:${tag}
docker pull registry.access.redhat.com/openshift3/ose-federation:${tag}
docker pull registry.access.redhat.com/openshift3/ose-haproxy-router:${tag}
docker pull registry.access.redhat.com/openshift3/ose-keepalived-ipfailover:${tag}
docker pull registry.access.redhat.com/openshift3/ose-pod:${tag}
docker pull registry.access.redhat.com/openshift3/ose-sti-builder:${tag}
docker pull registry.access.redhat.com/openshift3/ose:${tag}
docker pull registry.access.redhat.com/openshift3/container-engine:${tag}
#404 not found
#docker pull registry.access.redhat.com/openshift3/efs-provisioner:${tag}
docker pull registry.access.redhat.com/openshift3/node:${tag}
docker pull registry.access.redhat.com/openshift3/openvswitch:${tag}

#Pull all of the required OpenShift Container Platform containerized components for the additional centralized log aggregation and metrics aggregation components. Replace <tag> with v3.6 for the latest version.
tag1="v3.6"
docker pull registry.access.redhat.com/openshift3/logging-auth-proxy:${tag1}
docker pull registry.access.redhat.com/openshift3/logging-curator:${tag1}
docker pull registry.access.redhat.com/openshift3/logging-deployer:${tag1}
docker pull registry.access.redhat.com/openshift3/logging-elasticsearch:${tag1}
docker pull registry.access.redhat.com/openshift3/logging-fluentd:${tag1}
docker pull registry.access.redhat.com/openshift3/logging-kibana:${tag1}
docker pull registry.access.redhat.com/openshift3/metrics-cassandra:${tag1}
docker pull registry.access.redhat.com/openshift3/metrics-deployer:${tag1}
docker pull registry.access.redhat.com/openshift3/metrics-hawkular-metrics:${tag1}
docker pull registry.access.redhat.com/openshift3/metrics-hawkular-openshift-agent:${tag1}
docker pull registry.access.redhat.com/openshift3/metrics-heapster:${tag1}

#If you intend to enable the service catalog, Ansible service broker, and template service broker Technology Preview features (as described in Advanced Installation), pull the following images. Replace <tag> with v3.6.173.0.49 for the latest version.
docker pull registry.access.redhat.com/openshift3/ose-service-catalog:${tag}
docker pull registry.access.redhat.com/openshift3/ose-ansible-service-broker:${tag}
docker pull registry.access.redhat.com/openshift3/mediawiki-apb:${tag}
docker pull registry.access.redhat.com/openshift3/postgresql-apb:${tag}

#Pull the Red Hat-certified Source-to-Image (S2I) builder images that you intend to use in your OpenShift environment. You can pull the following images:
docker pull registry.access.redhat.com/jboss-amq-6/amq63-openshift
docker pull registry.access.redhat.com/jboss-datagrid-7/datagrid71-openshift
docker pull registry.access.redhat.com/jboss-datagrid-7/datagrid71-client-openshift
docker pull registry.access.redhat.com/jboss-datavirt-6/datavirt63-openshift
docker pull registry.access.redhat.com/jboss-datavirt-6/datavirt63-driver-openshift
docker pull registry.access.redhat.com/jboss-decisionserver-6/decisionserver64-openshift
docker pull registry.access.redhat.com/jboss-processserver-6/processserver64-openshift
docker pull registry.access.redhat.com/jboss-eap-6/eap64-openshift
docker pull registry.access.redhat.com/jboss-eap-7/eap70-openshift
docker pull registry.access.redhat.com/jboss-webserver-3/webserver31-tomcat7-openshift
docker pull registry.access.redhat.com/jboss-webserver-3/webserver31-tomcat8-openshift
docker pull registry.access.redhat.com/openshift3/jenkins-1-rhel7
docker pull registry.access.redhat.com/openshift3/jenkins-2-rhel7
docker pull registry.access.redhat.com/openshift3/jenkins-slave-base-rhel7
docker pull registry.access.redhat.com/openshift3/jenkins-slave-maven-rhel7
docker pull registry.access.redhat.com/openshift3/jenkins-slave-nodejs-rhel7
docker pull registry.access.redhat.com/rhscl/mongodb-32-rhel7
docker pull registry.access.redhat.com/rhscl/mysql-57-rhel7
docker pull registry.access.redhat.com/rhscl/perl-524-rhel7
docker pull registry.access.redhat.com/rhscl/php-56-rhel7
docker pull registry.access.redhat.com/rhscl/postgresql-95-rhel7
docker pull registry.access.redhat.com/rhscl/python-35-rhel7
docker pull registry.access.redhat.com/redhat-sso-7/sso70-openshift
docker pull registry.access.redhat.com/rhscl/ruby-24-rhel7
docker pull registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift
docker pull registry.access.redhat.com/redhat-sso-7/sso71-openshift
docker pull registry.access.redhat.com/rhscl/nodejs-6-rhel7
docker pull registry.access.redhat.com/rhscl/mariadb-101-rhel7

#Make sure to indicate the correct tag specifying the desired version number. For example, to pull both the previous and latest version of the Tomcat image:
docker pull \
registry.access.redhat.com/jboss-webserver-3/webserver30-tomcat7-openshift:latest

#If you are using a stand-alone registry or plan to enable the registry console with the integrated registry, you must pull the registry-console image.
#Replace <tag> with v3.6 for the latest version.

docker pull registry.access.redhat.com/openshift3/registry-console:${tag1}

#Export the OpenShift Container Platform containerized components:
mkdir -p /var/www/html/images && cd /var/www/html/images
cd /var/www/html/images && docker save -o ose3-images.tar \
    registry.access.redhat.com/openshift3/ose-ansible \
    registry.access.redhat.com/openshift3/ose-cluster-capacity \
    registry.access.redhat.com/openshift3/ose-deployer \
    registry.access.redhat.com/openshift3/ose-docker-builder \
    registry.access.redhat.com/openshift3/ose-docker-registry \
    registry.access.redhat.com/openshift3/ose-egress-http-proxy \
    registry.access.redhat.com/openshift3/ose-egress-router \
    registry.access.redhat.com/openshift3/ose-f5-router \
    registry.access.redhat.com/openshift3/ose-federation \
    registry.access.redhat.com/openshift3/ose-haproxy-router \
    registry.access.redhat.com/openshift3/ose-keepalived-ipfailover \
    registry.access.redhat.com/openshift3/ose-pod \
    registry.access.redhat.com/openshift3/ose-sti-builder \
    registry.access.redhat.com/openshift3/ose \
    registry.access.redhat.com/openshift3/container-engine \
    registry.access.redhat.com/openshift3/node \
    registry.access.redhat.com/openshift3/openvswitch
    #registry.access.redhat.com/openshift3/efs-provisioner \
#If you synchronized the metrics and log aggregation images, export:
cd /var/www/html/images && docker save -o ose3-logging-metrics-images.tar \
    registry.access.redhat.com/openshift3/logging-auth-proxy \
    registry.access.redhat.com/openshift3/logging-curator \
    registry.access.redhat.com/openshift3/logging-deployer \
    registry.access.redhat.com/openshift3/logging-elasticsearch \
    registry.access.redhat.com/openshift3/logging-fluentd \
    registry.access.redhat.com/openshift3/logging-kibana \
    registry.access.redhat.com/openshift3/metrics-cassandra \
    registry.access.redhat.com/openshift3/metrics-deployer \
    registry.access.redhat.com/openshift3/metrics-hawkular-metrics \
    registry.access.redhat.com/openshift3/metrics-hawkular-openshift-agent \
    registry.access.redhat.com/openshift3/metrics-heapster
#Export the S2I builder images that you synced in the previous section. For example, if you synced only the Jenkins and Tomcat images:
cd /var/www/html/images && docker save -o ose3-builder-images.tar \
    registry.access.redhat.com/jboss-webserver-3/webserver30-tomcat7-openshift:latest \
    registry.access.redhat.com/openshift3/jenkins-1-rhel7 \
    registry.access.redhat.com/openshift3/jenkins-2-rhel7 \
    registry.access.redhat.com/openshift3/jenkins-slave-base-rhel7 \
    registry.access.redhat.com/openshift3/jenkins-slave-maven-rhel7 \
    registry.access.redhat.com/openshift3/jenkins-slave-nodejs-rhel7
    #registry.access.redhat.com/jboss-webserver-3/webserver30-tomcat7-openshift:1.1 \
#During the installation (and for later updates, should you so choose), you will need a webserver to host the repositories. RHEL 7 can provide the Apache webserver.

scp /var/www/html/repos/images/ose3-images.tar root@atomic01:
ssh root@atomic01 "docker load -i ose3-images.tar"

scp /var/www/html/images/ose3-builder-images.tar
ssh root@atomic01 "docker load -i ose3-builder-images.tar"

sshpass -p'password' ssh-copy-id -o StrictHostKeyChecking=no atomic01.prayther.org

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
