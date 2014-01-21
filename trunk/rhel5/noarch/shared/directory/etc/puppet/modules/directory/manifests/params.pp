
class directory::params {

  $ldap_base       = 'O=U.S. Government, C=US'
  $pam_policy      = 'no'
  $ppolicy_default = 'cn=default,ou=policies,o=U.S. Government,c=US'
  $root_dn         = 'cn=root,o=U.S. Government,c=US'
  $root_pw         = 'password'
  $dir_path        = '/opt/openldap'

  # We previously used bdb. hdb is a new generation mechanism that still
  # uses berkely DB, but stores entries hierarchally
  $backend_db_type     = 'hdb'
  $backend_db_path     = "${dir_path}/ldap/backend_db"
  $audit_log_path      = "${dir_path}/ldap/auditlog"
  $cert_dir            = '/opt/certificates'
  $keystore_fullpath   = "${cert_dir}/keystore.pem"
  $truststore_fullpath = "${cert_dir}/truststore.pem"
  $module_path         = '/usr/lib64/openldap'

  # Log Level is 0x8 | 0x4000 | 0x64 | 0x32
  $log_level = '16488' 

  ## This is the master configuration for syncrpel
  ## checkpoint indicates that modifications to the DB are only
  ## written if 50 writes or 10 minutes have elapsed
  ## store the last 100 deletions/modifications in the session log
  $master_repl_array = ['overlay syncprov',
                        'nsyncprov-checkpoint 50 10',
                        'syncprov-sessionlog 100']

  $slave_repl_array = ['syncrepl rid=001',
                       " provider=ldap://${master_fqdn}:389",
                       ' type=refreshAndPersist',
                       ' interval=00:00:01:00',
                       ' filter="(objectClass=*)"',
                       ' scope=sub',
                       ' attrs="*,+"',
                       ' searchbase="o=U.S. Government,c=US"',
                       ' schemachecking=off',
                       ' bindmethod=simple',
                       ' binddn="cn=replication,o=U.S. Government,c=US"',
                       ' credentials=password']

  $password_access_type = 'attrs=userPassword'
  $password_access = 'self write by dn.base="cn=replication,o=U.S. Government,c=US" write by * auth'

  # This is an array specifing all the specific users who have access to all
  $specific_user_access = ['dn="cn=Wesley.Wilson, ou=NCES, ou=DISA, ou=DoD, O=U.S. Government, C=US" write',
                           'dn="cn=messaging,o=U.S Government, c=US" read',
                           'dn="cn=replication,o=U.S. Government,c=US" read',
                           'dn="cn=Service Discovery,o=U.S. Government,c=US" read',
                           'dn="cn=ESM,o=U.S. Government,c=US" read',
                           'users read',
                           'self write',
                           '* auth']

}
