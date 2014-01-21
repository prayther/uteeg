class fstab {
                #nosuid, nodev, on /home
                exec { "/bin/sed -i 's/\( \/home.*defaults\)/\1,nosuid,nodev/' /etc/fstab":
                        onlyif => "/usr/bin/test `grep ' \/home ' /etc/fstab | grep -c nosuid` -eq 0",
                }

}
