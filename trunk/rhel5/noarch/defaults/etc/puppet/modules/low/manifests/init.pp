#include iptables

# the use of the prefix on the classes allows the use of the module autoloader
# to find classes that are included in modules
# So, in the following case iptables is a class found in the
#   <module path>/iptables/manifests/init.pp
# class spawar::spawar_iptables inherits iptables::iptables{

# $Id


class spawar_exec {

#  exec { 'install High HBSS':
#    command   => 'mkdir -p /root/HBSS && cd /root/HBSS && wget --no-check-certificate https://www.spawar-chas.navy.smil.mil/downloads/install-linux-46-1694.sh && chmod 700 /root/HBSS/*',
#    unless    => 'file /root/HBSS/install-linux-46-1694.sh',
#    logoutput => 'on_failure',
#  }

#  exec { 'install HBSS':
#    command   => '/root/HBSS/install-linux-rpm-46-1694.sh -i',
#    unless    => 'ps aux | grep cma | grep -v grep',
#    logoutput => 'on_failure',
#  }

  exec { 'install Low HBSS':
    command   => '/root/hbss/install-hbss.sh -i',
    unless    => 'ps aux | grep cma | grep -v grep',
    logoutput => 'on_failure',
  }
}
# upgrade hbss
# exec { 'rpm -qa | grep -i mfecma-4.5.0.1812;if [ \$? != 0 ];then rpm --erase MFEcma MFErt ; /root/HBSS/install-linux-45-1812.sh -u;fi':
# require => Class['files']
#      }

class spawar_files {
	
  # low and high hbss are going to differ because the mechanism for delivery has to be different at this point
  # in both cases i want to generisize the name to install-hbss.sh, in the hopes that i can make the delivery the same in the future
  # the actual file on the low side is delivered in the rpm because i can not get a reliable location to pull from
  # on the high side i am pulling a specific version, so every time they version (and change the fricking name) this will break
  file { '/root/hbss/install-hbss.sh':
    ensure => present,
    source => 'puppet:///modules/spawar1/install-linux-rpm-46-1694.sh',
    owner  => 'root',
    group  => 'root',
    mode   => '0500',
  }
 
  file { '/etc/ntp.conf':
    ensure => present,
    source => 'puppet:///modules/spawar1/low-ntp.conf',
    owner => 'root',
    group => 'root',
    mode => '0644',
  }

  file { '/etc/ntp/step-tickers':
    ensure => present,
    source => 'puppet:///modules/spawar1/low-step-tickers',
    owner => 'root',
    group => 'root',
    mode => '0644',
  }

  file { '/etc/resolv.conf':
    ensure => present,
    source => 'puppet:///modules/spawar1/low-resolv.conf',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

#  as long as the satelilte servers resolve to rhn, it does not matter, high low
#  file { "/etc/cron.daily/sosreport.sh":
#    ensure => present,
#    source => 'puppet:///modules/spawar1/low-sosreport.sh',
#    owner  => 'root',
#    group  => 'root',
#    mode   => '0500',
#  }
}

class postfix {

        service {
                "postfix":
                        ensure    => running,
                        hasstatus => true,
                        enable    => true;
        }

	# Guide Section 3.11.1.1
	# Install postfix
	
	package {
		"postfix":
			ensure    => installed;
	}

	# Disable network listening
	augeas {
		"postfix-network-listening":
			context => "/files/etc/postfix/main.cf",
			changes => "set inet_interfaces localhost",
			onlyif => "get inet_interfaces != localhost",
	}
	# setting up spawar relay
    augeas {
         "relayhost":
            context => "/files/etc/postfix/main.cf",
            changes => "set relayhost [smtp.chs.spawar.navy.mil]"
    }
	
}