# All-in-one - compute
# Apply this second

#subject=/C=AU/ST=Some-State/O=OpenStack Infra CI/CN=localhost
$ssl_cert_file_contents = '-----BEGIN CERTIFICATE-----
MIICHTCCAYYCCQCCJzpgbep0ETANBgkqhkiG9w0BAQsFADBTMQswCQYDVQQGEwJB
VTETMBEGA1UECAwKU29tZS1TdGF0ZTEbMBkGA1UECgwST3BlblN0YWNrIEluZnJh
IENJMRIwEAYDVQQDDAlsb2NhbGhvc3QwHhcNMTYwMzA1MDAzMDE0WhcNMTYwNDA0
MDAzMDE0WjBTMQswCQYDVQQGEwJBVTETMBEGA1UECAwKU29tZS1TdGF0ZTEbMBkG
A1UECgwST3BlblN0YWNrIEluZnJhIENJMRIwEAYDVQQDDAlsb2NhbGhvc3QwgZ8w
DQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBALkOwXSZ9JeFdCAAvfvNZuFFTh9Fg3C/
DSHHstJDH4+8MH6EQt22bzKKk9yWElCcO3AGiiIdGHAB7GeV0hUzsXno+jJQTsHq
1JRFAfHyKVkQrt8jbYCAS8R9XEZBwXFqOHIpqU9B5M66pW3lxoS6VqttX0dwl+wW
FPhZumDbRPhlAgMBAAEwDQYJKoZIhvcNAQELBQADgYEAb1f28SqP+7QthNaFK2xM
QSSLosX1+owi0cjr9aPJ531BGA731dIJICZIqK78tY0hJMHpxA8Z4MT5xVFL74dc
tnoG66rwcEkvLhIFjiEUBUH9wJb0dZQXwNKTT35l+dNf5+zKDeEt1fhuf+BilGZs
PIXfKa+9plmqSayN5ums36I=
-----END CERTIFICATE-----'

class { '::infracloud::compute':
  nova_rabbit_password          => 'XXX',
  neutron_rabbit_password       => 'XXX',
  neutron_admin_password        => 'XXX',
  ssl_cert_file_contents        => $ssl_cert_file_contents,
  br_name                       => 'br-vlan2',
  controller_public_address     => 'localhost',
  virt_type                     => 'qemu',
}
