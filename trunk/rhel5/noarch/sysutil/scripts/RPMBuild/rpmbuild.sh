#!/bin/bash -x

$Id: rpmbuild.sh 1171 2013-01-08 19:55:18Z sysutil $

# sysutil_rpmbuild_svn_bootstrap.sh will source the config.cfg,
# boot strap the sysutil user, create an RPMBuild env
# and setup the SVN stuff defined in config.cfg

# Then, as the sysutil user, you can run the 
# rpmbuild_hosts.role.txt_svn_to_rpm_to_sat.sh
# script which will read hosts.role.txt to build
# RPM's for each host/role defined in the 
# comma delimited file. 

# I put a variable in my scripts named PROGNAME which
# holds the name of the program being run.  You can get
# this value from the first item on the command line ($0).
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

source $HOME/scripts/config.cfg || error_exit "Line $LINENO: Could not source config.cfg"

## need to put a better check for svn setup.  look at what permanent_svn.sh is doing
ls $HOME/.subversion/config
if [ $? != "0" ];then
  $HOME/scripts/SVN/permanent_svn.sh || error_exit "Line $LINENO: permanent_svn.sh failed"
fi

## this is the loop for "sysutil"  i will setup a loop and config.cfg entry for each major section so that people can easily work in a granular way
## you just have to edit config.cfg appropriately.  so each person will want to have their favorite sysutil/rpmbuild box so they have all there
## configs to work on what they want in config.cfg
if [ "${sysutilRPMBUILDENV}" != "" ];then
  for env in ${sysutilRPMBUILDENV};do
	for rhel in ${sysutilRPMBUILDRHEL};do
		for arch in ${sysutilRPMBUILDARCH};do
			for cat in ${sysutilRPMBUILDCATEGORY};do
			     #for release in ${sysutilRPMBUILDRELEASE};do
				/usr/bin/svn co     $SVNSERVER/$env/$rhel/$arch/$cat $HOME/$BASEDIR/$env/$rhel/$arch/$cat || error_exit "Line $LINENO: Failed: /usr/bin/svn co     $SVNSERVER/$env/$rhel/$arch/$cat $HOME/$BASEDIR/$env/$rhel/$arch"
				/usr/bin/svn update $SVNSERVER/$env/$rhel/$arch/$cat $HOME/$BASEDIR/$env/$rhel/$arch/$cat|| error_exit "Line $LINENO: Failed: /usr/bin/svn update $SVNSERVER/$env/$rhel/$arch/$cat $HOME/$BASEDIR/$env/$rhel/$arch"
				rsync -av $HOME/$BASEDIR/$env/$rhel/$arch/$cat/* $HOME/ || error_exit "Line $LINENO: Failed: rsync $HOME/$BASEDIR/$env/$rhel/$arch/$cat/* $HOME/"
				chmod -R 700 $HOME
				cd $HOME/$BASEDIR/$env/$rhel/$arch && tar --exclude='.svn' -czvf $HOME/$RPMBUILD/SOURCES/$cat.-$rhel-$archtar.gz $cat || error_exit Line $LINENO: Failed: "cd $HOME/$BASEDIR/$env/$rhel/$arch && tar --exclude='.svn' -czvf $HOME/$RPMBUILD/SOURCES/$cat-$rhel-$arch.tar.gz $cat-$rhel-$arch"
				for OLD in `grep Version: $HOME/$RPMBUILD/SPECS/$cat-$rhel-$arch.spec | cut -d. -f3`;do NUMBER=$(echo "$OLD" | /usr/bin/tr -d [:alpha:]) && STRING=$(echo "$OLD" | /usr/bin/tr -d [:digit:]) && NEW=$STRING$(($NUMBER+1)) && sed -i "s/Version:\ \ .0.$OLD/Version:\ \ .0.$NEW/" $HOME/$RPMBUILD/SPECS/$cat-$rhel-$arch.spec;done
				rm -f $HOME/$RPMBUILD/RPMS/$arch/$cat-$rhel-$arch*.rpm
				rpmbuild -bb $HOME/$RPMBUILD/SPECS/$cat-$rhel-$arch.spec || error_exit "Line $LINENO: Failed: rpmbuild -bb $HOME/$RPMBUILD/SPECS/$cat-$rhel-$arch.spec"
				$HOME/scripts/RPMBuild/RPMaddsign.sh $HOME/$RPMBUILD/RPMS/$arch/$cat-$rhel-$arch*.rpm || error_exit "Line $LINENO: Failed: $HOME/scripts/RPMBuild/RPMaddsign.sh $HOME/$RPMBUILD/RPMS/$arch/$cat-$rhel-$arch*.rpm"
				/usr/bin/svn -m "Version:  .0.$NEW" commit $HOME/$RPMBUILD/SPECS/$cat-$rhel-$arch.spec || error_exit "Line $LINENO: Failed: /usr/bin/svn -m "Version:  .0.$NEW" commit $HOME/$RPMBUILD/SPECS/$cat-$rhel-$arch.spec"				
			     #done
			done
		done
	done
  done
fi
# this is copying the "defaults" in place, to be augmented or overwritten by the "role" stuff below.  This will include a lot of stuff, all of the /etc/issue, sudoers, iptables, stig
# pretty much everthing that makes up a server... BUT DON'T MODIFY STUFF HERE!  DO IT AT THE ROLE LEVEL BELOW.  THIS SECTION AFFECTS ALL MACHINES.
if [ "${defaultsRPMBUILDENV}" != "" ];then
  for env in ${defaultsRPMBUILDENV};do
	for rhel in ${defaultsRPMBUILDRHEL};do
		for arch in ${defaultsRPMBUILDARCH};do
			for cat in ${defaultsRPMBUILDCATEGORY};do
			     #for release in ${sysutilRPMBUILDRELEASE};do
				/usr/bin/svn co     $SVNSERVER/$env/$rhel/$arch/$cat $HOME/$BASEDIR/$env/$rhel/$arch/$cat || error_exit "Line $LINENO: Failed: /usr/bin/svn co     $SVNSERVER/$env/$rhel/$arch/$cat $HOME/$BASEDIR/$env/$rhel/$arch/"
				/usr/bin/svn update $SVNSERVER/$env/$rhel/$arch/$cat $HOME/$BASEDIR/$env/$rhel/$arch/$cat || error_exit "Line $LINENO: Failed: /usr/bin/svn update $SVNSERVER/$env/$rhel/$arch/$cat $HOME/$BASEDIR/$env/$rhel/$arch/"
				chmod -R 700 $HOME/$BASEDIR/$env/$rhel/$arch/$cat
				cd $HOME/$BASEDIR/$env/$rhel/$arch/ && tar --exclude='.svn' -czvf $HOME/$RPMBUILD/SOURCES/$cat-$rhel-$arch.tar.gz $cat || error_exit Line $LINENO: Failed: "cd $HOME/$BASEDIR/$env/$rhel/puppet/roles/$arch && tar --exclude='.svn' -czvf $HOME/$RPMBUILD/SOURCES/$cat-$rhel-$arch.tar.gz $cat-$rhel-$arch"
				#for OLD in `grep "Version:" $HOME/$RPMBUILD/SPECS/$cat-$rhel-$arch.spec | awk -F"." '{ print $4 }'`;do ONE="1" && NEW=$(($OLD + $ONE)) && sed -i "0,/s/v.$OLDs/v.$OLD/v.$NEW/" $HOME/$RPMBUILD/SPECS/$cat-$rhel-$arch.spec;done
				for OLD in `grep "Version:" $HOME/$RPMBUILD/SPECS/$cat-$rhel-$arch.spec | awk -F"." '{ print $4 }'`;do ONE="1" && NEW=$(($OLD + $ONE)) && sed -i "0,/Version:/{s/v.$OLD/v.$NEW/}" $HOME/$RPMBUILD/SPECS/$cat-$rhel-$arch.spec;done
				rm -f $HOME/$RPMBUILD/RPMS/$arch/$cat-$rhel-$arch*.rpm
				rpmbuild -bb $HOME/$RPMBUILD/SPECS/$cat-$rhel-$arch.spec || error_exit "Line $LINENO: Failed: rpmbuild -bb $HOME/$RPMBUILD/SPECS/$cat-$rhel-$arch.spec"
				$HOME/scripts/RPMBuild/RPMaddsign.sh $HOME/$RPMBUILD/RPMS/$arch/$cat-$rhel-$arch*.rpm || error_exit "Line $LINENO: Failed: $HOME/scripts/RPMBuild/RPMaddsign.sh $HOME/$RPMBUILD/RPMS/$arch/$cat-$rhel-$arch*.rpm"
                                /usr/bin/rhnpush --server=$SATSERVER --user=$SATUSER --password=$SATPASSWORD -c $defaultsRPMBUILDRELEASE-defaults-$rhel-$arch $HOME/$RPMBUILD/RPMS/$arch/$cat-$rhel-$arch*.rpm
				/usr/bin/svn -m "Version:  2.0.v.$NEW" commit $HOME/$RPMBUILD/SPECS/$cat-$rhel-$arch.spec || error_exit "Line $LINENO: Failed: /usr/bin/svn -m "Version:  .0.$NEW" commit $HOME/$RPMBUILD/SPECS/$cat-$rhel-$arch.spec"
			     #done
			done
		done
	done
  done
fi
#  the "role" is the most granular configuration about a host and should include minor changes, like /etc/hosts or modifications to "stig" to allow operation, etc.
if [ "${roleRPMBUILDENV}" != "" ];then
  for env in ${roleRPMBUILDENV};do
	for rhel in ${roleRPMBUILDRHEL};do
		for arch in ${roleRPMBUILDARCH};do
			for cat in ${roleRPMBUILDCATEGORY};do
				/usr/bin/svn co     $SVNSERVER/$env/$rhel/$arch/roles/$cat $HOME/$BASEDIR/$env/$rhel/$arch/roles/$cat || error_exit "Line $LINENO: Failed: /usr/bin/svn co     $SVNSERVER/$env/$rhel/$arch/roles/$cat $HOME/$BASEDIR/$env/$rhel/$arch/"
				/usr/bin/svn update $SVNSERVER/$env/$rhel/$arch/roles/$cat $HOME/$BASEDIR/$env/$rhel/$arch/roles/$cat || error_exit "Line $LINENO: Failed: /usr/bin/svn update $SVNSERVER/$env/$rhel/$arch/roles/$cat $HOME/$BASEDIR/$env/$rhel/$arch/"
				chmod -R 700 $HOME/$BASEDIR/$env/$rhel/$arch/$cat
				cd $HOME/$BASEDIR/$env/$rhel/$arch/roles/ && tar --exclude='.svn' -czvf $HOME/$RPMBUILD/SOURCES/$cat-$rhel-$arch.tar.gz $cat || error_exit Line $LINENO: Failed: "cd $HOME/$BASEDIR/$env/$rhel/puppet/roles/$arch && tar --exclude='.svn' -czvf $HOME/$RPMBUILD/SOURCES/$cat-$rhel-$arch.tar.gz $cat-$rhel-$arch"
				for OLD in `grep Version: $HOME/$RPMBUILD/SPECS/$cat-$rhel-$arch.spec | cut -d. -f3`;do NUMBER=$(echo "$OLD" | /usr/bin/tr -d [:alpha:]) && STRING=$(echo "$OLD" | /usr/bin/tr -d [:digit:]) && NEW=$STRING$(($NUMBER+1)) && sed -i "s/Version:\ \ .0.$OLD/Version:\ \ .0.$NEW/" $HOME/$RPMBUILD/SPECS/$cat-$rhel-$arch.spec;done
				rm -f $HOME/$RPMBUILD/RPMS/$arch/$cat-$rhel-$arch*.rpm
				rpmbuild -bb $HOME/$RPMBUILD/SPECS/$cat-$rhel-$arch.spec || error_exit "Line $LINENO: Failed: rpmbuild -bb $HOME/$RPMBUILD/SPECS/$cat-$rhel-$arch.spec"
				$HOME/scripts/RPMBuild/RPMaddsign.sh $HOME/$RPMBUILD/RPMS/$arch/$cat-$rhel-$arch*.rpm || error_exit "Line $LINENO: Failed: $HOME/scripts/RPMBuild/RPMaddsign.sh $HOME/$RPMBUILD/RPMS/$arch/$cat-$rhel-$arch*.rpm"
				/usr/bin/svn -m "Version:  .0.$NEW" commit $HOME/$RPMBUILD/SPECS/$cat-$rhel-$arch.spec || error_exit "Line $LINENO: Failed: /usr/bin/svn -m "Version:  .0.$NEW" commit $HOME/$RPMBUILD/SPECS/$cat-$rhel-$arch.spec"
					# this is to capture the "defaults" info from above so that i can create a combined role-defaults.rpm
					for envdef in ${defaultsRPMBUILDENV};do
						for rheldef in ${defaultsRPMBUILDRHEL};do
							for archdef in ${defaultsRPMBUILDARCH};do
								for catdef in ${defaultsRPMBUILDCATEGORY};do
									rsync -av $HOME/$BASEDIR/$env/$rhel/$arch/roles/$cat/* $HOME/$BASEDIR/$envdef/$rheldef/$archdef/$catdef/
									# have to move the dir otherwise your directory names are out of sync in rpmbuild
									mv $HOME/$BASEDIR/$envdef/$rheldef/$archdef/$catdef $HOME/$BASEDIR/$envdef/$rheldef/$archdef/$cat-$catdef
									cd $HOME/$BASEDIR/$envdef/$rheldef/$archdef/ && tar --exclude='.svn' -czvf $HOME/$RPMBUILD/SOURCES/$cat-$catdef.tar.gz $cat-$catdef
									for OLD in `grep Version: $HOME/$RPMBUILD/SPECS/$cat-$catdef.spec | cut -d. -f3`;do NUMBER=$(echo "$OLD" | /usr/bin/tr -d [:alpha:]) && STRING=$(echo "$OLD" | /usr/bin/tr -d [:digit:]) && NEW=$STRING$(($NUMBER+1)) && sed -i "s/Version:\ \ .0.$OLD/Version:\ \ .0.$NEW/" $HOME/$RPMBUILD/SPECS/$cat-$catdef.spec;done
									rm -f $HOME/$RPMBUILD/RPMS/$arch/$cat-$catdef*.rpm
									rpmbuild -bb $HOME/$RPMBUILD/SPECS/$cat-$catdef.spec
									$HOME/scripts/RPMBuild/RPMaddsign.sh $HOME/$RPMBUILD/RPMS/$arch/$cat-$catdef*.rpm
									/usr/bin/svn -m "Version:  .0.$NEW" commit $HOME/$RPMBUILD/SPECS/$cat-$catdef.spec
								done
							done
						done
					done
				 rm -rf $HOME/$BASEDIR/$env/$rhel/$arch/roles/$cat; rm -rf $HOME/$RPMBUILD/SOURCES/$cat.tar.gz                              
			done
		done
	done
  done
fi
exit 0
