# adds infra cloud chain to trusted certs
class infracloud::cacert (
  $cacert_content,
) {
  case $::osfamily {
    'Debian': {
      file { '/usr/local/share/ca-certificates':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
      }

      file { '/usr/local/share/ca-certificates/openstack_infra_ca.crt':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content =>  $cacert_content,
        replace => true,
        require => File['/usr/local/share/ca-certificates'],
      }

      exec { 'update-ca-certificates':
        command     => '/usr/sbin/update-ca-certificates',
        subscribe   => [
          File['/usr/local/share/ca-certificates/openstack_infra_ca.crt'],
        ],
        refreshonly => true,
      }
    }
    'Redhat': {
      file { '/etc/pki/ca-trust/source/anchors':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
      }

      file { '/etc/pki/ca-trust/source/anchors/openstack_infra_ca.crt':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content =>  $cacert_content,
        replace => true,
        require => File['/etc/pki/ca-trust/source/anchors'],
      }

      exec { 'update-ca-certificates':
        command     => '/usr/bin/update-ca-trust',
        subscribe   => [
          File['/etc/pki/ca-trust/source/anchors/openstack_infra_ca.crt'],
        ],
        refreshonly => true,
      }
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily}. Only RedHat and Debian families are supported")
    }
  }
}
