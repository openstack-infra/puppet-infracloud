# class: OpenStack Infra Logs
class infracloud::logs(
  $port = '80',
  $vhost_name = $::fqdn,
  $docroot = '/var/www/logs',
) {

  file { $docroot:
    ensure  => directory,
    require => Class['::apache'],
  }

  file { "${docroot}/nova":
    ensure  => link,
    target  => '/var/log/nova',
    group   => root,
    owner   => root,
    require => File[$docroot],
  }

  ::apache::vhost::custom { $vhost_name,
    ensure  => present,
    content => template("infracloud/logs.vhost.erb"),
  }
}
