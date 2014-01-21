Summary:  ESM Greet test web service
Name: helloworld-esmtest-jumpatch
Version: 1.0.0
Release: 3
License: GPL
Group: Applications/System 
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch

Requires: apache-tomcat = 6.0.32 helloworld-esmtest = 1.0.0-2
Packager: desantisj

%define ipaddress %(/sbin/ifconfig  | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}' | grep -v 127.0.0.1)
%description

%build

%pre

%install


%post 
cp /opt/apache-tomcat-6.0.32/conf/agentconf-greet-services.xml /opt/apache-tomcat-6.0.32/conf/agentconf-greet-services.xml.rpmsave
sed -i "s/<Configuration type=\"WS-Notification\" endpoint=\"https:\/\/esm.chs.spawar.navy.mil\/esm-manager\/services\/QoSMetricsReceiveService\"/<Configuration type=\"WS-Notification\" endpoint=\"https:\/\/jum-sb.chs.spawar.navy.mil\/msg\/services\"/" /opt/apache-tomcat-6.0.32/conf/agentconf-greet-services.xml
sed -i "s/topic=\"peo.ges.esm.metrics\" hostname-verification=\"false\" register=\"false\"\/>/topic=\"esm.operationalstatus\" hostname-verification=\"false\" register=\"true\" \/>/" /opt/apache-tomcat-6.0.32/conf/agentconf-greet-services.xml


%postun

%clean

%files 

%changelog



