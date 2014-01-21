class project_resolv {

        file {
                "/etc/resolv.conf":
                        owner   => "root",
                        group   => "root",
                        mode    => 644,
                        content => template("project_resolv/resolv.conf.erb"),
        }

}
