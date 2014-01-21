# $Id: sysutil.spec 763 2012-08-15 13:52:46Z sysutil $
# $Id: sysutil.spec 763 2012-08-15 13:52:46Z sysutil $
Name:  sysutil
Version:  .0.46
Release:  1%{?dist}
Summary:  sysutil system account for SVN and RPM build
Packager: Aaron Prayther aprayther@lce.com Life Cycle Engineering
Group: Development/Tools
License:  GPL
URL: https://software.forge.mil
Source:  sysutil.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch: noarch
#BuildRequires:
Requires: subversion, rpm-build, rhnpush, expect, rpmlint, rpmdevtools, puppet-0.25.5, spacecmd

%description
The sysutil package delivers, RPM build tools, subversion and the ability to build "role" specific rpm's for services and applications.  Reading in hosts from the comma delimited file hosts.role.txt

# Yes! RPM does this by running ldd on every executable program in a package's %files list. Since ldd provides a list of the shared libraries each program requires, both halves of the equation are complete — that is, the packages that make shared libraries available, and the packages that require those shared libraries, are tracked by RPM. RPM can then take that information into account when packages are installed, upgraded, or erased.
# was braking my build, because of the vmware perl sdk stuff that is in the %files
AutoReqProv: no

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
%setup -q -n sysutil

%build

%pre
if ! id sysutil >& /dev/null; then
%{_sbindir}/useradd -f2 -p '\$2\$quu6T/\$e2KG6O2h1g83MX.aU8INl.' -u 607 -G users -c "system utility account for automation purposes" -m -d /home/sysutil -s /bin/bash sysutil
fi

# this is just taking a src file and moving it around /src/redhat/* and /var/tmp/ to keep things straight.. then cleanup.
%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/sysutil
rsync -av $RPM_BUILD_DIR/sysutil $RPM_BUILD_ROOT/home/

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
/home/sysutil/.gnupg/GPG-SPAWAR-KEY
/home/sysutil/.gnupg/gpg.conf
/home/sysutil/.gnupg/pubring.gpg
/home/sysutil/.gnupg/random_seed
/home/sysutil/.gnupg/secring.gpg
/home/sysutil/.gnupg/trustdb.gpg
/home/sysutil/.rpmmacros
/home/sysutil/.ssh/id_rsa
/home/sysutil/.ssh/id_rsa.pub
/home/sysutil/.subversion/README.txt
/home/sysutil/.subversion/auth/svn.ssl.server/011bf0895b14f236d333785a19688eb5
/home/sysutil/.subversion/config
/home/sysutil/.subversion/servers
/home/sysutil/forge-cert.p12
/home/sysutil/redhat/RPMS/README
/home/sysutil/redhat/SOURCES/README
/home/sysutil/redhat/SPECS/README
/home/sysutil/redhat/SPECS/avvdatspawar.spec
/home/sysutil/redhat/SPECS/esm-agent-7.0.0.spec
/home/sysutil/redhat/SPECS/esmgattestjaxws-1.0.0.spec
/home/sysutil/redhat/SPECS/helloworld-esmgat-1.0.0.spec
/home/sysutil/redhat/SPECS/helloworld-esmgat-jumpatch-1.0.0.3.spec
/home/sysutil/redhat/SPECS/puppet-nces-sb-vm-04.spec
/home/sysutil/redhat/SPECS/puppet-site.spec
/home/sysutil/redhat/SPECS/puppet-stig.spec
/home/sysutil/redhat/SPECS/sysutil.spec
/home/sysutil/redhat/SPECS/tomcat-6-0-32.spec
/home/sysutil/redhat/SPECS/uvscanspawar.spec
/home/sysutil/redhat/SPECS/db01.spec
/home/sysutil/redhat/SPECS/db02.spec
/home/sysutil/redhat/SPECS/dir01.spec
/home/sysutil/redhat/SPECS/dir02.spec
/home/sysutil/redhat/SPECS/dir03.spec
/home/sysutil/redhat/SPECS/dir04.spec
/home/sysutil/redhat/SPECS/esmgmt01.spec
/home/sysutil/redhat/SPECS/esmgmt02.spec
/home/sysutil/redhat/SPECS/esmui01.spec
/home/sysutil/redhat/SPECS/esmui02.spec
/home/sysutil/redhat/SPECS/tomcat-all.spec
/home/sysutil/redhat/SPECS/defaults.spec
/home/sysutil/redhat/SPECS/dev01-defaults.spec
/home/sysutil/redhat/SPECS/dev01.spec
/home/sysutil/redhat/SPECS/dev02.spec
/home/sysutil/redhat/SPECS/template.puppet-hosts.spec
/home/sysutil/scripts/PowerCLI/PowerCLIQuickReference.pdf
/home/sysutil/scripts/PowerCLI/build_vm_kickstart_for_each.ps1
/home/sysutil/scripts/PowerCLI/get_macs.ps1
/home/sysutil/scripts/PowerCLI/get_macs.txt
/home/sysutil/scripts/PowerCLI/hexnumbering.pdf
/home/sysutil/scripts/PowerCLI/testCommands.ps1
/home/sysutil/scripts/PowerCLI/config-1-hosts.txt
/home/sysutil/scripts/PowerCLI/vsphere_directory_structure.ps1
/home/sysutil/scripts/README
/home/sysutil/scripts/passwd.txt
/home/sysutil/scripts/user.txt
/home/sysutil/scripts/RHELisoBootForKS/README
/home/sysutil/scripts/RHELisoBootForKS/hosts
/home/sysutil/scripts/RHELisoBootForKS/isogen.sh
/home/sysutil/scripts/RHELisoBootForKS/isolinux/TRANS.TBL
/home/sysutil/scripts/RHELisoBootForKS/isolinux/boot.cat
/home/sysutil/scripts/RHELisoBootForKS/isolinux/boot.msg
/home/sysutil/scripts/RHELisoBootForKS/isolinux/general.msg
/home/sysutil/scripts/RHELisoBootForKS/isolinux/initrd.img
/home/sysutil/scripts/RHELisoBootForKS/isolinux/isolinux.bin
/home/sysutil/scripts/RHELisoBootForKS/isolinux/isolinux.cfg
/home/sysutil/scripts/RHELisoBootForKS/isolinux/isolinux.cfg.template
/home/sysutil/scripts/RHELisoBootForKS/isolinux/memtest
/home/sysutil/scripts/RHELisoBootForKS/isolinux/menu.c32
/home/sysutil/scripts/RHELisoBootForKS/isolinux/options.msg
/home/sysutil/scripts/RHELisoBootForKS/isolinux/param.msg
/home/sysutil/scripts/RHELisoBootForKS/isolinux/rescue.msg
/home/sysutil/scripts/RHELisoBootForKS/isolinux/splash.lss
/home/sysutil/scripts/RHELisoBootForKS/isolinux/vmlinuz
/home/sysutil/scripts/RPMBuild/RPMaddsign.sh
/home/sysutil/scripts/RPMBuild/rpmbuild.sh
/home/sysutil/scripts/disk-check.sh
/home/sysutil/scripts/errata-2.0.pl
/home/sysutil/scripts/hosts.master.txt
/home/sysutil/scripts/permanent_svn.sh
/home/sysutil/scripts/rpm_build-svn-to-rpmbuild-puppet-stig.sh
/home/sysutil/scripts/rpmbuild_hosts.role.txt_svn_to_rpm_to_sat.sh
/home/sysutil/scripts/sat-clone-channels.sh
/home/sysutil/scripts/sat-create-orgs.sh
/home/sysutil/scripts/sat-inventory.sh
/home/sysutil/scripts/sat-set-org-system-sw-entitlements.sh
/home/sysutil/scripts/satellite-clone-kickstart-from-hosts.sh
/home/sysutil/scripts/satellite-db-backup-primary.sh
/home/sysutil/scripts/satellite-db-backup-rsync-primary.sh
/home/sysutil/scripts/satellite-db-backup-secondary.sh
/home/sysutil/scripts/satellite-db-backup.sh
/home/sysutil/scripts/satellite-db-restore-secondary.sh
/home/sysutil/scripts/satellite-sync-cron.sh
/home/sysutil/scripts/slim-channels-svn-to-sat.sh
/home/sysutil/scripts/slim-kickstart-svn-to-sat.sh
/home/sysutil/scripts/slim-rpm-src-svn-to-util.sh
/home/sysutil/scripts/slim-sat-channel-create.sh
/home/sysutil/scripts/slim-sat-kickstart-create.sh
/home/sysutil/scripts/slim-sat-oracle-backup.sh
/home/sysutil/scripts/slim-sat-rhnpush-rpm.sh
/home/sysutil/scripts/slim-svn-to-sat.sh
/home/sysutil/scripts/svn_update_RPM_build_avvdat-xxxx.sh
/home/sysutil/scripts/svn_update_RPM_build_puppet-site.sh
/home/sysutil/scripts/svn_update_RPM_build_puppet-stig.sh
/home/sysutil/scripts/svn_update_RPM_build_uvscan.sh
   /home/sysutil/redhat/SPECS/dev02-defaults.spec
   /home/sysutil/scripts/PowerCLI/get_thick_provisioned.ps1
   /home/sysutil/scripts/PowerCLI/partitioning.ps1
   /home/sysutil/scripts/config.cfg
   /home/sysutil/scripts/hosts
   /home/sysutil/scripts/isoBoot/isogen-5-u7.sh
   /home/sysutil/scripts/isoBoot/isolinux/TRANS.TBL
   /home/sysutil/scripts/isoBoot/isolinux/boot.cat
   /home/sysutil/scripts/isoBoot/isolinux/boot.msg
   /home/sysutil/scripts/isoBoot/isolinux/general.msg
   /home/sysutil/scripts/isoBoot/isolinux/initrd.img
   /home/sysutil/scripts/isoBoot/isolinux/isolinux.bin
   /home/sysutil/scripts/isoBoot/isolinux/isolinux.cfg
   /home/sysutil/scripts/isoBoot/isolinux/isolinux.cfg.template
   /home/sysutil/scripts/isoBoot/isolinux/memtest
   /home/sysutil/scripts/isoBoot/isolinux/options.msg
   /home/sysutil/scripts/isoBoot/isolinux/param.msg
   /home/sysutil/scripts/isoBoot/isolinux/rescue.msg
   /home/sysutil/scripts/isoBoot/isolinux/splash.lss
   /home/sysutil/scripts/isoBoot/isolinux/vmlinuz
   /home/sysutil/scripts/sim.cfg
   /home/sysutil/scripts/sim.cfg.ps1
   /home/sysutil/scripts/test.sh
   /home/sysutil/scripts/vmware/AppUtil/HostUtil.pm
   /home/sysutil/scripts/vmware/AppUtil/VMUtil.pm
   /home/sysutil/scripts/vmware/AppUtil/XMLInputUtil.pm
   /home/sysutil/scripts/vmware/addVMAnnotation.input
   /home/sysutil/scripts/vmware/addVMAnnotation.pl
   /home/sysutil/scripts/vmware/buildServer.sh
   /home/sysutil/scripts/vmware/makeXMLConfigFile.pl
   /home/sysutil/scripts/vmware/makeXMLConfigFile.pl.orig
   /home/sysutil/scripts/vmware/powerops.pl
   /home/sysutil/scripts/vmware/sample_hosts.in
   /home/sysutil/scripts/vmware/vmISOManagement.pl
   /home/sysutil/scripts/vmware/vmcreate.pl
   /home/sysutil/scripts/vmware/vmcreate.xml
   /home/sysutil/scripts/vmware/vmcreate.xml.example
   /home/sysutil/scripts/vmware/vmcreate.xml.working
   /home/sysutil/scripts/vmware/vmcreate.xsd
   /home/sysutil/scripts/vmware/vmreconfig.pl
   /home/sysutil/scripts/vmware/vmreconfig.xml
   /home/sysutil/scripts/vmware/vmreconfig.xml.ajp
   /home/sysutil/scripts/vmware/vmreconfig.xml.bak
   /home/sysutil/scripts/vmware/vmreconfig.xml.example
   /home/sysutil/scripts/vmware/vmreconfig.xsd
   /home/sysutil/scripts/isoBoot/isogen.sh
   /home/sysutil/scripts/sysutil.private
   /home/sysutil/scripts/tst-template-2-ges
   /home/sysutil/scripts/vmware/changeVMMac.pl
   /home/sysutil/scripts/vmware/drs-control-final.pl
   /home/sysutil/scripts/vmware/drsConfig.pl
   /home/sysutil/scripts/vmware/makeXMLvmreconfig.pl
   /home/sysutil/scripts/vmware/partitioning.template
   /home/sysutil/scripts/vmware/tempges-role-tst-data
   /home/sysutil/scripts/vmware/vminfo.pl
   /home/sysutil/scripts/vmware/vmreconfig.xml.template
   /home/sysutil/scripts/vmware/whichClusterIsMyVMin.pl
   /home/sysutil/simweb/sim/css/style.css
   /home/sysutil/simweb/sim/img/accepted_48.png
   /home/sysutil/simweb/sim/img/cancel_48.png
   /home/sysutil/simweb/sim/img/loading.gif
   /home/sysutil/simweb/sim/index.php
   /home/sysutil/simweb/sim/index.php.ajp
   /home/sysutil/simweb/sim/info.php
   /home/sysutil/simweb/sim/js/libs/jquery-1.7.1.min.js
   /home/sysutil/simweb/sim/js/libs/modernizr-2.0.6.min.js
   /home/sysutil/simweb/sim/js/plugins.js
   /home/sysutil/simweb/sim/js/script.js
   /home/sysutil/simweb/sim/output/output.txt
   /home/sysutil/simweb/sim/process.php
   /home/sysutil/simweb/sim/process.php.ajp



# %doc

%changelog
* Thu Aug 04 2011 Aaron Prayther <apraytherATlceDOTcom - 001
-making sysutil system account
