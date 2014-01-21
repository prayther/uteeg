# $Id: db02.spec 763 2012-08-15 13:52:46Z sysutil $
Name:  db02
Version:  .0.9
Release:  1%{?dist}
Summary:  sysutil system account for SVN and RPM build
Packager: Aaron Prayther aprayther@lce.com Life Cycle Engineering
Group: Development/Tools
License:  GPL
URL: https://software.forge.mil
Source:  db02.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch: noarch
#BuildRequires:
Requires: subversion, rpm-build, expect, rpmlint, rpmdevtools, puppet, spacecmd

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
%setup -q -n db02

%build

%pre
if ! id sysutil >& /dev/null; then
%{_sbindir}/useradd -f2 -p '\$2\$quu6T/\$e2KG6O2h1g83MX.aU8INl.' -u 607 -G users -c "system utility account for automation purposes" -m -d /home/sysutil -s /bin/bash sysutil
fi

# this is just taking a src file and moving it around /src/redhat/* and /var/tmp/ to keep things straight.. then cleanup.
%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/db02
rsync -av $RPM_BUILD_DIR/db02 $RPM_BUILD_ROOT/home/

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
%defattr(700,sysutil,sysutil)

# %doc

%changelog
* Thu Aug 04 2011 Aaron Prayther <apraytherATlceDOTcom - 001
-making sysutil system account
