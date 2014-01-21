class syslog() {
   
    file {"/etc/syslog.conf":
	ensure => present,
        content => template("/etc/puppet/modules/syslog/templates/syslog.conf"),
        notify => Service['syslog'],
    }
    
    service {"syslog": 
         ensure => running,
      }

}



