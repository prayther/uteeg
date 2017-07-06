#!/bin/bash -x

# Create Activation Keys.
# This script will run after cv_promote.sh
hammer activation-key create --name='AK_Infra_Dev' --organization=redhat --content-view='CCV_RHEL7_Server' --lifecycle-environment='Infra_Dev'
