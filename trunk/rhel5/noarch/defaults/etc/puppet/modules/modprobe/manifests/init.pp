# Module: modprobe
#
# Class: modprobe
#
# Description:
#	This class disables certain kernel modules from loading such as odd
#	filesystems, usb and bluetooth drivers.
#
# Defines:
#	modprobe::disableModule( $module )
#	modprobe::turnOffModule( $module )
#
# LinuxGuide
#	2.2.2.2.1
#	2.5.3.1.1
#	2.2.2.5
#	3.3.14.3
#
# CCERef#:
#	CCE-4172-3
#
# File: /etc/puppet/modules/modprobe/manifests/init.pp
#
class modprobe {
	# GuideSection 2.2.2.2.1 2.5.3.1.1, 2.2.2.5, 3.3.14.3
	# Disable modprobe loading of usb-storage and unused file systems
        modprobe::disableModule{"Disable Cramfs, 2.2.2.5":   	module => "cramfs" }
        modprobe::disableModule{"Disable freevxfs, 2.2.2.5": 	module => "freevxfs" }
        modprobe::disableModule{"Disable jffs2, 2.2.2.5":    	module => "jffs2" }
        modprobe::disableModule{"Disable hfs, 2.2.2.5":      	module => "hfs" }
        modprobe::disableModule{"Disable hfsplus, 2.2.2.5":  	module => "hfsplus" }
        modprobe::disableModule{"Disable udf, 2.2.2.5":      	module => "udf" }
	modprobe::disableModule{"Disable usb-storage, 2.2.2.1":	module => "usb-storage" }
#	modprobe::disableModule{"Disable ipv6, 2.5.3.1.1":	module => "ipv6" }
	modprobe::turnOffModule{"Disable Bluetooth, 3.3.14.3":  module => "bluetooth" }
	modprobe::turnOffModule{"Disable net-pf-31, 3.3.14.3":  module => "net-pf-31" }

}

	# GuideSection 2.5.7.1, 2.5.7.2, 2.5.7.3, 2.5.7.4
	# Disable modprobe loading of uncommon protocols
        modprobe::disableModule{"Disable DCCP, 2.5.7.1":   	module => "dccp" }
        modprobe::disableModule{"Disable SCTP, 2.5.7.2":   	module => "sctp" }
        modprobe::disableModule{"Disable DCCP, 2.5.7.3":   	module => "rds" }
        modprobe::disableModule{"Disable DCCP, 2.5.7.4":   	module => "tipc" }

#########################################
# Function: fs::disableModule()
#
# Description:
#       This define adds a line to modprobe.conf to disable the given module.
#
# Paramters: 
#       $fs: This is the module to be disabled, defaults to null.
#
# Returns:
#       None
#########################################
define modprobe::disableModule ( $module = '' )
{
        augeas::basic-change {"$name":
                file    => "/etc/modprobe.conf",
                lens    => "modprobe.lns",
                changes => "set install[0] '$module /bin/true'",
                onlyif  => "match *[/files/etc/modprobe.conf[install = '$module /bin/true']] size == 0",
        }
}

#########################################
# Function: fs::turnOffModule()
#
# Description:
#       This define adds a line to modprobe.conf to turn off a module
#
# Paramters: 
#       $module: This is the module to be turned off, defaults to null.
#
# Returns:
#       None
#########################################

define modprobe::turnOffModule ( $module ='' )
{
	augeas::basic-change { "$name" :
                file    => "/etc/modprobe.conf",
                lens    => "modprobe.lns",
                changes => [
                                "set alias[last()+1] $module",
                                "set alias[last()]/modulename off",
                        ],
                onlyif => "match *[/files/etc/modprobe.conf[alias = '$module']] size == 0"
        }

}
