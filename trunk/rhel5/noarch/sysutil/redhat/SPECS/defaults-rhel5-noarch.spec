# $Id: defaults.spec 807.60...38.42.18:35:05Z sysutil $
Name:  defaults-rhel5-noarch
# use this exact versioning scheme, it was a pain, to get this to auto increment with sed.  even though sed was told to act on only the first instance of finding "the key value" 
# you can manually set the first 2 csv delimited fields, 2.0.  leave the v.? for the rpmbuild.sh script to find and increment the 4th field
Version: 2.0.v.18
Release:  1%{?dist}
Summary:  Default SPAWAR configuration/STIG RHEL5.X Puppet content
Packager: Aaron Prayther aprayther@lce.com Life Cycle Engineering
Group: Development/Tools
License:  GPL
URL: https://software.forge.mil
Source:  defaults-rhel5-noarch.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch: noarch
#BuildRequires:
Requires: puppet

%description
This package delivers the modified USGCB & CLIP puppet content and custom code created at SPAWAR to address STIG on rhel5.x servers and some local configuration.


# The scriptlets in %pre and %post are respectively run before and after a package is installed. The scriptlets %preun and %postun are run before and after a package is uninstalled. The scriptlets %pretrans and %posttrans are run at start and end of a transaction. On upgrade, the scripts are run in the following order:

# %pretrans of new package
# %pre of new package
# (package install)
# %post of new package
# %preun of old package
# (removal of old package)
# %postun of old package
# %posttrans of new package

%prep
%setup -q -n defaults

%build

%pre

# this is just taking a src file and moving it around /src/redhat/* and /var/tmp/ to keep things straight.. then cleanup.
%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/defaults
rsync -av $RPM_BUILD_DIR/defaults/* $RPM_BUILD_ROOT/


%post
# this enables puppet on this node
node=`hostname` 
echo "node '$node' inherits workstation {}" >> /etc/puppet/manifests/nodes/nodes.pp
#for i in `cat /etc/fstab | grep ext3 | awk '{ print $2 }'`;do cd $i && dd if=/dev/zero of=zeros.txt ; rm -f zeros.txt;done
#/etc/cron.monthly/fixme.sh &

# this will pull out the first octet of the ip 150 / 205 to decide if it is high or low
# then is sets the correct "role" in puppet manifest
shortname=`hostname | awk -F. '{ print $1 }'`
#if [ `grep $shortname /etc/puppet/manifests/nodes/hosts.master.txt | awk -F, '{ print $3 }' | awk -F. '{ print $1 }'` == "205" ]; then
#    sed -i '/high/ c     import "high"' /etc/puppet/manifests/nodes/nodes.pp
#    # the blow string to replace PS1= line with has extra \\ because they were being stripped out
#    sed -i '/PS1=/ c   [ "$PS1" = "\\\\s-\\\\v\\\\\\$ " ] && PS1="[\\u@\\h Unclassifed \\W]\\\\$ "' /etc/bashrc
#  else
#    sed -i '/low/ c     import "low"' /etc/puppet/manifests/nodes/nodes.pp
#    sed -i '/PS1=/ c   [ "$PS1" = "\\\\s-\\\\v\\\\\\$ " ] && PS1="[\\u@\\h SECRET \\W]\\\\$ "' /etc/bashrc
#fi


# this is to remove things outside the package list that this package somehow makes exist.
# like things that might be done in %preun
%postun
if [ $1 = 0 ]; then
#if [ $1 -ge 1 ]; then
        if [ -d /root/hbss ]; then
	rm -rf /root/hbss
        fi
        if [ -d /root/oval ]; then
	rm -rf /root/oval
        fi
# when puppet needs updating, it will probably break the puppet.conf, removing the puppet enc stuff
# need to create a cron job i guess
/bin/cp /etc/puppet/modules/puppet/files/puppet.conf /etc/puppet/
	# this will cleanup all the empty directories in /etc/puppet and including puppet
	# the empty dirs will exist because we are operating on each "file" in the files section,
	# not the directories.  to be safe in case something was put there outside this package.
        if [ -d /etc/puppet ]; then
	  for i in `ls -R /etc/puppet/* | grep : | sed s/://`;do rmdir -p --ignore-fail-on-non-empty $i;done
        fi
#        if [ -f /etc/cron.hourly/spawar.sh ]; then
#	  rm -f /etc/cron.hourly/spawar.sh
#        fi
fi

%clean
rm -rf $RPM_BUILD_ROOT

%files
# by listing every file and not just the directory, /etc/puppet , etc.
# you have the most control, you will not delete other things that may end up
# making home in some dir and it will leave behind empty directories after 
# yum remove <package>.
%defattr(700,root,root)
   /etc/cron.daily/daily_report.sh
   /etc/cron.daily/project.sh
   /etc/cron.daily/uvscan.sh
   /etc/puppet/INSTRUCTIONS
   /etc/puppet/README
   /etc/puppet/autosign.conf
   /etc/puppet/fileserver.conf
   /etc/puppet/manifests/extdata/common.csv
   /etc/puppet/manifests/extdata/dogs.chs.spawar.navy.mil.csv
   /etc/puppet/manifests/settings.pp
   /etc/puppet/manifests/site.pp
   /etc/puppet/modules/aide/manifests/init.pp
   /etc/puppet/modules/aliases/manifests/init.pp
   /etc/puppet/modules/aliases/templates/GEN004640.cron.erb
   /etc/puppet/modules/auditd/files/audit.rules.386
   /etc/puppet/modules/auditd/files/audit.rules.64
   /etc/puppet/modules/auditd/manifests/init.pp
   /etc/puppet/modules/automnt/manifests/init.pp
   /etc/puppet/modules/avahi/manifests/init.pp
   /etc/puppet/modules/badperms/lib/facter/unlabeled_device_files.rb
   /etc/puppet/modules/badperms/manifests/init.pp
   /etc/puppet/modules/badperms/templates/badperms.cron.erb
   /etc/puppet/modules/banner/files/issue
   /etc/puppet/modules/banner/files/rhel.xml
   /etc/puppet/modules/banner/manifests/init.pp
   /etc/puppet/modules/bootup/manifests/init.pp
   /etc/puppet/modules/consoleperms/files/console.perms
   /etc/puppet/modules/consoleperms/files/securetty
   /etc/puppet/modules/consoleperms/manifests/init.pp
   /etc/puppet/modules/coredmp/manifests/init.pp
   /etc/puppet/modules/cronat/manifests/init.pp
   /etc/puppet/modules/cronat/templates/at.deny.erb
   /etc/puppet/modules/cronat/templates/cron.allow.erb
   /etc/puppet/modules/cronat/templates/cron.deny.erb
   /etc/puppet/modules/execshield/manifests/init.pp
   /etc/puppet/modules/fstab/manifests/init.pp
   /etc/puppet/modules/grub/manifests/init.pp
   /etc/puppet/modules/homeperms/manifests/init.pp
   /etc/puppet/modules/iptables/lib/puppet/type/iptables.rb
   /etc/puppet/modules/iptables/manifests/init.pp
   /etc/puppet/modules/iptables/templates/iptables.erb
   /etc/puppet/modules/ipv6/manifests/init.pp
   /etc/puppet/modules/kernel/lib/facter/cpu_nx.rb
   /etc/puppet/modules/kernel/lib/facter/kernel_nx.rb
   /etc/puppet/modules/kernel/manifests/init.pp
   /etc/puppet/modules/ldap/manifests/init.pp
   /etc/puppet/modules/logrotate/manifests/init.pp
   /etc/puppet/modules/logwatch/manifests/init.pp
   /etc/puppet/modules/modprobe/manifests/init.pp
   /etc/puppet/modules/nfs/manifests/init.pp
   /etc/puppet/modules/ntp/manifests/init.pp
   /etc/puppet/modules/ntp/templates/ntp.conf.erb
   /etc/puppet/modules/pam/manifests/init.pp
   /etc/puppet/modules/pam/templates/GEN002100.cron.erb
   /etc/puppet/modules/password/files/checkUsers.bash
   /etc/puppet/modules/password/manifests/init.pp
   /etc/puppet/modules/path/manifests/init.pp
   /etc/puppet/modules/path/templates/checkRootPath.bash.erb
   /etc/puppet/modules/postfix/manifests/init.pp
   /etc/puppet/modules/puppet/files/puppet.conf
   /etc/puppet/modules/puppet/manifests/init.pp
   /etc/puppet/modules/rpmverify/files/rpmverify.cron
   /etc/puppet/modules/rpmverify/manifests/init.pp
   /etc/puppet/modules/rsyslog/manifests/init.pp
   /etc/puppet/modules/rsyslog/templates/rsyslog.conf.erb
   /etc/puppet/modules/samba/manifests/init.pp
   /etc/puppet/modules/screenlock/manifests/init.pp
   /etc/puppet/modules/selinux/manifests/init.pp
   /etc/puppet/modules/sendmail/manifests/init.pp
   /etc/puppet/modules/services/manifests/init.pp
   /etc/puppet/modules/ssh/manifests/init.pp
   /etc/puppet/modules/ssh/templates/GEN006620.cron.erb
   /etc/puppet/modules/sudo/files/sudoers
   /etc/puppet/modules/sudo/manifests/init.pp
   /etc/puppet/modules/sysctl/manifests/init.pp
   /etc/puppet/modules/tcpdump/manifests/init.pp
   /etc/puppet/modules/traceroute/manifests/init.pp
   /etc/puppet/modules/umask/manifests/init.pp
   /etc/puppet/modules/wireless/manifests/init.pp
   /etc/cron.monthly/root-grub-passwd.sh
   /etc/puppet/hosts.master.txt
   /etc/puppet/manifests/nodes/nodes.pp.off
   /etc/puppet/modules/dogs_network/manifests/init.pp
   /etc/puppet/modules/project_hbss/manifests/init.pp
   /etc/puppet/modules/project_iptables/manifests/init.pp
   /etc/puppet/modules/project_mcollective/manifests/init.pp
   /etc/puppet/modules/project_nagios/manifests/init.pp
   /etc/puppet/modules/project_packages/manifests/init.pp
   /etc/puppet/modules/project_users/files/VMWARE-PACKAGING-GPG-KEY.pub
   /etc/puppet/modules/project_users/files/ahainor.pub
   /etc/puppet/modules/project_users/files/ahill.pub
   /etc/puppet/modules/project_users/files/allendw.pub
   /etc/puppet/modules/project_users/files/andrell.shaw.pub
   /etc/puppet/modules/project_users/files/aprayther.pub
   /etc/puppet/modules/project_users/files/bash_logout
   /etc/puppet/modules/project_users/files/bash_profile
   /etc/puppet/modules/project_users/files/bashrc
   /etc/puppet/modules/project_users/files/bsimpson.pub
   /etc/puppet/modules/project_users/files/carterja.pub
   /etc/puppet/modules/project_users/files/cburch.pub
   /etc/puppet/modules/project_users/files/ccollins.pub
   /etc/puppet/modules/project_users/files/cpittman.pub
   /etc/puppet/modules/project_users/files/dcraft.pub
   /etc/puppet/modules/project_users/files/easomw.pub
   /etc/puppet/modules/project_users/files/ehiott.pub
   /etc/puppet/modules/project_users/files/fennor.pub
   /etc/puppet/modules/project_users/files/gstewart.pub
   /etc/puppet/modules/project_users/files/jsigh.pub
   /etc/puppet/modules/project_users/files/kaasaj.pub
   /etc/puppet/modules/project_users/files/lgeddis.pub
   /etc/puppet/modules/project_users/files/mcollins.pub
   /etc/puppet/modules/project_users/files/morganme.pub
   /etc/puppet/modules/project_users/files/oolivares.pub
   /etc/puppet/modules/project_users/files/ordonezm.pub
   /etc/puppet/modules/project_users/files/pjohnson.pub
   /etc/puppet/modules/project_users/files/pluu.pub
   /etc/puppet/modules/project_users/files/pricek.pub
   /etc/puppet/modules/project_users/files/rayjd.pub
   /etc/puppet/modules/project_users/files/retinascan
   /etc/puppet/modules/project_users/files/retinascan.pub
   /etc/puppet/modules/project_users/files/rharris.pub
   /etc/puppet/modules/project_users/files/skeys.pub
   /etc/puppet/modules/project_users/files/snelson.pub
   /etc/puppet/modules/project_users/files/sysutil
   /etc/puppet/modules/project_users/files/sysutil.pub
   /etc/puppet/modules/project_users/files/thomask.pub
   /etc/puppet/modules/project_users/files/umitchell.pub
   /etc/puppet/modules/project_users/manifests/init.pp
   /etc/puppet/modules/test/manifests/common.csv
   /etc/puppet/modules/test/manifests/data
   /etc/puppet/modules/test/manifests/init.pp
   /etc/puppet/puppet_external_node_classifier
   /etc/puppet/modules/yum/files/yum.cron
   /etc/puppet/modules/yum/manifests/init.pp
   /etc/puppet/post.iptables
   /etc/puppet/scripts/checkRootPath.bash
   /etc/puppet/scripts/checkUsers.bash
   /etc/puppet/tagmail.conf

# %doc

%changelog
* Thu Aug 23 2012 Aaron Prayther <apraytherATlceDOTcom -.0.2
-defaults
