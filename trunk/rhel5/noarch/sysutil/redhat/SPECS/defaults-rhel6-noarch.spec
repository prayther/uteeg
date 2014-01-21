# $Id: defaults.spec .17.8012-08-22 18:35:05Z sysutil $
Name:  defaults-rhel6-noarch
Version: 2.0.0
Release:  1%{?dist}
Summary:  Default SPAWAR configuration/STIG RHEL5.X Puppet content
Packager: Aaron Prayther aprayther@lce.com Life Cycle Engineering
Group: Development/Tools
License:  GPL
URL: https://software.forge.mil
Source:  defaults-rhel6-noarch.tar.gz
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
/etc/cron.monthly/fixme.sh &

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

#for i in `cat /etc/fstab | grep ext3 | awk '{ print $2 }'`;do cd $i && dd if=/dev/zero of=zeros.txt ; rm -f zeros.txt;done

# one time deal DELETE this line for next RPM build
# this is addressing any boxes that built accts, before puppet stig.pp was run setting proper defaults
#for i in `ls /home | grep -v lost`;do userdel $i;done

#puppet -d -l /var/log/puppet.log /etc/puppet/manifests/stig.pp && puppet -d -l /var/log/puppet.log /etc/puppet/manifests/site.pp & > /dev/null

# this is to remove things outside the package list that this package somehow makes exist.
# like things that might be done in %preun
%postun
if [ $1 = 0 ]; then
#if [ $1 -ge 1 ]; then
        if [ -d /root/hbss ]; then
	  rmdir --ignore-fail-on-non-empty /root/hbss
        fi
        if [ -d /root/oval ]; then
	  rmdir --ignore-fail-on-non-empty /root/oval
        fi
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
   /etc/puppet/INSTRUCTIONS
   /etc/puppet/README
   /etc/puppet/auth.conf
   /etc/puppet/autosign.conf
   /etc/puppet/fileserver.conf
   /etc/puppet/manifests/nodes/nodes.pp
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
   /etc/puppet/modules/project/files/GPG-SPAWAR-KEY
   /etc/puppet/modules/project/files/RPM-GPG-KEY-EPEL
   /etc/puppet/modules/project/files/VMWARE-PACKAGING-GPG-KEY.pub
   /etc/puppet/modules/project/files/ahainor.pub
   /etc/puppet/modules/project/files/allendw.pub
   /etc/puppet/modules/project/files/andrell.shaw.pub
   /etc/puppet/modules/project/files/aprayther.pub
   /etc/puppet/modules/project/files/bash_logout
   /etc/puppet/modules/project/files/bash_profile
   /etc/puppet/modules/project/files/bashrc
   /etc/puppet/modules/project/files/bsimpson.pub
   /etc/puppet/modules/project/files/ccollins.pub
   /etc/puppet/modules/project/files/cpittman.pub
   /etc/puppet/modules/project/files/crontab
   /etc/puppet/modules/project/files/dcraft.pub
   /etc/puppet/modules/project/files/easomw.pub
   /etc/puppet/modules/project/files/fennor.pub
   /etc/puppet/modules/project/files/gstewart.pub
   /etc/puppet/modules/project/files/install-linux-rpm-46-1694.sh
   /etc/puppet/modules/project/files/ip6tables
   /etc/puppet/modules/project/files/kaasaj.pub
   /etc/puppet/modules/project/files/lgeddis.pub
   /etc/puppet/modules/project/files/logrotate.conf
   /etc/puppet/modules/project/files/low-ntp.conf
   /etc/puppet/modules/project/files/low-resolv.conf
   /etc/puppet/modules/project/files/low-step-tickers
   /etc/puppet/modules/project/files/mcollins.pub
   /etc/puppet/modules/project/files/nrpe.cfg
   /etc/puppet/modules/project/files/oolivares.pub
   /etc/puppet/modules/project/files/ordonezm.pub
   /etc/puppet/modules/project/files/pjohnson.pub
   /etc/puppet/modules/project/files/pluu.pub
   /etc/puppet/modules/project/files/pricek.pub
   /etc/puppet/modules/project/files/rayjd.pub
   /etc/puppet/modules/project/files/resolv.conf
   /etc/puppet/modules/project/files/rharris.pub
   /etc/puppet/modules/project/files/sosreport.sh
   /etc/puppet/modules/project/files/step-tickers
   /etc/puppet/modules/project/files/sysutil.pub
   /etc/puppet/modules/project/files/sysutil_id_rsa
   /etc/puppet/modules/project/files/sysutil_id_rsa.pub
   /etc/puppet/modules/project/files/thomask.pub
   /etc/puppet/modules/project/files/umitchell.pub
   /etc/puppet/modules/project/files/uvscan.sh
   /etc/puppet/modules/project/manifests/init.pp
   /etc/puppet/modules/project/templates/bacula-fd.conf
   /etc/puppet/modules/project/templates/hosts
   /etc/puppet/modules/project/templates/nrpe.cfg
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
   /etc/puppet/modules/users/manifests/init.pp
   /etc/puppet/modules/wireless/manifests/init.pp
   /etc/puppet/modules/yum/files/yum.cron
   /etc/puppet/modules/yum/manifests/init.pp
   /etc/puppet/post.iptables
   /etc/puppet/puppet.conf
   /etc/puppet/scripts/checkRootPath.bash
   /etc/puppet/scripts/checkUsers.bash
   /etc/puppet/tagmail.conf



# %doc

%changelog
* Thu Aug 23 2012 Aaron Prayther <apraytherATlceDOTcom - 001
-defaults
