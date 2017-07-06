#!/bin/bash -x

# This is working with ID numbers, so just get the number of CV's (Content View) and LE (Lifecycle Env).
# List it and remove any extraneous lines that you don't want.
# Lifecycles need to be in sequence. If you just create them once I don't see a problem. If you delete and add and get numbers out of seq.
# This won't work.

# Nested for loop.
# Outer loop is for each CV that you want to promote. Make sure you all the CV ID's in seq. and before CCV's.
# If you promote CCV's before CV's you are promoting in the wrong order. Right ???
# The inner loop. LEC_FROM (--from-lifecycle-environment-id), LEC_TO (--to-lifecycle-environment-id).
# When LEC_FROM reaches <= $LE_Count-1 (the last number of hammer --csv lifecycle-environment list) stop.

CV_Count=$(hammer --csv content-view list --organization=redhat | sort -n | grep -vi "Content View ID,Name,Label,Composite,Repository IDs" | wc -l)
LE_Count=$(hammer --csv lifecycle-environment list --organization=redhat | sort -n | grep -vi "ID,Name,Prior" | wc -l)

for CV in $(seq 2 $CV_Count);do
  for (( LEC_FROM=1, LEC_TO=LEC_FROM+1; LEC_FROM <= $LE_Count-1; LEC_FROM++, LEC_TO=LEC_TO+1 ));do
    hammer content-view version promote --organization=redhat --from-lifecycle-environment-id=${LEC_FROM} --to-lifecycle-environment-id=${LEC_TO} --content-view-id=${CV}
  done
done
