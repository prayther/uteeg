class project_nagios {
    # Nagios nrpe packages
    package { [ 'nrpe',
                'nagios-plugins-all' ]:
      ensure  => installed,
#      require => Package['nrpe'],
     }
#  iptables { '000 spawar allow tcp 5666 Nagios':
#    proto => 'tcp',
#    dport => '5666',
#    jump => 'ACCEPT',
#     }
        # define the service so that i can refresh, once, one config changes below
        service { "nrpe":
                ensure => running,
                enable => true,
        }
        # custom check command /usr/lib64/nagios/plugins/check_cpu
        file {
                "/usr/lib64/nagios/plugins/check_cpu.sh":
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/check_cpu.sh"),
        }
        # custom check command /usr/lib64/nagios/plugins/check_selinux
        file {
                "/usr/lib64/nagios/plugins/check_selinux":
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/check_selinux"),
        }
        # custom check command /usr/lib64/nagios/plugins/check_mem
        file {
                "/usr/lib64/nagios/plugins/check_mem":
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/check_mem"),
        }
        # nrpe.cfg file, main modifications are removing the default checks at the bottom, configure include_dir=/etc/nrpe.d and allowing nets.chs.spawar.navy.mil be nagios server
        file {
                "/etc/nagios/nrpe.cfg":
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/nrpe.cfg"),
        }
        # the host.cfg file to send to nagios server, to define this host
        file {
                "/tmp/$hostname.cfg":
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/host.cfg.erb"),
        }
        # this first exec is just to fix broken keys so the rest of the rsync commands work
        exec { "/usr/bin/ssh-keyscan -t rsa nets >> ~sysutil/.ssh/known_hosts":
        onlyif => "test `/bin/grep nets ~sysutil/.ssh/known_hosts | wc -l` -eq 0"
         }
        exec { "/bin/su -l sysutil -c '/usr/bin/rsync -a /tmp/$hostname.cfg sysutil@nets:sim/rhel5/' && /bin/rm -f /tmp/$hostname.cfg": }
        # cpu check.  one file goes to nagios server, the other is local to define thresholds
        file {
                "/tmp/nrpe_cpu_$hostname.cfg":
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/nrpe_cpu.cfg.erb"),
        }
        exec { "/bin/su -l sysutil -c '/usr/bin/rsync -a /tmp/nrpe_cpu_$hostname.cfg sysutil@nets:sim/services/$hostname/' && ssh -o StrictHostKeyChecking=no -t -i /home/sysutil/.ssh/id_rsa sysutil@nets /bin/chmod -R 755 sim/services/$hostname && /bin/rm -f /tmp/nrpe_cpu_$hostname.cfg": } 
        file {
                "/etc/nrpe.d/check_cpu.cfg":
                        notify  => Service["nrpe"],
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/check_cpu.cfg.erb"),
        }
        # configure host alive check.  one file goes to nagios server, the other is local to define thresholds
        file {
                "/tmp/nrpe_host_alive_$hostname.cfg":
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/nrpe_host_alive.cfg.erb"),
        }
        exec { "/bin/su -l sysutil -c '/usr/bin/rsync -a /tmp/nrpe_host_alive_$hostname.cfg sysutil@nets:sim/services/$hostname/' && ssh -o StrictHostKeyChecking=no -t -i /home/sysutil/.ssh/id_rsa sysutil@nets /bin/chmod -R 755 sim/services/$hostname && /bin/rm -f /tmp/nrpe_host_alive_$hostname.cfg": } 
        file {
                "/etc/nrpe.d/check_host_alive.cfg":
                        notify  => Service["nrpe"],
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/check_host_alive.cfg.erb"),
        }
        # hbss check.  one file goes to nagios server, the other is local to define thresholds
        file {
                "/tmp/nrpe_hbss_$hostname.cfg":
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/nrpe_hbss.cfg.erb"),
        }
        exec { "/bin/su -l sysutil -c '/usr/bin/rsync -a /tmp/nrpe_hbss_$hostname.cfg sysutil@nets:sim/services/$hostname/' && ssh -o StrictHostKeyChecking=no -t -i /home/sysutil/.ssh/id_rsa sysutil@nets /bin/chmod -R 755 sim/services/$hostname && /bin/rm -f /tmp/nrpe_hbss_$hostname.cfg": }
        file {
                "/etc/nrpe.d/check_hbss.cfg":
                        notify  => Service["nrpe"],
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/check_hbss.cfg.erb"),
        }
        # load check.  one file goes to nagios server, the other is local to define thresholds
        file {
                "/tmp/nrpe_load_$hostname.cfg":
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/nrpe_load.cfg.erb"),
        }
        exec { "/bin/su -l sysutil -c '/usr/bin/rsync -a /tmp/nrpe_load_$hostname.cfg sysutil@nets:sim/services/$hostname/' && ssh -o StrictHostKeyChecking=no -t -i /home/sysutil/.ssh/id_rsa sysutil@nets /bin/chmod -R 755 sim/services/$hostname && /bin/rm -f /tmp/nrpe_load_$hostname.cfg": }
        file {
                "/etc/nrpe.d/check_load.cfg":
                        notify  => Service["nrpe"],
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/check_load.cfg.erb"),
        }
        # partions check.  one file goes to nagios server, the other is local to define thresholds
        file {
                "/tmp/nrpe_partitions_$hostname.cfg":
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/nrpe_partitions.cfg.erb"),
        }
        exec { "/bin/su -l sysutil -c '/usr/bin/rsync -a /tmp/nrpe_partitions_$hostname.cfg sysutil@nets:sim/services/$hostname/' && ssh -o StrictHostKeyChecking=no -t -i /home/sysutil/.ssh/id_rsa sysutil@nets /bin/chmod -R 755 sim/services/$hostname && /bin/rm -f /tmp/nrpe_partitions_$hostname.cfg": }
        file {
                "/etc/nrpe.d/check_partitions.cfg":
                        notify  => Service["nrpe"],
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/check_partitions.cfg.erb"),
        }
        # puppet check.  one file goes to nagios server, the other is local to define thresholds
        file {
                "/tmp/nrpe_puppet_$hostname.cfg":
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/nrpe_puppet.cfg.erb"),
        }
        exec { "/bin/su -l sysutil -c '/usr/bin/rsync -a /tmp/nrpe_puppet_$hostname.cfg sysutil@nets:sim/services/$hostname/' && ssh -o StrictHostKeyChecking=no -t -i /home/sysutil/.ssh/id_rsa sysutil@nets /bin/chmod -R 755 sim/services/$hostname && /bin/rm -f /tmp/nrpe_puppet_$hostname.cfg": }
        file {
                "/etc/nrpe.d/check_puppet.cfg":
                        notify  => Service["nrpe"],
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/check_puppet.cfg.erb"),
        }
        # selinux check.  one file goes to nagios server, the other is local to define thresholds
        file {
                "/tmp/nrpe_selinux_$hostname.cfg":
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/nrpe_selinux.cfg.erb"),
        }
        exec { "/bin/su -l sysutil -c '/usr/bin/rsync -a /tmp/nrpe_selinux_$hostname.cfg sysutil@nets:sim/services/$hostname/' && ssh -o StrictHostKeyChecking=no -t -i /home/sysutil/.ssh/id_rsa sysutil@nets /bin/chmod -R 755 sim/services/$hostname && /bin/rm -f /tmp/nrpe_selinux_$hostname.cfg": }
        file {
                "/etc/nrpe.d/check_selinux.cfg":
                        notify  => Service["nrpe"],
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/check_selinux.cfg.erb"),
        }
        # swap check.  one file goes to nagios server, the other is local to define thresholds
        file {
                "/tmp/nrpe_swap_$hostname.cfg":
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/nrpe_swap.cfg.erb"),
        }
        exec { "/bin/su -l sysutil -c '/usr/bin/rsync -a /tmp/nrpe_swap_$hostname.cfg sysutil@nets:sim/services/$hostname/' && ssh -o StrictHostKeyChecking=no -t -i /home/sysutil/.ssh/id_rsa sysutil@nets /bin/chmod -R 755 sim/services/$hostname && /bin/rm -f /tmp/nrpe_swap_$hostname.cfg": }
        file {
                "/etc/nrpe.d/check_swap.cfg":
                        notify  => Service["nrpe"],
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/check_swap.cfg.erb"),
        }
        # ssh -o StrictHostKeyChecking=no check.  one file goes to nagios server, the other is local to define thresholds
        file {
                "/tmp/nrpe_ssh_$hostname.cfg":
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/nrpe_ssh.cfg.erb"),
        }
        exec { "/bin/su -l sysutil -c '/usr/bin/rsync -a /tmp/nrpe_ssh_$hostname.cfg sysutil@nets:sim/services/$hostname/' && ssh -o StrictHostKeyChecking=no -t -i /home/sysutil/.ssh/id_rsa sysutil@nets /bin/chmod -R 755 sim/services/$hostname && /bin/rm -f /tmp/nrpe_ssh_$hostname.cfg": }
        file {
                "/etc/nrpe.d/check_ssh.cfg":
                        notify  => Service["nrpe"],
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/check_ssh.cfg.erb"),
        }
        # procs check.  one file goes to nagios server, the other is local to define thresholds
        file {
                "/tmp/nrpe_total_procs_$hostname.cfg":
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/nrpe_total_procs.cfg.erb"),
        }
        exec { "/bin/su -l sysutil -c '/usr/bin/rsync -a /tmp/nrpe_total_procs_$hostname.cfg sysutil@nets:sim/services/$hostname/' && ssh -o StrictHostKeyChecking=no -t -i /home/sysutil/.ssh/id_rsa sysutil@nets /bin/chmod -R 755 sim/services/$hostname && /bin/rm -f /tmp/nrpe_total_procs_$hostname.cfg": }
        file {
                "/etc/nrpe.d/check_total_procs.cfg":
                        notify  => Service["nrpe"],
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/check_total_procs.cfg.erb"),
        }
        # users check.  one file goes to nagios server, the other is local to define thresholds
        file {
                "/tmp/nrpe_users_$hostname.cfg":
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/nrpe_users.cfg.erb"),
        }
        exec { "/bin/su -l sysutil -c '/usr/bin/rsync -a /tmp/nrpe_users_$hostname.cfg sysutil@nets:sim/services/$hostname/' && ssh -o StrictHostKeyChecking=no -t -i /home/sysutil/.ssh/id_rsa sysutil@nets /bin/chmod -R 755 sim/services/$hostname && /bin/rm -f /tmp/nrpe_users_$hostname.cfg": }
        file {
                "/etc/nrpe.d/check_users.cfg":
                        notify  => Service["nrpe"],
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/check_users.cfg.erb"),
        }
        # zombies check.  one file goes to nagios server, the other is local to define thresholds
        file {
                "/tmp/nrpe_zombie_procs_$hostname.cfg":
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/nrpe_zombie_procs.cfg.erb"),
        }
        exec { "/bin/su -l sysutil -c '/usr/bin/rsync -a /tmp/nrpe_zombie_procs_$hostname.cfg sysutil@nets:sim/services/$hostname/' && ssh -o StrictHostKeyChecking=no -t -i /home/sysutil/.ssh/id_rsa sysutil@nets /bin/chmod -R 755 sim/services/$hostname && /bin/rm -f /tmp/nrpe_zombie_procs_$hostname.cfg": }
        file {
                "/etc/nrpe.d/check_zombie_procs.cfg":
                        notify  => Service["nrpe"],
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/check_zombie_procs.cfg.erb"),
        }
        # mem check.  one file goes to nagios server, the other is local to define thresholds
        file {
                "/tmp/nrpe_mem_$hostname.cfg":
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/nrpe_mem.cfg.erb"),
        }
        exec { "/bin/su -l sysutil -c '/usr/bin/rsync -a /tmp/nrpe_mem_$hostname.cfg sysutil@nets:sim/services/$hostname/' && ssh -o StrictHostKeyChecking=no -t -i /home/sysutil/.ssh/id_rsa sysutil@nets /bin/chmod -R 755 sim/services/$hostname && /bin/rm -f /tmp/nrpe_mem_$hostname.cfg": }
        file {
                "/etc/nrpe.d/check_mem.cfg":
                        notify  => Service["nrpe"],
                        owner   => "root",
                        group   => "root",
                        mode    => 755,
                        content => template("project_nagios/check_mem.cfg.erb"),
        }


}
