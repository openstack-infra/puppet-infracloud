# Class: OpenStack Infra Logs
#
class infracloud::logs(
  $docroot    = '/var/www/logs',
  $port       = '80',
  $vhost_name = $::fqdn,
) {
  include ::apache

  file { $docroot:
    ensure  => directory,
    require => Class['::apache'],
  }

  # Allow everybody to read neutron logs.
  file { '/var/log/neutron':
    ensure  => directory,
    group   => adm,
    mode    => '0644',
    owner   => neutron,
    require => Class['::neutron'],
  }

  file { "${docroot}/neutron":
    ensure  => link,
    target  => '/var/log/neutron',
    group   => root,
    owner   => root,
    require => [
      File[$docroot],
      File['/var/log/neutron'],
    ],
  }

  ::apache::vhost::custom { $vhost_name:
    ensure  => present,
    content => template('infracloud/logs.vhost.erb'),
  }

  # Temporary workaround until https://github.com/puppetlabs/puppetlabs-apache/pull/1388 is merged and released
  if $::apache::mod_enable_dir != undef {
    File[$::apache::mod_enable_dir] -> Exec["syntax verification for ${vhost_name}"]
  }
}
