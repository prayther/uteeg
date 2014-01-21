# /etc/puppet/modules/nfs/manifests/init.pp
#
# Module: nfs
#
# Class: nfs
#
# Description:
#       This module ensures nfs-related services are not running and disabled at
#	startup.
#
# Defines:
#       None
#
# LinuxGuide:
#	3.13.1.1
#	3.13.1.2
#	3.13.1.3
#	3.13.3.1
#
# CCERef#:
#	CCE-4396-8
#	CCE-3535-2
#	CCE-3568-3
#	CCE-4533-6
#	CCE-4550-0
#	CCE-4491-7
#	CCE-4473-5
#
class nfs {
	# GuideSection 3.13
	# NFS and RPC	

	# GuideSection 3.13.1.1
	# disable nfs services
	service {
		"nfslock": enable => false, ensure => stopped;
		"rpcgssd": enable => false, ensure => stopped;
		"rpcidmapd": enable => false, ensure => stopped;
	# GuideSection 3.13.1.2
		"netfs": enable => false, ensure => stopped;

	# GuideSection 3.13.1.3
		"portmap": enable => false, ensure => stopped;

	# GuideSection 3.13.3.1
		"nfs": enable => false, ensure => stopped;
		"rpcsvcgssd": enable => false, ensure => stopped;
	}
}
