# common parameters to be reused in infracloud
class infracloud::params {
  case $::osfamily {
    'Debian': {
      $cert_path = '/usr/local/share/ca-certificates'
      $cert_command = '/usr/sbin/update-ca-certificates'
      $bifrost_req_packages = [ 'gcc', 'libssl-dev', 'uuid-runtime' ]
    }
    'Redhat': {
      $cert_path = '/etc/pki/ca-trust/source/anchors'
      $cert_command = '/usr/bin/update-ca-trust'
      $bifrost_req_packages = [ 'gcc', 'openssl-devel', 'libselinux-python' ]
    }
    default: {
        fail('Only Debian and RedHat distros are supported.')
    }
  }
}
