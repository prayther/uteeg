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
class iptables::iptables {
	# GuideSection 2.5.5
	# Enable the iptables services
	service {
		"iptables":
			ensure    => running, 
			hasstatus => true,
			enable    => true,
	}

	# Configure iptables added rules to /etc/sysconfig/iptables

	# Note: iptables puts these rules in alphabetical order by name, 
	# so prefix with numbers if order is important

	# ICMP Rules

	iptables {
		"000 allow icmp any":
	                chain  => "INPUT", proto => "icmp", icmp => "any", jump => "ACCEPT", }

        # this says to accept communcation on "localhost" since many apps communicate this way.
	iptables {
		"00 accept on interface lo":
			chain   => "INPUT", iniface => "lo", jump => "ACCEPT", }

        # These settings allow the IPSEC protocols. Note that "50" and "51" are the 
        # numbers assigned to the protocol in /etc/protocols 
        iptables {"000 allow -p 50":
	                chain  => "INPUT", proto => "esp", jump  => "ACCEPT", }
        iptables {"000 allow -p 51":
	                chain  => "INPUT", proto => "ah", jump  => "ACCEPT", }

        # This has something to do with multi-cast DNS
        iptables {"000 allow tcp 5353":
	       chain  => "INPUT", proto => "udp", dport => "5353", destination => "224.0.0.251", jump  => "ACCEPT", }

        iptables {"000 allow tcp 631":
	                chain  => "INPUT", proto => "tcp", dport => "631", jump  => "ACCEPT", }

        iptables {"000 allow udp 631":
	                chain  => "INPUT", proto => "udp", dport => "631", jump  => "ACCEPT", }

	iptables { "000 allow established states":
	                chain  => "INPUT", state => "ESTABLISHED", jump => "ACCEPT", }

	iptables { "000 allow related states":
	                chain  => "INPUT", state => "RELATED", jump => "ACCEPT", }

        iptables {"000 allow tcp 22":
	                chain  => "INPUT", state  => "NEW", proto => "tcp", dport => "22", jump  => "ACCEPT", }

        iptables {"000 allow tcp 9102":
	                chain  => "INPUT", state  => "NEW", proto => "tcp", dport => "9102", jump  => "ACCEPT", }

        iptables {"000 allow tcp 591":
	                chain  => "INPUT", state  => "NEW", proto => "tcp", dport => "591", jump  => "ACCEPT", }

        iptables {"000 allow tcp 5222":
	                chain  => "INPUT", state  => "NEW", proto => "tcp", dport => "5222", jump  => "ACCEPT", }

        iptables {"000 allow tcp 4545":
	                chain  => "INPUT", state  => "NEW", proto => "tcp", dport => "4545", jump  => "ACCEPT", }

        iptables {"000 allow tcp 5666":
	                chain  => "INPUT", state  => "NEW", proto => "tcp", dport => "5666", jump  => "ACCEPT", }


        iptables {"000 allow tcp 161":
	                chain  => "INPUT", state  => "NEW", proto => "udp", dport => "161", jump  => "ACCEPT", }

        iptables {"000 reject":
	                chain  => "INPUT", reject => "icmp-host-prohibited", jump  => "REJECT", }


	# pre.iptables and post.iptable files
	# This overcomes the sorting problem for the final drop rule
	file { 
		"/etc/puppet/post.iptables":
			content => "-A INPUT -j DROP\n-A FORWARD -j DROP",
			mode => 0600,
	}

	
}

