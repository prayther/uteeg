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

#restart to confirm things work now.
systemctl restart dirsrv@ds-repl
systemctl status dirsrv@ds-repl
systemctl restart dirsrv-admin
systemctl status dirsrv-admin

#9.3.1.1. Creating the NSS Database Using the Command Line
/usr/bin/certutil -d /etc/dirsrv/slapd-ds-repl/ -N -f /root/password.txt

#Chapter 11. Managing FIPS Mode Support
#https://access.redhat.com/documentation/en-us/red_hat_directory_server/10/html-single/administration_guide/#Managing_FIPS_mode_support
modutil -dbdir /etc/dirsrv/slapd-ds-repl/ -fips true

#test
sysctl crypto.fips_enabled
modutil -dbdir /etc/dirsrv/slapd-ds-repl/ -fips true

#turn off
#modutil -dbdir /etc/dirsrv/slapd-ds-repl/ -fips false

#make private key
echo 'P@\$\$w0rd' > /root/openssl_password.txt
chown root.root /root/openssl_password.txt
chmod 400 /root/openssl_password.txt
openssl genpkey -algorithm RSA -out /etc/pki/CA/privkey.pem -pkeyopt rsa_keygen_bits:2048 -pass file:/root/openssl_password.txt

#4.7.2.2. Creating a Self-signed Certificate

cat << "EOF" > /etc/pki/CA/privkey.pem
-----BEGIN PRIVATE KEY-----
MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCvks8U5m78cpzZ
16SaHgxuZyhBVfi1ycbrYhffs8h81CphOVFf0SIWDkVDshetY9bUAXJigua1O460
GdxUxk+qH7LnEW7AlD6+u1vfxRMKoiNInezBXQ3yBZo37G5s6qP0yELNIIoVOR/z
r5E7TgorsgMLo/OExrIcXu4sy0l27C656fcWVtH+ZpfJ3eH30mITVEt9vlxmjSho
pZiiV2xzp+ycZnBR51X8+inD/ASljwx6VWwhL7tQQ8dA+Bfsk30AcUry93z04BOu
vOpOGdEFQft9g1ElG1IN6YsyOgES22EBwGDC6majV+lKoFc+rzwtRVcglBfARrU4
1g8570tbAgMBAAECggEAD4PyP98TPMTmHowjdCkmoRUFpixyQ6JWrVNoV7D8DSf0
rM3TZpvFHtzY+yAAXqa9g9Oy54i42ZgvRrQoV+eEf7y4YxoTxvnyx4koF9DDG4Pz
iUXHd9kA0/vxwnJm2cIshgOyf40aFsELFU5VD8AYPv9GrJ8q9HdYoxAyjQvT7KnS
CLkO0CPm5TL6m6u7fkyDmUNcf+ZTF01+S+41FCzLfdbADNEGesiJViWWo+OXtSd+
xngYv398vN3xH/OEUK4ocxY8CTMVTMYWu4DGZJz1Lbu1HuDs5gY+3FWmCTna2XHC
8irgwh93Y63F1MX3dlzxoJAIYKer8vw+phweoOXlWQKBgQDU2EGF5Y3LVTDXkx2J
unMF51Cb6cx+TGxM50jMF5FoC21xXLXX/Xml/ZDHCsub3tDAfZzchC1FWaMEhWvp
uCUuQ/Ok2wQLgTw0xcRC1RxKl512VuVHyKZiVs++MNlDdQ0A//PlJQoT5N0xi05X
S4p6QiywGieoxwSP1gqhJUATKQKBgQDTK/sT2QiLMsY8ZQ+Mdr9OepvMQQGVAdt6
Ff5yqTwY7vKXNDzs8Tb7OP0v0zEttepNwcKbhZJf2Kw1pGxdZ5MZv57+i80Nmqdo
HHeWPQ7cnXmbElOFSSJCos+zX5QlJebB9p+N2awvghG2uoiDcDJ7nRfypctVBQ1L
t1IJ8FOe4wKBgFm76rP2ubcV7YeVYIimcMP2Z8ez5CEDO02Y3NoevZDt8HAwtAGh
vd27b4RbCshmQgBFdRKLL0LjrZTEY2Cf4B0HTPsd0zC+hZGCJ2I90rWoAhzYOcXv
1CX1j5QRqCeGe7sGLd9XpE4K2S6AGsE2+eTdbVW5USsY7NVvWf/iYocxAoGAdrBa
j15F2g7wspNOuPEpN0/cb2H+JKUFmcnw2Ltb5tuuh+O5dqdg8rSmQZIfKwT7KzcD
TWw2yB49NG005w7G9Arqr0EeQE4zV2XgpRWuW7s61TjorppbYj6mJLhMyNBTsaMP
LKgyigU+NYkEH3QZO7cg9aXP8fpD7dGcj69/IGcCgYBTk0FC7dWIVUjpvDl1ZNF+
u6rGLN6T9pBAx51AyAcC/vSZyzIEpa8y67+NpgClcl1Pik4i6/iCdSvjxD1E/3bl
43MeNIqMOPNnsLgGq0aHSKqOXEwA78UgG5jubaNYe8p1fmOmEIp+tssA+FtFBEbf
dzfS2GQLsQy0dMndz3aigw==
-----END PRIVATE KEY-----
EOF

cat << "EOF" > /etc/pki/CA/selfcert.pem
-----BEGIN CERTIFICATE-----
MIID1TCCAr2gAwIBAgIJAP1PmeMpnRbcMA0GCSqGSIb3DQEBCwUAMIGAMQswCQYD
VQQGEwJVUzEXMBUGA1UECAwOTm9ydGggQ2Fyb2xpbmExEDAOBgNVBAcMB0RlZmF1
bHQxGDAWBgNVBAoMD0dsb2JhbCBTZWN1cml0eTEWMBQGA1UECwwNSVQgRGVwYXJ0
bWVudDEUMBIGA1UEAwwLZXhhbXBsZS5vcmcwHhcNMTgwOTEzMTM0MzIyWhcNMTkw
OTE0MTM0MzIyWjCBgDELMAkGA1UEBhMCVVMxFzAVBgNVBAgMDk5vcnRoIENhcm9s
aW5hMRAwDgYDVQQHDAdEZWZhdWx0MRgwFgYDVQQKDA9HbG9iYWwgU2VjdXJpdHkx
FjAUBgNVBAsMDUlUIERlcGFydG1lbnQxFDASBgNVBAMMC2V4YW1wbGUub3JnMIIB
IjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAr5LPFOZu/HKc2dekmh4Mbmco
QVX4tcnG62IX37PIfNQqYTlRX9EiFg5FQ7IXrWPW1AFyYoLmtTuOtBncVMZPqh+y
5xFuwJQ+vrtb38UTCqIjSJ3swV0N8gWaN+xubOqj9MhCzSCKFTkf86+RO04KK7ID
C6PzhMayHF7uLMtJduwuuen3FlbR/maXyd3h99JiE1RLfb5cZo0oaKWYoldsc6fs
nGZwUedV/Popw/wEpY8MelVsIS+7UEPHQPgX7JN9AHFK8vd89OATrrzqThnRBUH7
fYNRJRtSDemLMjoBEtthAcBgwupmo1fpSqBXPq88LUVXIJQXwEa1ONYPOe9LWwID
AQABo1AwTjAdBgNVHQ4EFgQUs95nraeWVSkXIbXk03fufPcyMRAwHwYDVR0jBBgw
FoAUs95nraeWVSkXIbXk03fufPcyMRAwDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0B
AQsFAAOCAQEAmKnwloCsiQIoC6qWjBCErgQHDHKREtBTI4EGiDs+pG1Ef0rlkeJx
cQVRs7kLZwKQ3HudekNNrh+/fB232whSd99ecExKu+woFbn/ryPMifk83MFvxGwP
DXVK2Enjb/NPenog1HBNLXh9k++vUEmM5Wr5thHx8INN01/hVGv/SjB3LepKITSX
1k8Il4TZBKN1GX/Xnjsj/xRQBTYyS66dlNj38S6qVrM8EvwPaRsAr7gG3sdX5Ehu
t8A2+t9akx8S3PX62ojqg4Bh81rHTth7U82yfwLKCjnbh58VIDIxG2vX1UwUoYIO
njvDxmU4LOR7iPLT/Ip15NW7NaTBmS3IXg==
-----END CERTIFICATE-----
EOF

#To verify a certificate chain the leaf certificate must be in cert.pem and the intermediate certificates which you do not trust must be directly concatenated in untrusted.pem. The trusted root CA certificate must be either among the default CA listed in /etc/pki/tls/certs/ca-bundle.crt or in a cacert.pem file. Then, to verify the chain,
cat /etc/pki/CA/selfcert.pem >> /etc/pki/tls/certs/ca-bundle.crt

#4.7.3. Verifying Certificates
openssl verify /etc/pki/CA/selfcert.pem

#9.3.3.1. Installing a CA Certificate Using the Command Line
certutil -d /etc/dirsrv/slapd-ds-repl/ -A -n "ca-cert" -t "C,," -i /etc/pki/CA/selfcert.pem -f /root/password.txt

#verify the certificate:
certutil -d /etc/dirsrv/slapd-ds-repl/ -V -n "ca-cert" -u V

#Verify if the Network Security Services (NSS) database is already initialized:
certutil -d /etc/dirsrv/slapd-ds-repl -L

#make noise
openssl rand -out /tmp/noise.bin 4096

#Create the self-signed certificate and add it to the NSS database:
#https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html-single/security_guide/#sec-Generating_Certificates. -8 adds subject alternative name
certutil -S -x -d /etc/dirsrv/slapd-ds-repl/ -z /tmp/noise.bin -n server-cert -s "CN=$HOSTNAME" -8 ds-stig.example.org,ds-repl.example.org -t "CT,C,C" -m $RANDOM --keyUsage digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment -f /root/password.txt

#verify that the generated certificate is self-signed:
certutil -L -d /etc/dirsrv/slapd-ds-repl/ -n server-cert | egrep "Issuer|Subject"

#9.4.1.5. Creating a Password File for Directory_Server
echo "Internal (Software) Token:P@\$\$w0rd" >> /etc/dirsrv/slapd-ds-repl/pin.txt
chown dirsrv:dirsrv /etc/dirsrv/slapd-ds-repl/pin.txt
chmod 400 /etc/dirsrv/slapd-ds-repl/pin.txt

#9.4.1.1. Enabling TLS in Directory_Server Using the Command Line
#run this first line on it's own, ldapmodify... -x and hit enter, put in P@$$w0rd
ldapmodify -D "cn=Directory Manager" -W -p 389 -h ds-repl.example.org -x

# cut and paste these next lines, hit enter and then ctrl D to exit interactive mode. need to put this in an input ldif file and get rid of the interactive stuff.
dn: cn=config
changetype: modify
replace: nsslapd-securePort
nsslapd-securePort: 636
-
replace: nsslapd-security
nsslapd-security: on

#Display the nickname of the server certificate in the NSS database:
certutil -L -d /etc/dirsrv/slapd-ds-repl/

#To enable the RSA cipher family, setting the NSS database security device, and the server certificate nickname, add the following entry to the directory:
ldapadd -D "cn=Directory Manager" -W -p 389 -h ds-repl.example.org -x
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
ldapmodify -D "cn=Directory Manager" -W -p 389 -h ds-repl.example.org -x
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
ldapmodify -D "cn=Directory Manager" -W -p 389 -h ds-repl.example.org -x
dn: cn=encryption,cn=config
changetype: modify
add: nsSSL3Ciphers
nsSSL3Ciphers: +all

#restart
systemctl restart dirsrv@ds-repl
systemctl status dirsrv@ds-repl
systemctl restart dirsrv-admin
systemctl status dirsrv-admin


#display encryption cert info
certutil -K -d /etc/dirsrv/slapd-ds-repl
certutil -L -d /etc/dirsrv/slapd-ds-repl/ -n server-cert

#9.4.1.3.1. Displaying and Setting the Ciphers Used by Directory_Server Using the Command Line
#Displaying all Available Ciphers
ldapsearch -xLLL -H ldap://ds-repl.example.org:389 -D "cn=Directory Manager" - W -b 'cn=encryption,cn=config' -s base nsSSLSupportedCiphers -o ldif-wrap=no -W

#Displaying the Ciphers Directory_Server Uses
ldapsearch -xLLL -H ldap://ds-repl.example.org:389 -D "cn=Directory Manager" - W -b 'cn=encryption,cn=config' -s base nsSSLEnabledCiphers -o ldif-wrap=no -W

#display the ciphers which are configured to be enabled and disabled:
ldapsearch -xLLL -H ldap://ds-repl.example.org:389 -D "cn=Directory Manager" - W -b 'cn=encryption,cn=config' -s base nsSSL3Ciphers -o ldif-wrap=no -W

#9.5. Displaying the Encryption Protocols Enabled in Directory Server
ldapsearch -D "cn=Directory Manager" -W -p 389 -h ds-repl.example.org -x -s base -b 'cn=encryption,cn=config' sslVersionMin sslVersionMax


COMMENT

echo "###INFO: Finished $0"
echo "###INFO: $(date)"
