
# This class creates a slave Open-ldap installation using delta-repl
# replcation
#
# == Parameters
#
# Document parameters here
#
# FQDN of the master, passed in via the node definiiont
#
# == Variables
#   [*master*] indicates master configuration is desired
#   [*master_fqdn*] set master fqdn 
#
#
# Put some examples on how to use your class here.
#
#   $master_fqdn_in = "somehost.chs.spawar.navy.mil"
#   include directory-master
#
# == Authors
#
#  Julia DeSantis <desantisj@saic.com\>
#
# == Copyright
#
#
class directory-master{

  class { 'directory':
    master => true
  }

  exec {'AddRootUser':
    try_sleep => 5,
    tries     => 2,
   	path      => [ '/usr/local/bin', '/usr/bin', '/usr/sbin', '/sbin'],
	  logoutput => true,
    # This is a force placeholder, the appropriate way to do this is
    # to use a ldapsearch query to see if the entry is there.
    creates => '/home/desantisj/force.txt',
    # Encountered issues when anything other than alphanumeric in these scripts. 
    command => 'ldapadd -xv -D "cn=root,o=U.S. Government,c=US" \
            -w password -f \
            /etc/puppet/modules/directory-master/templates/basic-root.ldif',
    require => Service["ldap"],
  }


  exec { 'AddLDAPStructure':
    try_sleep => 5,
    tries     => 2,
    path      => ['/usr/local/bin', '/usr/bin', '/usr/sbin', '/sbin'],
	  logoutput => true,
    # This is a force placeholder, the appropriate way to do this is
    # to use a ldapsearch query to see if the entry is there.
    creates => '/home/desantisj/force.txt',
    # Encountered issues when anything other than alphanumeric in these scripts. 
    # Note the -c, this makes it continue, even if the entries exists
    command => 'ldapadd -cxv -D "cn=root,o=U.S. Government,c=US" \
            -w password -f \
            /etc/puppet/modules/directory-master/templates/ldap-structure.ldif',
    require => [Service["ldap"], Exec["AddRootUser"] ]
  }

  exec { 'AddReplUser':
    # Here we add the following lines to trigger a retry if the operation
    # fails. This was neccessary because LDAP needed some more time to
    # initialize before ready to accept commands since the databases are
    # created upon installation.
    try_sleep => 5,
    tries     => 2,
    path      => ['/usr/local/bin', '/usr/bin', '/usr/sbin', '/sbin'],
    logoutput => true,
    # This is a force placeholder, the appropriate way to do this is
    # to use a ldapsearch query to see if the entry is there.
    creates => '/home/desantisj/force.txt',
    # Encountered issues when anything other than alphanumeric in these scripts. 
    command => 'ldapadd -xv -D "cn=root,o=U.S. Government,c=US" \
               -w password -f \
               /etc/puppet/modules/directory-master/templates/repl-user.ldif',
    require => Exec["AddLDAPStructure"],
  }

}
