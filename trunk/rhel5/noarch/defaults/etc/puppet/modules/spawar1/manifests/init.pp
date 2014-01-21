#include iptables

# $Id: init.pp 1151 2012-12-14 17:05:42Z sysutil $

# the use of the prefix on the classes allows the use of the module autoloader
# to find classes that are included in modules
# So, in the following case iptables is a class found in the
#   <module path>/iptables/manifests/init.pp
# class spawar::spawar_iptables inherits iptables::iptables{

class spawar_services {
  service { 'cma':
    ensure => running;
  }

#  service { 'nrpe':
#    ensure => running,
#    #subscribe => File['/etc/nagios/nrpe.cfg'],
#    require => Class['spawar_sw1'],
#  }
#  # NRPE entry in /etc/services
#  append_if_no_such_line { 'nrpe_services_entry':
#    file => '/etc/services',
#    line => 'nrpe              5666/tcp                        # NRPE',
#  }
  # NRPE entry in hosts.allow
  append_if_no_such_line { 'nrpe_hosts_allow_entry':
        file => '/etc/hosts.allow',
        line => 'nrpe:163.240.36.146',
        #line => 'nrpe:ALL',
  }
  # SPAWAR entry in hosts.allow
  append_if_no_such_line { 'spawar_hosts_allow_entry':
        file => '/etc/hosts.allow',
        line => 'sshd:ALL:allow',
  }
}


class spawar_sw1 {
  exec { 'install required packages':
    #command   => '/usr/bin/yum install -y audispd-plugins vmware-tools-esx-nox nagios-plugins-nrpe nrpe spauvscanwar acl bacula-client yum-security ovaldi puppet-0.25.5 setools sysstat audit screen vim-enhanced',
    command   => '/usr/bin/yum install -y iftop iotop ngrep yum-utils defaults ircd-ratbox-mkpasswd audispd-plugins vmware-tools-esx-nox acl yum-security ovaldi puppet setools sysstat audit screen vim-enhanced spacewalk-oscap',
    onlyif    => 'test `ps aux | grep yum | grep -v grep | grep -v yum-updatesd | wc -l` -eq 0',
    logoutput => 'on_failure',
  }

  # Nagios client packages
#  package { 'nrpe': ensure => installed, }
#  package { 'nagios-plugins':
#    ensure  => installed,
#    require => Package['nrpe'],
#  }
#  package { ['nagios-plugins-disk', 'nagios-plugins-load',
#             'nagios-plugins-nrpe', 'nagios-plugins-procs',
#             'nagios-plugins-time', 'nagios-plugins-users' ]:
#        ensure  => installed,
#        require => Package['nagios-plugins'],
#  }
#  $nagios_plugins_root  = '/usr/lib64/nagios/plugins'
#  file { [ "$nagios_plugins_root/check_disk",
#        "$nagios_plugins_root/check_load", "$nagios_plugins_root/check_nrpe",
#        "$nagios_plugins_root/check_procs", "$nagios_plugins_root/check_time",
#        "$nagios_plugins_root/check_users" ]:
#    ensure  => 'present',
#    owner   => 'root',
#    group   => 'nagios',
#    mode    => '7411',
#    require => [ Package['nagios-plugins-disk'], Package['nagios-plugins-load'],
#                 Package['nagios-plugins-nrpe'], Package['nagios-plugins-procs'],
#                 Package['nagios-plugins-time'], Package['nagios-plugins-users'] ],
#  }
}

class spawar_iptables inherits iptables {

# taken care of in the ssh module
# iptables {
#    'spawar allow tcp 22 ssh':
#      proto => 'tcp',
#      dport => '22',
#      jump => 'ACCEPT',
#  }


#  this needs to be taken care of in the postgres role
#  iptables { '000 spawar allow tcp 5432 PostgreSQL':
#    proto => 'tcp',
#    dport => '5432',
#    jump => 'ACCEPT',
#  }
  
# no longer used
#  iptables { '000 spawar allow tcp 9102 Bacula':
#    proto => 'tcp',
#    dport => '9102',
#    jump => 'ACCEPT',
#  }

  iptables { '000 spawar allow tcp 591 HBSS':
    proto => 'tcp',
    dport => '591',
    jump => 'ACCEPT',
  }

  iptables { '000 spawar allow tcp 5666 Nagios':
    proto => 'tcp',
    dport => '5666',
    jump => 'ACCEPT',
  }
}

class spawar_exec {

#  install in the high / low roles, just to keep both the delivery and installation in the same place
  exec { 'install HBSS':
    command   => '/root/hbss/install-linux-LANT.sh -i',
    unless    => 'ps aux | grep cma | grep -v grep',
    logoutput => 'on_failure',
    }
#  }  line => "*/5 * * * * root yum -y --exclude=puppet update defaults 2>&1 >/dev/null",

# upgrade hbss
# exec { 'rpm -qa | grep -i mfecma-4.5.0.1812;if [ \$? != 0 ];then rpm --erase MFEcma MFErt ; /root/HBSS/install-linux-45-1812.sh -u;fi':
# require => Class['files']
#      }

  exec { 'install additional GPG keys for yum/rpm':
    command   => 'rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL &&
                  rpm --import /etc/pki/rpm-gpg/VMWARE-PACKAGING-GPG-KEY.pub &&
                  rpm --import /etc/pki/rpm-gpg/GPG-SPAWAR-KEY',
    logoutput => 'on_failure',
  }
  
#  exec { 'run yum update':
#    command   => 'yum -y --exclude=puppet update defaults 2>&1 >/dev/null',
#    logoutput => 'on_failure',
#  }
  
}

class spawar_users {
  Exec { path => [ "/usr/bin", "/usr/sbin", "/bin", "/sbin" ] }

  # user accounts must be created after CLIP content runs to ensure
  # that PASS_MIN_DAYS is set in /etc/login.defs (GEN000540)
  
  define spawar_user($comment, $uid, $secgroups) {
    user { $name:
      ensure     => present,
      comment    => $comment,
      gid        => $name,
      require    => Group["$name"],
      groups     => $secgroups,       # secondary groups
      membership => minimum,
      shell      => '/bin/bash',
      home       => "/home/$name",
      uid        => "$uid",
    }

    group { $name:
      ensure => present,
      gid    => $uid,
    }

    # home directory permissions
    file { "/home/$name":
      ensure => directory,
      owner  => $name,
      group  => $name,
      mode   => '0700',
    }
    
        # home directory startup files
    file { "/home/$name/.bash_logout":
      ensure => file,
      owner  => $name,
      group  => $name,
      mode   => '0700',
      source => "puppet:///modules/spawar1/bash_logout",
      # => "[ ! -f /home/$name/.bash_logout ]",
    }
    
    # home directory startup files
    file { "/home/$name/.bash_profile":
      ensure => file,
      owner  => $name,
      group  => $name,
      mode   => '0700',
      source => "puppet:///modules/spawar1/bash_profile",
      # => "[ ! -f /home/$name/.bash_logout ]",
    }
    
        # home directory startup files
    file { "/home/$name/.bashrc":
      ensure => file,
      owner  => $name,
      group  => $name,
      mode   => '0700',
      source => "puppet:///modules/spawar1/bashrc",
      # => "[ ! -f /home/$name/.bash_logout ]",
    }    

    # change password
    exec { "$name change password":
      command   => "tr -dc A-Za-z0-9_\\!\\@\\#\\$\\%\\^\\? < /dev/urandom | \
                   head -c 64 | xargs | passwd --stdin $name",
      require   => User["$name"],
      logoutput => 'on_failure',
    }

    # setup SSH keys
    file { "/home/$name/.ssh":
      ensure  => directory,
      owner   => $name,
      group   => $name,
      mode    => '0600',
      require => File["/home/$name"],
    }
    file { "/home/$name/.ssh/authorized_keys":
      ensure  => file,
      owner   => $name,
      group   => $name,
      mode    => '0600',
      # files directory must contain authorized_keys file $name.pub
      source  => "puppet:///modules/spawar1/$name.pub",
      require => File["/home/$name/.ssh"],
    }
  }

  #
  # create users
  #
  spawar_user { 'retinascan':
    comment   => 'SPAWAR NetSec Retina scan acct',
    uid       => '603',
    secgroups => ['wheel', 'users'],
  }
  spawar_user { 'sysutil':
    comment   => 'system utility account for automation purposes',
    uid       => '607',
    secgroups => ['wheel', 'users'],
  }
  # special section for sysutil
  file { "/home/sysutil/.ssh/id_rsa":
    ensure => directory,
    source => 'puppet:///modules/spawar1/sysutil_id_rsa',
    owner  => 'sysutil',
    group  => 'sysutil',
    mode   => '0600',
  }
  # this is not needed because of the authorized_keys file, but is more obvious
  file { "/home/sysutil/.ssh/id_rsa.pub":
    ensure => directory,
    source => 'puppet:///modules/spawar1/sysutil_id_rsa.pub',
    owner  => 'sysutil',
    group  => 'sysutil',
    mode   => '0600',
  }
  spawar_user { 'praythea':
    comment   => 'Prayther, Aaron, LCE aprayther@lce.com, 843 218 2178',
    uid       => '600',
    secgroups => ['wheel', 'users'],
  }
  spawar_user { 'rayjd':
    comment   => 'Ray, Jeffrey D., Barling Bay jray@barlingbay.com',
    uid       => '610',
    secgroups => ['wheel', 'users'],
  }
#  spawar_user { 'ahainor':
#    comment   => 'Hainor, Aaron',
#    uid       => '840',
#    secgroups => ['wheel', 'users'],
#  }
#  spawar_user { 'ehiott':
#    comment   => 'Hiott, Erica',
#    uid       => '850',
#    secgroups => ['wheel', 'users'],
#  }
#  spawar_user { 'jsigh':
#    comment   => 'Sigh, John',
#    uid       => '870',
#    secgroups => ['wheel', 'users'],
#  }
#  spawar_user { 'lgeddis':
#    comment   => 'Geddis, Lacreshia',
#    uid       => '880',
#    secgroups => ['wheel', 'users'],
#  }
#  spawar_user { 'mcollins':
#    comment   => 'Collins, MaRenins',
#    uid       => '890',
#    secgroups => ['wheel', 'users'],
#  }
#  spawar_user { 'pjohnson':
#    comment   => 'Johnson, Patrick',
#    uid       => '910',
#    secgroups => ['wheel', 'users'],
#  }
#  spawar_user { 'snelson':
#    comment   => 'Nelson, Shevon',
#    uid       => '940',
#    secgroups => ['wheel', 'users'],
#  }
#  spawar_user { 'umitchell':
#    comment   => 'Mitchell, Ulonda',
#    uid       => '950',
#    secgroups => ['wheel', 'users'],
#  }
#  spawar_user { 'ahill':
#   comment   => 'Hill, Alan',
#   uid       => '990',
#   secgroups => ['wheel', 'users'],
# }    
#   spawar_user { 'allendw':
#  comment   => 'Allen, Darryl',
#  uid       => '5414',
#  secgroups => ['wheel', 'users'],
# }
#    spawar_user { 'cpittman':
#   comment   => 'Pittman, Charles',
#   uid       => '1030',
#   secgroups => ['wheel', 'users'],
#  }
#  spawar_user { 'pricek':
#    comment   => 'Price K., Kevin, kevin.l.price@saic.com',
#    uid       => '630',
#    secgroups => ['wheel', 'users'],
#  }
#  spawar_user { 'carterja':
#    comment   => 'Carter, Josh',
#    uid       => '670',
#    secgroups => ['wheel', 'users'],
#  }
#  spawar_user { 'morganme':
#    comment   => 'Morgan, Molly',
#    uid       => '710',
#    secgroups => ['wheel', 'users'],
#  }
#  spawar_user { 'andrell.shaw':
#    comment   => 'Shaw, Andrell',
#    uid       => '730',
#    secgroups => ['wheel', 'users'],
#  }
#  spawar_user { 'skeys':
#    comment   => 'Keys, Sabrina',
#    uid       => '750',
#    secgroups => ['wheel', 'users'],
#  }
#  spawar_user { 'fennor':
#    comment   => 'Fenno, Ryan',
#    uid       => '770',
#    secgroups => ['wheel', 'users'],
#  }
#  spawar_user { 'cburch':
#    comment   => 'Burch, Chris',
#    uid       => '790',
#    secgroups => ['wheel', 'users'],
#  }
   spawar_user { 'guzzardo':
     comment   => 'Guzzardo, Jane',
     uid       => '800',
     secgroups => ['wheel', 'users'],
   }
  spawar_user { 'oolivares':
    comment   => 'Olivares, Oliver',
    uid       => '810',
    secgroups => ['wheel', 'users'],
  }
  spawar_user { 'ordonezm':
    comment   => 'Ordonez, Marco',
    uid       => '820',
    secgroups => ['wheel', 'users'],
  }
  spawar_user { 'kaasaj':
    comment   => 'Kaasa, Jesse',
    uid       => '830',
    secgroups => ['wheel', 'users'],
  }
  spawar_user { 'stewartg':
    comment   => 'Stewart, Gary',
    uid       => '860',
    secgroups => ['wheel', 'users'],
  }
  spawar_user { 'luuphuos':
    comment   => 'Luu, Phuong',
    uid       => '920',
    secgroups => ['wheel', 'users'],
  }
  spawar_user { 'harrisrr':
    comment   => 'Harris, Rajah',
    uid       => '930',
    secgroups => ['wheel', 'users'],
  }
  spawar_user { 'craftd':
        comment   => 'Craft, Bowen',
        uid       => '960',
        secgroups => ['wheel', 'users'],
  }
  spawar_user { 'collincm':
        comment   => 'Collins, Cedrick',
        uid       => '970',
        secgroups => ['wheel', 'users'],
  }
  spawar_user { 'thomask':
        comment   => 'Thomas, Kip',
        uid       => '980',
        secgroups => ['wheel', 'users'],
  }
  spawar_user { 'simpsonb':
        comment   => 'Simpson, Brad',
        uid       => '1000',
        secgroups => ['wheel', 'users'],
  }
#    spawar_user { 'nguyenvt':
#        comment   => 'Nguyen, Vincent',
#        uid       => '1010',
#        secgroups => ['wheel', 'users'],
#  }
#    spawar_user { 'easomw':
#       comment   => 'Easom, William',
#       uid       => '1020',
#       secgroups => ['wheel', 'users'],
#  }
    spawar_user { 'smithak':
        comment   => 'Smith, Andrew',
        uid       => '1040',
        secgroups => ['wheel', 'users'],
  }
   spawar_user { 'marshalr':
        comment   => 'Marshall, Rob',
        uid       => '1050',
        secgroups => ['wheel', 'users'],
  }
   spawar_user { 'mcguiren':
        comment   => 'Mcguire, Nancy',
        uid       => '1060',
        secgroups => ['wheel', 'users'],
  }
   spawar_user { 'caldjas':
     comment   => 'Caldwell, Jason',
     uid       => '1070',
     secgroups => ['wheel', 'users'],
   }

  
}

define spawar_user_nomore {
  user { $name:
    ensure     => absent,
   }
   
  file { "/home/$name":
    ensure     => absent,
    force      => true,
   }
  }

  spawar_user_nomore { 'allendw':,
   }
  spawar_user_nomore { 'pjohnson':,
   }
  spawar_user_nomore { 'easomw':,
   }
  spawar_user_nomore { 'umitchell':,
   }
  spawar_user_nomore { 'morganme':,
   }
  spawar_user_nomore { 'ahainor':,
   }
  spawar_user_nomore { 'fennor':,
   }
  spawar_user_nomore { 'watsonjl':,
   }
  spawar_user_nomore { 'cburch':,
   }
  spawar_user_nomore { 'jsigh':,
   }
  spawar_user_nomore { 'netsecluscan':,
   }
  spawar_user_nomore { 'pricek':,
   }
  spawar_user_nomore { 'ahill':,
   }
  spawar_user_nomore { 'cpittman':,
   }
  spawar_user_nomore { 'lgeddis':,
   }
#  spawar_user_nomore { 'dcraft':,
#   }
  spawar_user_nomore { 'mcollins':,
   }
  spawar_user_nomore { 'carterja':,
   }
  spawar_user_nomore { 'clipuser':,
   }
  spawar_user_nomore { 'desantisj':,
   }
  spawar_user_nomore { 'grimmc':,
   }
  spawar_user_nomore { 'coopercj':,
   }
  spawar_user_nomore { 'ehiott':,
   }
  spawar_user_nomore { 'snelson':,
   } 
  spawar_user_nomore { 'lsoutiere':,
   }
  spawar_user_nomore { 'skeys':,
   }
#  spawar_user_nomore { 'bciano':,
#   }
  spawar_user_nomore { 'clay':,
   }
  spawar_user_nomore { 'cribbj':,
   }
  spawar_user_nomore { 'david':,
   }
  spawar_user_nomore { 'davisc':,
   }
  spawar_user_nomore { 'dshopp':,
   }
  spawar_user_nomore { 'hiteja':,
   }
  spawar_user_nomore { 'johnsonp':,
   }
  spawar_user_nomore { 'marshall':,
   }
  spawar_user_nomore { 'marshallr':,
   }
  spawar_user_nomore { 'mbucknam':,
   }
#  spawar_user_nomore { 'olivareso':,
#   }
  spawar_user_nomore { 'phuongl':,
   }
  spawar_user_nomore { 'repoutil':,
   }
  spawar_user_nomore { 'rmccarthy':,
   }
  spawar_user_nomore { 'ron':,
   }
  spawar_user_nomore { 'shaw':,
   }
  spawar_user_nomore { 'wlaforest':,
   }
#  spawar_user_nomore { 'agile':,
#   }
  spawar_user_nomore { 'cesira.maranon':,
   }
  spawar_user_nomore { 'congdonb':,
   }
#  spawar_user_nomore { 'mforrer':,
#   }
#  spawar_user_nomore { 'forrerm':,
#   }
  spawar_user_nomore { 'andy':,
   }
  spawar_user_nomore { 'annette':,
   }
  spawar_user_nomore { 'bcongdon':,
   }
  spawar_user_nomore { 'bdous':,
   }
  spawar_user_nomore { 'bredding':,
   }
  spawar_user_nomore { 'bruce':,
   }
  spawar_user_nomore { 'carlsond':,
   }
  spawar_user_nomore { 'cbarnes':,
   }
  spawar_user_nomore { 'ccarpentar':,
   }
  spawar_user_nomore { 'cclooper':,
   }
  spawar_user_nomore { 'chris':,
   }
  spawar_user_nomore { 'dwood':,
   }
#  spawar_user_nomore { 'dyoung':,
#   }
  spawar_user_nomore { 'forem':,
   }
  spawar_user_nomore { 'golubevn':,
   }
  spawar_user_nomore { 'jcheng':,
   }
  spawar_user_nomore { 'jnolan':,
   }
  spawar_user_nomore { 'john':,
   }
  spawar_user_nomore { 'jweeks':,
   }
  spawar_user_nomore { 'kmartin':,
   }
  spawar_user_nomore { 'kschweer':,
   }
  spawar_user_nomore { 'ksvetcos':,
   }
  spawar_user_nomore { 'lisbell':,
   }
  spawar_user_nomore { 'mike':,
   }
#  spawar_user_nomore { 'msp':,
#   }
  spawar_user_nomore { 'obanionc':,
   }
  spawar_user_nomore { 'oswaldj':,
   }
  spawar_user_nomore { 'patrick':,
   }
  spawar_user_nomore { 'paul':,
   }
  spawar_user_nomore { 'pkempter':,
   }
  spawar_user_nomore { 'prenzo':,
   }
  spawar_user_nomore { 'rashcraft':,
   }
  spawar_user_nomore { 'retina':,
   }
  spawar_user_nomore { 'rob':,
   }
  spawar_user_nomore { 'rradune':,
   }
  spawar_user_nomore { 'rwingfield':,
   }
  spawar_user_nomore { 'ryanj':,
   }
  spawar_user_nomore { 'segal':,
   }
  spawar_user_nomore { 'segalj':,
   }
  spawar_user_nomore { 'southerlandh':,
   }
#  spawar_user_nomore { 'stewartg':,
#   }
#  spawar_user_nomore { 'testy':,
#   }
  spawar_user_nomore { 'tmeeker':,
   }
  spawar_user_nomore { 'twinograd':,
   }
  spawar_user_nomore { 'wilsonw':,
   }
  spawar_user_nomore { 'woodd':,
   }
#  spawar_user_nomore { 'wwilson':,
#   }

define spawar_user_stale {
  user { $name:
    ensure     => absent,
   }
   # instead of deleting the user homedir, just change ownership to root
  file { "/home/$name":
    owner  => 'root',
    group  => 'root',
    recurse => true,
   } 
 }
  spawar_user_stale { 'andrell.shaw':,
   }
  spawar_user_stale { 'gstewart':,
   }
  spawar_user_stale { 'aprayther':,
   }
  spawar_user_stale { 'rmarshall':,
   }
  spawar_user_stale { 'vnguyen':,
   }
  spawar_user_stale { 'pluu':,
   }
  spawar_user_stale { 'rharris':,
   }
  spawar_user_stale { 'ccollins':,
   }
  spawar_user_stale { 'dcraft':,
   }
  spawar_user_stale { 'asmith':,
   }
  spawar_user_stale { 'bsimpson':,
   }
  spawar_user_stale { 'nguyenvt':,
   }
   
class spawar_files {

  file { '/etc/logrotate.conf':
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/spawar1/logrotate.conf',
  }

  file { '/etc/sysconfig/ip6tables':
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
    source => 'puppet:///modules/spawar1/ip6tables',
  }

  file { '/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL':
    owner  => 'root',
    group  => 'root',
    mode   => '0444',
    source => 'puppet:///modules/spawar1/RPM-GPG-KEY-EPEL',
  }

  file { '/etc/pki/rpm-gpg/VMWARE-PACKAGING-GPG-KEY.pub':
    owner  => 'root',
    group  => 'root',
    mode   => '0444',
    source => 'puppet:///modules/spawar1/VMWARE-PACKAGING-GPG-KEY.pub',
  }

  file { '/etc/pki/rpm-gpg/GPG-SPAWAR-KEY':
    owner  => 'root',
    group  => 'root',
    mode   => '0444',
    source => 'puppet:///modules/spawar1/GPG-SPAWAR-KEY',
  }

  # puppet user removed in /etc/puppet/modules/AC-17/manifests/init.pp
  file { "/etc/logrotate.d/puppet":
    ensure => absent,
  }
  
    # something done "quick and dirty" that is now being cleaned up
    # it was setting root/grub passwd, not bad
    # the second part was the scare stuff, dd to write zero's, or something, to completely fill
    # up each partition, based on hard coded info, bad if anything was anything else.
    # then it deleted the files used to zero.  this was all a workaround to a bug in vcenter
    # that did not allow the recovery of disc space on thin provisioned servers.
    # ******* remove this whold thing, along with any other files that were "cleaned up"
    # ******* at the next rev, once ALL machines have run this at least once
    # ******* that time will probably be when "roles" are introduced
    #
    # the root/grub passwd change part will be added to its own, rpm managed /etc/monthly/root-grub-passwd.sh script
  file { "/etc/cron.monthly/fixme.sh":
    ensure => absent,
  }

  file { '/root/HBSS':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }
 
  file { '/root/hbss/install-linux-LANT.sh':
    ensure => present,
    source => 'puppet:///modules/spawar1/install-linux-LANT.sh',
    owner  => 'root',
    group  => 'root',
    mode   => '0500',
  }
 
# append_if_no_such_line { "crontab":
# line => "*/5 * * * * root yum -y --exclude=puppet update defaults 2>&1 >/dev/null",
# file => "/etc/crontab",
# }
 
#  cron { 'update defaults RPM':
#    command => 'yum -y update defaults',
#    user    => root,
#    minute  => '*/5',
#  }

#  file { '/etc/nagios/nrpe.cfg':
#    ensure => present,
#    source => 'puppet:///modules/spawar1/nrpe.cfg',
#    owner  => 'root',
#    group  => 'root',
#    mode   => '0644',
#  }

#  file { '/etc/bacula':
#    ensure => directory,
#    owner  => 'root',
#    group  => 'root',
#    mode   => '0644',
#  }

#  file { '/etc/bacula/bacula-fd.conf':
#    ensure  => present,
#    content => template ("/etc/puppet/modules/spawar1/templates/bacula-fd.conf"),  # this one needs to be a "template" because we are using ruby vars,  Name = <%= hostname %>
#    owner   => 'root',
#    group   => 'root',
#    mode    => '0644',
#  }

# not delivering /etc/hosts any more.  sendmail is being replaced and we don't need it anymore
# this is also for retrofitting legacy, don't want to modify anything till there is a "role" in place for that server
#   file { "/etc/hosts":
#     ensure => present,
#     content => template ("/etc/puppet/modules/spawar1/templates/hosts"),  # this one needs to be a "template" because we are using ruby vars, <%= fqdn %> <%= hostname %>
#     owner => "root",
#     group => "root",
#     mode => 644;
#   }

    file { '/etc/cron.hourly/puppet-stig.sh':
    ensure => absent,
  }
    file { '/etc/cron.hourly/puppet-site.sh':
    ensure => absent,
  }
    file { '/etc/cron.hourly/spawar.sh':
    ensure => absent,
  }

  file { '/etc/crontab':
    ensure => present,
    source => 'puppet:///modules/spawar1/crontab',
    owner  => 'root',
    group  => 'root',
    mode   => '0600',
  }
 
# deliver with the rpm, so that defaults.rpm will cleanup if updated/uninstalled 
#  file { '/etc/cron.daily/spawar.sh':
#    ensure => present,
#    source => 'puppet:///modules/spawar1/spawar.sh',
#    owner  => 'root',
#    group  => 'root',
#    mode   => '0500',
#  }

  file { '/etc/cron.daily/uvscan.sh':
    ensure => absent,
    source => 'puppet:///modules/spawar1/uvscan.sh',
    owner  => 'root',
    group  => 'root',
    mode   => '0500',
  }

  file { '/etc/ntp/step-tickers':
    ensure => present,
    source => 'puppet:///modules/spawar1/step-tickers',
    owner => 'root',
    group => 'root',
    mode => '0644',
  }
    
  file { '/etc/ntp.conf':
    ensure => present,
    source => 'puppet:///modules/spawar1/ntp.conf',
    owner => 'root',
    group => 'root',
    mode => '0644',
  }

#  file { '/etc/resolv.conf':
#    ensure => present,
#    source => 'puppet:///modules/spawar1/resolv.conf',
#    owner  => 'root',
#    group  => 'root',
#    mode   => '0644',
#  }

  file { "/etc/cron.daily/sosreport.sh":
    ensure => present,
    source => 'puppet:///modules/spawar1/sosreport.sh',
    owner  => 'root',
    group  => 'root',
    mode   => '0500',
  }
}