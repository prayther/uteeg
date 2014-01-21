Summary: ESM Valve Agent install
Name: esm-agent
Version: 7.0.0
Release: 4 
License: Gov

Group: nces-spawar-sil
Source: esm-agent-7.0.0.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

Requires: apache-tomcat = 6.0.32
Packager: desantisj

%description
This is a simple RPM that contains the ESM agent jar
This will allow new releases of the JAR to be deployed seperately

%prep
%setup 

%build

%pre


%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/opt/apache-tomcat-6.0.32/lib
cp $RPM_BUILD_DIR/esm-agent-7.0.0/*.jar $RPM_BUILD_ROOT/opt/apache-tomcat-6.0.32/lib


%post 


%postun


%clean
rm -rf $RPM_BUILD_ROOT

%files 
%defattr(-, tomcat6, tomcat, 0744)
/opt/apache-tomcat-6.0.32/lib/esm-agent-7.0.0.1-RELEASE.jar

%changelog

