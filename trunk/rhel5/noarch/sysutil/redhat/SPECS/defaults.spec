# $Id: defaults.spec 1165 2012-12-18 18:35:31Z sysutil $
Name:  defaults
Version:  .0.307
Release:  1%{?dist}
Summary:  Default SPAWAR configuration/STIG RHEL5.X Puppet content
Packager: Aaron Prayther aprayther@lce.com Life Cycle Engineering
Group: Development/Tools
License:  GPL
URL: https://software.forge.mil
Source:  defaults.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch: noarch
#BuildRequires:
Requires: ircd-ratbox-mkpasswd

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

# this does appear to be the correct place to do something just before an rpm installs.  but cant do this because yum.pid is locked.
%pretrans
#/usr/bin/yum -y remove uvscanspawar

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
/etc/cron.daily/root-grub-passwd.sh &

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
#/root/McAfeeVSEForLinux-installer -i
#puppet -d -l /var/log/puppet.log /etc/puppet/manifests/stig.pp > /dev/null
#puppet -d -l /var/log/puppet.log /etc/puppet/manifests/site.pp & > /dev/null
#chkconfig nails off
#service nails stop

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
 /etc/cron.daily/root-grub-passwd.sh
 /etc/cron.daily/spawar.sh
 /etc/cron.monthly/oscap.py
 /etc/cron.monthly/oscap.pyc
 /etc/cron.monthly/oscap.pyo
 /etc/puppet/autosign.conf
 /etc/puppet/doc/classes/aide/aide.html
 /etc/puppet/doc/classes/aide.html
 /etc/puppet/doc/classes/auditd/auditd.html
 /etc/puppet/doc/classes/auditd.html
 /etc/puppet/doc/classes/automnt/automnt.html
 /etc/puppet/doc/classes/automnt.html
 /etc/puppet/doc/classes/avahi/avahi.html
 /etc/puppet/doc/classes/avahi.html
 /etc/puppet/doc/classes/badperms/badperms.html
 /etc/puppet/doc/classes/badperms.html
 /etc/puppet/doc/classes/banner/banner.html
 /etc/puppet/doc/classes/banner.html
 /etc/puppet/doc/classes/bootup/bootup.html
 /etc/puppet/doc/classes/bootup.html
 /etc/puppet/doc/classes/common/augeas.html
 /etc/puppet/doc/classes/common.html
 /etc/puppet/doc/classes/consoleperms/consoleperms.html
 /etc/puppet/doc/classes/consoleperms.html
 /etc/puppet/doc/classes/coredmp/coredmp.html
 /etc/puppet/doc/classes/coredmp.html
 /etc/puppet/doc/classes/cronat/cronat.html
 /etc/puppet/doc/classes/cronat.html
 /etc/puppet/doc/classes/dns/dns.html
 /etc/puppet/doc/classes/dns.html
 /etc/puppet/doc/classes/dovecot/dovecot.html
 /etc/puppet/doc/classes/dovecot.html
 /etc/puppet/doc/classes/execshield/execshield.html
 /etc/puppet/doc/classes/execshield.html
 /etc/puppet/doc/classes/fstab/fstab.html
 /etc/puppet/doc/classes/fstab.html
 /etc/puppet/doc/classes/homeperms/homeperms.html
 /etc/puppet/doc/classes/homeperms.html
 /etc/puppet/doc/classes/iptables.html
 /etc/puppet/doc/classes/iptables/iptables.html
 /etc/puppet/doc/classes/ipv6.html
 /etc/puppet/doc/classes/ipv6/ipv6.html
 /etc/puppet/doc/classes/kernel.html
 /etc/puppet/doc/classes/kernel/kernel.html
 /etc/puppet/doc/classes/logrotate.html
 /etc/puppet/doc/classes/logrotate/logrotate.html
 /etc/puppet/doc/classes/logwatch.html
 /etc/puppet/doc/classes/logwatch/logwatch.html
 /etc/puppet/doc/classes/modprobe.html
 /etc/puppet/doc/classes/modprobe/modprobe.html
 /etc/puppet/doc/classes/nfs.html
 /etc/puppet/doc/classes/nfs/nfs.html
 /etc/puppet/doc/classes/ntp.html
 /etc/puppet/doc/classes/ntp/ntp.html
 /etc/puppet/doc/classes/openldap.html
 /etc/puppet/doc/classes/openldap/openldap.html
 /etc/puppet/doc/classes/pam.html
 /etc/puppet/doc/classes/pam/pam.html
 /etc/puppet/doc/classes/password.html
 /etc/puppet/doc/classes/password/password.html
 /etc/puppet/doc/classes/path.html
 /etc/puppet/doc/classes/path/path.html
 /etc/puppet/doc/classes/puppet.html
 /etc/puppet/doc/classes/puppet/puppet.html
 /etc/puppet/doc/classes/rpmqva.html
 /etc/puppet/doc/classes/rpmqva/rpmqva.html
 /etc/puppet/doc/classes/samba.html
 /etc/puppet/doc/classes/samba/samba.html
 /etc/puppet/doc/classes/screenlock.html
 /etc/puppet/doc/classes/screenlock/screenlock.html
 /etc/puppet/doc/classes/selinux.html
 /etc/puppet/doc/classes/selinux/selinux.html
 /etc/puppet/doc/classes/sendmail.html
 /etc/puppet/doc/classes/sendmail/sendmail.html
 /etc/puppet/doc/classes/services.html
 /etc/puppet/doc/classes/services/services.html
 /etc/puppet/doc/classes/site.html
 /etc/puppet/doc/classes/ssh.html
 /etc/puppet/doc/classes/ssh/ssh.html
 /etc/puppet/doc/classes/sudo.html
 /etc/puppet/doc/classes/sudo/sudo.html
 /etc/puppet/doc/classes/syslog.html
 /etc/puppet/doc/classes/syslog/syslog.html
 /etc/puppet/doc/classes/umask.html
 /etc/puppet/doc/classes/umask/umask.html
 /etc/puppet/doc/classes/yum.html
 /etc/puppet/doc/classes/yum/yum.html
 /etc/puppet/doc/created.rid
 /etc/puppet/doc/files/tmp/puppet/manifests/nodes/nodes_pp.html
 /etc/puppet/doc/files/tmp/puppet/manifests/settings_pp.html
 /etc/puppet/doc/files/tmp/puppet/manifests/site_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/aide/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/auditd/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/automnt/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/avahi/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/badperms/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/banner/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/bootup/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/common/manifests/defines/augeas_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/common/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/consoleperms/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/coredmp/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/cronat/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/dns/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/dovecot/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/execshield/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/fstab/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/homeperms/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/iptables/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/ipv6/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/kernel/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/logrotate/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/logwatch/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/modprobe/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/nfs/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/ntp/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/openldap/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/pam/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/password/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/path/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/puppet/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/rpmqva/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/samba/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/screenlock/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/selinux/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/sendmail/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/services/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/ssh/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/sudo/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/syslog/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/umask/manifests/init_pp.html
 /etc/puppet/doc/files/tmp/puppet/modules/yum/manifests/init_pp.html
 /etc/puppet/doc/fr_class_index.html
 /etc/puppet/doc/fr_modules_index.html
 /etc/puppet/doc/index.html
 /etc/puppet/doc/modules/fr_aide.html
 /etc/puppet/doc/modules/fr_auditd.html
 /etc/puppet/doc/modules/fr_automnt.html
 /etc/puppet/doc/modules/fr_avahi.html
 /etc/puppet/doc/modules/fr_badperms.html
 /etc/puppet/doc/modules/fr_banner.html
 /etc/puppet/doc/modules/fr_bootup.html
 /etc/puppet/doc/modules/fr_common.html
 /etc/puppet/doc/modules/fr_consoleperms.html
 /etc/puppet/doc/modules/fr_coredmp.html
 /etc/puppet/doc/modules/fr_cronat.html
 /etc/puppet/doc/modules/fr_dns.html
 /etc/puppet/doc/modules/fr_dovecot.html
 /etc/puppet/doc/modules/fr_execshield.html
 /etc/puppet/doc/modules/fr_fstab.html
 /etc/puppet/doc/modules/fr_homeperms.html
 /etc/puppet/doc/modules/fr_iptables.html
 /etc/puppet/doc/modules/fr_ipv6.html
 /etc/puppet/doc/modules/fr_kernel.html
 /etc/puppet/doc/modules/fr_logrotate.html
 /etc/puppet/doc/modules/fr_logwatch.html
 /etc/puppet/doc/modules/fr_modprobe.html
 /etc/puppet/doc/modules/fr_nfs.html
 /etc/puppet/doc/modules/fr_ntp.html
 /etc/puppet/doc/modules/fr_openldap.html
 /etc/puppet/doc/modules/fr_pam.html
 /etc/puppet/doc/modules/fr_password.html
 /etc/puppet/doc/modules/fr_path.html
 /etc/puppet/doc/modules/fr_puppet.html
 /etc/puppet/doc/modules/fr_rpmqva.html
 /etc/puppet/doc/modules/fr_samba.html
 /etc/puppet/doc/modules/fr_screenlock.html
 /etc/puppet/doc/modules/fr_selinux.html
 /etc/puppet/doc/modules/fr_sendmail.html
 /etc/puppet/doc/modules/fr_services.html
 /etc/puppet/doc/modules/fr_site.html
 /etc/puppet/doc/modules/fr_ssh.html
 /etc/puppet/doc/modules/fr_sudo.html
 /etc/puppet/doc/modules/fr_syslog.html
 /etc/puppet/doc/modules/fr_umask.html
 /etc/puppet/doc/modules/fr_yum.html
 /etc/puppet/doc/nodes/82f9ebf37d93845cdffd27d27f4e8e52/039967aaa89075f8f57a6129f83cbd56.html
 /etc/puppet/doc/nodes/82f9ebf37d93845cdffd27d27f4e8e52/c21f969b5f03d33d43e04f8f136e7682.html
 /etc/puppet/doc/nodes/82f9ebf37d93845cdffd27d27f4e8e52/f0470582327ae0e99d5fbad3dbe0982b.html
 /etc/puppet/doc/rdoc-style.css
 /etc/puppet/INSTRUCTIONS
 /etc/puppet/manifests/nodes1.pp.off
 /etc/puppet/manifests/nodes/csv2json.sh
 /etc/puppet/manifests/nodes/hosts.master.json.no_placeholders
 /etc/puppet/manifests/nodes/hosts.master.test
 /etc/puppet/manifests/nodes/hosts.master.txt
 /etc/puppet/manifests/nodes/hosts.readme
 /etc/puppet/manifests/nodes/nodes.pp
 /etc/puppet/manifests/settings.pp
 /etc/puppet/manifests/site.pp
 /etc/puppet/manifests/stig.pp
 /etc/puppet/modules/AC-17/manifests/init.pp
 /etc/puppet/modules/AC-3/manifests/init.pp
 /etc/puppet/modules/AC-3/templates/sa1
 /etc/puppet/modules/AC-3/templates/sa2
 /etc/puppet/modules/AC-3/templates/sysstat
 /etc/puppet/modules/AC-7/manifests/init.pp
 /etc/puppet/modules/AC-7/templates/system-auth.tpl
 /etc/puppet/modules/aide/manifests/init.pp
 /etc/puppet/modules/auditd/files/audit.rules.386
 /etc/puppet/modules/auditd/files/audit.rules.64
 /etc/puppet/modules/auditd/manifests/init.pp
 /etc/puppet/modules/automnt/manifests/init.pp
 /etc/puppet/modules/avahi/manifests/init.pp
 /etc/puppet/modules/badperms/lib/facter/unlabeled_device_files.rb
 /etc/puppet/modules/badperms/manifests/init.pp
 /etc/puppet/modules/badperms/templates/badperms.cron.erb
 /etc/puppet/modules/banner/files/issue
 /etc/puppet/modules/banner/files/issue.net
 /etc/puppet/modules/banner/files/rhel.xml
 /etc/puppet/modules/banner/manifests/init.pp
 /etc/puppet/modules/bootup/manifests/init.pp
 /etc/puppet/modules/common/manifests/defines/augeas.pp
 /etc/puppet/modules/common/manifests/init.pp
 /etc/puppet/modules/consoleperms/files/console.perms
 /etc/puppet/modules/consoleperms/files/securetty
 /etc/puppet/modules/consoleperms/manifests/init.pp
 /etc/puppet/modules/coredmp/manifests/init.pp
 /etc/puppet/modules/cronat/manifests/init.pp
 /etc/puppet/modules/directory-iptables/manifests/init.pp
 /etc/puppet/modules/directory/manifests/config.pp
 /etc/puppet/modules/directory/manifests/init.pp
 /etc/puppet/modules/directory/manifests/install.pp
 /etc/puppet/modules/directory/manifests/params.pp
 /etc/puppet/modules/directory/manifests/service.pp
 /etc/puppet/modules/directory-master/manifests/init.pp
 /etc/puppet/modules/directory-master/templates/basic-root.ldif
 /etc/puppet/modules/directory-master/templates/ldap-data.ldif
 /etc/puppet/modules/directory-master/templates/ldap-structure.ldif
 /etc/puppet/modules/directory-master/templates/repl-user.ldif
 /etc/puppet/modules/directory-slave/manifests/init.pp
 /etc/puppet/modules/directory/templates/DB_CONFIG
 /etc/puppet/modules/directory/templates/extendedinetorgperson.schema
 /etc/puppet/modules/directory/templates/ldap.conf
 /etc/puppet/modules/directory/templates/slapd.conf
 /etc/puppet/modules/execshield/manifests/init.pp
 /etc/puppet/modules/fstab/manifests/init.pp
 /etc/puppet/modules/GEN000920/manifests/init.pp
 /etc/puppet/modules/GEN000980/manifests/init.pp
 /etc/puppet/modules/GEN002560/manifests/init.pp
 /etc/puppet/modules/GEN003040/manifests/init.pp
 /etc/puppet/modules/GEN003340/manifests/init.pp
 /etc/puppet/modules/GEN004640/manifests/init.pp
 /etc/puppet/modules/GEN0054x0/manifests/init.pp
 /etc/puppet/modules/homeperms/manifests/init.pp
 /etc/puppet/modules/IA-2/manifests/init.pp
 /etc/puppet/modules/iptables/lib/puppet/type/iptables.rb
 /etc/puppet/modules/iptables/manifests/init.pp
 /etc/puppet/modules/iptables/templates/iptables.erb
 /etc/puppet/modules/ipv6/manifests/init.pp
 /etc/puppet/modules/kernel/lib/facter/cpu_nx.rb
 /etc/puppet/modules/kernel/lib/facter/kernel_nx.rb
 /etc/puppet/modules/kernel/manifests/init.pp
 /etc/puppet/modules/ldap/manifests/init.pp
 /etc/puppet/modules/LNX00320/manifests/init.pp
 /etc/puppet/modules/LNX00340/manifests/init.pp
 /etc/puppet/modules/LNX00400/manifests/init.pp
 /etc/puppet/modules/LNX00480/manifests/init.pp
 /etc/puppet/modules/LNX00580/manifests/init.pp
 /etc/puppet/modules/logrotate/manifests/init.pp
 /etc/puppet/modules/logwatch/manifests/init.pp
 /etc/puppet/modules/low/manifests/init.pp
 /etc/puppet/modules/modprobe/manifests/init.pp
 /etc/puppet/modules/nfs/manifests/init.pp
 /etc/puppet/modules/ntp/manifests/init.pp
 /etc/puppet/modules/ntp/templates/ntp.conf.erb
 /etc/puppet/modules/pam/manifests/init.pp
 /etc/puppet/modules/password/files/checkUsers.bash
 /etc/puppet/modules/password/manifests/init.pp
 /etc/puppet/modules/password/templates/libuser.conf.erb
 /etc/puppet/modules/path/manifests/init.pp
 /etc/puppet/modules/path/templates/checkRootPath.bash.erb
 /etc/puppet/modules/postfix/manifests/init.pp
 /etc/puppet/modules/project_nagios/manifests/init.pp
 /etc/puppet/modules/project_nagios/templates/check_cpu.cfg.erb
 /etc/puppet/modules/project_nagios/templates/check_cpu.sh
 /etc/puppet/modules/project_nagios/templates/check_hbss.cfg.erb
 /etc/puppet/modules/project_nagios/templates/check_host_alive.cfg.erb
 /etc/puppet/modules/project_nagios/templates/check_http.cfg.erb
 /etc/puppet/modules/project_nagios/templates/check_load.cfg.erb
 /etc/puppet/modules/project_nagios/templates/check_mem
 /etc/puppet/modules/project_nagios/templates/check_mem.cfg.erb
 /etc/puppet/modules/project_nagios/templates/check_partitions.cfg.erb
 /etc/puppet/modules/project_nagios/templates/check_puppet.cfg.erb
 /etc/puppet/modules/project_nagios/templates/check_selinux
 /etc/puppet/modules/project_nagios/templates/check_selinux.cfg.erb
 /etc/puppet/modules/project_nagios/templates/check_ssh.cfg.erb
 /etc/puppet/modules/project_nagios/templates/check_swap.cfg.erb
 /etc/puppet/modules/project_nagios/templates/check_total_procs.cfg.erb
 /etc/puppet/modules/project_nagios/templates/check_users.cfg.erb
 /etc/puppet/modules/project_nagios/templates/check_zombie_procs.cfg.erb
 /etc/puppet/modules/project_nagios/templates/host.cfg.erb
 /etc/puppet/modules/project_nagios/templates/nrpe.cfg
 /etc/puppet/modules/project_nagios/templates/nrpe_cpu.cfg.erb
 /etc/puppet/modules/project_nagios/templates/nrpe_hbss.cfg.erb
 /etc/puppet/modules/project_nagios/templates/nrpe_host_alive.cfg.erb
 /etc/puppet/modules/project_nagios/templates/nrpe_load.cfg.erb
 /etc/puppet/modules/project_nagios/templates/nrpe_mem.cfg.erb
 /etc/puppet/modules/project_nagios/templates/nrpe_partitions.cfg.erb
 /etc/puppet/modules/project_nagios/templates/nrpe_puppet.cfg.erb
 /etc/puppet/modules/project_nagios/templates/nrpe_selinux.cfg.erb
 /etc/puppet/modules/project_nagios/templates/nrpe_ssh.cfg.erb
 /etc/puppet/modules/project_nagios/templates/nrpe_swap.cfg.erb
 /etc/puppet/modules/project_nagios/templates/nrpe_total_procs.cfg.erb
 /etc/puppet/modules/project_nagios/templates/nrpe_users.cfg.erb
 /etc/puppet/modules/project_nagios/templates/nrpe_zombie_procs.cfg.erb
 /etc/puppet/modules/puppet/files/puppet.conf
 /etc/puppet/modules/puppet/manifests/init.pp
 /etc/puppet/modules/rpmverify/files/rpmverify.cron
 /etc/puppet/modules/rpmverify/manifests/init.pp
 /etc/puppet/modules/rsyslog/files/syslog.conf
 /etc/puppet/modules/rsyslog/manifests/init.pp
 /etc/puppet/modules/rsyslog/templates/rsyslog.conf.erb
 /etc/puppet/modules/rsyslog/templates/rsyslog.erb
 /etc/puppet/modules/samba/manifests/init.pp
 /etc/puppet/modules/SC-5/manifests/init.pp
 /etc/puppet/modules/screenlock/manifests/init.pp
 /etc/puppet/modules/selinux/manifests/init.pp
 /etc/puppet/modules/sendmail/manifests/init.pp
 /etc/puppet/modules/services/manifests/init.pp
 /etc/puppet/modules/spawar1/files/ahainor.pub
 /etc/puppet/modules/spawar1/files/ahill.pub
 /etc/puppet/modules/spawar1/files/allendw.pub
 /etc/puppet/modules/spawar1/files/asmith.pub
 /etc/puppet/modules/spawar1/files/bash_logout
 /etc/puppet/modules/spawar1/files/bash_profile
 /etc/puppet/modules/spawar1/files/bashrc
 /etc/puppet/modules/spawar1/files/bsimpson.pub
 /etc/puppet/modules/spawar1/files/caldjas.pub
 /etc/puppet/modules/spawar1/files/ccollins.pub
 /etc/puppet/modules/spawar1/files/collincm.pub
 /etc/puppet/modules/spawar1/files/craftd.pub
 /etc/puppet/modules/spawar1/files/crontab
 /etc/puppet/modules/spawar1/files/dcraft.pub
 /etc/puppet/modules/spawar1/files/ehiott.pub
 /etc/puppet/modules/spawar1/files/GPG-SPAWAR-KEY
 /etc/puppet/modules/spawar1/files/gstewart.pub
 /etc/puppet/modules/spawar1/files/guzzardo.pub
 /etc/puppet/modules/spawar1/files/harrisrr.pub
 /etc/puppet/modules/spawar1/files/install-linux-LANT.sh
 /etc/puppet/modules/spawar1/files/ip6tables
 /etc/puppet/modules/spawar1/files/jsigh.pub
 /etc/puppet/modules/spawar1/files/kaasaj.pub
 /etc/puppet/modules/spawar1/files/lgeddis.pub
 /etc/puppet/modules/spawar1/files/logrotate.conf
 /etc/puppet/modules/spawar1/files/low-resolv.conf
 /etc/puppet/modules/spawar1/files/low-step-tickers
 /etc/puppet/modules/spawar1/files/luuphuos.pub
 /etc/puppet/modules/spawar1/files/marshalr.pub
 /etc/puppet/modules/spawar1/files/mcguiren.pub
 /etc/puppet/modules/spawar1/files/mcollins.pub
 /etc/puppet/modules/spawar1/files/nguyenvt.pub
 /etc/puppet/modules/spawar1/files/ntp.conf
 /etc/puppet/modules/spawar1/files/oolivares.pub
 /etc/puppet/modules/spawar1/files/ordonezm.pub
 /etc/puppet/modules/spawar1/files/pjohnson.pub
 /etc/puppet/modules/spawar1/files/pluu.pub
 /etc/puppet/modules/spawar1/files/praythea.pub
 /etc/puppet/modules/spawar1/files/rayjd.pub
 /etc/puppet/modules/spawar1/files/resolv.conf
 /etc/puppet/modules/spawar1/files/rharris.pub
 /etc/puppet/modules/spawar1/files/rmarshall.pub
 /etc/puppet/modules/spawar1/files/RPM-GPG-KEY-EPEL
 /etc/puppet/modules/spawar1/files/simpsonb.pub
 /etc/puppet/modules/spawar1/files/smithak.pub
 /etc/puppet/modules/spawar1/files/snelson.pub
 /etc/puppet/modules/spawar1/files/sosreport.sh
 /etc/puppet/modules/spawar1/files/step-tickers
 /etc/puppet/modules/spawar1/files/stewartg.pub
 /etc/puppet/modules/spawar1/files/sysutil_id_rsa
 /etc/puppet/modules/spawar1/files/sysutil_id_rsa.pub
 /etc/puppet/modules/spawar1/files/sysutil.pub
 /etc/puppet/modules/spawar1/files/thomask.pub
 /etc/puppet/modules/spawar1/files/umitchell.pub
 /etc/puppet/modules/spawar1/files/uvscan.sh
 /etc/puppet/modules/spawar1/files/VMWARE-PACKAGING-GPG-KEY.pub
 /etc/puppet/modules/spawar1/files/vnguyen.pub
 /etc/puppet/modules/spawar1/manifests/init.pp
 /etc/puppet/modules/spawar1/templates/bacula-fd.conf
 /etc/puppet/modules/spawar1/templates/hosts
 /etc/puppet/modules/spawar1/templates/nrpe.cfg
 /etc/puppet/modules/spawar/manifests/init.pp
 /etc/puppet/modules/ssh/manifests/init.pp
 /etc/puppet/modules/sudo/files/sudoers
 /etc/puppet/modules/sudo/manifests/init.pp
 /etc/puppet/modules/umask/manifests/init.pp
 /etc/puppet/modules/wireless/manifests/init.pp
 /etc/puppet/modules/yum/files/yum.cron
 /etc/puppet/modules/yum/manifests/init.pp
 /etc/puppet/post.iptables
 /etc/puppet/puppet.conf.usgcb
 /etc/puppet/README
 /etc/puppet/scripts/checkRootPath.bash
 /etc/puppet/scripts/checkUsers.bash
 /etc/puppet/tagmail.conf
 /etc/sim-release
 /root/McAfeeVSEForLinux-1.9.0.28822.noarch.tar.gz
 /root/McAfeeVSEForLinux-installer
 /root/nails.options
 /root/U_RedHat_5-V1R4_STIG_Benchmark-oval.xml
 /root/U_RedHat_5-V1R4_STIG_Benchmark-xccdf.xml
 /var/lib/puppet/lib/puppet/type/append_if_no_such_line.rb
 /var/lib/puppet/lib/puppet/type/delete_line.rb


# %doc

%changelog
* Thu Aug 04 2011 Aaron Prayther <apraytherATlceDOTcom - 001
-defaults
