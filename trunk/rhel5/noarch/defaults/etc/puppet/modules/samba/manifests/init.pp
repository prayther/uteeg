#
# Module: samba
#
# Class: samba
#
# Description:
#	Enables Samba packet signing for the Samba client to prevent
#	man-in-the-middle attacks.
#
# Defines:
#	None
#
# LinuxGuide:
#	3.18.2.10
#	3.18.2.11
#
# CCERef#:
#	TBD
#
# File: /etc/puppet/modules/samba/manifests/init.pp
#
class samba {
	# GuideSection 3.18.1
	# Disable Samba if possible
	service { "samba" :
		ensure => false,
		enable => false,
	}

	# GuideSection 3.18.2.10
	# Require Client SMB Packet Signing, if using smbclient
	augeas{ "samba-client-signing" :
		context => "/files/etc/samba/smb.conf/*[. = 'global']",
		changes => "set 'client\ signing' mandatory",
		onlyif	=> "get 'client\ signing' != mandatory",
	}

	
	# GuideSection 3.18.2.11
	# Require Client SMB Packet Signing, if using mount.cifs
	augeas { "cifs-client-signing" :
		context => "/files/etc/fstab/*[vfstype =~ regexp('(ci|smb)fs')][count(opt[. =~ regexp('sec=(krb5i|ntlmv2i)')]) = 0]",
		changes => [
			"ins opt after opt[last()]",
			"set opt[last()] sec=krb5i"
		],
		onlyif	=> "match /files/etc/fstab/*[vfstype =~ regexp('(ci|smb)fs')][count(opt[. =~ regexp('sec=(krb5i|ntlmv2i)')]) = 0] size > 0"
	}
}
