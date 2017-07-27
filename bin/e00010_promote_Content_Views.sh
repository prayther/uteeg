#!/bin/bash -x

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"
LogFile="../log/virt-inst.log"
LOG_() { while IFS='' read -r line; do echo "$(date)-${0} $line" >> "${LogFile}"; done; }
exec 2> >(LOG_)

source ../etc/virt-inst.cfg

# This is working with ID numbers, so just get the number of CV's (Content View) and LE (Lifecycle Env).
# List it and remove any extraneous lines that you don't want.
# Lifecycles need to be in sequence. If you just create them once I don't see a problem. If you delete and add and get numbers out of seq.
# This won't work.

# Nested for loop.
# Outer loop is for each CV that you want to promote.
# If you promote CCV's before CV's you are promoting in the wrong order. Right ???
# The inner loop. LEC_FROM (--from-lifecycle-environment-id), LEC_TO (--to-lifecycle-environment-id).
# When LEC_FROM reaches <= $LE_Count-1 (the last number of hammer --csv lifecycle-environment list) stop.

#CV_Count=$(hammer --csv content-view list --organization=redhat | sort -n | grep -vi "Content View ID,Name,Label,Composite,Repository IDs" | wc -l)
#CV_Count=$(hammer --csv content-view list --organization=redhat | sort -n | grep -vi "Content View ID,Name,Label,Composite,Repository IDs" | awk -F"," '{print $1}')
#LE_Count=$(hammer --csv lifecycle-environment list --organization=redhat | sort -n | grep -vi "ID,Name,Prior" | wc -l)
#
#for CV in $($CV_Count | tr ' ' ',');do
#  for (( LEC_FROM=1, LEC_TO=LEC_FROM+1; LEC_FROM <= $LE_Count-1; LEC_FROM++, LEC_TO=LEC_TO+1 ));do
#    hammer content-view version promote --organization=redhat --from-lifecycle-environment-id=${LEC_FROM} --to-lifecycle-environment-id=${LEC_TO} --content-view-id=${CV}
#  done
#done
# there is an error below that tries to promote the default view... not worried about it now. those fail pretty quickly and then the rest go.

if [ "${PROMOTEALL}" != "no" ];then
  CV_Count=$(hammer --csv content-view list --organization=redhat | sort -n | grep -vi "Content View ID,Name,Label,Composite,Repository IDs" | awk -F"," '{print $1}')
  LE_Count=$(hammer --csv lifecycle-environment list --organization=redhat | sort -n | grep -vi "ID,Name,Prior" | wc -l)

  for CV in $CV_Count;do
    for (( LEC_FROM=1, LEC_TO=LEC_FROM+1; LEC_FROM <= $LE_Count-1; LEC_FROM++, LEC_TO=LEC_TO+1 ));do
      hammer content-view version promote --organization=redhat --from-lifecycle-environment-id=${LEC_FROM} --to-lifecycle-environment-id=${LEC_TO} --content-view-id=${CV}
    done
  done
fi

# just promote Dev CV's
CV_Count=$(hammer --csv content-view list --organization=redhat | sort -n | grep -vi "Content View ID,Name,Label,Composite,Repository IDs" | awk -F"," '{print $1}')
#LE_Count=$(hammer --csv lifecycle-environment list --organization=redhat | grep -i dev | sort -n | grep -vi "ID,Name,Prior" | wc -l)
LE_Count_var=$(hammer --csv lifecycle-environment list --organization=redhat | grep -i dev | sort -n | grep -vi "ID,Name,Prior" | awk -F"," '{print $1}')
LE_Count=$(echo "${LE_Count_var}" | tr '\n' ' ')
LEC_FROM=1

for CV in $CV_Count;do
  for LEC_TO in $(echo ${LE_Count});do
    hammer content-view version promote --organization=redhat --from-lifecycle-environment-id=${LEC_FROM} --to-lifecycle-environment-id=${LEC_TO} --content-view-id=${CV}
  done
done

