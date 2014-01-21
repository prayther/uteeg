#
# Module: fstab
#
# Class: fstab
#
# Description:
#       This class ensures potentially dangerous partitions are mounted with
#	restrictive options.
#
# Defines:
#       set-mount-options - for setting a mount option on all of a specific file
#	system type in the fstab
#
# LinuxGuide:
#       2.2.1.1
#	2.2.1.2
#	3.13.3.2
#
# CCERef#:
#	CCE-4249-9
#	CCE-4024-6
#	CCE-4368-7
#	CCE-4526-0
#
# TODO:
#       Determine how to isolate removable partitions locally mounted.
class fstab {
	# GuideSection 2.2.1.1
	# Add nodev option to Non-Root Local Partitions
	augeas{ "fstab-non-root-nodev" :
		context => "/files/etc/fstab/*[file != '/'][count(opt[. = 'nodev']) = 0]",
		changes => [
			"ins opt after opt[last()]",
			"set opt[last()] nodev"
		],
		onlyif	=> "match /files/etc/fstab/*[file != '/'][count(opt[. = 'nodev']) = 0] size > 0",
	}

	set-mount-options {
		# GuideSection 2.2.1.2
		# Add nosuid option to Removable Media Partitions
		### Unsure how to isolate removable media in fstab ###
		#"rem_nosuid":
		#	fstype => ?,
		#	option => nosuid;

		# Add noexec option to Removable Media Partitions
		### Unsure how to isolate removable media in fstab ###
		#"rem_nosuid":
		#	fstype => ?,
		#	option => nosuid;

		# Add nodev option to Removable Media Partitions
		### Handled by Guidesection 2.2.1.1 ###
		
		# GuideSection 3.13.3.2
		# Add nosuid option to Remote Media Partitions
		"nfs_nosuid":
			fstype => 'nfs',
			option => 'nosuid';

		# Add noexec option to Remote Media Partitions
		"nfs_noexec":
			fstype => 'nfs',
			option => 'noexec';

		# Add nodev option to Remote Media Partitions
		### Handled by Guidesection 2.2.1.1 ###
	}

	define set-mount-options($fstype,$option) {
		augeas{ "fstab-$fstype-$option":
			context => "/files/etc/fstab/*[vfstype = '$fstype'][count(opt[. = '$option']) = 0]",
			changes => [
				"ins opt after opt[last()]",
				"set opt[last()] $option"
			],
			onlyif	=> "match /files/etc/fstab/*[vfstype = '$fstype'][count(opt[. = '$option']) = 0] size > 0",
		}
	}
}
