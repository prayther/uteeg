Summary: Tomcat6 installation package using gzipped tar
Name: esmtestjaxws
Version: 1.0.0
Release: 1
License: GPL
# We should define some standards for this perhaps, SIL, service and config/source?
Group: nces-spawar-sil
#URL: http://www.tomcat.apache.org
Source: esmtestjaxws-1.0.0.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

Requires: apache-tomcat = 6.0.32
Packager: desantisj

%description
Test JAX-WS Web Service for ESM
# The first setup command handles Source: above.   The seocnd command handles the second source tag Source1: The "-a 1" says indicates "Source1", -D says don't delete the directory, -T tells it not to unpack Source0
%prep
%setup 

%build

%pre


%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/opt/apache-tomcat-6.0.32/lib
mkdir -p $RPM_BUILD_ROOT/opt/apache-tomcat-6.0.32/webapps
mkdir -p $RPM_BUILD_ROOT/opt/apache-tomcat-6.0.32/endorsed
mkdir -p $RPM_BUILD_ROOT/opt/apache-tomcat-6.0.32/conf
cp $RPM_BUILD_DIR/esmtestjaxws-1.0.0/endorsed/*.jar $RPM_BUILD_ROOT/opt/apache-tomcat-6.0.32/endorsed
cp $RPM_BUILD_DIR/esmtestjaxws-1.0.0/lib/*.jar $RPM_BUILD_ROOT/opt/apache-tomcat-6.0.32/lib
cp $RPM_BUILD_DIR/esmtestjaxws-1.0.0/webapps/*.war $RPM_BUILD_ROOT/opt/apache-tomcat-6.0.32/webapps
cp $RPM_BUILD_DIR/esmtestjaxws-1.0.0/conf/*.xml $RPM_BUILD_ROOT/opt/apache-tomcat-6.0.32/conf


%post 
cp /opt/apache-tomcat-6.0.32/conf/server.xml /opt/apache-tomcat-6.0.32/conf/server.xml.bak
# this command inserts the Valve confiugration in server.xml before the </Host> tag
sed '/<\/Host>/i <Valve className="mil.disa.nces.esm.agent.ValveAgent" path="../conf/AddNumbersAgentConfig.xml"\/>' /opt/apache-tomcat-6.0.32/conf/server.xml > /opt/apache-tomcat-6.0.32/conf/server.xml.valve
mv /opt/apache-tomcat-6.0.32/conf/server.xml.valve /opt/apache-tomcat-6.0.32/conf/server.xml


%postun


%clean
rm -rf $RPM_BUILD_ROOT

%files 
%defattr(-, tomcat6, tomcat, 0744)
/opt/apache-tomcat-6.0.32/endorsed/jaxws-api.jar
/opt/apache-tomcat-6.0.32/endorsed/jaxb-api.jar
/opt/apache-tomcat-6.0.32/lib/activation.jar
/opt/apache-tomcat-6.0.32/lib/FastInfoset.jar
/opt/apache-tomcat-6.0.32/lib/gmbal-api-only.jar
/opt/apache-tomcat-6.0.32/lib/ha-api.jar
/opt/apache-tomcat-6.0.32/lib/http.jar
/opt/apache-tomcat-6.0.32/lib/jaxws-api.jar
/opt/apache-tomcat-6.0.32/lib/jaxb-impl.jar
/opt/apache-tomcat-6.0.32/lib/jaxb-xjc.jar
/opt/apache-tomcat-6.0.32/lib/jaxb-api.jar
/opt/apache-tomcat-6.0.32/lib/jaxws-rt.jar
/opt/apache-tomcat-6.0.32/lib/jaxws-tools.jar
/opt/apache-tomcat-6.0.32/lib/jsr173_api.jar
/opt/apache-tomcat-6.0.32/lib/jsr181-api.jar
/opt/apache-tomcat-6.0.32/lib/jsr250-api.jar
/opt/apache-tomcat-6.0.32/lib/management-api.jar
/opt/apache-tomcat-6.0.32/lib/mimepull.jar
/opt/apache-tomcat-6.0.32/lib/policy.jar
/opt/apache-tomcat-6.0.32/lib/resolver.jar
/opt/apache-tomcat-6.0.32/lib/saaj-api.jar
/opt/apache-tomcat-6.0.32/lib/saaj-impl.jar
/opt/apache-tomcat-6.0.32/lib/stax-ex.jar
/opt/apache-tomcat-6.0.32/lib/streambuffer.jar
/opt/apache-tomcat-6.0.32/lib/woodstox.jar
/opt/apache-tomcat-6.0.32/webapps/jaxws-fromwsdl.war
/opt/apache-tomcat-6.0.32/conf/AddNumbersAgentConfig.xml

%changelog

