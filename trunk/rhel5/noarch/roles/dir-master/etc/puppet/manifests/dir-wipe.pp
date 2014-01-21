

node default {

  # Here we use the base iptables so that we remove the directory customations

  service {'ldap': 
	ensure => stopped,
        before => Package["openldap-servers"],
  }

  package { "openldap-sha2-2.3.43-1": 
        ensure => absent,
  }

  package { "openldap-servers-overlays" :
        ensure => absent,
  }

  ## Here we make sure that openldap-servers is removed first
  ## otherwise, openldap-servers-overlays fails.
  package { "openldap-servers" :
        ensure => absent,
        require => [Package["openldap-servers-overlays"], Package["openldap-sha2-2.3.43-1"] ],
  }

  ## Here we use "require" to make sure that the packages are removed before
  ## the disk is cleaned up
  file {'/opt/openldap/ldap': 
        ensure => absent,
        force => true,
        require => Package["openldap-servers"],
        ## Don't backup these files to the filebucket because we aren't interested in restoring them.
        backup => false,
  }

  file {'/etc/openldap':
        ensure => absent,
        force => true,
        require => Package["openldap-servers"],
        backup => false,
  }
}
