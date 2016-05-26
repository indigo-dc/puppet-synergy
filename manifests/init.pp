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
# [*user_shares*]
# Define relative shares between user under a same project.
# {'ProjectA' => {'userA1' => 60, 'userA2' => 40},
#  'ProjectB' => {'userB1' => 10, 'userB2' => 90}}
#
# === Authors
#
# Vincent Llorens <vincent.llorens@cc.in2p3.fr>
#
# === Copyright
#
# Copyright 2016 Vincent Llorens - INDIGO-DataCloud, unless otherwise noted.
#


class synergy (
  $synergy_db_url,
  $dynamic_quotas,
  $project_shares,
  $user_shares,
  $keystone_url,
  $keystone_admin_user,
  $keystone_admin_password,
){
  # Packages to download and install
  $rdo_rpm = 'https://repos.fedorapeople.org/repos/openstack/openstack-liberty/rdo-release-liberty-3.noarch.rpm'
  $synergy_service_rpm = 'https://github.com/indigo-dc/synergy-service/releases/download/v0.2/python-synergy-service-0.2-2.el7.centos.noarch.rpm'
  $synergy_service_deb = 'https://github.com/indigo-dc/synergy-service/releases/download/v0.2/python-synergy-service_0.2-1_all.deb'

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

  package { 'wget':
    ensure => present,
  }

  # Install Synergy package and dependencies
  # TODO better way to store this intermediate package files
  if $os_name == 'CentOS' and $os_version == '7' {
    exec {'wget rdo.rpm':
      command => "/usr/bin/wget -q -O /tmp/rdo.rpm $rdo_rpm",
      creates => '/tmp/rdo.rpm',
      require => Package['wget'],
    }

    file { '/tmp/rdo.rpm':
      ensure  => present,
      require => Exec['wget rdo.rpm'],
    }

    package { 'rdo-release':
      provider => 'rpm',
      ensure   => present,
      source   => '/tmp/rdo.rpm',
      require  => File['/tmp/rdo.rpm'],
    }

    package { 'python-dateutil':
      ensure => present,
    }

    package { 'python-eventlet':
      ensure => present,
    }

    package { 'python-pip':
      ensure => present,
    }

    # Fix puppet not being able to discover pip on *EL >= 6
    # https://tickets.puppetlabs.com/browse/PUP-4997
    file { '/usr/bin/pip-python':
      ensure  => 'link',
      target  => '/usr/bin/pip',
      require => Package['python-pip'],
    }
  
    package { 'oslo.config':
      ensure   => present,
      provider => 'pip',
      require  => Package['python-pip'],
    }

    package { 'python-oslo-log':
      ensure  => present,
      require => Package['rdo-release'],
    }

    package { 'python-oslo-messaging':
      ensure  => present,
      require => Package['rdo-release'],
    }

    exec {'wget python-synergy-service.rpm':
      command => "/usr/bin/wget -q -O /tmp/python-synergy-service.rpm $synergy_service_rpm",
      creates => '/tmp/python-synergy-service.rpm',
      require => Package['wget'],
    }

    file { '/tmp/python-synergy-service.rpm':
      ensure  => present,
      require => Exec['wget python-synergy-service.rpm'],
    }

    package { 'python-synergy-service':
      provider => 'rpm',
      ensure   => present,
      source   => '/tmp/python-synergy-service.rpm',
      require  => [
        Package['python-dateutil'],
        Package['python-eventlet'],
        Package['oslo.config'],
        Package['python-oslo-log'],
        Package['python-oslo-messaging'],
        File['/tmp/python-synergy-service.rpm'] ],
    }
  }
  elsif $os_name == 'Ubuntu' and $os_version == '14.04' {
    exec { 'wget python-synergy-service.deb':
      command => "/usr/bin/wget -q -O /tmp/python-synergy-service.deb $synergy_service_deb",
      creates => '/tmp/python-synergy-service.deb',
      require => Package['wget'],
    }

    file { 'python-synergy-service.deb':
      path    => '/tmp/python-synergy-service.deb',
      ensure  => present,
      require => Exec['wget python-synergy-service.deb'],
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
      provider => 'dpkg',
      ensure   => latest,
      source   => '/tmp/python-synergy-service.deb',
      require  => [
        File['python-synergy-service.deb'],
        Package['python-eventlet'],
        Package['python-pbr'],
        Package['python-oslo.messaging'],
        Package['python-dateutil'],
        Package['python-oslo.config'],
      ],
    }
  }
  else {
    fail("This module supports CentOS 7 and Ubuntu 14.04 only, not $os_name $os_version.")
  }

  # TODO when the scheduler is shipped
  # Install the Synergy scheduler
  # package { 'synergy-scheduler-manager':
  #   provider => 'pip',
  #   ensure   => latest,
  #   require  => Package['python-synergy-service'],
  # }

  # Set the configuration
  file { '/etc/synergy/synergy.conf':
    ensure  => present,
    content => template('synergy/synergy.conf.erb'),
    require => Package['python-synergy-service'],
  }
}
