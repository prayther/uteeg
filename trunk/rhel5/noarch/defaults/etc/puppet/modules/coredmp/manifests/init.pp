#
# Module: coredump
#
# Class: coredump
#
# Description:
#       This class disables coredumps
#
# Defines:
#       None
#
# LinuxGuide:
#       2.2.4.2
#
# CCERef#:
#       CCE-4209-3
#	CCE-4247-3
#
class coredmp {
	# GuideSection 2.2.4.2
	# CCE-4225-9
	# CCE-4247-3
	# Disable core dumps
	augeas::basic-change { "/etc/security/limits.conf": 
		file   =>"/etc/security/limits.conf", 
		lens   =>"limits.lns", 
		changes=> [
			"set domain '*'",
			"set domain/type hard",
			"set domain/item core",
			"set domain/value 0", 
		]
        }

        augeas::basic-change { "/etc/sysctl.conf":
		 file   =>"/etc/sysctl.conf",
		 lens   =>"sysctl.lns",
		 changes=> "set fs.suid_dumpable 0",
        }
}
