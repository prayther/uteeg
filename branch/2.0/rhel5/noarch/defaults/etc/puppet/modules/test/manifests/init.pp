$extlookup_datadir    = "/etc/puppet/modules/test/manifests/data"
$extlookup_precedence = [$environment, 'common']
 
node 'dogs' {
  include dns
}
 
class dns {
  $dnsserver    = extlookup('dnsserver')
  $searchdomain = extlookup('searchdomain')
 
  file { '/etc/resolv.conf':
    content => "search ${searchdomain}\n nameserver ${dnsserver}\n",
  }
}
