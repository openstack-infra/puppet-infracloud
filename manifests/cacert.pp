# adds infra cloud chain to trusted certs
class infracloud::cacert (
  $cacert_content,
) {
  file { '/usr/local/share/ca-certificates/openstack_infra_ca.crt':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content =>  $cacert_content,
    replace => true,
  }

  case $::osfamily {
    'Debian': {
      exec { 'update-ca-certificates':
        command     => '/usr/sbin/update-ca-certificates',
        subscribe   => [
          File['/usr/local/share/ca-certificates/openstack_infra_ca.crt'],
        ],
        refreshonly => true,
      }
    }
    'Redhat': {
      # first copy cert to shared path
      file { '/etc/pki/ca-trust/source/anchors/openstack_infra_ca.crt':
        ensure  => present,
        source  => '/usr/local/share/ca-certificates/openstack_infra_ca.crt',
        require => File['/usr/local/share/ca-certificates/openstack_infra_ca.crt'],
      }

      exec { 'update-ca-certificates':
        command     => '/usr/bin/update-ca-trust',
        subscribe   => [
          File['/usr/local/share/ca-certificates/openstack_infra_ca.crt'],
        ],
        require     => File['/etc/pki/ca-trust/source/anchors/openstack_infra_ca.crt'],
        refreshonly => true,
      }
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily}. Only RedHat and Debian families are supported")
    }
  }
}
