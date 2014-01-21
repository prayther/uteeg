clear
Connect-VIServer -server C2E-VCenter -user aprayther -password qweQWE123!@#123

New-folder -Name cooper -Location steel

New-folder -Name esm -Location steel
New-folder -Name esm_dev -Location esm
New-folder -Name esm_tst -Location esm
New-folder -Name esm_ci -Location esm

New-folder -Name  infra -Location steel
New-folder -Name  dirty -Location infra
New-folder -Name  clean -Location infra
New-folder -Name  windoze -Location infra
New-folder -Name  rhel -Location infra
New-folder -Name  rhel-template -Location infra
New-folder -Name  windoze-template -Location infra

New-folder -Name  testing -Location steel
New-folder -Name  testing-tomcat -Location steel

New-folder -Name  openldap -Location steel
New-folder -Name  openldap_tst -Location openldap
New-folder -Name  openldap_dev -Location openldap
New-folder -Name  openldap_ci -Location openldap

New-folder -Name  oracle -Location steel
New-folder -Name  oracle_dev -Location oracle
New-folder -Name  oracle_tst -Location oracle
New-folder -Name  oracle_ci -Location oracle

New-folder -Name  prayther -Location steel

New-folder -Name  process_devel -Location steel
New-folder -Name  openldap -Location process_devel
New-folder -Name  db -Location process_devel

New-folder -Name  terracotta -Location steel