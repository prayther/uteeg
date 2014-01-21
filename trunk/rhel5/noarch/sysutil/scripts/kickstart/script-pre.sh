%pre  --logfile=/tmp/partitioning.log
${ip=`ip address | grep -v 127.0.0.1 | grep -v inet6 | grep inet | awk -F" " '{ print $2 }' | awk -F/ '{ print $1 }'`}
wget -O /tmp/partitioning http://rhn.chs.spawar.navy.mil/partition.files/$ip.partitioning
%end