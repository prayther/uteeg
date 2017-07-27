#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"
LogFile="../log/virt-inst.log"
LOG_() { while IFS='' read -r line; do echo "$(date)-${0} $line" >> "${LogFile}"; done; }
exec 2> >(LOG_)

source ../etc/virt-inst.cfg

# Nested for loop.
# Outer loop is for each CV that you want to promote.
# The inner loop. LEC_FROM (--from-lifecycle-environment-id), LEC_TO (--to-lifecycle-environment-id).
# When LEC_FROM reaches <= $LE_Count-1 (the last number of hammer --csv lifecycle-environment list) stop.

if [ "${PROMOTEALL}" != "no" ];then
  CV_Count=$(hammer --csv content-view list --organization="${ORG}" | sort -n | grep -vi "Content View ID,Name,Label,Composite,Repository IDs" | awk -F"," '{print $1}')
  LE_Count=$(hammer --csv lifecycle-environment list --organization="${ORG}" | sort -n | grep -vi "ID,Name,Prior" | wc -l)

  for CV in $CV_Count;do
    for (( LEC_FROM=1, LEC_TO=LEC_FROM+1; LEC_FROM <= $LE_Count-1; LEC_FROM++, LEC_TO=LEC_TO+1 ));do
      hammer content-view version promote --organization="${ORG}" --from-lifecycle-environment-id="${LEC_FROM}" --to-lifecycle-environment-id="${LEC_TO}" --content-view-id="${CV}"
    done
  done
fi

# just promote Dev CV's
CV_Count=$(hammer --csv content-view list --organization="${ORG}" | sort -n | grep -vi "Content View ID,Name,Label,Composite,Repository IDs" | awk -F"," '{print $1}')
# the "grep -i dev," is important to just get the Dev lifecycle, from-lifecycle-environment-id="Library" --to-lifecycle-environment-id="Dev"
# if you leave the comman out you will promote everthing to the next lifecycle "Test".
LE_Count_var=$(hammer --csv lifecycle-environment list --organization="${ORG}" | grep -vi "ID,Name,Prior" | grep -i dev, | awk -F"," '{print $1}'
LE_Count=$(echo "${LE_Count_var}" | tr '\n' ' ')
LEC_FROM=1

for CV in $CV_Count;do
  for LEC_TO in $(echo ${LE_Count});do
    hammer content-view version promote --organization="${ORG}" --from-lifecycle-environment-id="${LEC_FROM}" --to-lifecycle-environment-id="${LEC_TO}" --content-view-id="${CV}"
  done
done
