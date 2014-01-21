# Module: pam
#
# Class: pam
#
# Description:
#	This class hardens the pam area
#
# Defines:
#	pam::changeParm( $parm, $value, $path, $module, $type, $filename )
#
# Variables:
#	filename
#	module
#	parm
#	path
#	type
#	value
#
# Facts:
#	None
#
# LinuxGuide:
#	2.3.3.1.1
#	2.3.3.2
#	2.3.3.6
#
# CCERef#:
#	CCE-3762-2
#	CCE-3410-8
#
class pam {

	# GEN002100 CAT II Description: The .rhosts files is supported in PAM
	file {
		"/etc/cron.daily/GEN002100.cron":
		owner   => "root",
		group   => "root",
		mode    => 700,
		content => template("pam/GEN002100.cron.erb"),
	}



	# GuideSection 2.3.3.7
	# Remove the pam_ccreds Package if Possible
	package {
		"pam_ccreds":
			ensure => absent;
	}

	# GuideSection 2.3.3.1.1
	# CCE-3762-2
	# Protect accounts via pamcracklib
	pam::changeParm { "required":
		parm     => "required",
		value    => "",
		path     => "control",
		module   => "pam_cracklib.so",
		type     => "password",
		filename => "system-auth"
	}

	pam::changeParm { "retry":
		parm     => "retry",
		value    => "3",
		path     => "argument",
		module   => "pam_cracklib.so",
		type     => "password",
		filename => "system-auth"
	}

	pam::changeParm { "minlen":
		parm     => "minlen",
		value    => "14",
		path     => "argument",
		module   => "pam_cracklib.so",
		type     => "password",
		filename => "system-auth"
	}

	pam::changeParm { "dcredit":
		parm     => "dcredit",
		value    => "-1",
		path     => "argument",
		module   => "pam_cracklib.so",
		type     => "password",
		filename => "system-auth"
	}

	pam::changeParm { "ucredit":
		parm     => "ucredit",
		value    => "-1",
		path     => "argument",
		module   => "pam_cracklib.so",
		type     => "password",
		filename => "system-auth"
	}

	pam::changeParm { "ocredit":
		parm     => "ocredit",
		value    => "-1",
		path     => "argument",
		module   => "pam_cracklib.so",
		type     => "password",
		filename => "system-auth"
	}

	pam::changeParm { "lcredit":
		parm     => "lcredit",
		value    => "-1",
		path     => "argument",
		module   => "pam_cracklib.so",
		type     => "password",
		filename => "system-auth"
	}

	pam::changeParm { "difok":
		parm     => "difok",
		value    => "3",
		path     => "argument",
		module   => "pam_cracklib.so",
		type     => "password",
		filename => "system-auth"
	}

	augeas {
		# GuideSection 2.3.3.2
		# CCE-3410-8
		# Set Lockouts for Failed Password Attempts
		"2.3.3.2 Set Lockouts for Failed Password Attempts":
			context => "/files/etc/pam.d",
			changes => [
				"set system-auth/*[type = 'auth'][module = 'pam_tally2.so']/argument[.=~regexp('deny.*')] deny=3",
				"set system-auth/*[type = 'auth'][module = 'pam_tally2.so']/argument[.=~regexp('onerr.*')] onerr=fail",
				#"set system-auth/*[type = 'auth'][module = 'pam_tally2.so']/argument[.=~regexp('unlock_time.*')] unlock_time=900",
				"set system-auth/*[type = 'auth'][module = 'pam_tally2.so']/argument[.=~regexp('lock_time.*')] lock_time=3",
			],
			#onlyif  => "match system-auth/*[type='auth'][module='pam_tally2.so'][argument='deny=3' and argument='onerr=fail' and argument='unlock_time=900'] size == 0";
			onlyif  => "match system-auth/*[type='auth'][module='pam_tally2.so'][argument='deny=3' and argument='onerr=fail' and argument='lock_time=3'] size == 0";
		"2.3.3.2 Set Lockouts for Failed Password Attempts: Missing pam_tally2.so auth type":
			context => "/files/etc/pam.d",
			changes => [
				"ins 01 before system-auth/*[type='auth'][position() = 1]",
				"set system-auth/01/type auth",
				"set system-auth/01/control required",
				"set system-auth/01/module pam_tally2.so",
				"set system-auth/01/argument[1] deny=3",
				"set system-auth/01/argument[2] onerr=fail",
				#"set system-auth/01/argument[3] unlock_time=900",
				"set system-auth/01/argument[3] lock_time=3",
			],
			onlyif  => "match system-auth/*[type='auth'][module='pam_tally2.so'] size == 0";
		"2.3.3.2 Set Lockouts for Failed Password Attempts: Missing pam_tally2.so account type":
			context => "/files/etc/pam.d",
			changes => [
				"ins 01 before system-auth/*[type='account'][position() = 1]",
				"set system-auth/01/type account",
				"set system-auth/01/control required",
				"set system-auth/01/module pam_tally2.so",
			],
			onlyif  => "match system-auth/*[type='account'][module='pam_tally2.so'] size == 0";

		# GuideSection 2.3.3.5
		# Upgrade Password Hashing Algorithm to SHA-512
		# /etc/libuser.conf crypt_style setting is controlled by password module
		"2.3.3.5 Upgrade Password Hashing Algorithm to SHA-512 in /etc/pam.d/system-auth":
			context => "/files/etc/pam.d",
			changes => [
				"set system-auth/*[type = 'password'][module = 'pam_unix.so']/argument[. = 'sha512'] sha512",
				"rm system-auth/*[type = 'password'][module = 'pam_unix.so']/argument[. = 'md5']",
			],
			onlyif  => "match system-auth/*[type='password'][module='pam_unix.so']/argument[.='sha512'] size == 0";
		"2.3.3.5 Upgrade Password Hashing Algorithm to SHA-512 in /etc/login.defs":
			context => "/files/etc/login.defs",
			changes => [
				"set ENCRYPT_METHOD SHA512",
			],
			onlyif  => "match ENCRYPT_METHOD[.='SHA512'] size == 0";


                # GuideSection x.x.x.x
                # PAM FAILLOGIN DELAY
                "Entry Missing, setting up: GEN000480 Finding Category: CAT II, Reference: UNIX STIG: 3.1.3, Description: The login delay between login prompts after a failed login is set to less than four seconds.":
                        context => "/files/etc/pam.d",
                        changes => [
                                "set system-auth/*[type = 'auth'][module = 'pam_faildelay.so']/argument[.=~regexp('delay.*')] delay=4000000",
                        ],
			onlyif  => "match system-auth/*[type='auth'][module='pam_faildelay.so'][argument='delay=4000000'] size == 0";

                # GuideSection x.x.x.x
                # PAM FAILLOGIN DELAY
                "Entry Missing, fixing: GEN000480 Finding Category: CAT II, Reference: UNIX STIG: 3.1.3, Description: The login delay between login prompts after a failed login is set to less than four seconds.":
                        context => "/files/etc/pam.d",
                        changes => [
                                "ins 02 before system-auth/*[type='auth'][position() = 2]",
                                "set system-auth/02/type auth",
                                "set system-auth/02/control optional",
                                "set system-auth/02/module pam_faildelay.so",
				"set system-auth/02/argument[1] delay=4000000"
                        ],
                        onlyif  => "match system-auth/*[type='auth'][module='pam_faildelay.so'] size == 0";

		# GuideSection x.x.x.x
		# PAM FAILLOGIN DELAY
                "GEN000480 Finding Category: CAT II, Reference: UNIX STIG: 3.1.3, Description: The login delay between login prompts after a failed login is set to less than four seconds.":
                        context => "/files/etc/pam.d",
                        changes => [
                                #"set system-auth/*[type = 'auth'][module = 'pam_faildelay.so']/argument[. = ''] delay=4000000",
                                "set system-auth/*[type = 'auth'][module = 'pam_faildelay.so']/argument[. = 'delay=4000000'] delay=4000000",
                                "rm system-auth/*[type = 'auth'][module = 'pam_faildelay.so']/argument[. = '']",
                        ],
                        onlyif  => "match system-auth/*[type='auth'][module='pam_faildelay.so']/argument[.= '4000000'] size == 0";
                "login.defs entry so SRR find it, fixing: GEN000480 Finding Category: CAT II, Reference: UNIX STIG: 3.1.3, Description: The login delay between login prompts after a failed login is set to less than four seconds.":
                        context => "/files/etc/login.defs",
                        changes => [
                                "set FAIL_DELAY 4",
                        ], 
                        onlyif  => "match FAIL_DELAY[.= '4'] size == 0";

	}

	# GuideSection 2.3.3.6
	# Limit Password Reuse
	pam::changeParm { "reusepass":
		parm     => "remember",
		value    => "24",
		path     => "argument",
		module   => "pam_unix.so",
		type     => "password",
		filename => "system-auth"
	}
}

#########################################
# Function: logrotate::changeParm()
#
# Description:
#	This define changes $parm to $value
#
# Parameters:
#	$parm: This is the parameter to change.
#	$value: Change the parameter to this value.
#	$path: Look in this path to find $filename
#	$module: Look for this module name in $filename
#	$type: This is the type of setting to change (password, auth, acct, etc.)
#	$filename: Change this file
#
# Returns:
#	None
#########################################
define pam::changeParm ( $parm="", $value = "", $path = "", $module = "", $type = "", $filename="")
{
	if($value == "")
	{
		augeas {
			"pam-$filename-change-$module-$parm" :
				context => "/files/etc/pam.d",
				changes => "set $filename/*[type = '$type'][module ='$module']/$path $parm";
		}
	}
	else
	{

		augeas {
			"pam-$filename-change-$module-$parm" :
				context => "/files/etc/pam.d",
				changes => "set $filename/*[type = '$type'][module ='$module']/$path[. =~regexp('$parm=.*')] $parm=$value";
		}
	}
}
