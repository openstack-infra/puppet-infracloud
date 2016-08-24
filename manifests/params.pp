# common parameters to be reused in infracloud
class infracloud::params {
  case $::osfamily {
    'Debian': {
      $cert_path = '/usr/local/share/ca-certificates'
      $cert_command = '/usr/bin/update-ca-certificates'
    }
    'Redhat': {
      $cert_path = '/etc/pki/ca-trust/source/anchors'
      $cert_command = '/usr/bin/update-ca-trust'
  }
}
