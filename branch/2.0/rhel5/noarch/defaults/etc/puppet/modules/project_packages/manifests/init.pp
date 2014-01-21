class project_packages {

    package { [ '#defaults-rhel5-noarch',
                'ircd-ratbox-mkpasswd',
                'audispd-plugins',
                'vmware-open-vm-tools-nox',
                'avvdatspawar',
                'uvscanspawar',
                'acl',
                'yum-security',
                'ovaldi',
                'puppet',
                'setools',
                'sysstat',
    #            'audit',
                'screen',
                'vim-enhanced' ]:
               ensure => 'installed',
             }
}
