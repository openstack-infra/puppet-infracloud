class infracloud::compute(
  $nova_rabbit_password,
  $neutron_rabbit_password,
  $neutron_admin_password,
  $br_name,
  $controller_public_address,
) {

  ### Networking ###

  class {'::infracloud::veth':
    br_name => $br_name,
  }

  ### Repos ###
  include ::apt

  class { '::openstack_extras::repo::debian::ubuntu':
    release         => 'kilo',
    package_require => true,
  }

  ### Nova ###

  # nova.conf
  class { '::nova':
    rabbit_userid      => 'nova',
    rabbit_password    => $nova_rabbit_password,
    rabbit_host        => $controller_public_address,
    rabbit_port        => '5671',
    rabbit_use_ssl     => true,
    glance_api_servers => "https://${controller_public_address}:9292",
  }

  # nova-compute service
  class { '::nova::compute':
    enabled => true,
  }

  # nova.conf neutron credentials
  class { '::nova::network::neutron':
    neutron_url            => "https://${controller_public_address}:9696",
    neutron_admin_auth_url => "https://${controller_public_address}:35357/v2.0",
    neutron_admin_password => $neutron_admin_password,
  }

  ### Neutron ###

  # neutron.conf
  class { '::neutron':
    rabbit_user     => 'neutron',
    rabbit_password => $neutron_rabbit_password,
    rabbit_host     => $controller_public_address,
    rabbit_port     => '5671',
    rabbit_use_ssl  => true,
  }

  # ML2
  class { '::neutron::agents::ml2::linuxbridge':
    physical_interface_mappings => ['provider:veth2'],
    require                     => Class['infracloud::veth'],
  }
  # Fix for https://bugs.launchpad.net/ubuntu/+source/neutron/+bug/1453188
  file { '/usr/bin/neutron-plugin-linuxbridge-agent':
    ensure => link,
    target => '/usr/bin/neutron-linuxbridge-agent',
    before => Package['neutron-plugin-linuxbridge-agent'],
  }
}
