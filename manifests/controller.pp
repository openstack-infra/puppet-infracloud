# Class: OpenStack Infra Cloud
#
class infracloud::controller(
  $br_name,
  $glance_admin_password,
  $glance_mysql_password,
  $keystone_admin_password,
  $keystone_admin_token,
  $keystone_mysql_password,
  $keystone_rabbit_password,
  $neutron_admin_password,
  $neutron_mysql_password,
  $neutron_rabbit_password,
  $neutron_subnet_allocation_pools,
  $neutron_subnet_cidr,
  $neutron_subnet_gateway,
  $nova_admin_password,
  $nova_mysql_password,
  $nova_rabbit_password,
  $root_mysql_password,
  $ssl_key_file_contents,
  $ssl_cert_file_contents,
  $controller_public_address = $::fqdn,
  $mysql_max_connections = 1024,
  $openstack_release = 'ocata',
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

  class { '::infracloud::veth':
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

      package { 'erlang':
        ensure => present,
        before => Class['::rabbitmq'],
      }

      class { '::selinux':
        mode   => 'permissive',
      }
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} The 'infracloud' module only supports osfamily Debian or RedHat.")
    }
  }

  ### Database ###

  class { '::mysql::server':
    root_password    => $root_mysql_password,
    restart          => true,
    override_options => {
      'mysqld' => {
        'max_connections' => $mysql_max_connections,
      }
    }
  }

  ### Messaging ###

  file { '/etc/rabbitmq/ssl/private':
    ensure => directory,
    owner  => 'root',
    mode   => '0755',
  }

  infracloud::ssl_key { 'rabbitmq':
    key_content => $ssl_key_file_contents,
    key_path    => "/etc/rabbitmq/ssl/private/${controller_public_address}.pem",
    require     => Package['rabbitmq-server'],
  }

  class { '::rabbitmq':
    delete_guest_user     => true,
    environment_variables => {
      'RABBITMQ_NODE_IP_ADDRESS' => '127.0.0.1',
    },
    ssl                   => true,
    ssl_only              => true,
    ssl_cacert            => $ssl_cert_path,
    ssl_cert              => $ssl_cert_path,
    ssl_key               => "/etc/rabbitmq/ssl/private/${controller_public_address}.pem",
    require               => File[$ssl_cert_path],
  }

  ### Keystone ###

  class { '::keystone::db::mysql':
    password => $keystone_mysql_password,
  }

  infracloud::rabbitmq_user { 'keystone':
    password => $keystone_rabbit_password,
  }

  # keystone.conf
  class { '::keystone':
    database_connection => "mysql://keystone:${keystone_mysql_password}@127.0.0.1/keystone",
    catalog_type        => 'sql',
    admin_token         => $keystone_admin_token,
    admin_password      => $keystone_admin_password,
    service_name        => 'httpd',
    enable_ssl          => true,
    admin_bind_host     => $controller_public_address,
    rabbit_userid       => 'keystone',
    rabbit_password     => $keystone_rabbit_password,
    rabbit_host         => $controller_public_address,
    rabbit_port         => '5671',
    rabbit_use_ssl      => true,
  }

  # keystone admin user, projects
  class { '::keystone::roles::admin':
    email    => 'postmaster@example.com',
    password => $keystone_admin_password,
  }

  # keystone auth endpoints
  class { '::keystone::endpoint':
    default_domain => 'Default',
    public_url     => $keystone_auth_uri,
    admin_url      => $keystone_admin_uri,
  }

  # apache server
  include ::apache

  file { '/etc/ssl/private':
    ensure => directory,
    owner  => 'root',
    mode   => '0710',
  }

  $keystone_ssl_key_path = "/etc/ssl/private/${controller_public_address}-keystone.pem"

  # keystone vhost
  class { '::keystone::wsgi::apache':
    ssl_key   => $keystone_ssl_key_path,
    ssl_cert  => $ssl_cert_path,
    subscribe => Class['::infracloud::cacert'],
    require   => File['/etc/ssl/private'],
  }

  infracloud::ssl_key { 'keystone':
    key_content => $ssl_key_file_contents,
    key_path    => $keystone_ssl_key_path,
    notify      => Service['httpd'],
    require     => [ Package['keystone'], File['/etc/ssl/private'] ],
  }

  ### Glance ###

  $glance_database_connection = "mysql://glance:${glance_mysql_password}@127.0.0.1/glance"

  class { '::glance::db::mysql':
    password => $glance_mysql_password,
  }

  class { '::glance::api::authtoken':
    password            => $glance_admin_password,
    project_domain_name => 'Default',
    user_domain_name    => 'Default',
    auth_uri            => $keystone_auth_uri,
    auth_url            => $keystone_admin_uri,
  }

  # glance-api.conf
  class { '::glance::api':
    database_connection => $glance_database_connection,
    cert_file           => $ssl_cert_path,
    enable_v1_api       => false,
    enable_v2_api       => true,
    default_store       => ['file'],
    stores              => ['file'],
    key_file            => "/etc/glance/ssl/private/${controller_public_address}.pem",
    subscribe           => Class['::infracloud::cacert'],
  }

  infracloud::ssl_key { 'glance':
    key_content => $ssl_key_file_contents,
    notify      => Service[$::glance::params::api_service_name],
    require     => Package[$::glance::params::api_package_name],
  }

  # set filesystem_store_datadir to /var/lib/glance/images in glance-api.conf
  # and glance-registry.conf
  class { '::glance::backend::file': }

  # keystone user, role, service, endpoints for glance service
  class { '::glance::keystone::auth':
    password   => $glance_admin_password,
    public_url => "https://${controller_public_address}:9292",
    admin_url  => "https://${controller_public_address}:9292",
  }

  ### Neutron server ###
  sysctl::value { 'net.ipv4.conf.default.rp_filter':
    value => 0
  }
  sysctl::value { 'net.ipv4.conf.all.rp_filter':
    value => 0
  }

  class { '::neutron::db::mysql':
    password => $neutron_mysql_password,
  }

  infracloud::rabbitmq_user { 'neutron':
    password => $neutron_rabbit_password,
  }

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
    subscribe       => Class['::infracloud::cacert'],
  }

  class { '::neutron::keystone::authtoken':
    password            => $neutron_admin_password,
    project_domain_name => 'Default',
    user_domain_name    => 'Default',
    auth_uri            => $keystone_auth_uri,
    auth_url            => $keystone_admin_uri,
  }

  infracloud::ssl_key { 'neutron':
    key_content => $ssl_key_file_contents,
    notify      => Service['neutron-server'],
    require     => Package['neutron'],
  }

  # keystone user, role, service, endpoints for neutron service
  class { '::neutron::keystone::auth':
    password   => $neutron_admin_password,
    public_url => "https://${controller_public_address}:9696/",
    admin_url  => "https://${controller_public_address}:9696/",
  }

  # neutron-server service and related neutron.conf and api-paste.conf params
  class { '::neutron::server':
    password            => $neutron_admin_password,
    database_connection => "mysql://neutron:${neutron_mysql_password}@127.0.0.1/neutron?charset=utf8",
    sync_db             => true,
  }

  # neutron client package
  class { '::neutron::client': }

  # neutron.conf nova credentials
  class { '::neutron::server::notifications':
    auth_url => $keystone_admin_uri,
    password => $nova_admin_password,
  }

  # ML2
  class { '::neutron::plugins::ml2':
    type_drivers          => ['flat', 'vlan'],
    tenant_network_types  => [],
    mechanism_drivers     => ['linuxbridge'],
    flat_networks         => ['provider'],
    network_vlan_ranges   => ['provider'],
    enable_security_group => true,
  }
  class { '::neutron::agents::ml2::linuxbridge':
    physical_interface_mappings => ['provider:veth2'],
    require                     => Class['infracloud::veth'],
  }

  class { '::neutron::agents::dhcp':
    interface_driver => 'linuxbridge',
  }

  # Provider network
  neutron_network { 'public':
    shared                    => true,
    provider_network_type     => 'flat',
    provider_physical_network => 'provider',
  }

  # Provider subnet with three allication pools representing three "subnets"
  neutron_subnet { 'provider-subnet-infracloud':
    cidr             => $neutron_subnet_cidr,
    gateway_ip       => $neutron_subnet_gateway,
    network_name     => 'public',
    dns_nameservers  => ['8.8.8.8', ],
    allocation_pools => $neutron_subnet_allocation_pools,
  }

  ### Nova ###

  class { '::nova::db':
    database_connection           => "mysql://nova:${nova_mysql_password}@127.0.0.1/nova?charset=utf8",
    api_database_connection       => "mysql://nova_api:${nova_mysql_password}@127.0.0.1/nova_api?charset=utf8",
    placement_database_connection => "mysql://nova_placement:${nova_mysql_password}@127.0.0.1/nova_placement?charset=utf8",
  }
  class { '::nova::db::mysql':
    password => $nova_mysql_password,
    host     => '127.0.0.1',
  }
  class { '::nova::db::mysql_api':
    password => $nova_mysql_password,
    host     => '127.0.0.1',
  }
  class { '::nova::db::mysql_placement':
    password => $nova_mysql_password,
    host     => '127.0.0.1',
  }
  include ::nova::cell_v2::simple_setup

  infracloud::rabbitmq_user { 'nova':
    password => $nova_rabbit_password,
  }

  # nova.conf - general
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
    subscribe          => Class['::infracloud::cacert'],
  }
  infracloud::ssl_key { 'nova':
    key_content => $ssl_key_file_contents,
    notify      => Service['nova-api'],
    require     => Class['::nova'],
  }

  # keystone user, role, service, endpoints for nova service
  class { '::nova::keystone::auth':
    password   => $nova_admin_password,
    public_url => "https://${controller_public_address}:8774/v2.1",
    admin_url  => "https://${controller_public_address}:8774/v2.1",
  }
  class { '::nova::keystone::authtoken':
    password            => $nova_admin_password,
    project_domain_name => 'Default',
    user_domain_name    => 'Default',
    auth_uri            => $keystone_auth_uri,
    auth_url            => $keystone_admin_uri,
  }
  class { '::nova::keystone::auth_placement':
    password   => $nova_admin_password,
    public_url => "https://${controller_public_address}:8778/placement",
    admin_url  => "https://${controller_public_address}:8778/placement",
  }

  # nova.conf neutron credentials
  class { '::nova::network::neutron':
    neutron_auth_url => "${keystone_admin_uri}/v3",
    neutron_password => $neutron_admin_password,
    neutron_url      => "https://${controller_public_address}:9696",
  }

  # api service and endpoint-related params in nova.conf
  class { '::nova::api':
    enabled_apis   => 'osapi_compute',
    admin_password => $nova_admin_password,
    auth_uri       => $keystone_auth_uri,
    identity_uri   => $keystone_admin_uri,
  }
  class { '::nova::wsgi::apache_placement':
    api_port => '8778',
    ssl_key  => "/etc/nova/ssl/private/${controller_public_address}.pem",
    ssl_cert => $ssl_cert_path,
    ssl      => true,
  }
  class { '::nova::placement':
    auth_url => $keystone_admin_uri,
    password => $nova_admin_password,
  }

  # conductor service
  include ::nova::conductor

  # scheduler service
  include ::nova::scheduler

  ### Logging ###
  include ::infracloud::logs
}
