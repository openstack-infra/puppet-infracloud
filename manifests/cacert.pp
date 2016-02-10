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

  exec { 'update-ca-certificates':
    command     => '/usr/sbin/update-ca-certificates',
    timeout     => 900, # 15 minutes
    subscribe   => [
        File['/usr/local/share/ca-certificates/openstack_infra_ca.crt'],
      ],
    refreshonly => true,
    require     => [
        File['/usr/local/share/ca-certificates/openstack_infra_ca.crt'],
      ],
  }
}
