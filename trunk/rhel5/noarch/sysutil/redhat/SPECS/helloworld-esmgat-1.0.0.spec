Summary:  ESM Greet test web service
Name: helloworld-esmtest
Version: 1.0.0
Release: 2
License: GPL
Group: Applications/System 
Source: helloworld-esmtest-1.0.0.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

Requires: apache-tomcat = 6.0.32
Packager: desantisj

# This sets the IP address of the machine on eth0 into the enviornment variable
%define ipaddress %(/sbin/ifconfig  | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}' | grep -v 127.0.0.1)
%description
Test JAX-WS Web Service for ESM
%prep
%setup 

%build

%pre


%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/opt/apache-tomcat-6.0.32/webapps
mkdir -p $RPM_BUILD_ROOT/opt/apache-tomcat-6.0.32/conf
mkdir -p $RPM_BUILD_ROOT/tmp/agentCache
cp $RPM_BUILD_DIR/helloworld-esmtest-1.0.0/webapps/*.war $RPM_BUILD_ROOT/opt/apache-tomcat-6.0.32/webapps
cp $RPM_BUILD_DIR/helloworld-esmtest-1.0.0/conf/*.xml $RPM_BUILD_ROOT/opt/apache-tomcat-6.0.32/conf


%post 
cp /opt/apache-tomcat-6.0.32/conf/server.xml /opt/apache-tomcat-6.0.32/conf/server.xml.bak
# this command inserts the Valve confiugration in server.xml before the </Host> tag
sed '/<\/Host>/i <Valve className="mil.disa.nces.esm.agent.ValveAgent" path="/opt/apache-tomcat-6.0.32/conf/agentconf-greet-services.xml"\/>' /opt/apache-tomcat-6.0.32/conf/server.xml > /opt/apache-tomcat-6.0.32/conf/server.xml.valve
mv /opt/apache-tomcat-6.0.32/conf/server.xml.valve /opt/apache-tomcat-6.0.32/conf/server.xml
# This command replaces "localhost" in the agent file with the FQDN of the host
sed -i "s/localhost/$HOSTNAME/" /opt/apache-tomcat-6.0.32/conf/agentconf-greet-services.xml 
# This replaces the REPLACE_IP_ADDRESS string with the ipaddress using the marco defined above
sed -i "s/REPLACE_IP_ADDRESS/%{ipaddress}/" /opt/apache-tomcat-6.0.32/conf/agentconf-greet-services.xml

%postun


%clean
rm -rf $RPM_BUILD_ROOT

%files 
%defattr(-, tomcat6, tomcat, 0744)
/opt/apache-tomcat-6.0.32/webapps/HelloWorld.war
/opt/apache-tomcat-6.0.32/conf/agentconf-greet-services.xml
# We need to make the agentCache directory
%attr(0744, tomcat6, tomcat) /tmp/agentCache

%changelog

