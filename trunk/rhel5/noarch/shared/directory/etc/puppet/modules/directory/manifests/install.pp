
class directory::install {

  # ensures that the latest version of the RPM is installed by YUM. 
  # a specific version string could also be used.

  package { 'openldap-servers.x86_64': 
    ensure => latest,
  }

  package {'openldap-servers-overlays.x86_64':
	  ensure => latest,
  }

  package {'openldap-clients.x86_64':
    ensure => latest,
  }

  package {'openldap-sha2-2.3.43-1.x86_64': 
    ensure => latest,
  } 

}
