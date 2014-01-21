node default {
}

node workstation inherits default {
#Please keep in alphabetical order to improve maintainability
#	include "aide"
	include "aliases"
	include "auditd"
	#include "automnt" Not required by USGCB, but a good idea for security
#	include "avahi"
	include "badperms"
	include "banner"
	include "bootup"
	include "consoleperms"
#	include "coredmp"
	include "cronat"
#	include "execshield"
	include "fstab"
	include "grub"
	include "homeperms"
	include "iptables"
	include "ipv6"
	include "kernel"
#	include "logrotate"
#	include "logwatch"
#	include "modprobe"
#	include "nfs"
#	include "ntp"
#	include "ldap"
	include "pam"
	include "password"
	include "path"
	include "postfix"
	include "puppet"      # Don't include this on your puppet server
#	include "rpmverify"
#	include "samba"
#	include "screenlock"
#	include "selinux"
	include "sendmail"
#	include "services"
	include "ssh"
	include "sudo"
	include "tcpdump"
	include "sysctl"
	include "traceroute"
#	include "rsyslog"
	include "umask"
	include "users"
#	include "wireless"
#	include "yum"
}

node /.*puppet.*/ inherits workstation {
}
node 'dogs.chs.spawar.navy.mil' inherits workstation {}
