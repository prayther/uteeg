
#  This class creates a slave Open-ldap installation using delta-repl 
#  replcation
#
# == Parameters
#
# Document parameters here
#
# [* master_fqdn_in*]
# FQDN of the master, passed in via the node definiiont
#
# == Variables
#
#
# Put some examples on how to use your class here.
#
#   $master_fqdn_in = "somehost.chs.spawar.navy.mil"
#   include directory-slave
#
# == Authors
#
#  Julia DeSantis <desantisj@saic.com\>
#
# == Copyright
#
#
class directory-slave ($master_fqdn_in) {

  class {"directory":
    master      =>  false,
    master_fqdn => $master_fqdn_in,
  }

  exec {"Wait for Master":
    tries     => 5,
    try_sleep => 300,
    command   => "/usr/bin/ldapsearch -xv -D 'cn=root,o=U.S. Government,c=US' -w password -H ldap://$master_fqdn_in",
    logoutput => on_failure,
    require   => Service["ldap"],
    before    => Exec["Perform Repl"],
  }

  exec {"Perform Repl":
    path    => "/etc/init.d",
    command => "ldap restart",
    require => Service["ldap"],
    before    => Exec["Restart LDAP Repl"],
  }

  exec { "Restart LDAP Repl":
    path    => "/etc/init.d",
    command => "ldap restart",
    onlyif  => "/bin/sleep 10",    # workaround for crashing replication server
    require => Service["ldap"],
  }
}