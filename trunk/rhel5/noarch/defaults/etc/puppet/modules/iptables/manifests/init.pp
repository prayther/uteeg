#
# Module: iptables
#
# Class: iptables
#
# Description:
#       This class configures the iptables firewall. Additional rules for other
#	services are defined in their appropriate manifest.
#
# Defines:
#       None
#
# LinuxGuide:
#       2.5.5.1
#	2.5.5.3.1
#
# CCERef#:
#       CCE-4189-7
#
class iptables {
	# GuideSection 2.5.5
	# Enable the iptables services
	service {
		"iptables":
			ensure    => running,
			hasstatus => true,
			enable    => true;
	}

	# Configure iptables added rules to /etc/sysconfig/iptables

	# Note: iptables puts these rules in alphabetical order by name, 
	# so prefix with numbers if order is important

	# ICMP Rules

	iptables {
		"000 allow icmp echo reply":
			proto => "icmp",
#			icmp => "echo-reply",
			icmp => 0,
			jump => "ACCEPT",
	}

	iptables {
		"000 allow icmp destination unreachable":
			proto => "icmp",
			icmp => 3,
			jump => "ACCEPT",
	}

	iptables {
		"000 allow icmp time exceeded":
			proto => "icmp",
			icmp  => 11,
			jump  => "ACCEPT",
	}



	# Explicitly allow/drop certain incoming connections
	iptables {
		"0 allow loopback":
			iniface => "lo",
			jump => "ACCEPT",
	}

#	iptables {
#		"000 drop avahi (mDNS)":
#			proto => "udp",
#			dport => "5353",
#			destination => "224.0.0.251",
#			jump => "DROP",
#	}

	iptables {
		"000 allow established states":
			state => "ESTABLISHED",
			jump => "ACCEPT",
	}

	iptables {
		"000 allow related states":
			state => "RELATED",
			jump => "ACCEPT",
	}
	
	# Logging
	iptables {
		"800 log class A spoofing attempt":
			iniface => "eth0",
			source => "10.0.0.0/8",
			jump => "LOG",
			log_prefix => "IP DROP SPOOF A: ",
	}	

	iptables {
		"800 log class B spoofing attempt":
			iniface => "eth0",
			source => "172.16.0.0/12",
			jump => "LOG",
			log_prefix => "IP DROP SPOOF B: ",
	}

	iptables {
		"800 log class C spoofing attempt":
			iniface => "eth0",
			source => "192.168.0.0/16",
			jump => "LOG",
			log_prefix => "IP DROP SPOOF C: ",
	}

	iptables {
		"800 log multicast spoofing attempt":
			iniface => "eth0",
			source => "224.0.0.0/4",
			jump => "LOG",
			log_prefix => "IP DROP MULTICAST D: ",
	}

	iptables {
		"800 log spoofing E attempt":
			iniface => "eth0",
			source => "240.0.0.0/5",
			jump => "LOG",
			log_prefix => "IP DROP SPOOF E: ",
	}

	iptables {
		"800 log loopback spoofing attempt":
			iniface => "eth0",
			destination => "127.0.0.0/8",
			jump => "LOG",
			log_prefix => "IP DROP LOOPBACK: ",
	}

	iptables {
		"801 log all other incoming packets before they get dropped":
			jump => "LOG",
			log_prefix => "IP INPUT DROP: ",
	}


	# Explicitly DROP anything that is not matched
	#iptables {
#		"zzz drop everything from input chain":
#			jump => "DROP",
#	}
#	iptables {
#		"zzz drop everything from forward chain":
#			chain => "FORWARD",
#			jump => "DROP",
#	}


	# pre.iptables and post.iptable files
	# This overcomes the sorting problem for the final drop rule
	file { 
		"/etc/puppet/post.iptables":
			content => "-A INPUT -j DROP\n-A FORWARD -j DROP",
			mode => 0600,
	}

	
}

