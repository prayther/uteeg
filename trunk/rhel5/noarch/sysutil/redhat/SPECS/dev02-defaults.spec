# $Id: dev02-defaults.spec 763 2012-08-15 13:52:46Z sysutil $
Name:  dev01-defaults
Version:  .0.16
Release:  1%{?dist}
Summary:  sysutil system account for SVN and RPM build
Packager: Aaron Prayther aprayther@lce.com Life Cycle Engineering
Group: Development/Tools
License:  GPL
URL: https://software.forge.mil
Source:  dev01-defaults.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch: noarch
#BuildRequires:
#Requires: subversion, rpm-build, expect, rpmlint, rpmdevtools, puppet, spacecmd

%description
The sysutil package delivers, RPM build tools, subversion and the ability to build "role" specific rpm's for services and applications.  Reading in hosts from the comma delimited file hosts.role.txt

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
%setup -q -n dev01-defaults

%build

%pre
if ! id sysutil >& /dev/null; then
%{_sbindir}/useradd -f2 -p '\$2\$quu6T/\$e2KG6O2h1g83MX.aU8INl.' -u 607 -G users -c "system utility account for automation purposes" -m -d /home/sysutil -s /bin/bash sysutil
fi

# this is just taking a src file and moving it around /src/redhat/* and /var/tmp/ to keep things straight.. then cleanup.
%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/dev01-defaults
rsync -av $RPM_BUILD_DIR/dev01-defaults/* $RPM_BUILD_ROOT/

# for some reason that i have not figured out the {files} stanza below does not set the owneship correctly
# on all the files, so this chown is a work around
%post
/bin/chown -R sysutil.sysutil /home/sysutil
/bin/chmod -R 700 /home/sysutil

# this is the uninstall or upgrade from the perspective of: yum remove or yum upgrade on the client
%postun
 %{_sbindir}/userdel -rf sysutil

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(644,root,root)
   /etc/puppet/COPYING
   /etc/puppet/manifests/hosts.pp
   /etc/puppet/manifests/init.pp
   /etc/puppet/manifests/init1.pp
   /etc/puppet/manifests/role.pp
   /etc/puppet/manifests/site.pp
   /etc/puppet/manifests/stig.pp
   /etc/puppet/modules/AC-11/manifests/init.pp
   /etc/puppet/modules/AC-15/files/cupsd.conf
   /etc/puppet/modules/AC-15/manifests/init.pp
   /etc/puppet/modules/AC-17/manifests/init.pp
   /etc/puppet/modules/AC-3/manifests/init.pp
   /etc/puppet/modules/AC-3/templates/sa1
   /etc/puppet/modules/AC-3/templates/sa2
   /etc/puppet/modules/AC-3/templates/sysstat
   /etc/puppet/modules/AC-7/manifests/init.pp
   /etc/puppet/modules/AC-7/templates/system-auth.tpl
   /etc/puppet/modules/AC-8/files/Default.sed
   /etc/puppet/modules/AC-8/files/issue
   /etc/puppet/modules/AC-8/files/issue.net
   /etc/puppet/modules/AC-8/manifests/init.pp
   /etc/puppet/modules/AU-2/files/auditd.conf
   /etc/puppet/modules/AU-2/manifests/init.pp
   /etc/puppet/modules/AU-2/templates/audit.rules
   /etc/puppet/modules/GEN000020/manifests/init.pp
   /etc/puppet/modules/GEN000440/manifests/init.pp
   /etc/puppet/modules/GEN000920/manifests/init.pp
   /etc/puppet/modules/GEN000980/manifests/init.pp
   /etc/puppet/modules/GEN001080/manifests/init.pp
   /etc/puppet/modules/GEN001280/manifests/init.pp
   /etc/puppet/modules/GEN001460/manifests/init.pp
   /etc/puppet/modules/GEN001560/manifests/init.pp
   /etc/puppet/modules/GEN001580/manifests/init.pp
   /etc/puppet/modules/GEN0017x0/manifests/init.pp
   /etc/puppet/modules/GEN001800/manifests/init.pp
   /etc/puppet/modules/GEN001820/manifests/init.pp
   /etc/puppet/modules/GEN002040/manifests/init.pp
   /etc/puppet/modules/GEN002120/files/shells
   /etc/puppet/modules/GEN002120/manifests/init.pp
   /etc/puppet/modules/GEN002320/manifests/init.pp
   /etc/puppet/modules/GEN002560/manifests/init.pp
   /etc/puppet/modules/GEN002640/manifests/init.pp
   /etc/puppet/modules/GEN002860/files/audit.logrotate
   /etc/puppet/modules/GEN002860/manifests/init.pp
   /etc/puppet/modules/GEN003040/manifests/init.pp
   /etc/puppet/modules/GEN003180/manifests/init.pp
   /etc/puppet/modules/GEN003340/manifests/init.pp
   /etc/puppet/modules/GEN003400/manifests/init.pp
   /etc/puppet/modules/GEN003500/manifests/init.pp
   /etc/puppet/modules/GEN003520/manifests/init.pp
   /etc/puppet/modules/GEN003700/manifests/init.pp
   /etc/puppet/modules/GEN003740/manifests/init.pp
   /etc/puppet/modules/GEN003760/manifests/init.pp
   /etc/puppet/modules/GEN003860/manifests/init.pp
   /etc/puppet/modules/GEN004360/manifests/init.pp
   /etc/puppet/modules/GEN004440/manifests/init.pp
   /etc/puppet/modules/GEN004480/manifests/init.pp
   /etc/puppet/modules/GEN004540/manifests/init.pp
   /etc/puppet/modules/GEN004560/manifests/init.pp
   /etc/puppet/modules/GEN004580/manifests/init.pp
   /etc/puppet/modules/GEN004640/manifests/init.pp
   /etc/puppet/modules/GEN004880/manifests/init.pp
   /etc/puppet/modules/GEN005000/manifests/init.pp
   /etc/puppet/modules/GEN005360/manifests/init.pp
   /etc/puppet/modules/GEN0054x0/manifests/init.pp
   /etc/puppet/modules/GEN0057x0/manifests/init.pp
   /etc/puppet/modules/GEN006100/manifests/init.pp
   /etc/puppet/modules/GEN006160/manifests/init.pp
   /etc/puppet/modules/GEN006260/manifests/init.pp
   /etc/puppet/modules/GEN006280/manifests/init.pp
   /etc/puppet/modules/GEN006300/manifests/init.pp
   /etc/puppet/modules/GEN006320/manifests/init.pp
   /etc/puppet/modules/GEN006340/manifests/init.pp
   /etc/puppet/modules/IA-2/manifests/init.pp
   /etc/puppet/modules/LNX00160/manifests/init.pp
   /etc/puppet/modules/LNX00220/manifests/init.pp
   /etc/puppet/modules/LNX00320/manifests/init.pp
   /etc/puppet/modules/LNX00340/manifests/init.pp
   /etc/puppet/modules/LNX00360/files/custom.conf
   /etc/puppet/modules/LNX00360/manifests/init.pp
   /etc/puppet/modules/LNX00400/manifests/init.pp
   /etc/puppet/modules/LNX00480/manifests/init.pp
   /etc/puppet/modules/LNX00580/manifests/init.pp
   /etc/puppet/modules/SC-5/manifests/init.pp
   /etc/puppet/modules/source/GPG-SPAWAR-KEY
   /etc/puppet/modules/source/RPM-GPG-KEY-EPEL
   /etc/puppet/modules/source/RPM-GPG-KEY-oracle
   /etc/puppet/modules/source/VMWARE-PACKAGING-GPG-KEY.pub
   /etc/puppet/modules/source/andrell.shaw.pub
   /etc/puppet/modules/source/aprayther.pub
   /etc/puppet/modules/source/carterja.pub
   /etc/puppet/modules/source/check_cpu_perf.sh
   /etc/puppet/modules/source/coopercj.pub
   /etc/puppet/modules/source/crontab
   /etc/puppet/modules/source/desantisj.pub
   /etc/puppet/modules/source/forge-cert.p12
   /etc/puppet/modules/source/grimmc.pub
   /etc/puppet/modules/source/issue
   /etc/puppet/modules/source/issue.net
   /etc/puppet/modules/source/morganme.pub
   /etc/puppet/modules/source/nrpe.cfg
   /etc/puppet/modules/source/ntp.conf
   /etc/puppet/modules/source/pricek.pub
   /etc/puppet/modules/source/puppet-site-cron.sh
   /etc/puppet/modules/source/puppet-site-yum.sh
   /etc/puppet/modules/source/puppet-site.sh
   /etc/puppet/modules/source/puppet-stig-cron.sh
   /etc/puppet/modules/source/puppet-stig.sh
   /etc/puppet/modules/source/rayjd.pub
   /etc/puppet/modules/source/resolv.conf
   /etc/puppet/modules/source/sendmail.cf
   /etc/puppet/modules/source/skeys.pub
   /etc/puppet/modules/source/snmpd.conf
   /etc/puppet/modules/source/snmpd.conf.init
   /etc/puppet/modules/source/snmpd.conf.new
   /etc/puppet/modules/source/sosreport.sh
   /etc/puppet/modules/source/step-tickers
   /etc/puppet/modules/source/sudoers
   /etc/puppet/modules/source/sysutil.id_rsa
   /etc/puppet/modules/source/sysutil.id_rsa.pub
   /etc/puppet/modules/source/template.hosts.pp
   /etc/puppet/modules/source/template.init.pp
   /etc/puppet/modules/source/uvscan.sh
   /etc/puppet/modules/source/watsonjl.pub
   /etc/puppet/modules/source/yum.rb
   /etc/puppet/modules/templates/bacula-fd.conf
   /etc/puppet/modules/templates/hosts
   /etc/puppet/modules/templates/template.puppet-hosts-cron.sh
   /etc/puppet/modules/templates/template.puppet-hosts-yum.sh
   /root/hbss/install-linux-rpm-46-1694.sh
   /root/oval/clip-ovaldi.xml
   /root/oval/com.redhat.rhsa-all.xml
   /var/lib/puppet/lib/puppet/type/append_if_no_such_line.rb


# %doc

%changelog
* Thu Aug 04 2011 Aaron Prayther <apraytherATlceDOTcom - 001
-making sysutil system account
