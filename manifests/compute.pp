#Class infracloud::compute
#
class infracloud::compute(
  $br_name,
  $controller_public_address,
  $neutron_admin_password,
  $neutron_rabbit_password,
  $nova_rabbit_password,
  $ssl_cert_file_contents,
  $ssl_key_file_contents,
  $virt_type = 'kvm',
  $openstack_release = 'mitaka',
) {

  $keystone_auth_uri = "https://${controller_public_address}:5000"
  $keystone_admin_uri = "https://${controller_public_address}:35357"

  include ::infracloud::params
  $ssl_cert_path = "${::infracloud::params::cert_path}/openstack_infra_ca.crt"

  ### Certificate Chain ###

  class { '::infracloud::cacert':
    cacert_content => $ssl_cert_file_contents,
  }

  ### Networking ###

  class {'::infracloud::veth':
    br_name => $br_name,
  }

  ### Repos and selinux ###
  case $::osfamily {
    'Debian': {
      include ::apt

      case $::operatingsystem {
        'Ubuntu': {
          class { '::openstack_extras::repo::debian::ubuntu':
            release         => $openstack_release,
            package_require => true,
          }
        }
        'Debian': {
          class { '::openstack_extras::repo::debian::debian':
            release         => $openstack_release,
            package_require => true,
          }
        }
        default: {
          fail("Unsupported operating system: ${::operatingsystem}")
        }
      }
    }
    'RedHat': {
      class { '::openstack_extras::repo::redhat::redhat':
        release         => $openstack_release,
        package_require => true,
      }
      class { '::selinux':
        mode   => 'permissive',
      }
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} The 'infracloud' module only supports osfamily Debian or RedHat.")
    }
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
  class { '::nova::placement':
    auth_url => $keystone_admin_uri,
    password => $nova_admin_password,
  }

  file { '/etc/nova/ssl':
    ensure  => directory,
    owner   => 'root',
    mode    => '0755',
    require => Class['::nova'],
  }

  file { '/etc/nova/ssl/private':
    ensure  => directory,
    owner   => 'root',
    mode    => '0755',
    require => File['/etc/nova/ssl'],
  }

  infracloud::ssl_key { 'nova':
    key_path    => "/etc/nova/ssl/private/${controller_public_address}.pem",
    key_content => $ssl_key_file_contents,
    require     => File['/etc/nova/ssl/private'],
  }

  # nova-compute service
  class { '::nova::compute':
    force_raw_images => false,
  }

  # nova.conf neutron credentials
  class { '::nova::network::neutron':
    neutron_url      => "https://${controller_public_address}:9696",
    neutron_auth_url => "${keystone_admin_uri}/v3",
    neutron_password => $neutron_admin_password,
  }

  # Libvirt parameters
  class { '::nova::compute::libvirt':
    # Enhance disk I/O
    libvirt_disk_cachemodes => ['file=unsafe'],
    # KVM in prod, qemu in tests
    libvirt_virt_type       => $virt_type,
  }

  # NOTE(pabelanger): This is needed for force_raw_images to work. Otherwise
  # nova will still convert images to raw.
  nova_config {
    'libvirt/images_type': value => 'qcow2';
  }

  ### Neutron ###

  # neutron.conf
  class { '::neutron':
    core_plugin     => 'ml2',
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
}
