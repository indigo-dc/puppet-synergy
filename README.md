# Synergy

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with synergy](#setup)
    * [What synergy affects](#what-synergy-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with synergy](#beginning-with-synergy)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

Set up and manage [Synergy](https://launchpad.net/synergy-service) on an existing
OpenStack instance.


## Module Description

Users that already have an OpenStack instance can use this module to install
and configure the two main Synergy components:

- [synergy-service](https://launchpad.net/synergy-service)
- [synergy-scheduler-manager](https://launchpad.net/synergy-scheduler-manager)

This module will download the latest version of Synergy and install it.
One can manage Synergy configuration directly through this module.


## Setup

### What synergy affects

* Synergy configuration file at `/etc/synergy/synergy.conf`
* packages `synergy-service` (rpm or deb depending on the platform) and
  `synergy-scheduler-manager` (via pip)

### Setup Requirements

An OpenStack instance (with the version specified in [Limitations](#limitations)).

The Puppet module [puppetlabs/apt](https://forge.puppet.com/puppetlabs/apt/)
if you plan to install on Ubuntu.

An OpenStack package repository for fetching `python-oslo*` libraries:

- on Ubuntu, use the [*OpenStack/CloudArchive*](https://wiki.ubuntu.com/OpenStack/CloudArchive) repository.
- on CentOS, the *CentOS Cloud SIG* repository will be installed during the Puppet run through the `centos-openstack-release-{openstackversion}` package.

### Beginning with synergy

Make sure this module is discoverable by your Puppet instance.

Declare the `synergy` class (see [Usage](#usage)).

## Usage

```puppet
class { 'synergy':
  synergy_db_url          => 'mysql://test:test@localhost',
  dynamic_quotas          => {'project_A' => 1,  'project_B' => 2},
  project_shares          => {'project_A' => 70, 'project_B' => 30 },
  user_shares             => {'project_A' => {'user1' => 60, 'user2' => 40 },
                              'project_B' => {'user3' => 80, 'user4' => 20}},
  keystone_url            => 'https://example.com',
  keystone_admin_user     => 'admin',
  keystone_admin_password => 'the admin password',
}
```

## Reference

### Class: `synergy`

#### Parameters

- `synergy_db_url` (*required*): the Synergy database, must be compliant to the [SQLAlchemy database URL schema](http://docs.sqlalchemy.org/en/latest/core/engines.html#database-urls). 
- `synergy_log_file` (default: `/var/log/synergy/synergy.log`): a file to log to.
- `synergy_log_level` (default: `INFO`): log all information including and above this level, choices: `INFO`, `WARNING`, `ERROR`.
- `synergy_service_host` (default: `localhost`): synergy host.
- `synergy_service_port` (default: `8051`): synergy port.
- `synergy_project_shares` (*required*): a puppet hash describing the project shares (see [Usage](#usage) for an example).
- `keystone_url` (*required*): Keystone URL.
- `keystone_admin_user` (*required*): Keystone admin user.
- `keystone_admin_password` (*required*): Keystone admin password.
- `nova_url` (*required*): Nova URL
- `nova_db_url` (*required*): Nova database URL, in SQLAlchemy format.
- `nova_conf_path` (default: undef): path to the configuration file used by Nova.
- `amqp_backend` (default: `rabbit`): AMQP backend.
- `amqp_host` (*required*): AMQP host.
- `amqp_port` (default: `5672`): AMQP port.
- `amqp_user` (default: `openstack`): AMQP user.
- `amqp_password` (*required*): AMQP password.
- `amqp_virtual_host` (default: `/`): AMQP virtual host.
- `metadata_secret` (*required*): a random secret.
- `enable_external_repository` (default: `true`): whether or not to setup external package repositories.

## Limitations

**Operating System**
- CentOS 7
- Ubuntu 14.04

**OpenStack version**
- Liberty


## Development

Feel free to submit pull requests on the [project github page](https://github.com/indigo-dc/synergy-service).
