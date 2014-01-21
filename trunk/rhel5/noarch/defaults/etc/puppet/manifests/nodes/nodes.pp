# $Id: nodes.pp 1044 2012-10-16 17:13:27Z sysutil $
node default {
#	what is "common"?
	import "common"
	import "spawar"
	import "spawar1"	
#	import "low"	
#	import "high"	
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
#	include "ipv6"
	include "kernel"
#	include "logrotate"
	include "logwatch"
	include "modprobe"
	include "nfs"
# not running this ntp because it uses a configuration file that makes it difficult to have roles
# so putting it in spawar1
#	include "ntp"
#	include "ldap"
	include "pam"
	include "password"
	include "path"
# adding this to roles to differentiate smtp servers
	include "postfix"
    include "project_nagios"
	include "puppet"
	include "rpmverify"
	include "samba"
	include "screenlock"
#	include "selinux"
	include "sendmail"
#	include "services"
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
