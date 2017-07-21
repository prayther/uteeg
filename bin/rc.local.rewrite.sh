#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root

cd "${BASH_SOURCE%/*}"
source ../etc/install-configure-satellite.cfg
source ../etc/virt-inst.cfg
source ../etc/register_cdn.cfg

exec >> ../log/rc.local.rewrite.log 2>&1

cat << EOH > /etc/rc.d/rc.local
#!/bin/bash

# run commands together so they don't run at the same time.
/bin/bash /root/uteeg/1 && \
/bin/bash /root/uteeg/bin/2 && \
/bin/bash /root/uteeg/bin/3 && \
/bin/bash /root/uteeg/bin/4 && \
/bin/bash /root/uteeg/bin/5 && \
/bin/bash /root/uteeg/bin/6 && \
/bin/bash /root/uteeg/bin/7 && \
/bin/bash /root/uteeg/bin/8
# step 2 put the orig rc.local in place and reboot
cp /root/rc.local.orig /etc/rc.local
EOH

chmod 0755 /etc/rc.local
/usr/bin/systemctl enable rc.local
/sbin/reboot
