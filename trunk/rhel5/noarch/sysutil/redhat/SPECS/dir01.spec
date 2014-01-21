# $Id: dir01.spec 763 2012-08-15 13:52:46Z sysutil $
Name:  dir01
Version:  .0.5
Release:  1%{?dist}
Summary:  openldap dir01 master
Packager: Aaron Prayther aprayther@lce.com Life Cycle Engineering
Group: infrastructure
License:  GPL
URL: https://software.forge.mil
Source:  dir01.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch: noarch
#BuildRequires:
Requires: defaults

%description
role based configuration for the master openldap server dir01

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
%setup -q -n dir01

%build

%pre

# this is just taking a src file and moving it around /src/redhat/* and /var/tmp/ to keep things straight.. then cleanup.
%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT
# the reason this makes te dir01 directory is because that's what rsync does. 
rsync -av $RPM_BUILD_DIR/dir01/etc $RPM_BUILD_ROOT

# for some reason that i have not figured out the {files} stanza below does not set the owneship correctly
# on all the files, so this chown is a work around
%post

# this is the uninstall or upgrade from the perspective of: yum remove or yum upgrade on the client
%postun

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(755,root,root)
   /etc/puppet/files/ldapData.ldif
   /etc/puppet/manifests/dir-master.pp
   /etc/puppet/manifests/dir-wipe.pp

# %doc

%changelog
* Thu Aug 04 2011 Aaron Prayther <apraytherATlceDOTcom - 001
-making sysutil system account
