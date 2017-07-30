#!/bin/bash -x

#https://github.com/prayther/uteeg
#http://www.opensourcerers.org/installing-and-configuring-red-hat-satellite-6-via-shell-script/
# mschreie@redhat.com
# setting up  a satellite for demo purposes
# mainly following Adrian Bredshaws awsome book: http://gsw-hammer.documentation.rocks/

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export HOME=/root
cd "${BASH_SOURCE%/*}"

logfile="../log/$(basename $0 .sh).log"
donefile="../log/$(basename $0 .sh).done"
touch $logfile
touch $donefile

exec > >(tee -a "$logfile") 2>&1

echo "###INFO: Starting $0"
echo "###INFO: $(date)"

# read configuration (needs to be adopted!)
#. ./satenv.sh
source ../etc/virt-inst.cfg


doit() {
        echo "INFO: doit: $@" >&2
        cmd2grep=$(echo "$*" | sed -e 's/\\//' | tr '\n' ' ')
        grep -q "$cmd2grep" $donefile
        if [ $? -eq 0 ] ; then
                echo "INFO: doit: found cmd in donefile - skipping" >&2
        else
                "$@" 2>&1 || {
                        echo "ERROR: cmd was unsuccessfull RC: $? - bailing out" >&2
                        exit 1
                }
                echo "$cmd2grep" >> $donefile
                echo "INFO: doit: cmd finished successfull" >&2
        fi
}

# Nested for loop.
# Outer loop is for each CV that you want to promote.
# The inner loop. LEC_FROM (--from-lifecycle-environment-id), LEC_TO (--to-lifecycle-environment-id).
# When LEC_FROM reaches <= $LE_Count-1 (the last number of hammer --csv lifecycle-environment list) stop.

promote_cv () { if [ "${PROMOTEALL}" != "no" ];then
  CV_Count=$(hammer --csv content-view list --organization="${ORG}" | sort -n | grep -vi "Content View ID,Name,Label,Composite,Repository IDs" | awk -F"," '{print $1}')
  LE_Count=$(hammer --csv lifecycle-environment list --organization="${ORG}" | sort -n | grep -vi "ID,Name,Prior" | wc -l)

  for CV in $CV_Count;do
    for (( LEC_FROM=1, LEC_TO=LEC_FROM+1; LEC_FROM <= $LE_Count-1; LEC_FROM++, LEC_TO=LEC_TO+1 ));do
      hammer content-view version promote --organization="${ORG}" --from-lifecycle-environment-id="${LEC_FROM}" --to-lifecycle-environment-id="${LEC_TO}" --content-view-id="${CV}"
    done
  done
fi
}
doit promote_cv

# just promote Dev CV's
doit CV_Count=$(hammer --csv content-view list --organization="${ORG}" | sort -n | grep -vi "Content View ID,Name,Label,Composite,Repository IDs" | awk -F"," '{print $1}')
# the "grep -i dev," is important to just get the Dev lifecycle, from-lifecycle-environment-id="Library" --to-lifecycle-environment-id="Dev"
# if you leave the comman out you will promote everthing to the next lifecycle "Test".
doit LE_Count_var=$(hammer --csv lifecycle-environment list --organization="${ORG}" | grep -vi "ID,Name,Prior" | grep -i dev, | awk -F"," '{print $1}')
doit LE_Count=$(echo "${LE_Count_var}" | tr '\n' ' ')
doit LEC_FROM=1

promote_dev_cv () { for CV in $CV_Count;do
  for LEC_TO in $(echo ${LE_Count});do
    hammer content-view version promote --organization="${ORG}" --from-lifecycle-environment-id="${LEC_FROM}" --to-lifecycle-environment-id="${LEC_TO}" --content-view-id="${CV}"
  done
done
}
doit promote_dev_cv
