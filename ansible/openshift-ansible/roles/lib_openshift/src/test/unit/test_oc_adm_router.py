#!/usr/bin/env python
'''
 Unit tests for oc adm router
'''

import os
import six
import sys
import unittest
import mock

# Removing invalid variable names for tests so that I can
# keep them brief
# pylint: disable=invalid-name,no-name-in-module
# Disable import-error b/c our libraries aren't loaded in jenkins
# pylint: disable=import-error
# place class in our python path
module_path = os.path.join('/'.join(os.path.realpath(__file__).split('/')[:-4]), 'library')  # noqa: E501
sys.path.insert(0, module_path)
from oc_adm_router import Router, RouterConfig, locate_oc_binary  # noqa: E402


# pylint: disable=too-many-public-methods
class RouterTest(unittest.TestCase):
    '''
     Test class for Router
    '''
    dry_run = '''{
    "kind": "List",
    "apiVersion": "v1",
    "metadata": {},
    "items": [
        {
            "kind": "ServiceAccount",
            "apiVersion": "v1",
            "metadata": {
                "name": "router",
                "creationTimestamp": null
            }
        },
        {
            "kind": "ClusterRoleBinding",
            "apiVersion": "v1",
            "metadata": {
                "name": "router-router-role",
                "creationTimestamp": null
            },
            "userNames": [
                "system:serviceaccount:default:router"
            ],
            "groupNames": null,
            "subjects": [
                {
                    "kind": "ServiceAccount",
                    "namespace": "default",
                    "name": "router"
                }
            ],
            "roleRef": {
                "kind": "ClusterRole",
                "name": "system:router"
            }
        },
        {
            "kind": "DeploymentConfig",
            "apiVersion": "v1",
            "metadata": {
                "name": "router",
                "creationTimestamp": null,
                "labels": {
                    "router": "router"
                }
            },
            "spec": {
                "strategy": {
                    "type": "Rolling",
                    "rollingParams": {
                        "maxUnavailable": "25%",
                        "maxSurge": 0
                    },
                    "resources": {}
                },
                "triggers": [
                    {
                        "type": "ConfigChange"
                    }
                ],
                "replicas": 2,
                "test": false,
                "selector": {
                    "router": "router"
                },
                "template": {
                    "metadata": {
                        "creationTimestamp": null,
                        "labels": {
                            "router": "router"
                        }
                    },
                    "spec": {
                        "volumes": [
                            {
                                "name": "server-certificate",
                                "secret": {
                                    "secretName": "router-certs"
                                }
                            }
                        ],
                        "containers": [
                            {
                                "name": "router",
                                "image": "registry.redhat.io/openshift3/ose-haproxy-router:v3.5.0.39",
                                "ports": [
                                    {
                                        "containerPort": 80
                                    },
                                    {
                                        "containerPort": 443
                                    },
                                    {
                                        "name": "stats",
                                        "containerPort": 1936,
                                        "protocol": "TCP"
                                    }
                                ],
                                "env": [
                                    {
                                        "name": "DEFAULT_CERTIFICATE_DIR",
                                        "value": "/etc/pki/tls/private"
                                    },
                                    {
                                        "name": "ROUTER_EXTERNAL_HOST_HOSTNAME"
                                    },
                                    {
                                        "name": "ROUTER_EXTERNAL_HOST_HTTPS_VSERVER"
                                    },
                                    {
                                        "name": "ROUTER_EXTERNAL_HOST_HTTP_VSERVER"
                                    },
                                    {
                                        "name": "ROUTER_EXTERNAL_HOST_INSECURE",
                                        "value": "false"
                                    },
                                    {
                                        "name": "ROUTER_EXTERNAL_HOST_INTERNAL_ADDRESS"
                                    },
                                    {
                                        "name": "ROUTER_EXTERNAL_HOST_PARTITION_PATH"
                                    },
                                    {
                                        "name": "ROUTER_EXTERNAL_HOST_PASSWORD"
                                    },
                                    {
                                        "name": "ROUTER_EXTERNAL_HOST_PRIVKEY",
                                        "value": "/etc/secret-volume/router.pem"
                                    },
                                    {
                                        "name": "ROUTER_EXTERNAL_HOST_USERNAME"
                                    },
                                    {
                                        "name": "ROUTER_EXTERNAL_HOST_VXLAN_GW_CIDR"
                                    },
                                    {
                                        "name": "ROUTER_SERVICE_HTTPS_PORT",
                                        "value": "443"
                                    },
                                    {
                                        "name": "ROUTER_SERVICE_HTTP_PORT",
                                        "value": "80"
                                    },
                                    {
                                        "name": "ROUTER_SERVICE_NAME",
                                        "value": "router"
                                    },
                                    {
                                        "name": "ROUTER_SERVICE_NAMESPACE",
                                        "value": "default"
                                    },
                                    {
                                        "name": "ROUTER_SUBDOMAIN"
                                    },
                                    {
                                        "name": "STATS_PASSWORD",
                                        "value": "eSfUICQyyr"
                                    },
                                    {
                                        "name": "STATS_PORT",
                                        "value": "1936"
                                    },
                                    {
                                        "name": "STATS_USERNAME",
                                        "value": "admin"
                                    }
                                ],
                                "resources": {
                                    "requests": {
                                        "cpu": "100m",
                                        "memory": "256Mi"
                                    }
                                },
                                "volumeMounts": [
                                    {
                                        "name": "server-certificate",
                                        "readOnly": true,
                                        "mountPath": "/etc/pki/tls/private"
                                    }
                                ],
                                "livenessProbe": {
                                    "httpGet": {
                                        "path": "/healthz",
                                        "port": 1936,
                                        "host": "localhost"
                                    },
                                    "initialDelaySeconds": 10
                                },
                                "readinessProbe": {
                                    "httpGet": {
                                        "path": "/healthz",
                                        "port": 1936,
                                        "host": "localhost"
                                    },
                                    "initialDelaySeconds": 10
                                },
                                "imagePullPolicy": "IfNotPresent"
                            }
                        ],
                        "nodeSelector": {
                            "type": "infra"
                        },
                        "serviceAccountName": "router",
                        "serviceAccount": "router",
                        "hostNetwork": true,
                        "securityContext": {}
                    }
                }
            },
            "status": {
                "latestVersion": 0,
                "observedGeneration": 0,
                "replicas": 0,
                "updatedReplicas": 0,
                "availableReplicas": 0,
                "unavailableReplicas": 0
            }
        },
        {
            "kind": "Service",
            "apiVersion": "v1",
            "metadata": {
                "name": "router",
                "creationTimestamp": null,
                "labels": {
                    "router": "router"
                },
                "annotations": {
                    "service.alpha.openshift.io/serving-cert-secret-name": "router-certs"
                }
            },
            "spec": {
                "ports": [
                    {
                        "name": "80-tcp",
                        "port": 80,
                        "targetPort": 80
                    },
                    {
                        "name": "443-tcp",
                        "port": 443,
                        "targetPort": 443
                    },
                    {
                        "name": "1936-tcp",
                        "protocol": "TCP",
                        "port": 1936,
                        "targetPort": 1936
                    }
                ],
                "selector": {
                    "router": "router"
                }
            },
            "status": {
                "loadBalancer": {}
            }
        }
    ]
}'''

    @mock.patch('oc_adm_router.locate_oc_binary')
    @mock.patch('oc_adm_router.Utils._write')
    @mock.patch('oc_adm_router.Utils.create_tmpfile_copy')
    @mock.patch('oc_adm_router.Router._run')
    def test_state_present(self, mock_cmd, mock_tmpfile_copy, mock_write, mock_oc_binary):
        ''' Testing a create '''
        params = {'state': 'present',
                  'debug': False,
                  'namespace': 'default',
                  'name': 'router',
                  'default_cert': None,
                  'cert_file': None,
                  'key_file': None,
                  'cacert_file': None,
                  'labels': {"router": "router", "another-label": "val"},
                  'ports': ['80:80', '443:443'],
                  'images': None,
                  'latest_images': None,
                  'clusterip': None,
                  'portalip': None,
                  'session_affinity': None,
                  'service_type': None,
                  'kubeconfig': '/etc/origin/master/admin.kubeconfig',
                  'replicas': 2,
                  'selector': 'type=infra',
                  'service_account': 'router',
                  'router_type': None,
                  'host_network': None,
                  'extended_validation': True,
                  'external_host': None,
                  'external_host_vserver': None,
                  'external_host_insecure': False,
                  'external_host_partition_path': None,
                  'external_host_username': None,
                  'external_host_password': None,
                  'external_host_private_key': None,
                  'stats_user': None,
                  'stats_password': None,
                  'stats_port': 1936,
                  'edits': []}

        mock_cmd.side_effect = [
            (1, '', 'Error from server (NotFound): deploymentconfigs "router" not found'),
            (1, '', 'Error from server (NotFound): service "router" not found'),
            (1, '', 'Error from server (NotFound): serviceaccount "router" not found'),
            (1, '', 'Error from server (NotFound): secret "router-certs" not found'),
            (1, '', 'Error from server (NotFound): clsuterrolebinding "router-router-role" not found'),
            (0, RouterTest.dry_run, ''),
            (0, '', ''),
            (0, '', ''),
            (0, '', ''),
            (0, '', ''),
            (0, '', ''),
        ]

        mock_tmpfile_copy.side_effect = [
            '/tmp/mocked_kubeconfig',
        ]

        mock_oc_binary.side_effect = [
            'oc',
        ]

        results = Router.run_ansible(params, False)

        self.assertTrue(results['changed'])
        for result in results['module_results']['results']:
            self.assertEqual(result['returncode'], 0)

        mock_cmd.assert_has_calls([
            mock.call(['oc', 'get', 'dc', 'router', '-o', 'json', '-n', 'default'], None),
            mock.call(['oc', 'get', 'svc', 'router', '-o', 'json', '-n', 'default'], None),
            mock.call(['oc', 'get', 'sa', 'router', '-o', 'json', '-n', 'default'], None),
            mock.call(['oc', 'get', 'secret', 'router-certs', '-o', 'json', '-n', 'default'], None),
            mock.call(['oc', 'get', 'clusterrolebinding', 'router-router-role', '-o', 'json', '-n', 'default'], None),
            mock.call(['oc', 'adm', 'router', 'router', '--external-host-insecure=False',
                       "--labels=another-label=val,router=router",
                       '--ports=80:80,443:443', '--replicas=2', '--selector=type=infra', '--service-account=router',
                       '--stats-port=1936', '--dry-run=True', '-o', 'json', '-n', 'default'], None),
            mock.call(['oc', 'create', '-f', mock.ANY, '-n', 'default'], None),
            mock.call(['oc', 'create', '-f', mock.ANY, '-n', 'default'], None),
            mock.call(['oc', 'create', '-f', mock.ANY, '-n', 'default'], None),
            mock.call(['oc', 'create', '-f', mock.ANY, '-n', 'default'], None)])

    old_deployment = '''{
    "kind": "DeploymentConfig",
    "apiVersion": "v1",
    "metadata": {
        "name": "router",
        "labels": {
            "router": "router"
        }
    },
    "spec": {
        "strategy": {
            "type": "Rolling",
            "rollingParams": {
                "maxUnavailable": "25%",
                "maxSurge": 0
            },
            "resources": {}
        },
        "triggers": [
            {
                "type": "ConfigChange"
            }
        ],
        "replicas": 2,
        "test": false,
        "selector": {
            "router": "router"
        },
        "template": {
            "metadata": {
                "labels": {
                    "router": "router"
                }
            },
            "spec": {
                "volumes": [
                    {
                        "name": "server-certificate",
                        "secret": {
                            "secretName": "router-certs"
                        }
                    }
                ],
                "containers": [
                    {
                        "name": "router",
                        "image": "registry.redhat.io/openshift3/ose-haproxy-router:v3.5.0.39",
                        "ports": [
                            {
                                "containerPort": 80
                            },
                            {
                                "containerPort": 443
                            },
                            {
                                "name": "stats",
                                "containerPort": 1936,
                                "protocol": "TCP"
                            }
                        ],
                        "env": [
                            {
                                "name": "DEFAULT_CERTIFICATE_DIR",
                                "value": "/etc/pki/tls/private"
                            },
                            {
                                "name": "ROUTER_EXTERNAL_HOST_HOSTNAME"
                            },
                            {
                                "name": "ROUTER_EXTERNAL_HOST_HTTPS_VSERVER"
                            },
                            {
                                "name": "ROUTER_EXTERNAL_HOST_HTTP_VSERVER"
                            },
                            {
                                "name": "ROUTER_EXTERNAL_HOST_INSECURE",
                                "value": "false"
                            },
                            {
                                "name": "ROUTER_EXTERNAL_HOST_INTERNAL_ADDRESS"
                            },
                            {
                                "name": "ROUTER_EXTERNAL_HOST_PARTITION_PATH"
                            },
                            {
                                "name": "ROUTER_EXTERNAL_HOST_PASSWORD"
                            },
                            {
                                "name": "ROUTER_EXTERNAL_HOST_PRIVKEY",
                                "value": "/etc/secret-volume/router.pem"
                            },
                            {
                                "name": "ROUTER_EXTERNAL_HOST_USERNAME"
                            },
                            {
                                "name": "ROUTER_EXTERNAL_HOST_VXLAN_GW_CIDR"
                            },
                            {
                                "name": "ROUTER_SERVICE_HTTPS_PORT",
                                "value": "443"
                            },
                            {
                                "name": "ROUTER_SERVICE_HTTP_PORT",
                                "value": "80"
                            },
                            {
                                "name": "ROUTER_SERVICE_NAME",
                                "value": "router"
                            },
                            {
                                "name": "ROUTER_SERVICE_NAMESPACE",
                                "value": "default"
                            },
                            {
                                "name": "ROUTER_SUBDOMAIN"
                            },
                            {
                                "name": "STATS_PASSWORD",
                                "value": "eSfUICQyyr"
                            },
                            {
                                "name": "STATS_PORT",
                                "value": "1936"
                            },
                            {
                                "name": "STATS_USERNAME",
                                "value": "admin"
                            }
                        ],
                        "resources": {
                            "requests": {
                                "cpu": "100m",
                                "memory": "256Mi"
                            }
                        },
                        "volumeMounts": [
                            {
                                "name": "server-certificate",
                                "readOnly": true,
                                "mountPath": "/etc/pki/tls/private"
                            }
                        ],
                        "livenessProbe": {
                            "httpGet": {
                                "path": "/healthz",
                                "port": 1936,
                                "host": "localhost"
                            },
                            "initialDelaySeconds": 10
                        },
                        "readinessProbe": {
                            "httpGet": {
                                "path": "/healthz",
                                "port": 1936,
                                "host": "localhost"
                            },
                            "initialDelaySeconds": 10
                        },
                        "imagePullPolicy": "IfNotPresent"
                    }
                ],
                "nodeSelector": {
                    "type": "infra"
                },
                "serviceAccountName": "router",
                "serviceAccount": "router",
                "hostNetwork": true,
                "securityContext": {}
            }
        }
    }
}'''

    @mock.patch('oc_adm_router.locate_oc_binary')
    @mock.patch('oc_adm_router.Utils._write')
    @mock.patch('oc_adm_router.Utils.create_tmpfile_copy')
    @mock.patch('oc_adm_router.Router._run')
    def test_with_old_deployment(self, mock_cmd, mock_tmpfile_copy, mock_write, mock_oc_binary):
        ''' Testing create with old deployment lacking EXTENDED_VALIDATION '''
        params = {'state': 'present',
                  'debug': False,
                  'namespace': 'default',
                  'name': 'router',
                  'default_cert': None,
                  'cert_file': None,
                  'key_file': None,
                  'cacert_file': None,
                  'labels': {"router": "router", "another-label": "val"},
                  'ports': ['80:80', '443:443'],
                  'images': None,
                  'latest_images': None,
                  'clusterip': None,
                  'portalip': None,
                  'session_affinity': None,
                  'service_type': None,
                  'kubeconfig': '/etc/origin/master/admin.kubeconfig',
                  'replicas': 2,
                  'selector': 'type=infra',
                  'service_account': 'router',
                  'router_type': None,
                  'host_network': None,
                  'extended_validation': True,
                  'external_host': None,
                  'external_host_vserver': None,
                  'external_host_insecure': False,
                  'external_host_partition_path': None,
                  'external_host_username': None,
                  'external_host_password': None,
                  'external_host_private_key': None,
                  'stats_user': None,
                  'stats_password': None,
                  'stats_port': 1936,
                  'edits': []}

        mock_cmd.side_effect = [
            (0, RouterTest.old_deployment, ''),
            (1, '', 'Error from server (NotFound): service "router" not found'),
            (1, '', 'Error from server (NotFound): serviceaccount "router" not found'),
            (1, '', 'Error from server (NotFound): secret "router-certs" not found'),
            (1, '', 'Error from server (NotFound): clusterrolebinding "router-router-role" not found'),
            (0, RouterTest.dry_run, ''),
            (0, '', ''),
            (0, '', ''),
            (0, '', ''),
            (0, '', ''),
            (0, '', ''),
        ]

        mock_tmpfile_copy.side_effect = [
            '/tmp/mocked_kubeconfig',
        ]

        mock_oc_binary.side_effect = [
            'oc',
        ]

        results = Router.run_ansible(params, False)

        self.assertTrue(results['changed'])
        for result in results['module_results']['results']:
            self.assertEqual(result['returncode'], 0)

        # Need any_order=True (second parameter to assert_has_calls)
        # because the order of the oc create/replace commands is
        # non-deterministic.
        mock_cmd.assert_has_calls([
            mock.call(['oc', 'get', 'dc', 'router', '-o', 'json', '-n', 'default'], None),
            mock.call(['oc', 'get', 'svc', 'router', '-o', 'json', '-n', 'default'], None),
            mock.call(['oc', 'get', 'sa', 'router', '-o', 'json', '-n', 'default'], None),
            mock.call(['oc', 'get', 'secret', 'router-certs', '-o', 'json', '-n', 'default'], None),
            mock.call(['oc', 'get', 'clusterrolebinding', 'router-router-role', '-o', 'json', '-n', 'default'], None),
            mock.call(['oc', 'adm', 'router', 'router', '--external-host-insecure=False',
                       "--labels=another-label=val,router=router",
                       '--ports=80:80,443:443', '--replicas=2', '--selector=type=infra', '--service-account=router',
                       '--stats-port=1936', '--dry-run=True', '-o', 'json', '-n', 'default'], None),
            mock.call(['oc', 'replace', '-f', mock.ANY, '-n', 'default'], None),
            mock.call(['oc', 'create', '-f', mock.ANY, '-n', 'default'], None),
            mock.call(['oc', 'create', '-f', mock.ANY, '-n', 'default'], None),
            mock.call(['oc', 'create', '-f', mock.ANY, '-n', 'default'], None)], True)

    old_service = '''{
    "kind": "Service",
    "apiVersion": "v1",
    "metadata": {
        "name": "router",
        "labels": {
            "router": "router"
        }
    },
    "spec": {
        "ports": [
            {
                "name": "80-tcp",
                "protocol": "TCP",
                "port": 80,
                "targetPort": 80
            },
            {
                "name": "443-tcp",
                "protocol": "TCP",
                "port": 443,
                "targetPort": 443
            },
            {
                "name": "1936-tcp",
                "protocol": "TCP",
                "port": 1936,
                "targetPort": 1936
            }
        ],
        "selector": {
            "router": "router"
        }
    }
}'''

    @mock.patch('oc_adm_router.locate_oc_binary')
    @mock.patch('oc_adm_router.Utils._write')
    @mock.patch('oc_adm_router.Utils.create_tmpfile_copy')
    @mock.patch('oc_adm_router.Router._run')
    def test_create_with_old_service(self, mock_cmd, mock_tmpfile_copy, mock_write, mock_oc_binary):
        ''' Testing create with old service lacking annotation '''
        params = {'state': 'present',
                  'debug': False,
                  'namespace': 'default',
                  'name': 'router',
                  'default_cert': None,
                  'cert_file': None,
                  'key_file': None,
                  'cacert_file': None,
                  'labels': {"router": "router", "another-label": "val"},
                  'ports': ['80:80', '443:443'],
                  'images': None,
                  'latest_images': None,
                  'clusterip': None,
                  'portalip': None,
                  'session_affinity': None,
                  'service_type': None,
                  'kubeconfig': '/etc/origin/master/admin.kubeconfig',
                  'replicas': 2,
                  'selector': 'type=infra',
                  'service_account': 'router',
                  'router_type': None,
                  'host_network': None,
                  'extended_validation': True,
                  'external_host': None,
                  'external_host_vserver': None,
                  'external_host_insecure': False,
                  'external_host_partition_path': None,
                  'external_host_username': None,
                  'external_host_password': None,
                  'external_host_private_key': None,
                  'stats_user': None,
                  'stats_password': None,
                  'stats_port': 1936,
                  'edits': []}

        mock_cmd.side_effect = [
            (1, '', 'Error from server (NotFound): deploymentconfigs "router" not found'),
            (0, RouterTest.old_service, ''),
            (1, '', 'Error from server (NotFound): serviceaccount "router" not found'),
            (1, '', 'Error from server (NotFound): secret "router-certs" not found'),
            (1, '', 'Error from server (NotFound): clusterrolebinding "router-router-role" not found'),
            (0, RouterTest.dry_run, ''),
            (0, '', ''),
            (0, '', ''),
            (0, '', ''),
            (0, '', ''),
            (0, '', ''),
        ]

        mock_tmpfile_copy.side_effect = [
            '/tmp/mocked_kubeconfig',
        ]

        mock_oc_binary.side_effect = [
            'oc',
        ]

        results = Router.run_ansible(params, False)

        self.assertTrue(results['changed'])
        for result in results['module_results']['results']:
            self.assertEqual(result['returncode'], 0)

        # Need any_order=True (second parameter to assert_has_calls)
        # because the order of the oc create/replace commands is
        # non-deterministic.
        mock_cmd.assert_has_calls([
            mock.call(['oc', 'get', 'dc', 'router', '-o', 'json', '-n', 'default'], None),
            mock.call(['oc', 'get', 'svc', 'router', '-o', 'json', '-n', 'default'], None),
            mock.call(['oc', 'get', 'sa', 'router', '-o', 'json', '-n', 'default'], None),
            mock.call(['oc', 'get', 'secret', 'router-certs', '-o', 'json', '-n', 'default'], None),
            mock.call(['oc', 'get', 'clusterrolebinding', 'router-router-role', '-o', 'json', '-n', 'default'], None),
            mock.call(['oc', 'adm', 'router', 'router', '--external-host-insecure=False',
                       "--labels=another-label=val,router=router",
                       '--ports=80:80,443:443', '--replicas=2', '--selector=type=infra', '--service-account=router',
                       '--stats-port=1936', '--dry-run=True', '-o', 'json', '-n', 'default'], None),
            mock.call(['oc', 'create', '-f', mock.ANY, '-n', 'default'], None),
            mock.call(['oc', 'replace', '-f', mock.ANY, '-n', 'default'], None),
            mock.call(['oc', 'create', '-f', mock.ANY, '-n', 'default'], None),
            mock.call(['oc', 'create', '-f', mock.ANY, '-n', 'default'], None)], True)

    @mock.patch('oc_adm_router.locate_oc_binary')
    @mock.patch('oc_adm_router.Utils._write')
    @mock.patch('oc_adm_router.Utils.create_tmpfile_copy')
    @mock.patch('oc_adm_router.Router._run')
    def test_append_to_env(self, mock_cmd, mock_tmpfile_copy, mock_write, mock_oc_binary):
        ''' Testing edits that append environment variables '''

        mock_cmd.side_effect = [
            (1, '', 'Error from server (NotFound): deploymentconfigs "router" not found'),
            (1, '', 'Error from server (NotFound): service "router" not found'),
            (1, '', 'Error from server (NotFound): serviceaccount "router" not found'),
            (1, '', 'Error from server (NotFound): secret "router-certs" not found'),
            (1, '', 'Error from server (NotFound): clusterrolebinding "router-router-role" not found'),
            (0, RouterTest.dry_run, ''),
        ]

        mock_oc_binary.side_effect = [
            'oc',
        ]

        router_options = {
            'default_cert': {'value': None, 'include': False},
            'cert_file': {'value': None, 'include': False},
            'key_file': {'value': None, 'include': False},
            'images': {'value': None, 'include': True},
            'latest_images': {'value': None, 'include': True},
            'labels': {'value': {"router": "router"}, 'include': True},
            'ports': {'value': ['80:80', '443:443'], 'include': True},
            'replicas': {'value': 2, 'include': True},
            'selector': {'value': 'type=infra', 'include': True},
            'service_account': {'value': 'router', 'include': True},
            'router_type': {'value': None, 'include': False},
            'host_network': {'value': None, 'include': True},
            'extended_validation': {'value': True, 'include': False},
            'external_host': {'value': None, 'include': True},
            'external_host_vserver': {'value': None, 'include': True},
            'external_host_insecure': {'value': False, 'include': True},
            'external_host_partition_path': {'value': None, 'include': True},
            'external_host_username': {'value': None, 'include': True},
            'external_host_password': {'value': None, 'include': True},
            'external_host_private_key': {'value': None, 'include': True},
            'stats_user': {'value': None, 'include': True},
            'stats_password': {'value': None, 'include': True},
            'stats_port': {'value': None, 'include': True},
            'cacert_file': {'value': None, 'include': False},
            'edits': {
                'value': [
                    {
                        "action": "append",
                        "key": "spec.template.spec.containers[0].env",
                        "value": {
                            "name": "VARIABLE1",
                            "value": "value in first edit"
                        }
                    },
                    {
                        "action": "append",
                        "key": "spec.template.spec.containers[0].env",
                        "value": {
                            "name": "VARIABLE1",
                            "value": "value in second edit"
                        }
                    },
                    {
                        "action": "append",
                        "key": "spec.template.spec.containers[0].env",
                        "value": {
                            "name": "VARIABLE2",
                            "value": "xyz"
                        }
                    },
                    {
                        "action": "append",
                        "key": "spec.template.spec.containers[0].env",
                        "value": {
                            "name": "ROUTER_SUBDOMAIN",
                            "value": "${name}-${namespace}.domain.tld"
                        }
                    }
                ],
                'include': False
            },
        }
        router = Router(RouterConfig('router', 'default', '', router_options))
        router.get()

        dc = None
        for item in router.prepared_router.items():
            if item[0] == 'DeploymentConfig':
                dc = item[1]['obj']
        self.assertNotEqual(dc, None)

        for var in ['ROUTER_SUBDOMAIN', 'VARIABLE1', 'VARIABLE2']:
            matches = [env for env in dc.get_env_vars() if env['name'] == var]
            self.assertEqual(1, len(matches),
                             "expected to find {} 1 time, found it {} times: {}".format(var, len(matches), matches))

        var = dc.get_env_var('VARIABLE1')
        self.assertEqual(var['value'], 'value in second edit')

    @unittest.skipIf(six.PY3, 'py2 test only')
    @mock.patch('os.path.exists')
    @mock.patch('os.environ.get')
    def test_binary_lookup_fallback(self, mock_env_get, mock_path_exists):
        ''' Testing binary lookup fallback '''

        mock_env_get.side_effect = lambda _v, _d: ''

        mock_path_exists.side_effect = lambda _: False

        self.assertEqual(locate_oc_binary(), 'oc')

    @unittest.skipIf(six.PY3, 'py2 test only')
    @mock.patch('os.path.exists')
    @mock.patch('os.environ.get')
    def test_binary_lookup_in_path(self, mock_env_get, mock_path_exists):
        ''' Testing binary lookup in path '''

        oc_bin = '/usr/bin/oc'

        mock_env_get.side_effect = lambda _v, _d: '/bin:/usr/bin'

        mock_path_exists.side_effect = lambda f: f == oc_bin

        self.assertEqual(locate_oc_binary(), oc_bin)

    @unittest.skipIf(six.PY3, 'py2 test only')
    @mock.patch('os.path.exists')
    @mock.patch('os.environ.get')
    def test_binary_lookup_in_usr_local(self, mock_env_get, mock_path_exists):
        ''' Testing binary lookup in /usr/local/bin '''

        oc_bin = '/usr/local/bin/oc'

        mock_env_get.side_effect = lambda _v, _d: '/bin:/usr/bin'

        mock_path_exists.side_effect = lambda f: f == oc_bin

        self.assertEqual(locate_oc_binary(), oc_bin)

    @unittest.skipIf(six.PY3, 'py2 test only')
    @mock.patch('os.path.exists')
    @mock.patch('os.environ.get')
    def test_binary_lookup_in_home(self, mock_env_get, mock_path_exists):
        ''' Testing binary lookup in ~/bin '''

        oc_bin = os.path.expanduser('~/bin/oc')

        mock_env_get.side_effect = lambda _v, _d: '/bin:/usr/bin'

        mock_path_exists.side_effect = lambda f: f == oc_bin

        self.assertEqual(locate_oc_binary(), oc_bin)

    @unittest.skipIf(six.PY2, 'py3 test only')
    @mock.patch('shutil.which')
    @mock.patch('os.environ.get')
    def test_binary_lookup_fallback_py3(self, mock_env_get, mock_shutil_which):
        ''' Testing binary lookup fallback '''

        mock_env_get.side_effect = lambda _v, _d: ''

        mock_shutil_which.side_effect = lambda _f, path=None: None

        self.assertEqual(locate_oc_binary(), 'oc')

    @unittest.skipIf(six.PY2, 'py3 test only')
    @mock.patch('shutil.which')
    @mock.patch('os.environ.get')
    def test_binary_lookup_in_path_py3(self, mock_env_get, mock_shutil_which):
        ''' Testing binary lookup in path '''

        oc_bin = '/usr/bin/oc'

        mock_env_get.side_effect = lambda _v, _d: '/bin:/usr/bin'

        mock_shutil_which.side_effect = lambda _f, path=None: oc_bin

        self.assertEqual(locate_oc_binary(), oc_bin)

    @unittest.skipIf(six.PY2, 'py3 test only')
    @mock.patch('shutil.which')
    @mock.patch('os.environ.get')
    def test_binary_lookup_in_usr_local_py3(self, mock_env_get, mock_shutil_which):
        ''' Testing binary lookup in /usr/local/bin '''

        oc_bin = '/usr/local/bin/oc'

        mock_env_get.side_effect = lambda _v, _d: '/bin:/usr/bin'

        mock_shutil_which.side_effect = lambda _f, path=None: oc_bin

        self.assertEqual(locate_oc_binary(), oc_bin)

    @unittest.skipIf(six.PY2, 'py3 test only')
    @mock.patch('shutil.which')
    @mock.patch('os.environ.get')
    def test_binary_lookup_in_home_py3(self, mock_env_get, mock_shutil_which):
        ''' Testing binary lookup in ~/bin '''

        oc_bin = os.path.expanduser('~/bin/oc')

        mock_env_get.side_effect = lambda _v, _d: '/bin:/usr/bin'

        mock_shutil_which.side_effect = lambda _f, path=None: oc_bin

        self.assertEqual(locate_oc_binary(), oc_bin)
