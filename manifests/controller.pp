# class: OpenStack Infra Cloud
class infracloud::controller(
  # TODO (yolanda): Set this to mandatory. But needs to be optional for tests to pass now
  $keystone_rabbit_password = 'dummy_pass',
  $neutron_rabbit_password,
  $nova_rabbit_password,
  $root_mysql_password,
  $keystone_mysql_password,
  $glance_mysql_password,
  $neutron_mysql_password,
  $nova_mysql_password,
  $glance_admin_password,
  $keystone_admin_password,
  $neutron_admin_password,
  $nova_admin_password,
  $keystone_admin_token,
  $br_name,
  $controller_public_address = $::fqdn,
  $ssl_key_file_contents = undef, # TODO(crinkle): make required
  $ssl_cert_file_contents = undef, # TODO(crinkle): make required
  # Non-functional parameters
  # TODO(crinkle): remove
  $ssl_chain_file_contents = undef,
  $keystone_ssl_key_file_contents = undef,
  $keystone_ssl_cert_file_contents = undef,
  $neutron_ssl_key_file_contents = undef,
  $neutron_ssl_cert_file_contents = undef,
  $glance_ssl_key_file_contents = undef,
  $glance_ssl_cert_file_contents = undef,
  $nova_ssl_key_file_contents = undef,
  $nova_ssl_cert_file_contents = undef,
) {

  $keystone_auth_uri = "https://${controller_public_address}:5000"
  $keystone_admin_uri = "https://${controller_public_address}:35357"
  $ssl_cert_path = '/etc/ssl/certs/openstack_infra_ca.pem'

  ### Certificate Chain ###

  class { '::infracloud::cacert':
    cacert_content => $ssl_cert_file_contents,
  }

  ### Networking ###

  class { '::infracloud::veth':
    br_name => $br_name,
  }

  ### Repos ###

  include ::apt

  class { '::openstack_extras::repo::debian::ubuntu':
    release         => 'kilo',
    package_require => true,
  }

  ### Database ###

  class { '::mysql::server':
    root_password    => $root_mysql_password,
    override_options => {
      'mysqld' => {
        'max_connections' => '1024',
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
    key_content  => $ssl_key_file_contents,
    key_path     => "/etc/rabbitmq/ssl/private/${controller_public_address}.pem",
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
    service_name        => 'httpd',
    enable_ssl          => true,
    admin_bind_host     => $controller_public_address,
    rabbit_userid       => 'keystone',
    rabbit_password     => $keystone_rabbit_password,
    rabbit_host         => $controller_public_address,
    rabbit_port         => '5671',
    rabbit_use_ssl      => true,
    # Hack to work around a bug in the puppet module
    # https://review.openstack.org/#/c/280462/
    kombu_ssl_ca_certs  => [],
    kombu_ssl_certfile  => [],
    kombu_ssl_keyfile   => [],
  }

  # keystone admin user, projects
  class { '::keystone::roles::admin':
    email    => 'postmaster@no.test',
    password => $keystone_admin_password,
  }

  # keystone auth endpoints
  class { '::keystone::endpoint':
    public_url => $keystone_auth_uri,
    admin_url  => $keystone_admin_uri,
  }

  # apache server
  include ::apache

  $keystone_ssl_key_path = "/etc/ssl/private/${controller_public_address}-keystone.pem"

  # keystone vhost
  class { '::keystone::wsgi::apache':
    ssl_key   => $keystone_ssl_key_path,
    ssl_cert  => $ssl_cert_path,
    subscribe => Class['::infracloud::cacert'],
  }

  infracloud::ssl_key { 'keystone':
    key_content => $ssl_key_file_contents,
    key_path    => $keystone_ssl_key_path,
    notify      => Service['httpd'],
  }

  ### Glance ###

  $glance_database_connection = "mysql://glance:${glance_mysql_password}@127.0.0.1/glance"

  class { '::glance::db::mysql':
    password => $glance_mysql_password,
  }

  # glance-api.conf
  class { '::glance::api':
    database_connection => $glance_database_connection,
    keystone_password   => $glance_admin_password,
    auth_uri            => $keystone_auth_uri,
    identity_uri        => $keystone_admin_uri,
    cert_file           => $ssl_cert_path,
    key_file            => "/etc/glance/ssl/private/${controller_public_address}.pem",
    subscribe           => Class['::infracloud::cacert'],
  }

  infracloud::ssl_key { 'glance':
    key_content => $ssl_key_file_contents,
    notify      => Service['glance-api'],
  }

  # glance-registry.conf
  class { '::glance::registry':
    database_connection => $glance_database_connection,
    keystone_password   => $glance_admin_password,
    auth_uri            => $keystone_auth_uri,
    identity_uri        => $keystone_admin_uri,
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
    enabled         => true,
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
    auth_password       => $neutron_admin_password,
    database_connection => "mysql://neutron:${neutron_mysql_password}@127.0.0.1/neutron?charset=utf8",
    sync_db             => true,
    auth_uri            => $keystone_auth_uri,
    identity_uri        => $keystone_admin_uri,
  }

  # neutron client package
  class { '::neutron::client': }

  # neutron.conf nova credentials
  class { '::neutron::server::notifications':
    nova_url               => "https://${controller_public_address}:8774/v2",
    nova_admin_auth_url    => "${keystone_admin_uri}/v2.0",
    nova_admin_username    => 'nova',
    nova_admin_password    => $nova_admin_password,
    nova_admin_tenant_name => 'services',
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
  # Fix for https://bugs.launchpad.net/ubuntu/+source/neutron/+bug/1453188
  file { '/usr/bin/neutron-plugin-linuxbridge-agent':
    ensure => link,
    target => '/usr/bin/neutron-linuxbridge-agent',
    before => Package['neutron-plugin-linuxbridge-agent'],
  }

  # DHCP
  class { '::neutron::agents::dhcp':
    interface_driver       => 'neutron.agent.linux.interface.BridgeInterfaceDriver',
    dhcp_delete_namespaces => true,
  }

  # Provider network
  neutron_network { 'public':
    shared                    => true,
    provider_network_type     => 'flat',
    provider_physical_network => 'provider',
  }

  # Provider subnet with three allication pools representing three "subnets"
  neutron_subnet { 'provider-subnet-53-54-55':
    cidr             => '15.184.52.0/22',
    gateway_ip       => '15.184.52.1',
    network_name     => 'public',
    dns_nameservers  => ['8.8.8.8'],
    allocation_pools => [
                          'start=15.184.53.2,end=15.184.53.254',
                          'start=15.184.54.2,end=15.184.54.254',
                          'start=15.184.55.2,end=15.184.55.254'
                        ],
  }

  ### Nova ###

  class { '::nova::db::mysql':
    password => $nova_mysql_password,
    host     => '127.0.0.1',
  }

  infracloud::rabbitmq_user { 'nova':
    password => $nova_rabbit_password,
  }

  # nova.conf - general
  class { '::nova':
    database_connection => "mysql://nova:${nova_mysql_password}@127.0.0.1/nova?charset=utf8",
    rabbit_userid       => 'nova',
    rabbit_password     => $nova_rabbit_password,
    rabbit_host         => $controller_public_address,
    rabbit_port         => '5671',
    rabbit_use_ssl      => true,
    glance_api_servers  => "https://${controller_public_address}:9292",
    use_ssl             => true,
    cert_file           => $ssl_cert_path,
    key_file            => "/etc/nova/ssl/private/${controller_public_address}.pem",
    subscribe           => Class['::infracloud::cacert'],
  }
  infracloud::ssl_key { 'nova':
    key_content => $ssl_key_file_contents,
    notify      => Service['nova-api'],
    require     => Class['::nova'],
  }

  # keystone user, role, service, endpoints for nova service
  class { '::nova::keystone::auth':
    password               => $nova_admin_password,
    public_url             => "https://${controller_public_address}:8774/v2/%(tenant_id)s",
    admin_url              => "https://${controller_public_address}:8774/v2/%(tenant_id)s",
    configure_ec2_endpoint => false,
    configure_endpoint_v3  => false,
  }

  # nova.conf neutron credentials
  class { '::nova::network::neutron':
    neutron_admin_password => $neutron_admin_password,
    neutron_url            => "https://${controller_public_address}:9696",
  }

  # api service and endpoint-related params in nova.conf
  class { '::nova::api':
    enabled        => true,
    enabled_apis   => 'osapi_compute',
    admin_password => $nova_admin_password,
    auth_uri       => $keystone_auth_uri,
    identity_uri   => $keystone_admin_uri,
    osapi_v3       => false,
  }

  # conductor service
  class { '::nova::conductor':
    enabled => true,
  }

  # scheduler service
  class { '::nova::scheduler':
    enabled => true,
  }
}
