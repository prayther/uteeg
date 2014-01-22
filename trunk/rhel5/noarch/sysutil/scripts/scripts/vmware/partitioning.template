clearpart --all --drives=sda
partition /boot --fstype ext3 --size=400
partition pv.01 --size=250 --grow
volgroup vg00 pv.01
logvol swap --fstype swap --name=swap --vgname=vg00 --size=<swap>
logvol / --fstype ext3 --name=root --vgname=vg00 --size=<root>
logvol /var --fstype ext3 --name=var --vgname=vg00 --size=<var>
logvol /var/log --fstype ext3 --name=varlog --vgname=vg00 --size=<varlog>
logvol /var/log/audit --fstype ext3 --name=varlogaudit --vgname=vg00 --size=<varlogaudit>
logvol /home --fstype ext3 --name=home --vgname=vg00 --size=<home>
logvol /opt --fstype ext3 --name=opt --vgname=vg00 --size=<opt>
logvol /data --fstype ext3 --name=data --vgname=vg00 --size=<data>
logvol /usr --fstype ext3 --name=usr --vgname=vg00 --size=<usr>
logvol /tmp --fstype ext3 --name=tmp --vgname=vg00 --size=<tmp>
