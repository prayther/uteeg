# Class: sendmail
#
# Description: 
#	Ensures the sendmail daemon is off and the package uninstalled.
#
# Guide Reference:
#	3.11.2.1
#
# CCE Reference:
#	CCE-4293-7
#
class sendmail {
	# Guide Section 3.11.1.1
	# Disable and uninstall sendmail
	service {
		"sendmail":
		        ensure    => false,
			enable    => false;
	}
	
	package { "sendmail":
			ensure    => absent;
	}
}
