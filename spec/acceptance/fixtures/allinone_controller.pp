# All-in-one - controller
# Apply this first
$ssl_key_file_contents = '-----BEGIN RSA PRIVATE KEY-----
MIICXQIBAAKBgQC5DsF0mfSXhXQgAL37zWbhRU4fRYNwvw0hx7LSQx+PvDB+hELd
tm8yipPclhJQnDtwBooiHRhwAexnldIVM7F56PoyUE7B6tSURQHx8ilZEK7fI22A
gEvEfVxGQcFxajhyKalPQeTOuqVt5caEularbV9HcJfsFhT4Wbpg20T4ZQIDAQAB
AoGBALNBQc8qmixzjuq5DU5txmwLcAMGmK2LwrKn9+WIM3hNeEP05bhR0SCJ73RK
we7nhwOasg8dU+CbXF1yWI9FBXFFsBMBXyPGAAr7E4pQvN3h09q1PuA9fPFOU0F1
vZmI25ZDW3vQsd5BjcygmE9USviopbeWHnZd8fAmxIQDW1r5AkEA3Jfm9lpC6Xay
OElx3cEVJdsiY8IYe/7AkR9d1u1uWKdAQa3beiG3T5A3XF0LmLWD0Rz/mpFB5ub+
nWVZp6BSxwJBANbCtDG1b+kdfGHhP6EDOJMgVtLHIwZijfJlxHdhrGfFvFfGrSn/
mfcYixNO8E8+2e1akHC5107RhdnVDZ9I73MCQCL6k00NEv8iKzBxtPSM4WWXUeSv
qmI/Cxn391FVZOH5416Gyv6ayg57t8uVlXkpjzVhe8ZushyDFGyw3X6PFZECQGjW
ydKOaSBa5ZJ+vGokwWSJX/krf3ypdfQEHCHPS7OpAuWytmwPPCE1GQeG/Kci3o4R
LPvqrSHsBLSvXiQJHeMCQQDCFAiGIsrKChS25VXzD8o3/LwJBBAPfMPDhdczERjn
ARTaDO5RKFRmdVysuWnZtmIIcyShybNezWbASmy5nCUg
-----END RSA PRIVATE KEY-----'

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

class { '::infracloud::controller':
  keystone_rabbit_password         => 'XXX',
  neutron_rabbit_password          => 'XXX',
  nova_rabbit_password             => 'XXX',
  root_mysql_password              => 'XXX',
  keystone_mysql_password          => 'XXX',
  glance_mysql_password            => 'XXX',
  neutron_mysql_password           => 'XXX',
  nova_mysql_password              => 'XXX',
  keystone_admin_password          => 'XXX',
  glance_admin_password            => 'XXX',
  neutron_admin_password           => 'XXX',
  nova_admin_password              => 'XXX',
  keystone_admin_token             => 'XXX',
  ssl_key_file_contents            => $ssl_key_file_contents,
  ssl_cert_file_contents           => $ssl_cert_file_contents,
  br_name                          => 'br-vlan2',
  controller_public_address        => 'localhost',
  neutron_subnet_cidr              => '10.1.0.0/24',
  neutron_subnet_gateway           => '10.1.0.1',
  neutron_subnet_allocation_pools  => ['start=10.1.0.16,end=10.1.0.32'],
}
