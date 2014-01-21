# Global Settings for puppet are stored in this file

$hosttemplates = [ "linux-server" ]
$hostgroups = [ "servers" ]
$search_domains = [ "chs.spawar.navy.mil spawar.navy.mil" ]
$dns_servers = [ "150.125.132.20","150.125.132.24" ]

#$ntpd_servers = [ "ntp.$domain" ]
$ntpd_servers = [ "150.125.14.5","150.125.132.24" ]

#$syslog_servers = [ "127.0.0.1" ]
#$syslog_client_options = "-m 0"
#$syslog_server_options = "-m 0 -r -s $domain"
