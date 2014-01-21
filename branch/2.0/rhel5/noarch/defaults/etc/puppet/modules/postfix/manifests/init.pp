# Module: postfix
#
# Class: postfix
#
# Description: 
#	Ensures the postfix mail service is installed and properly configured.
#
# Defines:
#	None
#
# Variables:
#	None
#
# Facts:
#	None
#
# LinuxGuide:
#	3.11.1.1
#
# CCERef#:
#	TBD
#
class postfix {
   $relayhost           = extlookup('relayhost')
#     managed_postfix{ "main.cf":
#       relayhost       => "${relayhost}",


	package {
		"postfix":
			ensure => installed;
	}

	# Disable network listening
	augeas {
		"postfix-network-listening":
			context => "/files/etc/postfix/main.cf",
			lens    => "postfix_main.lns",
			incl    => "/etc/postfix/main.cf",
			changes => "set inet_interfaces localhost",
			onlyif  => "get inet_interfaces != localhost";
	}


        if ($relayhost !="") {
            augeas { "relayhost":
                context => "/files/etc/postfix/main.cf",
                lens    => "postfix_main.lns",
                incl    => "/etc/postfix/main.cf",
                changes => "set relayhost [${relayhost}]",
                onlyif  => "get relayhost != [${relayhost}]";
            }
        }













#	augeas {
#		"relayhost":
#			context => "/files/etc/postfix/main.cf",
#			lens    => "postfix_main.lns",
#			incl    => "/etc/postfix/main.cf",
#			changes => "set relayhost [smtp.spawar.navy.mil]",
#			onlyif  => "get relayhost != [smtp.spawar.navy.mil]";
#	}
}
