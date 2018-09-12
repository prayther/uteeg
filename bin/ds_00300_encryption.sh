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
echo 'P@$$w0rd' >/root/password.txt

#Chapter 11. Managing FIPS Mode Support
#https://access.redhat.com/documentation/en-us/red_hat_directory_server/10/html-single/administration_guide/#Managing_FIPS_mode_support
modutil -dbdir /etc/dirsrv/slapd-ds-stig/ -fips true

#test
sysctl crypto.fips_enabled
modutil -dbdir /etc/dirsrv/slapd-ds-stig/ -fips true

#turn off
#modutil -dbdir /etc/dirsrv/slapd-ds-stig/ -fips false

#restart to confirm things work now.
systemctl restart dirsrv@ds-stig
systemctl status dirsrv@ds-stig

#9.3.1.1. Creating the NSS Database Using the Command Line
/usr/bin/certutil -d /etc/dirsrv/slapd-ds-stig/ -N

#9.3.2. Creating a Certificate Signing Request
/usr/bin/certutil -d /etc/dirsrv/slapd-ds-stig -R -g 2048 -a -o /etc/pki/CA/ds-stig.example.org.csr -8 ds-stig.example.org,ds-repl.example.org -s "CN=ds-stig.example.org,O=Example,L=Default,ST=North Carolina,C=US"

#make private key
openssl genpkey -algorithm RSA -out /etc/pki/CA/privkey.pem

#4.7.2.2. Creating a Self-signed Certificate
openssl req -new -x509 -key /etc/pki/CA/privkey.pem -out /etc/pki/CA/selfcert.pem -days 366
#Table 12.2. certutil Examples
#Creates a self-signed CA certificate.
#https://access.redhat.com/documentation/en-US/Red_Hat_Directory_Server/8.1/html/Administration_Guide/Managing_SSL-Using_certutil.html
#certutil -S -n "CA certificate" -s "cn=My Org CA cert, dc=example,dc=org" -2 -x -t "CT,," -m 1000 -v 120 -d . -k rsa -f /root/password.txt

#To verify a certificate chain the leaf certificate must be in cert.pem and the intermediate certificates which you do not trust must be directly concatenated in untrusted.pem. The trusted root CA certificate must be either among the default CA listed in /etc/pki/tls/certs/ca-bundle.crt or in a cacert.pem file. Then, to verify the chain,
cat /etc/pki/CA/selfcert.pem >> /etc/pki/tls/certs/ca-bundle.crt

#4.7.3. Verifying Certificates
openssl verify /etc/pki/CA/selfcert.pem

#9.3.3.1. Installing a CA Certificate Using the Command Line
certutil -d /etc/dirsrv/slapd-ds-stig/ -A -n "ca-cert" -t "C,," -i /etc/pki/CA/selfcert.pem

#verify the certificate:
certutil -d /etc/dirsrv/slapd-ds-stig/ -V -n "ca-cert" -u V

#Verify if the Network Security Services (NSS) database is already initialized:
certutil -d /etc/dirsrv/slapd-ds-stig -L

#make noise
openssl rand -out /tmp/noise.bin 4096

#Create the self-signed certificate and add it to the NSS database:
#https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html-single/security_guide/#sec-Generating_Certificates. -8 adds subject alternative name
certutil -S -x -d /etc/dirsrv/slapd-ds-stig/ -z /tmp/noise.bin -n server-cert -s "CN=$HOSTNAME" -8 ds-stig.example.org,ds-repl.example.org -t "CT,C,C" -m $RANDOM --keyUsage digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment

#verify that the generated certificate is self-signed:
certutil -L -d /etc/dirsrv/slapd-ds-stig/ -n server-cert | egrep "Issuer|Subject"

#9.4.1.5. Creating a Password File for Directory_Server
echo "Internal (Software) Token:P@\$\$w0rd" >> /etc/dirsrv/slapd-ds-stig/pin.txt
chown dirsrv:dirsrv /etc/dirsrv/slapd-ds-stig/pin.txt
chmod 400 /etc/dirsrv/slapd-ds-stig/pin.txt

#9.4.1.1. Enabling TLS in Directory_Server Using the Command Line
#run this first line on it's own, ldapmodify... -x and hit enter, put in P@$$w0rd
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
certutil -L -d /etc/dirsrv/slapd-ds-stig/

#To enable the RSA cipher family, setting the NSS database security device, and the server certificate nickname, add the following entry to the directory:
ldapadd -D "cn=Directory Manager" -W -p 389 -h ds-stig.example.org -x
dn: cn=RSA,cn=encryption,cn=config
cn: RSA
objectClass: top
objectClass: nsEncryptionModule
nsSSLToken: internal (software)
nsSSLPersonalitySSL: server-cert
nsSSLActivation: on

#######################
# this is how to modify existing...
#######################
# don't run by default!!!
#######################
# this modifies the previous command!!!
#######################
#If the previous command fails, because the cn=RSA,cn=encryption,cn=config entry already exists, update the corresponding attributes:
ldapmodify -D "cn=Directory Manager" -W -p 389 -h ds-stig.example.org -x
dn: cn=RSA,cn=encryption,cn=config
changetype: modify
replace: nsSSLToken
nsSSLToken: internal (software)

#only modify one attribute at a time
dn: cn=RSA,cn=encryption,cn=config
changetype: modify
replace: nsSSLPersonalitySSL
nsSSLPersonalitySSL: server-cert
#######################
#######################

#http://directory.fedoraproject.org/docs/389ds/design/nss-cipher-design.html#available-by-setting-all-but-weak--nss-3162-1
#To configure the ciphers for the Directory Server, the config parameter nsSSL3Ciphers in cn=encryption,cn=config is used.
ldapmodify -D "cn=Directory Manager" -W -p 389 -h ds-stig.example.org -x
dn: cn=encryption,cn=config
changetype: modify
add: nsSSL3Ciphers
nsSSL3Ciphers: +all

#restart
systemctl restart dirsrv@ds-stig
systemctl status dirsrv@ds-stig

#display encryption cert info
ldapsearch -H ldap://localhost:389 -D 'cn=Directory Manager' -W -Z -b 'cn=encryption,cn=config' -x
certutil -K -d /etc/dirsrv/slapd-ds-stig
certutil -L -d /etc/dirsrv/slapd-ds-stig/ -n server-cert

#9.4.1.3.1. Displaying and Setting the Ciphers Used by Directory_Server Using the Command Line
#Displaying all Available Ciphers
ldapsearch -xLLL -H ldap://ds-stig.example.org:389 -D "cn=Directory Manager" - W -b 'cn=encryption,cn=config' -s base nsSSLSupportedCiphers -o ldif-wrap=no -W
#Displaying the Ciphers Directory_Server Uses
ldapsearch -xLLL -H ldap://ds-stig.example.org:389 -D "cn=Directory Manager" - W -b 'cn=encryption,cn=config' -s base nsSSLEnabledCiphers -o ldif-wrap=no -W
#display the ciphers which are configured to be enabled and disabled:
ldapsearch -xLLL -H ldap://ds-stig.example.org:389 -D "cn=Directory Manager" - W -b 'cn=encryption,cn=config' -s base nsSSL3Ciphers -o ldif-wrap=no -W

#9.5. Displaying the Encryption Protocols Enabled in Directory Server
ldapsearch -D "cn=Directory Manager" -W -p 389 -h ds-stig.example.org -x -s base -b 'cn=encryption,cn=config' sslVersionMin sslVersionMax

COMMENT

systemctl restart dirsrv@ds-stig
systemctl status dirsrv@ds-stig

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
