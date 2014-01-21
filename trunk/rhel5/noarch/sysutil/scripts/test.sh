#!/bin/bash -x

# $Id: test.sh 763 2012-08-15 13:52:46Z sysutil $

#  this script creates iso boot images to kickstart a rhel server from.
#  while a little cumbersome, compared to pxe, etc it does eliminate
# the need to host pxe and dhcp

PROGNAME=$(basename $0)
function error_exit
{

#       ----------------------------------------------------------------
#       Function for exit due to fatal program error
#               Accepts 1 argument:
#                       string containing descriptive error message
#       ----------------------------------------------------------------


        echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
        echo "${PROGNAME}: ${1:-"Unknown Error"}" | /bin/mail -s "${PROGNAME}: ${1:-"Unknown Error"}" root@localhost
        exit 1
}

# Example call of the error_exit function.  Note the inclusion
# of the LINENO environment variable.  It contains the current
# line number.

source $HOME/scripts/config.sh || error_exit "Line $LINENO: Could not source config.cfg"


 [ -d $HOME/iso ] || mkdir $HOME/iso


