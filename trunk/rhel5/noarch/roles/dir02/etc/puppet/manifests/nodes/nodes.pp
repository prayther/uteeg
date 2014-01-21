# $Id: nodes.pp 763 2012-08-15 13:52:46Z sysutil $
node default {
	import "common"
	import "spawar"
	import "spawar1"	
}
node workstation inherits default {
#Please keep in alphabetical order to improve maintainability
	include "aide"
	include "auditd"
	include "automnt"
	include "avahi"
	include "badperms"
	include "banner"
	include "bootup"
#	include "consoleperms"
	include "coredmp"
	include "cronat"
#	include "directory::dir_iptables"
	include "execshield"
#	include "fstab"
	include "homeperms"
#	include "iptables"
	include "ipv6"
	include "kernel"
	include "logrotate"
	include "logwatch"
	include "modprobe"
	include "nfs"
	include "ntp"
#	include "ldap"
	include "pam"
	include "password"
	include "path"
	include "postfix"
	include "puppet"
	include "rpmverify"
	include "samba"
	include "screenlock"
#	include "selinux"
	include "sendmail"
	include "services"
	include "spawar_exec"
	include "spawar_files"
#	include "spawar_iptables"
	include "spawar_lnx00140"
	include "spawar_services"
	include "spawar_sw"
	include "spawar_sw1"
	include "spawar_users"
	include "ssh"
	include "sudo"
	include "rsyslog"
	include "umask"
	include "wireless"
	include "yum"
}

node /.*puppet.*/ inherits workstation {
}

#node 'best.chs.spawar.navy.mil' inherits workstation {}
node 'best.chs.spawar.navy.mil' inherits workstation {
   class {"directory-slave":
          master_fqdn_in => "bees.chs.spawar.navy.mil",
   }
}
