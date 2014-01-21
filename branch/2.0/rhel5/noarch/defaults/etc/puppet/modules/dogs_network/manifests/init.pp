class dogs_network {
# /etc/puppet/manifests/site.pp references where the external vars are defined,
# multiple csv files located at /etc/puppet/manifests/extdata
# makes it into a configuration file of sorts and separates "data" from puppet code
# making it much easier to see and understand.

# networking section

  $devicelo            = extlookup('devicelo')
  $ipaddrlo            = extlookup('ipaddrlo')
  $netmasklo           = extlookup('netmasklo')
  $networklo           = extlookup('networklo')
  $namelo              = extlookup('namelo')
  $broadcastlo         = extlookup('broadcastlo')
  $uplo                = extlookup('uplo')
  $deviceeth0          = extlookup('deviceeth0')
  $ipaddreth0          = extlookup('ipaddreth0')
  $netmasketh0         = extlookup('netmasketh0')
  $networketh0         = extlookup('networketh0')
  $nameeth0            = extlookup('nameeth0')
  $broadcasteth0       = extlookup('broadcasteth0')
  $hwaddreth0          = extlookup('hwaddreth0')
  $upeth0              = extlookup('upeth0')
  $gatewayeth0         = extlookup('gatewayeth0')
  $ipv6initeth0        = extlookup('ipv6initeth0')
  $networking_ipv6eth0 = extlookup('networking_ipv6eth0')
  $hostnameeth0        = extlookup('hostnameeth0')
  $networkingeth0      = extlookup('networkingeth0')
#  $dnsserver           = extlookup('dnsserver')
#  $dnsserver1          = extlookup('dnsserver1')
  $searchdomain        = extlookup('searchdomain')

   managed_interface{ "${devicelo}":
       device          => "${devicelo}",
       ipaddr          => "${ipaddrlo}",
       netmask         => "${netmasklo}",
       network         => "${networklo}",
       name            => "${namelo}",
       broadcast       => "${broadcastlo}",
       up              => "${uplo}",
   }

   managed_interface{ "${deviceeth0}":
       # /etc/sysconfig/network-scripts/ifcfg-eth0
       device          => "${deviceeth0}",
       ipaddr          => "${ipaddreth0}",
       netmask         => "${netmasketh0}",
       network         => "${networketh0}",
       name            => "${nameeth0}",
       broadcast       => "${broadcasteth0}",
       hwaddr          => "${hwaddreth0}",
       up              => "${upeth0}",
       # /etc/sysconfig/network
       gateway         => "${gatewayeth0}",
       ipv6init        => "${ipv6initeth0}",
       networking_ipv6 => "${networking_ipv6eth0}",
       hostname        => "${hostnameeth0}",
       networking      => "${networkingeth0}",
       # /etc/postfix/main.cf
#       relayhost       => "${relayhost}",
   }

#   managed_interface{ "eth1":
#       # /etc/sysconfig/network-scripts/ifcfg-eth0
#       device  => "eth1",
#       ipaddr  => "192.168.1.3",
#       netmask => "255.255.255.0",
#       network => "192.168.1.0",
#       name => "eth1",
#       broadcast => "192.168.1.255",
#       hwaddr  => "00:50:56:00:00:E5",
#       up  => true,
#   }

#   managed_interface{ "eth0:0":
#       # /etc/sysconfig/network-scripts/ifcfg-eth0
#       device  => "eth0:0",
#       ipaddr  => "192.168.1.3",
#       netmask => "255.255.255.0",
#       network => "192.168.1.0",
#       name => "eth0:0",
#       broadcast => "192.168.1.255",
#       hwaddr  => "00:50:56:00:00:E4",
#       up  => true,
#   }


        define managed_interface($device, $ipaddr, $netmask, $name, $broadcast, $up=true, $network="", $hwaddr="", $gateway="", $ipv6init="", $hostname="", $networking_ipv6="", $networking="") {

    ##
    ## Handle RedHat derivatives
    ##
    if ($operatingsystem == redhat) or ($operatingsystem == centos) or ($operatingsystem == fedora) {
        if ($up) {
            $onBoot = "yes"
        } else {
            $onBoot = "no"
        }

        augeas { "main-$device":
            context => "/files/etc/sysconfig/network-scripts/ifcfg-$device",
            changes => [
                "set DEVICE $device",
                "set BOOTPROTO none",
                "set ONBOOT $onBoot",
                "set NETMASK $netmask",
                "set NAME $name",
                "set BROADCAST $broadcast",
                "set IPADDR $ipaddr",
            ],
        }

        if ($network!="") {
            augeas { "network-$device":
                context => "/files/etc/sysconfig/network-scripts/ifcfg-$device",
                changes => [
                    "set NETWORK $network",
                ],
            }
        }

        if ($hwaddr!="") {
            augeas { "mac-$device":
                context => "/files/etc/sysconfig/network-scripts/ifcfg-$device",
                changes => [
                    "set HWADDR $hwaddr",
                ],
            }
        }

        if ($gateway!="") {
            augeas { "gateway-$device":
                context => "/files/etc/sysconfig/network",
                changes => [
                    "set GATEWAY $gateway",
                ],
            }
        }

        if ($ipv6init !="") {
            augeas { "ipv6init-$device":
                context => "/files/etc/sysconfig/network",
                changes => [
                    "set IPV6INIT $ipv6init",
                ],
            }
        }

        if ($hostname !="") {
            augeas { "hostname-$device":
                context => "/files/etc/sysconfig/network",
                changes => [
                    "set HOSTNAME $hostname",
                ],
            }
        }

        if ($networking !="") {
            augeas { "networking-$device":
                context => "/files/etc/sysconfig/network",
                changes => [
                    "set NETWORKING $networking",
                ],
            }
        }

        if ($networking_ipv6 !="") {
            augeas { "networking_ipv6-$device":
                context => "/files/etc/sysconfig/network",
                changes => [
                    "set NETWORKING_IPV6 $networking_ipv6",
                ],
            }
        }

        if $up {
            exec {"ifup-$device":
                command => "/sbin/ifup $device",
                unless  => "/sbin/ifconfig | grep $device",
                require => Augeas["main-$device"],
            }
        } else {
            exec {"ifdown-$device":
                command => "/sbin/ifconfig $device down",
                onlyif  => "/sbin/ifconfig | grep $device",
            }
        }

# postfix, moved to postfix module
#        if ($relayhost !="") {
#            augeas { "relayhost":
#                context => "/files/etc/postfix/main.cf",
#                lens    => "postfix_main.lns",
#                incl    => "/etc/postfix/main.cf",
#                changes => "set relayhost [${relayhost}]",
#                onlyif  => "get relayhost != [${relayhost}]";
#            }
#        }





    }
  }
}
