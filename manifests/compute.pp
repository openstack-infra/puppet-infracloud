#Class infracloud::compute
#
class infracloud::compute(
  $br_name,
  $controller_public_address,
  $neutron_admin_password,
  $neutron_rabbit_password,
  $nova_rabbit_password,
  # Non-functional parameters
  # TODO(crinkle): remove
  $controller_management_address = undef,
  $ssl_cert_file_contents        = undef, #TODO: make required
) {

  $ssl_cert_path = '/etc/ssl/certs/openstack_infra_ca.pem'

  ### Certificate Chain ###

  class { '::infracloud::cacert':
    cacert_content => $ssl_cert_file_contents,
  }

  ### Networking ###

  class {'::infracloud::veth':
    br_name => $br_name,
  }

  ### Repos ###
  include ::apt

  class { '::openstack_extras::repo::debian::ubuntu':
    release         => 'liberty',
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
    use_ssl            => true,
    cert_file          => $ssl_cert_path,
    key_file           => "/etc/nova/ssl/private/${controller_public_address}.pem",
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

  # Enhance disk I/O
  class { '::nova::compute::libvirt':
    libvirt_disk_cachemodes => ['file=unsafe'],
  }

  ### Neutron ###

  # neutron.conf
  class { '::neutron':
    core_plugin     => 'ml2',
    enabled         => true,
    rabbit_user     => 'neutron',
    rabbit_password => $neutron_rabbit_password,
    rabbit_host     => $controller_public_address,
    rabbit_port     => '5671',
    rabbit_use_ssl  => true,
    use_ssl         => true,
    cert_file       => $ssl_cert_path,
    key_file        => "/etc/neutron/ssl/private/${controller_public_address}.pem",
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
  # Fix to make sure linuxbridge-agent can reach rabbit after moving it
  Neutron_config['oslo_messaging_rabbit/rabbit_hosts'] ~> Service['neutron-plugin-linuxbridge-agent']
}
