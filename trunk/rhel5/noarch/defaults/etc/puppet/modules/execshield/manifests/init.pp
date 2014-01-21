#
# Module: execshield
#
# Class: execshield
#
# Description:
#       This class makes sure execshield is enabled
#
# Defines:
#       None
#
# LinuxGuide:
#       2.2.4.3
#
# CCERef#:
#       CCE-4168-1
#	CCE-4146-7
#
class execshield {
	# GuideSection 2.2.4.3
	# CCE-4168-1, CCE-4146-7
	# Enable execshield
	augeas::basic-change {"Enable ExecShield, 2.2.4.3": 
		file=>"/etc/sysctl.conf", 
		lens=>"sysctl.lns", 
		changes => [
			"set kernel.exec-shield 1",
			"set kernel.randomize_va_space 1", 
		]
        }
}
