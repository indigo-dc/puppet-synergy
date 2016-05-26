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

Set up [Synergy](https://launchpad.net/synergy-service) on an existing
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

Classes:

- `synergy`

## Limitations

**Operating System**
- CentOS 7
- Ubuntu 14.04

**OpenStack version**
- Liberty


## Development

Feel free to submit pull requests on the [project github page](https://github.com/indigo-dc/synergy-service).

## Release Notes

