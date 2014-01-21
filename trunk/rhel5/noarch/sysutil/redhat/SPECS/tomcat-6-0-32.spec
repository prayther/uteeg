Summary: Tomcat6 installation package using gzipped tar
Name: apache-tomcat
Version: 6.0.32
Release: 2
License: GPL
# We should define some standards for this perhaps, SIL, service and config/source?
Group: Applications/Internet
URL: http://www.tomcat.apache.org
Source: apache-tomcat-6.0.32.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

BuildRequires: jre >= 1.6.0
Packager: desantisj

%description
Tomcat is a servlet container used to host web applications.  This rpm package automates install of the latest version of Tomcat 6 available at www.tomcat.apache.org

# The first setup command handles Source: above.   The seocnd command handles the second source tag Source1: The "-a 1" says indicates "Source1", -D says don't delete the directory, -T tells it not to unpack Source0
%prep
%setup -q

%build

%pre
if grep tomcat: /etc/group >> /dev/null ; then
 : # group already exists
else
 %{_sbindir}/groupadd tomcat 
fi

if ! id tomcat6 >& /dev/null; then 
 %{_sbindir}/useradd tomcat6 -g tomcat -p P@$$w0rd
fi


%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/opt/apache-tomcat-6.0.32
mkdir -p $RPM_BUILD_ROOT/etc/init.d
cp -r $RPM_BUILD_DIR/apache-tomcat-6.0.32 $RPM_BUILD_ROOT/opt
cp $RPM_BUILD_DIR/apache-tomcat-6.0.32/startup/tomcat6 $RPM_BUILD_ROOT/etc/init.d


%post 
#chkconfig --add tomcat6
ln -s /etc/init.d/tomcat6 /etc/rc3.d/S99tomcat6
ln -s /etc/init.d/tomcat6 /etc/rc3.d/K01tomcat6

%postun
rm /etc/rc3.d/S99tomcat6
rm /etc/rc3.d/K01tomcat6
#chkconfig --del tomcat6
rm -rf /opt/apache-tomcat-6.0.32
 %{_sbindir}/userdel -rf tomcat6 
 %{_sbindir}/groupdel tomcat 


%clean
rm -rf $RPM_BUILD_ROOT

%files 
%defattr(-, tomcat6, tomcat, 0744)
/opt/apache-tomcat-6.0.32/*
# Here we make server.xml a config file.
%config /opt/apache-tomcat-6.0.32/conf/server.xml
# herre we set the ownership of the startup/shutdown file
%attr(755, root, root) /etc/init.d/tomcat6

%changelog

