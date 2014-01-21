class fstab {
                #nosuid, nodev, on /home
                exec { "sed -i 's/\( \/home.*defaults\)/\1,nosuid,nodev/' /etc/fstab":
                        onlyif => "test `grep ' \/home ' /etc/fstab | grep -c nosuid` -eq 0",
                }

}
