#Create 3 lifecycle environment paths
#    Openshift Apps -> Dev -> Prod
#    Public_Website -> Dev -> Test -> Prod
#    App -> Dev -> Test -> UAT -> Prod -> Legacy

hammer lifecycle-environment create --name='Infra_Dev' --prior='Library' --organization=redhat
hammer lifecycle-environment create --name='Infra_Test' --prior='Infra_Dev' --organization=redhat
hammer lifecycle-environment create --name='Infra_Prod' --prior='Infra_Test' --organization=redhat


hammer lifecycle-environment create --name='App_Dev' --prior='Library' --organization=redhat
hammer lifecycle-environment create --name='App_Test' --prior='App_Dev' --organization=redhat
hammer lifecycle-environment create --name='App_UAT' --prior='App_Test' --organization=redhat
hammer lifecycle-environment create --name='App_Prod' --prior='App_UAT' --organization=redhat


