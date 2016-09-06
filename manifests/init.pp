# == Class: synergy
#
# Install Synergy on an existing OpenStack instance.
#
# === TODO
# - doc:examples
# - doc:parameters
# - create db tables using an sql script?
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
  $amqp_host,
  $amqp_port=5672,
  $amqp_user='openstack',
  $amqp_password,
  $amqp_virtual_host='/',
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

  # Install Synergy package and dependencies
  if $os_name == 'CentOS' and $os_version == '7' {
    yumrepo { 'indigo':
      descr    => 'INDIGO-DataCloud repository for Synergy',
      enabled  => 1,
      baseurl  => 'http://repo.indigo-datacloud.eu/repository/indigo/1/centos7/x86_64/base/',
      gpgcheck => 1,
      gpgkey   => 'http://repo.indigo-datacloud.eu/repository/RPM-GPG-KEY-indigodc',
    }

    package { 'centos-release-openstack-liberty':
      ensure => latest,
    }

    package { 'python-dateutil':
      ensure => present,
    }

    package { 'python-eventlet':
      ensure  => present,
      require => Package['centos-release-openstack-liberty'],
    }

    package { 'python2-oslo-config':
      ensure  => present,
      require => Package['centos-release-openstack-liberty'],
    }

    package { 'python-oslo-log':
      ensure  => present,
      require => Package['centos-release-openstack-liberty'],
    }

    package { 'python-oslo-messaging':
      ensure  => present,
      require => Package['centos-release-openstack-liberty'],
    }

    package { 'python-synergy-service':
      ensure   => present,
      require  => [
        Package['centos-release-openstack-liberty'],
        Yumrepo['indigo'],
      ],
    }

    package { 'python-synergy-scheduler-manager':
      ensure  => present,
      require => [
        Package['python-synergy-service'],
        Yumrepo['indigo'],
      ],
    }
  }

  elsif $os_name == 'Ubuntu' and $os_version == '14.04' {
    apt::key { 'indigo':
      id     => '02F49DBEE9D159F18FD3D35F4CC3AB0A98098DFB',
      source => 'http://repo.indigo-datacloud.eu/repository/RPM-GPG-KEY-indigodc',
    }

    apt::source { 'indigo':
      location => 'http://repo.indigo-datacloud.eu/repository/indigo/1/ubuntu/',
      repos    => "main third-party",
      require  => Apt::Key['indigo'],
    }

    package { 'python-eventlet':
      ensure => present,
    }

    package { 'python-pbr':
      ensure => present,
    }

    package { 'python-oslo.messaging':
      ensure => present,
    }

    package { 'python-dateutil':
      ensure => present,
    }

    package { 'python-oslo.config':
      ensure => present,
    }

    package { 'python-synergy-service':
      provider => 'apt',
      name     => 'python-synergy-service',
      ensure   => present,
      require  => [
        Package['python-eventlet'],
        Package['python-pbr'],
        Package['python-oslo.messaging'],
        Package['python-dateutil'],
        Package['python-oslo.config'],
        Apt::Source['indigo'],
      ],
    }

    package { 'python-synergy-scheduler-manager':
      name    => 'python-synergy-scheduler-manager',
      ensure  => present,
      require => [
        Package['python-synergy-service'],
        Apt::Source['indigo'],
      ],
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
