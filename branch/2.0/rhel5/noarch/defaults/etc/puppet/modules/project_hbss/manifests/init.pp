class project_hbss {

    # rdt&e documents 591 needing to be bidirectional for hbss
    iptables { '000 spawar allow tcp 591 HBSS':
      proto => 'tcp',
      dport => '591',
      jump => 'ACCEPT',
    }

    # pulling $rhn from the /etc/puppet/manifests/exdata/*
    $rhn = extlookup('rhn')
      rhn_host{ "{$rhn}":
      rhn => "${rhn}",
    }

        # sets up the external $var to be used
        define rhn_host($rhn) {

            # wget hbss install binarie from $rhn
            exec { "wget hbss binary":
              command => "/usr/bin/wget -O - http://$rhn/hbss/install-hbss.sh > /root/install-hbss.sh",
            # unless  => "/usr/bin/file /root/install-hbss.sh",
            }
        }

    # hbss permissions
    file { "/root/install-hbss.sh":
      ensure => file,
      owner  => root,
      group  => root,
      mode   => '0700',
      require => Exec['wget hbss binary'],
    }

    # install hbss is it's not running already
    exec { 'install HBSS':
      command   => '/root/install-hbss.sh -i',
      unless    => '/bin/ps aux | /bin/grep cma | /bin/grep -v grep',
      logoutput => 'on_failure',
      require => File['/root/install-hbss.sh'],
    }

    # update hbss, to see if the downloaded binary is newer
    exec { 'update HBSS':
      command   => '/root/install-hbss.sh -u',
      require => File['/root/install-hbss.sh'],
    }

    # each time puppet runs (daily?) restart, after confirming running
    exec { 'restart HBSS':
      command   => '/sbin/service cma restart',
      logoutput => 'on_failure',
      require => Exec['install HBSS'],
    }


}
