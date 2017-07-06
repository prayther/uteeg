#!/bin/bash -x

# Create Host Collections
# RHEL
# Lifecycle
# App

# Run after creating Content Views and Lifecycles. It uses those to create the Host Collections.
# Create a host group for each CCV.

for CV in $(hammer --csv content-view list --organization redhat | grep CCV | awk -F"," '{print$2}' | sed 's/^[^_]*_//g');do
  for LE in $(hammer --csv lifecycle-environment list --organization redhat | grep -v "Library" | grep -v "Name" | awk -F"," '{print $2}');do
    hammer host-collection create --name="HC_${LE}_${CV}" --organization=redhat
  done
done




