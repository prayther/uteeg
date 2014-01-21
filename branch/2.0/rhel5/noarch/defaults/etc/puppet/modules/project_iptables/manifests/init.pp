class project_iptables {

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
