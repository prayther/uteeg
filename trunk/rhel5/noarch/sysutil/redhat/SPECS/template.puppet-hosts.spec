Name:           puppet-<%= hostname %>
Version:        .1.1001
Release:        1%{?dist}
Summary:        host puppet content
Packager:       Aaron Prayther aprayther@lce.com Life Cycle Engineering
Group:          Development/Tools
License:        GPL
URL:            https://software.forge.mil/DoDBastile
Source0:        $RPM_SOURCE_DIR/puppet-<%= hostname %>
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
#BuildRequires:
Requires:       puppet >= 0.25, subversion, rpm-build, expect, rpmdevtools

%description
The puppet content to address, hosts things, like ntp.conf, resolv, etc on RHEL 5.x servers.

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
rm -rf $RPM_BUILD_ROOT
mkdir $RPM_BUILD_ROOT

# this is just taking a src file and moving it around /src/redhat/* and /var/tmp/ to keep things straight.. then cleanup.
%install
rm -rf $RPM_SOURCE_DIR/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)/
mkdir $RPM_SOURCE_DIR/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
rsync -av $RPM_SOURCE_DIR/puppet-<%= hostname %>/* $RPM_SOURCE_DIR/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)/
rsync -av $RPM_SOURCE_DIR/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)/* %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)/
rm -rf $RPM_SOURCE_DIR/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)/

%clean
rm -rf $RPM_BUILD_ROOT

%pretrans
%pre
chage -l sysutil 2>&1 >/dev/null
  if [ $? != "0" ]; then
    /usr/sbin/useradd -f0 -p '\$1\$quu6T/\$e2KG6O0h1g83MX.aU8INl.' -u 607 -G users,integrators -c "system utility account for automation purposes" -m -d /home/sysutil -s /bin/bash sysutil 2>&1 >/dev/null
  fi

# chown -R sysutil.sysutil ~sysutil

# this is on the client, right after the rpm package makes it to the client and runs.
%post
mkdir -p ~sysutil/redhat/BUILD ~sysutil/redhat/SRPMS
chown -R sysutil.sysutil ~sysutil
chmod 700 ~sysutil/*.sh ~sysutil/.gnu*
# /usr/bin/puppet -d -l /var/log/puppet/puppet-<%= hostname %>.log /etc/puppet/manifests/<%= hostname %>.pp

# this is the uninstall or upgrade from the perspective of: yum remove or yum upgrade on the client
%preun
%postun
if [ $1 = 0 ]; then
        if [ -d /etc/puppet/manifests ]; then
          rm -rf /etc/puppet/manifests/<%= hostname %>.pp /etc/puppet/modules/<%= hostname %>
        fi
        if [ -d ~sysutil ]; then
          chage -l sysutil 2>&1 >/dev/null
            if [ $? == "0" ]; then
              userdel sysutil 2>&1 >/dev/null
            fi
        fi
fi
%posttrans

%files
%defattr(-,root,root,-)
   /etc/puppet/modules/<%= hostname %>/manifests/init.pp
   /etc/puppet/modules/<%= hostname %>/templates/hosts
   /etc/puppet/modules/<%= hostname %>/templates/bacula-fd.conf
   /etc/puppet/modules/<%= hostname %>/templates/nrpe.cfg
   /etc/puppet/modules/<%= hostname %>/templates/puppet-<%= hostname %>-yum.sh
   /etc/puppet/modules/<%= hostname %>/templates/puppet-<%= hostname %>-cron.sh
   /etc/puppet/modules/<%= hostname %>/templates/snmpd.conf
   /etc/puppet/modules/<%= hostname %>/templates/snmpd.conf.init
   /etc/puppet/modules/<%= hostname %>/templates/snmpd.conf.new
   /etc/puppet/modules/<%= hostname %>/templates/sudoers
   /etc/puppet/modules/<%= hostname %>/source/check_cpu_perf.sh
   /etc/puppet/modules/<%= hostname %>/source/GPG-SPAWAR-KEY
   /etc/puppet/modules/<%= hostname %>/source/check_cpu_perf.sh
   /etc/puppet/modules/<%= hostname %>/source/RPM-GPG-KEY-EPEL
   /etc/puppet/modules/<%= hostname %>/source/RPM-GPG-KEY-oracle
   /etc/puppet/modules/<%= hostname %>/source/VMWARE-PACKAGING-GPG-KEY.pub
   /etc/puppet/modules/<%= hostname %>/source/forge-cert.p12
   /etc/puppet/modules/<%= hostname %>/source/install-linux-45-1470
   /etc/puppet/modules/<%= hostname %>/source/install-linux-45-1812.sh
   /etc/puppet/manifests/<%= hostname %>.pp

# %doc

# %changelog
# * Mon Mar 14 2011 Aaron Prayther <aprayther@lce.com - .001-1
# -first stab
