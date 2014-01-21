#
#
#
# /etc/puppet/modules/puppet/manifests/init.pp

class puppet {
	file {	
		"/etc/puppet/puppet.conf":
			owner => root, group => wheel, mode => 644,
			replace => true,
			source => "puppet:///modules/puppet/puppet.conf";
	}
		
}
