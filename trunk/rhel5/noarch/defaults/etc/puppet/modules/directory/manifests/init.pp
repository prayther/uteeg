
include  directory-iptables

# Note here we are using "::fqdn", this follows the convention of 
# specifing "top scope" since fqdn is a global fact.
# Also, not that master_fqdn has a default value

class directory($master, $master_fqdn = $::fqdn) {

  #include rsyslog

  include directory-iptables

  require directory::params

  include directory::install,directory::config,directory::service

}

