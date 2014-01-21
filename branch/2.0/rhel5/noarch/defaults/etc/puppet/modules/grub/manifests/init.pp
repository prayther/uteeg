class grub {
	$grub_password = '$1$8Yfbi0$Hx2mP2MV8Ab9dR2pbK./q0'
	augeas { "grub-create-password":
	  context => "/files/boot/grub/menu.lst",
	  changes => [
	    "ins password after default",
	    "set password/md5 ''",
	    "set password $grub_password",
	  ],
	  onlyif => "match password size == 0",
	}

	augeas { "grub-set-password":
	  context => "/files/boot/grub/menu.lst",
	  changes => "set password $grub_password",
	  require => Augeas["grub-create-password"],
	}
}
