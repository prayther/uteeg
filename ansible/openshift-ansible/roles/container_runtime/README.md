Container Runtime
=========

Ensures docker package or system container is installed, and optionally raises timeout for systemd-udevd.service to 5 minutes.

This role is designed to be used with import_role and tasks_from.

Entry points
------------
* package_docker.yml - install and setup docker container runtime.
* package_crio.yml - install and setup crio container runtime.
* registry_auth.yml - place docker login credentials.

Requirements
------------

Ansible 2.4


Dependencies
------------

Depends on openshift_facts having already been run.

Example Playbook
----------------

    - hosts: servers
      tasks:
      - import_role: container_runtime
        tasks_from: package_docker.yml

License
-------

ASL 2.0

Author Information
------------------

Red Hat, Inc
