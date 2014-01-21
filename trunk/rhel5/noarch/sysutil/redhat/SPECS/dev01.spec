# $Id: dev01.spec 763 2012-08-15 13:52:46Z sysutil $
Name:  dev01
Version:  .0.17
Release:  1%{?dist}
Summary:  dev rpm for developing "role" configuration
Packager: Aaron Prayther aprayther@lce.com Life Cycle Engineering
Group: Development/Tools
License:  GPL
URL: https://software.forge.mil
Source:  dev01.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch: noarch
#BuildRequires:
#Requires: defaults.rpm

%description
The dev01 package delivers, a test for building "roles" dev01 and dev02 as a complimentary "roles" to each other, like primary and secondary.
This will deliver all the "defaults", stig, /etc/hosts, etc but those can be added to, deleted, or modified by making appropriate entries for "role".
Creating a directory in "role" that is empty would eliminate that from being included in the 

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
%setup -q -n dev01

%build

%pre
if ! id sysutil >& /dev/null; then
%{_sbindir}/useradd -f2 -p '\$2\$quu6T/\$e2KG6O2h1g83MX.aU8INl.' -u 607 -G users -c "system utility account for automation purposes" -m -d /home/sysutil -s /bin/bash sysutil
fi

# this is just taking a src file and moving it around /src/redhat/* and /var/tmp/ to keep things straight.. then cleanup.
%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/dev01
rsync -av $RPM_BUILD_DIR/dev01 $RPM_BUILD_ROOT/home/

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
-making dev01 role rpm
