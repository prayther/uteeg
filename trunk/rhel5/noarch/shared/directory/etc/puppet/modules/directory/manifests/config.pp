
class directory::config {

  require directory::params

  file { '/opt/openldap':
    ensure  => directory,
    owner   => 'ldap',
    group   => 'ldap',
    recurse => true,
    mode    => '0644',
    # This requires the install class to run to ensure
    # the ldap user hasalready been created.
    require => Class['directory::install'],
  }

  file { '/opt/openldap/ldap':
    ensure  => directory,
    owner   => 'ldap',
    group   => 'ldap',
    recurse => true,
    mode    => '0644',
    require => Class['directory::install'],
  }

  # ensures this file is present.
  # TBD:  We should have specific names and directory locations for these that
  # are common across servers
  file { '/opt/certificates/keystore.pem':
    ensure => present,
    owner  => 'ldap',
    group  => 'ldap',
    mode   => '0644',
  }

  # ensures this file is present. 
  # The idea here is that these files would have to exist prior 
  # TBD: Not sure if this is best, or if they should be packaged somehow
  file { '/opt/certificates/truststore.pem':
    ensure => present,
    owner  => 'ldap',
    group  => 'ldap',
    mode   => '0644',
  }

  # This uses a template to create the ldap.conf; parameters are defined in
  # the Class directory::params
  file { '/etc/openldap/ldap.conf':
    content => template('directory/ldap.conf'),
    # This means that this class has to have been applied first, meaning  
    # that configuration won't occur until openldap rpm's are installed.
    require => Class['directory::install'],
    #  This causes the service class to be updated, so if changes to 
    # this file are applied, the service is restarted.
    notify  => Class['directory::service'],
  }


  file { '/etc/openldap/slapd.conf':
    owner   => 'ldap',
    group   => 'ldap',
    mode    => '0644',
    content => template('directory/slapd.conf'), 
    require => Class['directory::install'],
    notify  => Class['directory::service'],
  }

  file { '/etc/openldap/schema/extendedinetorgperson.schema':
	  content => template('directory/extendedinetorgperson.schema'),
	  require => Class['directory::install'],
	  notify  => Class['directory::service'],
  } 

  # This ensures that this directory is present or created
  file { 'backend_database_path':
    name   => '/opt/openldap/ldap/backend_db',
    ensure => directory,
    owner  => 'ldap',
    group  => 'ldap',
    mode   => '0700',
  }

  file {'/opt/openldap/ldap/backend_db/DB_CONFIG':
    ensure  => present,
    content => template('directory/DB_CONFIG'),
    require => Class['directory::install'],
    notify  => Class['directory::service'],
    owner   => 'ldap',
    group   => 'ldap',
  }

  file {'accesslog_database_path':
    name   =>  '/opt/openldap/ldap/accesslog_db',
    ensure => directory,
    owner  => 'ldap',
    group  => 'ldap',
    mode   => '0700',
  }

  file { '/opt/openldap/ldap/accesslog_db/DB_CONFIG':
    ensure  => present,
    content => template('directory/DB_CONFIG'),
    require => Class['directory::install'],
    notify  => Class['directory::service'],
    owner   => 'ldap',
    group   => 'ldap',
  }

  # This causes all files under /etc/openldap to be applied the following
  file { '/etc/openldap':
    recurse => true,
    owner   => 'ldap',
    group   => 'ldap',
    mode    =>  '0644',
  }

}
