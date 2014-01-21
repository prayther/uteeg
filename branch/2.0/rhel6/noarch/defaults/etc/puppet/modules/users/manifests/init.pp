class users {
  Exec { path => [ "/usr/bin", "/usr/sbin", "/bin", "/sbin" ] }

  # user accounts must be created after CLIP content runs to ensure
  # that PASS_MIN_DAYS is set in /etc/login.defs (GEN000540)
  
  define user($comment, $uid, $secgroups) {
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
  #user { 'netsecluscan':
  #  comment   => 'SPAWAR NetSec Retina scan acct',
  #  uid       => '603',
  #  secgroups => ['wheel', 'users'],
  #}
define user_nomore {
  user { $name:
    ensure     => absent,
   }
   # instead of deleting the user homedir, just change ownership to root
#  file { "/home/$name":
#    owner  => 'root',
#    group  => 'root',
#    recurse => true,
#   }
  file { "/home/$name":
    ensure     => absent,
    force      => true,
   }
}
  user_nomore { 'puppet':,
   }
  user_nomore { 'avahi-autoipd':,
   }
  user_nomore { 'ftp':,
   }
  user_nomore { 'halt':,
   }
  user_nomore { 'shutdown':,
   }
  user_nomore { 'reboot':,
   }
  user_nomore { 'games':,
   }
  user_nomore { 'news':,
   }
  user_nomore { 'sync':,
   }
  user_nomore { 'operator':,
   }
  user_nomore { 'gopher':,
   }
  user_nomore { 'nfsnobody':,
   }
# this is for a bug in puppet that requires this group to be availble in order to eliminate an err:
group { "puppet":
    ensure => "present",
} 
}
