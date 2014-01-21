# $Id: init.pp 763 2012-08-15 13:52:46Z sysutil $
# Class: postfix
#
# Description: 
#	Ensures the postfix mail service is installed and properly configured.
#
# Guide Reference:
#	3.11.1.1
#
# CCE Reference:
#	TBD
#
class postfix {

        service {
                "postfix":
                        ensure    => running,
                        hasstatus => true,
                        enable    => true;
        }

	# Guide Section 3.11.1.1
	# Install postfix
	
	package {
		"postfix":
			ensure    => installed;
	}

	# Disable network listening
	augeas {
		"postfix-network-listening":
			context => "/files/etc/postfix/main.cf",
			changes => "set inet_interfaces localhost",
			onlyif => "get inet_interfaces != localhost",
	}
	# setting up spawar relay
    augeas {
         "relayhost":
            context => "/files/etc/postfix/main.cf",
            changes => "set relayhost [smtp.chs.spawar.navy.mil]"
    }
	
}
