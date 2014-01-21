#
# Module: ntp
#
# Class: ntp
#
# Description:
#       This class configures and launches ntp
#
# Defines:
#       None
#
# LinuxGuide:
#       3.10.2.1.1
#       3.10.2.1.2
#
# CCERef#:
#       CCE-4292-9
#
# Variables:
#       None
#
# Facts:
#       None
#
class ntp {
	# GuideSection 3.10.2.1.2
	# Configure network protocol	
	cron { ntpd:
		command => "/usr/sbin/ntpd -q -u ntp:ntp 2>&1 >/dev/null",
		user    => "root",
		minute  => 15,
		require => [Package["ntp"],File["/etc/ntp.conf"]],
	}

	# GuideSection 3.10.2.1.1
	file {  
                "/etc/ntp.conf":
                        owner   => root,
                        group   => root,
                        mode    => 644,
                        content => template("ntp/ntp.conf.erb"),
                        require => Package["ntp"],
	}

	package {
                "ntp":
                ensure => installed,
                name   => "ntp",
        }

	service {
		"ntpd":
		ensure     => running,
		hasstatus  => true,
		hasrestart => true,
		enable     => true,
	}

	# Set the clock whenever ntp.conf is changed, and allow large clock changes 
	exec {
		"ntp initial clock set":
			subscribe   => File["/etc/ntp.conf"],
			command     => "/usr/sbin/ntpd -g -q -u ntp:ntp",
			refreshonly => true, 
			# Usable timeout to hide "command timed out" errors
			timeout     => "-1",
	}
}
