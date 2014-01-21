node default {
  # hardcoded paths
  $opt_pg      = '/opt/PostgresPlus'
  $edb_home    = "$opt_pg/9.0AS"
  $edb_fs      = "$edb_home/data"

  include edb_preinstall
  include edb_lvm
  include edb_install::generic
  include edb_install::primary
}