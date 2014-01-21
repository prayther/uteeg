# Global Settings for puppet are stored in this file

#$dns_server = "dns.$domain"
$dns_server = "150.125.132.20,150.125.132.24"

#$ntpd_servers = [ "ntp.$domain" ]
$ntpd_servers = [ "150.125.75.212", "150.125.75.156" ]

$syslog_servers = [ "127.0.0.1", "127.0.0.1" ]
$syslog_client_options = "-m 0"
$syslog_server_options = "-m 0 -r -s $domain"

$hosttemplates = "linux-server"
$hostgroups = "services"