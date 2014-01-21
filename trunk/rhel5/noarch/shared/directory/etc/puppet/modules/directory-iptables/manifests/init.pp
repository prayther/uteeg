
# This class inherits from the system ipables class and opens two additional ports
# needed for ldap.
#
# == Parameters
#
#  N/A
#
#
#
# Put some examples on how to use your class here.
#
#   include directory-iptables
#
# == Authors
#
#  Julia DeSantis <desantisj@saic.com\>
#
# == Copyright
#
#
class directory-iptables inherits iptables::iptables{

  iptables { '000 allow tcp 636 echo reply':
    proto => 'tcp',
    dport => '636',
    jump  => 'ACCEPT',
  }

  iptables { '000 allow tcp 389 echo reply':
    proto => 'tcp',
    dport => '389',
    jump  => 'ACCEPT',
  }

}



