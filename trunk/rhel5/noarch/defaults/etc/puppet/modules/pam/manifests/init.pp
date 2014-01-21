# Module: pam
#
# Class: pam
#
# Description:
#       This class hardens the pam area
# Defines:
#       pam::changeParm
#	pam::addNumTriesLock
#
# LinuxGuide:
#       2.3.3.1.1
#       2.3.3.2
#	2.3.3.6
#
# CCERef#:
#       CCE-3762-2
#	CCE-3410-8
#
class pam {
	# GuideSection 2.3.3.1.1
	# CCE-3762-2
	# Protect accounts via pamcracklib
	pam::changeParm { "required": 
		parm     => 'required',  
		value    => '',  
		path     => 'control', 
		module   => 'pam_cracklib.so', 
		type     => 'password', 
		filename => 'system-auth'
	}

	pam::changeParm { "retry":
		parm     => 'retry',
		value    => '3',
		path     => 'argument',
		module   => 'pam_cracklib.so',
		type     => 'password',
		filename => 'system-auth'
	}

	pam::changeParm { "minlen": 
		parm     => 'minlen', 
		value    => '14',  
		path     => 'argument', 
		module   => 'pam_cracklib.so', 
		type     => 'password', 
		filename => 'system-auth' 
	}

	pam::changeParm { "dcredit": 
		parm     => 'dcredit', 
		value    => '-1', 
		path     => 'argument', 
		module   => 'pam_cracklib.so', 
		type     => 'password', 
		filename => 'system-auth' 
	}

	pam::changeParm { "ucredit": 
		parm     => 'ucredit', 
		value    => '-1', 
		path     => 'argument', 
		module   => 'pam_cracklib.so', 
		type     => 'password', 
		filename => 'system-auth' 
	}

	pam::changeParm { "ocredit": 
		parm     => 'ocredit', 
		value    => '-1', 
		path     => 'argument', 
		module   => 'pam_cracklib.so', 
		type     => 'password', 
		filename => 'system-auth' 
	}

	pam::changeParm { "lcredit": 
		parm     => 'lcredit', 
		value    => '-1',  
		path     => 'argument', 
		module   => 'pam_cracklib.so', 
		type     => 'password', 
		filename => 'system-auth' 
	}

	pam::changeParm { "difok":
		parm     => 'difok',
		value    => '3',
		path     => 'argument',
		module   => 'pam_cracklib.so',
		type     => 'password',
		filename => 'system-auth'
	}

	# GuideSection 2.3.3.2
	# CCE-3410-8
	# Set Lockouts for Failed Password Attempts
	pam::changeParm { "required-2.3.3.2": 
		parm     => 'required', 
		value    => '',  
		path     => 'control', 
		module   => 'pam_unix.so', 
		type     => 'auth', 
		filename => 'system-auth' 
	}

	augeas { "remove-lines":
		context => "/files/etc/pam.d",
		changes => [
			"remove system-auth/*[type='auth'][control='requisite'][module ='pam_succeed_if.so']",
			"remove system-auth/*[type='auth'][control='required'][module ='pam_deny.so']",
		],
	}

	# Add whatever files you want to enable locking out for.
	pam::addNumTriesLock { "login" : }


	# GuideSection 2.3.3.6
	# Limit Password Reuse
	pam::changeParm { "reusepass": 
		parm=>'remember', 
		value=> '24',  
		path=>'argument', 
		module => 'pam_unix.so', 
		type => 'password', 
		filename=>'system-auth' 
	}
	package {
		"pam_ccreds":
		ensure => 'absent'
	}
}

define pam::changeParm ( $parm='', $value = '', $path = '', $module = '', $type = '', $filename='')
{
	if($value == '')
	{
		augeas::basic-change { "pam-$filename-change-$module-$parm" :
			file => "/etc/pam.d",
			lens    => "pam.lns",
                        changes => "set $filename/*[type = '$type'][module ='$module']/$path $parm"
        	}
	}
	else
	{

		augeas::basic-change { "pam-$filename-change-$module-$parm" :
			file => "/etc/pam.d",
			lens    => "pam.lns",
			changes => "set $filename/*[type = '$type'][module ='$module']/$path[. =~regexp('$parm=.*')] $parm=$value"
		}
	}
}

define pam::addNumTriesLock ()
{
	 augeas::basic-change  { "numTriesLock-$name":
		file    => "/etc/pam.d",
		lens    => "pam.lns",
		changes => [
			"insert 01 after $name/*[type = 'auth'][last()]",
			"set $name/01/type auth",
			"set $name/01/control required",
			"set $name/01/module pam_tally2.so",
			"set $name/01/argument[1] 'deny=5'",
			"set $name/01/argument[2] 'onerr=fail'"
		],
		onlyif =>"match *[/files/etc/pam.d/$name/*[type='auth'][control='required'][module='pam_tally2.so']] size == 0"
        }

	augeas::basic-change { "numTriesLockacct-$name":
		file    => "/etc/pam.d",
		lens    => "pam.lns",
		changes => [
			"insert 01 after $name/*[type = 'account'][last()]",
			"set $name/01/type account",
			"set $name/01/control required",
			"set $name/01/module pam_tally2.so"
		],
		onlyif =>"match *[/files/etc/pam.d/$name/*[type='account'][control='required'][module='pam_tally2.so']] size == 0"
	}
}
