# Class: selinux
#
# File: /etc/puppet/modules/selinux/manifests/init.pp
#
# Description:
#	This class ensures that selinux is properly configured to be enforcing
#	by checking that it is set in /etc/sysconfig/selinux and /etc/grub.conf
#
# Guide Reference:
#	2.4.2
#	2.4.3.2
#	2.4.2.1
#
# CCE Reference:
#	CCE-3624-4, CCE-3668-1, CCE-3977-6
#
# TODO:
#	Determine if we need to uninstall/disable any setroubleshoot helper
#	services
#
class selinux {
	# GuideSection 2.4
	# Settings for SELinux	
	
	# GuideSection 2.4.2 and 2.4.2.1
	# Turn on selinux
	augeas::basic-change { "selinux-enforcing, 2.4.2.1" :
		file    => "/etc/sysconfig/selinux",
		lens    => "shellvars.lns",
		changes => [
				"set SELINUX enforcing",
				"set SELINUXTYPE targeted",
			],
		tags   =>  ["CCE3624-4", "TBD" ],
		}
	
	service {
		# GuideSection 2.4.3.1
		# Disable setroubleshoot
		"setroubleshoot": 
			ensure    => stopped,
			hasstatus => true,
			enable    => false;

		# GuideSection 2.4.3.2
		# Disable mcstrans
		"mcstrans": 
			ensure    => stopped,
			hasstatus => true,
			enable    => false,
			tag      => "CCE-3668-1";
	}

	package {
		"setroubleshoot": ensure => absent;
		#"setroubleshoot-server": ensure => absent;
		#"setroubleshoot-plugins": ensure => absent;
		#"selinux-policy-strict": ensure => present;
		#"selinux-policy-mls": ensure => present;
	}

	# GuideSection 2.4.2
	# Ensure selinux=0 or enforcing=0 are not in grub.conf
	augeas::basic-change { "no-selinux-off-grub.conf, 2.4.2":
			file    => "/etc/grub.conf",
			lens    => "grub.lns",
			changes =>  [
				"rm title[*]/kernel/selinux[.='0']",
				"rm title[*]/kernel/enforcing[.='0']"
			],
			tags    => [ "CCE-3977-6", "TBD" ],
	}

	# GuideSection 2.4.2.1
	# Ensure SELinux is Properly Enabled
	if $selinux != 'true' {
		crit("Selinux status=$selinux, which is not true")
	}

	if $selinux_enforced != 'true' {
		crit("Selinux mode = $selinux_enforced, which is not true")
	}
}
