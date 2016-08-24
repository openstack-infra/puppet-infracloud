# adds infra cloud chain to trusted certs
class infracloud::cacert (
  $cacert_content,
) {
  include ::infracloud::params

  file { $::infracloud::params::ssl_cert_path:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { "${::infracloud::params::cert_path}/openstack_infra_ca.crt":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content =>  $cacert_content,
    replace => true,
    require => File[$::infracloud::params::cert_path],
  }

  exec { 'update-ca-certificates':
    command     => $::infracloud::params::cert_command,
    subscribe   => [
        File["${::infracloud::params::cert_path}/openstack_infra_ca.crt"],
      ],
      refreshonly => true,
    }
  }
}
