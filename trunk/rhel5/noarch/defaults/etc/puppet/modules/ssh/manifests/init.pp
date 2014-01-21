# Module: ssh
#
# Description:
#	The ssh module configures the /etc/ssh/sshd_config file to add some 
#	rules that limit the clients logging into an ssh server.
#
# Linux Guide:
#	3.5.2
#	3.5.2.1, 3.5.2.3, 3.5.2.4, 3.5.2.5, 3.5.2.6, 3.5.2.7, 3.5.2.8
#
# CCE Reference:
#	CCE-3660-8, CCE-3845-5, CCE-4325-7, CCE-4370-3, CCE-4387-7,
#	CCE-4431-3, CCE-4475-0
#
# TODO:
#	Some setting in /manifests/settings.pp could determine whether to use
#	sshd at all.  And if so select one set of rules disabling sshd, and 
#	if not, select the other set of rules currently enforced.
#
#	Tightening down iptables rules would also be recommended.
#	Guide 3.5.2.9
#
class ssh {
	# GuideSection
	# 3.5.2 3.5.2.1 3.5.2.3 3.5.2.4 3.5.2.5 3.5.2.6 3.5.2.7 3.5.2.8
	# Configure ssh server
	augeas::basic-change { "sshd_config, 3.5.2.*" :
			file    => "/etc/ssh/sshd_config",
			lens    => "sshd.lns",
			changes => [
					"set Protocol 2",
					"set ClientAliveInterval 900",
					"set ClientAliveCountMax 0",
					"set IgnoreRhosts yes",
					"set HostbasedAuthentication no",
					"set PermitRootLogin no",
					"set PermitEmptyPasswords no",
					"set Banner /etc/issue",
					"set PermitUserEnvironment no",
					"set Ciphers aes256-cbc,aes128-ctr,aes192-ctr,aes256-ctr",
			],
		}

	service { "sshd": 
		ensure    => true,
		hasstatus => true,
		enable    => true,
#		require   => [Package["openssh-server"], Iptables["000 allow ssh"]],
		require   => [Package["openssh-server"]],
	}
	

	package { 
		"openssh-clients":
			ensure => "installed";
		"openssh-server":
			ensure => "installed";
	}

# disabling all firewall modifications/turning on iptables if it was off for retrofitting of ges services boxes
#	 iptables {
#                "000 allow ssh":
#			proto => "tcp",
#			dport => "22",
#			jump  => "ACCEPT",
#       }
}
