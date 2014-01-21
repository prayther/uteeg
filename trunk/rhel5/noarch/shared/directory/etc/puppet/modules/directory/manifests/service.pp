
class directory::service {

  include directory::params

  service { 'ldap':
    # Make sure the service is running
    ensure     => running,

    # This means the service has a "restart" parameter in the init script
    hasrestart => true,

    # This means the service will be configured to be started at boot
    enable     => true,

    # This means the service requires it be installed
    require    => Class['directory::config'],

    #  This means that the service class is affected if this files change.
    #  This ensures that the service restarts when these change
    subscribe => File['/etc/openldap/slapd.conf',
                      '/etc/openldap/ldap.conf'],
  }
  
}
