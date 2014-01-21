#
# Module: logrotate
#
# Class: logrotate
#
# Description:
#       This class installs ensures logrotate is rotating the specified files.
#
# Defines:
#       None
#
# LinuxGuide:
#       2.6.1.5
#
# CCERef#:
#       CCE-4182-2
#
class logrotate {
	# GuideSection 2.6.1.5
	# CCE-4182-2
	# Ensure all logs rotated

	logrotate::changeParm{"/var/log/messages": }
	logrotate::changeParm{"/var/log/kern.log": }
	logrotate::changeParm{"/var/log/daemon.log":}
	logrotate::changeParm{"/var/log/secure":}
	logrotate::changeParm{"/var/log/maillog":}
	logrotate::changeParm{"/var/log/cron":}
	logrotate::changeParm{"/var/log/syslog":}
	logrotate::changeParm{"/var/log/unused.log":}
}

define logrotate::changeParm ( )
{
	augeas::basic-change{ "logrotate-$name" :
		file => "/etc/logrotate.d/syslog",
		lens => "logrotate.lns",
		changes => [ 
			"ins file before rule/file[1]",
			"set rule/file[1] $name",
		],
		onlyif =>"match *[/files/etc/logrotate.d/syslog/*[file='$name']] size == 0",
	}
}

