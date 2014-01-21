# Define: augeas::basic-change
#
# This defines a basic augeas change. Specifying a lens will greatly increase
# the performance.
#
# Parameters:
#	$file:
#		This is the file you want to change
#	$lens:
#		This specifies what lens to use if any
#	$changes:
#		This can be one or many changes to perform on the specified file
# Sample Usage:
#	augeas::basic-change { "/etc/inittab": file => "/etc/inittab", lens=>"inittab.lns", changes=> ["set ~/runlevels S",] }
define augeas::basic-change ( $file='', $lens='', $changes='', $onlyif='', $tags='undef')
{
	if ($lens == '')  
	{
		$lens="undef"
		$incl="undef"
	}
	else
	{
		$incl=$file
	}
	
	# You should set this 0 if the puppet Server is running version <26.0
	# else set it to 1 to get the added speed benefits.
	$isRowlf=0

	if (versioncmp($puppetversion, "0.26.0") >= 0) and ($isRowlf==1)
	{
		augeas {"$name" :
			context => "/files$file",
			lens    => $lens, 
			incl    => $incl,
			changes => $changes,
			onlyif  => $onlyif,
			tag     => $tags,
		}
	}
	else
	{		
		augeas {"$name" :
                	context => "/files$file",
                	changes => $changes,
			onlyif  => $onlyif,
			tag     =>  $tags,
        	}
	}
}
