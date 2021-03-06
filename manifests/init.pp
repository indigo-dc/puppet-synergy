# == Class: synergy
#
# Install Synergy on an existing OpenStack instance.
#
# === TODO
# - release v1.0.0
#
# [*project_shares*]
# Define relative shares between each project.
# {'ProjectA' => 70, 'ProjectB' => 30}
#
# === Authors
#
# Vincent Llorens <vincent.llorens@cc.in2p3.fr>
#
# === Copyright
#
# Copyright 2016 Vincent Llorens - INDIGO-DataCloud, unless otherwise noted.
#

include apt

class synergy (
  $synergy_db_url,
  $synergy_log_file='/var/log/synergy/synergy.log',
  $synergy_log_level='INFO',
  $synergy_service_host='localhost',
  $synergy_service_port=8051,
  $synergy_project_shares,
  $keystone_url,
  $keystone_admin_user,
  $keystone_admin_password,
  $nova_url,
  $nova_db_url,
  $amqp_backend='rabbit',
  $amqp_hosts='',
  $amqp_host,
  $amqp_port=5672,
  $amqp_user='openstack',
  $amqp_password,
  $amqp_virtual_host='/',
  $metadata_secret,
  $enable_external_repository=true,
){
  # Check which OS we are running on
  $os_name = $::operatingsystem
  if $os_name == 'Ubuntu' {
    $os_version = $::operatingsystemrelease
  }
  elsif $os_name == 'CentOS' {
    $os_version = $::operatingsystemmajrelease
  }
  else {
    $os_version = undef
  }

  # Set package requirements w.r.t. "enable_external_repository"
  $centos_synergy_service_require   = []
  $centos_synergy_scheduler_require = [Package['python-synergy-service']]
  $ubuntu_synergy_service_require   = []
  $ubuntu_synergy_scheduler_require = [Package['python-synergy-service']]

  if $enable_external_repository {
    $centos_synergy_service_require   += [Package['centos-release-openstack-liberty']]
    $centos_synergy_service_require   += [Yumrepo['indigo']]
    $centos_synergy_scheduler_require += [Yumrepo['indigo']]
    $ubuntu_synergy_service_require   += [Apt::Source['indigo']]
    $ubuntu_synergy_scheduler_require += [Apt::Source['indigo']]
  }

  # Install/check Synergy dependency that is not available as a system package
  package { 'tabulate':
    provider => 'pip',
    ensure   => 'present',
  }

  # CentOS 7 packages
  if $os_name == 'CentOS' and $os_version == '7' {
    # Install or not the CentOS OpenStack repository
    if $enable_external_repository {
      package { 'centos-release-openstack-liberty':
        ensure => latest,
      }
    }

    # Install or not the INDIGO-DC repository
    if $enable_external_repository {
      yumrepo { 'indigo':
        descr    => 'INDIGO-DataCloud repository for Synergy',
        enabled  => 1,
        baseurl  => 'http://repo.indigo-datacloud.eu/repository/indigo/1/centos7/x86_64/base/',
        gpgcheck => 1,
        gpgkey   => 'http://repo.indigo-datacloud.eu/repository/RPM-GPG-KEY-indigodc',
      }
    }

    package { 'python-synergy-service':
      ensure   => present,
      require  => $centos_synergy_service_require,
    }

    package { 'python-synergy-scheduler-manager':
      ensure  => present,
      require => $centos_synergy_scheduler_require,
    }
  }

  # Ubuntu 14.04 packages
  elsif $os_name == 'Ubuntu' and $os_version == '14.04' {
    # Install or not the INDIGO-DC repository
    if $enable_external_repository {
      apt::key { 'indigo':
        id     => '02F49DBEE9D159F18FD3D35F4CC3AB0A98098DFB',
        source => 'http://repo.indigo-datacloud.eu/repository/RPM-GPG-KEY-indigodc',
      }
      apt::source { 'indigo':
        location => 'http://repo.indigo-datacloud.eu/repository/indigo/1/ubuntu/',
        repos    => "main third-party",
        require  => Apt::Key['indigo'],
      }
    }

    package { 'python-synergy-service':
      provider => 'apt',
      name     => 'python-synergy-service',
      ensure   => present,
      require  => $ubuntu_synergy_service_require,
    }

    package { 'python-synergy-scheduler-manager':
      name    => 'python-synergy-scheduler-manager',
      ensure  => present,
      require => $ubuntu_synergy_scheduler_require,
    }
  }
  else {
    fail("This module supports CentOS 7 and Ubuntu 14.04 only, not $os_name $os_version.")
  }

  # Set the configuration
  file { '/etc/synergy/synergy.conf':
    ensure  => present,
    content => template('synergy/synergy.conf.erb'),
    require => Package['python-synergy-service'],
  }
}
