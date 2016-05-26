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

  # Install Synergy package and dependencies
  if $os_name == 'CentOS' and $os_version == '7' {
    yumrepo { 'cc-vendor':
      descr    => 'Vendor repository for Synergy',
      enabled  => 1,
      baseurl  => "http://ccrepoli.in2p3.fr/linux/el/${os_version}x/${::architecture}/vendor",
      gpgcheck => 0,
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
        Yumrepo['cc-vendor'] ],
    }
  }
  # TODO better way to store the intermediate package files
  elsif $os_name == 'Ubuntu' and $os_version == '14.04' {
    package { 'wget':
      ensure => present,
    }

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
