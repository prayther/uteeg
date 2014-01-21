class project_users {
  Exec { path => [ "/usr/bin", "/usr/sbin", "/bin", "/sbin" ] }

  # user accounts must be created after CLIP content runs to ensure
  # that PASS_MIN_DAYS is set in /etc/login.defs (GEN000540)
  
  define managed_user($comment, $uid, $secgroups) {
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
      source => "puppet:///modules/project_users/bash_logout",
      # => "[ ! -f /home/$name/.bash_logout ]",
    }
    
    # home directory startup files
    file { "/home/$name/.bash_profile":
      ensure => file,
      owner  => $name,
      group  => $name,
      mode   => '0700',
      source => "puppet:///modules/project_users/bash_profile",
      # => "[ ! -f /home/$name/.bash_logout ]",
    }
    
        # home directory startup files
    file { "/home/$name/.bashrc":
      ensure => file,
      owner  => $name,
      group  => $name,
      mode   => '0700',
      source => "puppet:///modules/project_users/bashrc",
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
      source  => "puppet:///modules/project_users/$name.pub",
      require => File["/home/$name/.ssh"],
    }
  }

  #
  # create users
  #
  managed_user { 'retinascan':
    comment   => 'SPAWAR NetSec Retina scan acct',
    uid       => '603',
    secgroups => ['wheel', 'users'],
  }
  managed_user { 'sysutil':
    comment   => 'system utility account for automation purposes',
    uid       => '607',
    secgroups => ['wheel', 'users'],
  }
  # special section for sysutil
  file { "/home/sysutil/.ssh/id_rsa":
    ensure => directory,
    source => 'puppet:///modules/project_users/sysutil',
    owner  => 'sysutil',
    group  => 'sysutil',
    mode   => '0600',
  }
  # this is not needed because of the authorized_keys file, but is more obvious
  file { "/home/sysutil/.ssh/id_rsa.pub":
    ensure => directory,
    source => 'puppet:///modules/project_users/sysutil.pub',
    owner  => 'sysutil',
    group  => 'sysutil',
    mode   => '0600',
  }
  managed_user { 'aprayther':
    comment   => 'Prayther, Aaron, LCE aprayther@lce.com, 843 218 2178',
    uid       => '600',
    secgroups => ['wheel', 'users'],
  }
  managed_user { 'rayjd':
    comment   => 'Ray, Jeffrey D., Barling Bay jray@barlingbay.com',
    uid       => '610',
    secgroups => ['wheel', 'users'],
  }
  managed_user { 'pricek':
    comment   => 'Price K., Kevin, kevin.l.price@saic.com',
    uid       => '630',
    secgroups => ['wheel', 'users'],
  }
#  managed_user { 'carterja':
#    comment   => 'Carter, Josh',
#    uid       => '670',
#    secgroups => ['wheel', 'users'],
#  }
#  managed_user { 'morganme':
#    comment   => 'Morgan, Molly',
#    uid       => '710',
#    secgroups => ['wheel', 'users'],
#  }
  managed_user { 'andrell.shaw':
    comment   => 'Shaw, Andrell',
    uid       => '730',
    secgroups => ['wheel', 'users'],
  }
#  managed_user { 'skeys':
#    comment   => 'Keys, Sabrina',
#    uid       => '750',
#    secgroups => ['wheel', 'users'],
#  }
  managed_user { 'fennor':
    comment   => 'Fenno, Ryan',
    uid       => '770',
    secgroups => ['wheel', 'users'],
  }
#  managed_user { 'cburch':
#    comment   => 'Burch, Chris',
#    uid       => '790',
#    secgroups => ['wheel', 'users'],
#  }
  managed_user { 'oolivares':
    comment   => 'Olivares, Oliver',
    uid       => '810',
    secgroups => ['wheel', 'users'],
  }
  managed_user { 'ordonezm':
    comment   => 'Ordonez, Marco',
    uid       => '820',
    secgroups => ['wheel', 'users'],
  }
  managed_user { 'kaasaj':
    comment   => 'Kaasa, Jesse',
    uid       => '830',
    secgroups => ['wheel', 'users'],
  }
  managed_user { 'ahainor':
    comment   => 'Hainor, Aaron',
    uid       => '840',
    secgroups => ['wheel', 'users'],
  }
#  managed_user { 'ehiott':
#    comment   => 'Hiott, Erica',
#    uid       => '850',
#    secgroups => ['wheel', 'users'],
#  }
  managed_user { 'gstewart':
    comment   => 'Stewart, Gary',
    uid       => '860',
    secgroups => ['wheel', 'users'],
  }
#  managed_user { 'jsigh':
#    comment   => 'Sigh, John',
#    uid       => '870',
#    secgroups => ['wheel', 'users'],
#  }
#  managed_user { 'lgeddis':
#    comment   => 'Geddis, Lacreshia',
#    uid       => '880',
#    secgroups => ['wheel', 'users'],
#  }
  managed_user { 'mcollins':
    comment   => 'Collins, MaRenins',
    uid       => '890',
    secgroups => ['wheel', 'users'],
  }
  managed_user { 'pjohnson':
    comment   => 'Johnson, Patrick',
    uid       => '910',
    secgroups => ['wheel', 'users'],
  }
  managed_user { 'pluu':
    comment   => 'Luu, Phuong',
    uid       => '920',
    secgroups => ['wheel', 'users'],
  }
  managed_user { 'rharris':
    comment   => 'Harris, Rajah',
    uid       => '930',
    secgroups => ['wheel', 'users'],
  }
#  managed_user { 'snelson':
#    comment   => 'Nelson, Shevon',
#    uid       => '940',
#    secgroups => ['wheel', 'users'],
#  }
  managed_user { 'umitchell':
    comment   => 'Mitchell, Ulonda',
    uid       => '950',
    secgroups => ['wheel', 'users'],
  }
  managed_user { 'dcraft':
        comment   => 'Craft, Bowen',
        uid       => '960',
        secgroups => ['wheel', 'users'],
  }
  managed_user { 'ccollins':
        comment   => 'Collins, Cedrick',
        uid       => '970',
        secgroups => ['wheel', 'users'],
  }
  managed_user { 'thomask':
        comment   => 'Thomas, Kip',
        uid       => '980',
        secgroups => ['wheel', 'users'],
  }
#  managed_user { 'ahill':
#       comment   => 'Hill, Alan',
#       uid       => '990',
#       secgroups => ['wheel', 'users'],
# }    
  managed_user { 'bsimpson':
        comment   => 'Simpson, Brad',
        uid       => '1000',
        secgroups => ['wheel', 'users'],
  }
    managed_user { 'allendw':
        comment   => 'Allen, Darryl',
        uid       => '5414',
        secgroups => ['wheel', 'users'],
  }
#    managed_user { 'openuid':
#       comment   => 'Dupliate, User',
#       uid       => '1010',
#       secgroups => ['wheel', 'users'],
#  }
    managed_user { 'easomw':
        comment   => 'Easom, William',
        uid       => '1020',
        secgroups => ['wheel', 'users'],
  }
    managed_user { 'cpittman':
        comment   => 'Pittman, Charles',
        uid       => '1030',
        secgroups => ['wheel', 'users'],
  }

}

define managed_user_nomore {
  user { $name:
    ensure     => absent,
   }
   # instead of deleting the user homedir, just change ownership to root
  file { "/home/$name":
    owner  => 'root',
    group  => 'root',
    recurse => true,
   }

#  file { "/home/$name":
#    ensure     => absent,
#    force      => true,
#   }

}

#  managed_user_nomore { 'morganme':,
#   }
#  managed_user_nomore { 'watsonjl':,
#   }

