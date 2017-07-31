#!/bin/bash -x

#https://github.com/prayther/uteeg
#http://www.opensourcerers.org/installing-and-configuring-red-hat-satellite-6-via-shell-script/
# mschreie@redhat.com
# setting up  a satellite for demo purposes
# mainly following Adrian Bredshaws awsome book: http://gsw-hammer.documentation.rocks/

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
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

#hammer --cvs location list | awk -F"," '{print $2}'
doit hammer compute-resource create --description 'LibVirt Compute Resource' --locations ${LOC} --name Libvirt_CR --organizations "$ORG" --url "qemu+ssh://root@${GATEWAY}/system/" --provider libvirt --set-console-password 0

doit firewall-cmd --add-port=5910-5930/tcp
doit firewall-cmd --add-port=5910-5930/tcp --permanent

# setup for compute resource with libvirt
#su - foreman -s /bin/bash
#ssh-keygen
#ssh-copy-id root@${GATEWAY}

doit ls /usr/share/foreman/.ssh || doit mkdir /usr/share/foreman/.ssh
doit chmod 0700 /usr/share/foreman/.ssh

id_rsa () { cat << EOH > /usr/share/foreman/.ssh/id_rsa
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAuXluOWqlZrEaiYrFOPvwwc3Rz1u+JmFHoil1LQ1E9RmBr4/N
tKZJLxmEDzUrrDskPp8CjJm9t0CMQo5QaKNos1hlbhpcZ81ipZBvbkdi+ICANuYo
FRadTkA1lhSB2Icsr24dXQJXaCYonoVICeGjMfHZKBiblGaKprm/FphKfD9TK3Sa
m4ylWteb0iPaZBxtwHxJdNW+RgXbzJOcRiThSd7X2Ht1fkH1/jB6Nl032k/qCEhi
d+s2iccGcczfRLJmeEFDFq+ZouiW94+SCCFe/Aki7Y9RBlT2nycz84vcAnfz2ymf
1ktZpk7tXo5ouWkAPgDEJAPWKhOVwOXTp/xqswIDAQABAoIBAB1sm0T2m0jgXeJm
JoW0ymwkl916o375PeEHDLTZ/w+XPVC50puPKdsUBDRZbhVDyKs6lK/zj/prfhTs
+OqwyeJx6p1+Bxzco4K6mEL5hkUANdb/ymoWDVylqRqnJDZSs48dPAFOZsl6DEWh
xVzz8+zvflDzHnN7lRGANEWEYYS2TfWZgF3mjV4DGrqOa+j9jutqWdd8VYtp5h4L
oV0wzWep7y3jDDB3kN1ck3oWBh/n7gBEFdUU23u6cjw4vTBMohZ+3Kcx29UpQwGi
ugHv3VumW49QIJY98+uqqxiPbB3Gm8eJsBIREweCXgfP7NhnU0PMtWuOaSBcbF+w
mu/zMyECgYEA316Ez0ESckdxTPYt2fvZx0a/r/9qoTeWN+O8MQCmVlRydY9XgOuP
zzZqU7sTnRPd0qjoeALT9VcgWB8a6/PPuE//KJaeVGNJbtcP5o6nM07lGobhYovH
lYs35axVRe2G7MaBpAbLxpgp+NkD4R238FI0zsxdmWR/tIAntiKf6NECgYEA1JG7
nsCQbVGVnT2vE8y1ZK9VTUGPIq0w45v57f8kzcXLjb+xMCWTN6xVbrt3THo2jnEs
stsPaSucXXJDBBuIben9OxMNFYFJnTWbVGSgCGEv+DUljNEclGA5sjcY7JNif8B8
Kk3Ik+cVVMqI0IgpbNGTDOZKpkjmhP1Z9dDZvEMCgYAHtoTRf0a6yXrBFJMavtaT
Sf8efaxZ6sh2H5gE/SfBPWNCafO0kO3DUvay83fG6cO0HX8Bfd+BzkNgp5pPYXjf
vWtrJGBNO6xydlynMm/VlrjUhKnNtFPs9wS0GpJLOtt425Xoaw+oSOLSI/Q9VsBe
PQhzx5zHyi+atP4qDOIGsQKBgQCAfBn46hIiUabqZUd240xdMHGSAed/oUmkujnG
dmsLidvwsQZrwLqMczksdlm0u0ZQsO3AqhJVkouwHAmP6Qh8z2tGEszcy8nwIV/j
EfN9PSlekNlClX793G/jXdRN4wQtje4/L8bmR04oc0dhLHxFjyOgL269teDIT87Z
e0SwuwKBgA5ghNRg0zjjVUZKCmk4t5+2+7Asa8Bl3+pS7rXUmzvJcfGasZJ7Gujd
TCb7A74Fdrcmaua9l/tFE2ftFQMVHgJmkEjTnG9LEZPZUzMO1JD2tZIpJ79dT1WA
gtVv8TALfkcC6897a0HNXqb+7jdIzRYX6QPoshy80DdikxSfxikM
-----END RSA PRIVATE KEY-----
EOH
}
doit id_rsa

doit chmod 0600 /usr/share/foreman/.ssh/id_rsa

id_rsa_pub () { cat << EOF > /usr/share/foreman/.ssh/id_rsa.pub
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5eW45aqVmsRqJisU4+/DBzdHPW74mYUeiKXUtDUT1GYGvj820pkkvGYQPNSusOyQ+nwKMmb23QIxCjlBoo2izWGVuGlxnzWKlkG9uR2L4gIA25igVFp1OQDWWFIHYhyyvbh1dAldoJiiehUgJ4aMx8dkoGJuUZoqmub8WmEp8P1MrdJqbjKVa15vSI9pkHG3AfEl01b5GBdvMk5xGJOFJ3tfYe3V+QfX+MHo2XTfaT+oISGJ36zaJxwZxzN9EsmZ4QUMWr5mi6Jb3j5IIIV78CSLtj1EGVPafJzPzi9wCd/PbKZ/WS1mmTu1ejmi5aQA+AMQkA9YqE5XA5dOn/Gqz foreman@sat.laptop.prayther
EOF
}
doit id_rsa_pub

doit chmod 0644 /usr/share/foreman/.ssh
doit chown foreman.foreman -R /usr/share/foreman/.ssh
# copy ssh id
ssh_copy_id () { ssh-copy-id -i /usr/share/foreman/.ssh/id_rsa.pub root@${GATEWAY}
}
doit ssh_copy_id

# create known_hosts without ansering yes
doit /bin/su -s /bin/bash -c "ssh -o StrictHostKeyChecking=no root@${GATEWAY} exit" foreman

# import crt for libvirt vm console on your workstation/laptop browser
#http://10.0.0.8/pub/katello-server-ca.crt
