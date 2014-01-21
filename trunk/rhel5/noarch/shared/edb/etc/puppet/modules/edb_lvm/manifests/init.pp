# Class: edb_lvm
#
# This class uses the puppet-lvm module to set up and mount the required
# logical volume for installation of EnterpriseDB PostgreSQL.
#
# == Parameters
#
# == Variables
#
# $edb_pv is the physical volume associated with the EnterpriseDB installation.
# $edb_vg is the volume group associated with the EnterpriseDB installation.
# $edb_lv is the logical volume associated with the EnterpriseDB installation.
# $edb_lv_size is the size of $edb_lv.
# $edb_fs is the filesystem associated with the EnterpriseDB installation.
# $edb_fs_type is $edb_fs's type.
#
# == Examples
#
# This class should only ever need to be used in a simple include statement.
#
# == Authors
#
# Ryan Fenno <ryan.d.fenno@saic.com>
#
include lvm
class edb_lvm {
  
  # all of this is hardcoded
  $edb_pv      = '/dev/sda2'
  $edb_vg      = 'vg00'
  $edb_lv      = 'postgresData'
  $edb_lv_size = '2G'
  $edb_dev     = "/dev/$edb_vg/$edb_lv"
  $edb_fs_type = 'ext3'

  # create directory tree for mountpoint
  file { "$opt_pg":
    ensure  => directory,
    owner   => 'enterprisedb',
    group   => 'enterprisedb',
    mode    => '0700',
    require => User['enterprisedb'],
  }
  file { "$edb_home":
    ensure  => directory,
    owner   => 'enterprisedb',
    group   => 'enterprisedb',
    mode    => '0700',
    require => [ User['enterprisedb'], File["$opt_pg"] ],
  }
  file { "$edb_fs":
    ensure  => directory,
    owner   => 'enterprisedb',
    group   => 'enterprisedb',
    mode    => '0700',
    require => [ User['enterprisedb'], File["$edb_home"] ],
  }

  # setup the mountable filesystem
  physical_volume { "$edb_pv":
    ensure => present,
  }
  volume_group { "$edb_vg":
    ensure           => present,
    physical_volumes => ["$edb_pv"],
  }
  logical_volume { "$edb_lv":
    ensure       => present,
    volume_group => "$edb_vg",
    size         => "$edb_lv_size",
  }
  filesystem { "$edb_dev":
    ensure  => present,
    fs_type => "$edb_fs_type",
  }
  
  # mount the filesystem
  mount { "$edb_fs":
    ensure  => mounted,
    device  => "$edb_dev",
    fstype  => "$edb_fs_type",
    options => 'defaults',
    require => Filesystem["$edb_dev"],
  }
}