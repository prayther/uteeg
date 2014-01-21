class aliases {
        # GEN004640  CAT I Description: The sendmail decode command is not disabled.
        file {
                "/etc/cron.daily/GEN004640.cron":
                owner   => "root",
                group   => "root",
                mode    => 700,
                content => template("aliases/GEN004640.cron.erb"),
        }
}
