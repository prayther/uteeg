class sysctl {
        # LNX00520 CAT II Description: The /etc/sysctl.conf file is more permissive than 600
        file {
                "/etc/sysctl.conf":
                owner   => "root",
                group   => "root",
                mode    => 600,
        }
#        augeas {
#                "sysctl.conf GEN003600":
#                        context => "/files/etc/sysctl.conf",
#                        lens    => "sysctl.conf.lns",
#                        incl    => "/etc/sysctl.conf",
#                        changes => "set net.ipv4.tcp_max_syn_backlog = 1280";
#        }

}
