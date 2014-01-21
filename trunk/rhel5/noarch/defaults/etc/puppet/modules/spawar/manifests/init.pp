#include iptables

# the use of the prefix on the classes allows the use of the module autoloader
# to find classes that are included in modules
# So, in the following case iptables is a class found in the <module path>/iptables/manifests/init.pp
#class spawar::spawar_iptables inherits iptables::iptables{

#class spawar::spawar_services {
# service { "cma":
#           ensure => running;
#         }
#
# service { "nrpe":
#           ensure => running,
#           #subscribe => File["/etc/nagios/nrpe.cfg"],
#           require => Class["spawar::spawar_sw"],
#         }
#}


class spawar_sw {
# exec { " yum install -y audispd-plugins vmware-open-vm-tools nagios-plugins-nrpe nrpe uvscanspawar acl bacula-client yum-security ovaldi puppet setools sysstat audit screen vim-enhanced":
# onlyif => "test `ps aux | grep yum | grep -v grep | grep -v yum-updatesd | wc -l` -eq 0"
#      }

 exec { "/usr/bin/yum remove -y bacula-client tcpdump firstboot-tui system-config-securitylevel-tui":
 onlyif => "test `ps aux | grep yum | grep -v grep | grep -v yum-updatesd | wc -l` -eq 0"
      }
}

class spawar_lnx00140  {
 #LNX00140 - GRUB Boot Loader Encrypted Password, timeout=10, password --md5 <password>
 exec { "sed -i '/timeout/ c timeout=10' /boot/grub/grub.conf":
        onlyif => "test `grep -c ^timeout /boot/grub/grub.conf` -gt 0"
      }

 exec { "sed -i '/timeout/ a password --md5 \$1\$jUN9U0\$cvVJap90wlSxRZs4PlFNj.' /boot/grub/grub.conf":
        onlyif => "test `grep -c ^password /boot/grub/grub.conf` -eq 0"
      }
}
