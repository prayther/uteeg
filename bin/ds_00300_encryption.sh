#!/bin/bash -x


if [ -z "${1}" ];then
  echo ""
  #echo " ./virt-install.sh <vmname> <disc in GB> <vcpus> <ram>"
  echo " ./ds-install.sh shortname ds (short for ds.example.org)
  echo ""
  echo "Ex: ./virt-install.sh testvm
  #echo "Ex: ./virt-install.sh testvm 10 2 2048"
  echo ""
  echo "Make sure you have an entry in uteeg/etc/hosts for your vmname"
  echo "Only run one of these at a time. Building multiple"
  echo "VM's gets all wacky with the libvirtd restart and "
  echo "starting and stopping the network"
  echo ""
  echo "All the starting and stopping is to get dhcp leases straight"
  echo ""
  echo ""
  exit 1
fi


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
if [[ $(hostname -s | awk -F"-" '{print $1}') -ne "gfs" ]];then
 echo ""
 echo "Need to run this on the 'gfs' node"
 echo ""
 exit 1
fi

if [[ $(hostname -s | awk -F"-" '{print $2}') -ne "admin" ]];then
 echo ""
 echo "Need to run this on the 'admin' node"
 echo ""
 exit 1
fi

if [[ $(id -u) != "0" ]];then
        echo "Must run as root"
        echo
        exit 1
fi

<<COMMENT
#setup TLS
echo password >/root/password.txt
#9.3.1.1. Creating the NSS Database Using the Command Line
/usr/bin/certutil -d /etc/dirsrv/slapd-example/ -N -f /root/password.txt
cp /etc/pki/nssdb/pkcs11.txt /etc/dirsrv/slapd-example/
chown dirsrv:dirsrv /etc/dirsrv/slapd-example/*.db
chown dirsrv:dirsrv /etc/dirsrv/slapd-example/pkcs11.txt
chmod 600 /etc/dirsrv/slapd-example/*.db
chmod 600 /etc/dirsrv/slapd-example/pkcs11.txt
#9.3.2. Creating a Certificate Signing Request
mkdir /root/pki
/usr/bin/certutil -d /etc/dirsrv/slapd-example -R -g 2048 -a -o /root/pki/ds-stig.example.org.csr -8 ds-stig.example.org -s "CN=ds-stig.example.org,O=Example,L=Default,ST=North Carolina,C=US" -f /root/password.txt
#verify
openssl req -in ds-stig.example.org.csr -noout -text
#openssl req -new -sha256 -key mydomain.com.key -subj "/C=US/ST=CA/O=MyOrg, Inc./CN=mydomain.com" -out mydomain.com.csr

#make private key
openssl genpkey -algorithm RSA -out /root/pki/privkey.pem

#4.7.2.2. Creating a Self-signed Certificate
openssl req -new -x509 -key /root/pki/privkey.pem -out /root/pki/selfcert.pem -days 366

#4.7.3. Verifying Certificates
openssl verify /root/pki/selfcert.pem
#selfcert.pem: C = US, ST = North Carolina, L = Default City, O = Default Company Ltd, CN = ds-stig.example.org
#error 18 at 0 depth lookup:self signed certificate
#OK

#9.3.3.1. Installing a CA Certificate Using the Command Line
certutil -d /etc/dirsrv/slapd-example/ -A -n "tst" -t "C,," -i /root/pki/selfcert.pem

#9.3.4. Installing a Certificate
certutil -d /etc/dirsrv/slapd-example/ -A -n "tst" -t ",," -a -i /root/pki/selfcert.pem

#9.3.4.1. Installing a Server Certificate Using the Command Line
certutil -d /etc/dirsrv/slapd-example/ -A -n "tst" -t ",," -a -i /root/pki/selfcert.pem
#verify the certificate:
certutil -d /etc/dirsrv/slapd-example/ -V -n "tst" -u V

#Verify if the Network Security Services (NSS) database is already initialized:
certutil -d /etc/dirsrv/slapd-example -L

#make noise
openssl rand -out /tmp/noise.bin 4096
#Create the self-signed certificate and add it to the NSS database:
certutil -S -x -d /etc/dirsrv/slapd-example/ -z /tmp/noise.bin -n "server cert" -s "CN=ds-stig.example.org" -t "CT,C,C" -m $RANDOM --keyUsage digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment -f /root/password
#verify that the generated certificate is self-signed:
certutil -L -d /etc/dirsrv/slapd-example/ -n "tst" | egrep "Issuer|Subject"

#9.4.1.1. Enabling TLS in Directory Server Using the Command Line
ls -1 /etc/dirsrv/slapd-example/*.db
#run this first line on it's own, ldapmodify... -x and hit enter, put in password
ldapmodify -D "cn=Directory Manager" -W -p 389 -h ds-stig.example.org -x
# cut and paste these next lines, hit enter and then ctrl D to exit interactive mode. need to put this in an input ldif file and get rid of the interactive stuff.
dn: cn=config
changetype: modify
replace: nsslapd-securePort
nsslapd-securePort: 636
-
replace: nsslapd-security
nsslapd-security: on

#Display the nickname of the server certificate in the NSS database:
certutil -L -d /etc/dirsrv/slapd-example/
#Certificate Nickname                                         Trust Attributes
#                                                             SSL,S/MIME,JAR/XPI
#
#tst                                                          ,,   
#tst1                                                         CTu,Cu,Cu


#To enable the RSA cipher family, setting the NSS database security device, and the server certificate nickname, add the following entry to the directory:
ldapadd -D "cn=Directory Manager" -W -p 389 -h ds-stig.example.org -x
dn: cn=RSA,cn=encryption,cn=config
cn: RSA
objectClass: top
objectClass: nsEncryptionModule
nsSSLToken: internal (software)
nsSSLPersonalitySSL: tst1
nsSSLActivation: on

#adding new entry "cn=RSA,cn=encryption,cn=config"

systemctl restart dirsrv@example

#9.4.1.3.1. Displaying and Setting the Ciphers Used by Directory Server Using the Command Line
#Displaying all Available Ciphers
ldapsearch -xLLL -H ldap://ds-stig.example.org:389 -D "cn=Directory Manager" - W -b 'cn=encryption,cn=config' -s base nsSSLSupportedCiphers -o ldif-wrap=no -w password
#Displaying the Ciphers Directory Server Uses
ldapsearch -xLLL -H ldap://ds-stig.example.org:389 -D "cn=Directory Manager" - W -b 'cn=encryption,cn=config' -s base nsSSLEnabledCiphers -o ldif-wrap=no -w password
#display the ciphers which are configured to be enabled and disabled:
ldapsearch -xLLL -H ldap://ds-stig.example.org:389 -D "cn=Directory Manager" - W -b 'cn=encryption,cn=config' -s base nsSSL3Ciphers -o ldif-wrap=no -w password

#o enable only specific ciphers, update the nsSSL3Ciphers attribute. For example, to enable only the TLS_RSA_WITH_AES_128_GCM_SHA256 cipher:
ldapmodify -D "cn=Directory Manager" -W -p 389 -h ds-stig.example.org -x
dn: cn=encryption,cn=config
changetype: modify
add: nsSSL3Ciphers
nsSSL3Ciphers: -all,+TLS_RSA_WITH_AES_128_GCM_SHA256
#restart
systemctl restart dirsrv@example
COMMENT

echo "###INFO: Finished $0"
echo "###INFO: $(date)"