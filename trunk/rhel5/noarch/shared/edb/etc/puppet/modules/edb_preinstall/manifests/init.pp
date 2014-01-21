# Class: edb_preinstall
#
# This class performs the preinstallation tasks for the installation of
# EnterpriseDB PostgreSQL.
#
# == Parameters
#
# == Variables
#
# == Examples
#
# This class should only ever need to be used in a simple include statement.
#
# == Authors
#
# Ryan Fenno <ryan.d.fenno@saic.com>
#
class edb_preinstall {
  user { 'enterprisedb':
    ensure  => present,
    gid     => 'enterprisedb',
    require => Group['enterprisedb'],
    home    => "$edb_home",
    comment => 'Postgres Plus Advanced Server',
    }  

  group { 'enterprisedb':
    ensure => present,
  }
  
  #
  # setup installation directory
  #
  $install_dir = '/opt/postgresql_install'
  file { "$install_dir":
    ensure => directory,
    owner  => enterprisedb,
    group  => enterprisedb,
  }
  
  $install_name = 'ppasmeta-9.0.4.14-linux-x64'
  $tarball = "$install_name.tar.gz"
  file { "$install_dir/$tarball":
  	ensure => present,
  	owner  => enterprisedb,
  	group  => enterprisedb,
  	source => "puppet:///modules/edb_preinstall/$tarball",
  }

  exec { "tar zxf $tarball":
    cwd     => "$install_dir",
    creates => "$install_dir/$install_name",
    path    => '/bin',
  }

}