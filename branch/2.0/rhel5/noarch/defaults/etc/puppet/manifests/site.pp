$extlookup_datadir = "/etc/puppet/manifests/extdata"
$extlookup_precedence = ["%{fqdn}", "domain_%{domain}", "common"]

import "settings.pp"

# The array tells the code how to resolve values, first it will try 
# to find it in web1.myclient.com.csv then in domain_myclient.com.csv and finally in common.csv
# It will read from all of them, not just the first.  This allows global and role level granularity

# extdata/common.csv will contain global configs, like that of NIPR/SIPR.
# 2 main configs will drive all infrastructure and server/service configuration
# all other configs like the puppet csv files here will be generated from the...
# hosts.master file for the servers and config.cfg for all project info, release channels and names
# service names, contact info, etc, etc.

