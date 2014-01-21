#!/usr/bin/python

import xmlrpclib
import csv
import socket
import StringIO
import os

#spacewalkserver = "163.240.36.253"
spacwalkuser = "admin-ges"
spacewalkpass = "munge"


hostnamefqdn = socket.getfqdn()
hostnamecsv = csv.reader(StringIO.StringIO(hostnamefqdn), delimiter='.')
for a in hostnamecsv:
  hostname = str(a[0])

ifile  = open('/etc/puppet/manifests/nodes/hosts.master.txt', "rb")
reader = csv.reader(ifile, delimiter=',')
for i in reader:
  if hostname == i[0]:


      SPACEWALKID = int(i[48])

      client = xmlrpclib.ServerProxy('https://163.240.36.253/rpc/api')
      key = client.auth.login((spacwalkuser), (spacewalkpass))
      client.system.scap.scheduleXccdfScan(key, (SPACEWALKID),
          '/root/U_RedHat_5-V1R4_STIG_Benchmark-xccdf.xml',
          '--profile MAC-3_Classified')

os.system("rhn_check")