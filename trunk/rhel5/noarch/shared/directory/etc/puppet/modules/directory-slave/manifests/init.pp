
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

  exec { "Restart LDAP Repl":
    path    => "/etc/init.d",
    command => "ldap restart",
    onlyif  => "/bin/sleep 10",    # workaround for crashing replication server
    require => Service["ldap"],
  }
}
