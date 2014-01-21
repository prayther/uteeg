#
# Module: ipv6
#
# Class: ipv6
#
# Description:
#       This class disables the ipv6 networking and stops the ipv6 iptables.
#
# Defines:
#       None
#
# LinuxGuide:
#       2.5.3.1.2
#
# CCERef#:
#       None
#
class ipv6 {
	# GuideSection 2.5.3.1.2
	#augeas::basic-change { "ipv6if" :
	#	file    => "/etc/sysconfig/network",
	#	lens    => "shellvars.lns",
	#	changes => [
	#			"set NETWORKING_IPV6 no",
	#			"set IPV6INIT no",
	#	],
	#}
	
	service {
		"ip6tables":
			ensure    => running,
			hasstatus => true,
			enable    => true;
	}
}
