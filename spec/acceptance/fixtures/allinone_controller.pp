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

#subject=/C=AU/ST=Some-State/O=OpenStack Infra CI/CN=infracloud.local
$ssl_cert_file_contents = '-----BEGIN CERTIFICATE-----
MIICPTCCAaYCCQDuKIXOrdO/WTANBgkqhkiG9w0BAQsFADBjMQswCQYDVQQGEwJB
VTETMBEGA1UECAwKU29tZS1TdGF0ZTEkMCIGA1UECgwbT3BlblN0YWNrIEluZnJh
c3RydWN0dXJlIENJMRkwFwYDVQQDDBBpbmZyYWNsb3VkLmxvY2FsMB4XDTE2MDMw
ODA0NDg0NVoXDTE2MDQwNzA0NDg0NVowYzELMAkGA1UEBhMCQVUxEzARBgNVBAgM
ClNvbWUtU3RhdGUxJDAiBgNVBAoMG09wZW5TdGFjayBJbmZyYXN0cnVjdHVyZSBD
STEZMBcGA1UEAwwQaW5mcmFjbG91ZC5sb2NhbDCBnzANBgkqhkiG9w0BAQEFAAOB
jQAwgYkCgYEAuQ7BdJn0l4V0IAC9+81m4UVOH0WDcL8NIcey0kMfj7wwfoRC3bZv
MoqT3JYSUJw7cAaKIh0YcAHsZ5XSFTOxeej6MlBOwerUlEUB8fIpWRCu3yNtgIBL
xH1cRkHBcWo4cimpT0HkzrqlbeXGhLpWq21fR3CX7BYU+Fm6YNtE+GUCAwEAATAN
BgkqhkiG9w0BAQsFAAOBgQBTxjRBlOqXPKXL/WGGLeM4nWcbj+c/3ebHbQB/dPEC
NyH66SFu5Ncsu2y/Ufz2GgFUrnayNsjWEXCGLp+iGztnNZSZ1A+huGNUrwcTojf3
/KXYEu5gjSqfM3EjoLn7I0bqHPM1H60AMezv2gqkn5CSLt2pjKiNd1BrPnKfaRTk
Cw==
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
  controller_public_address        => 'infracloud.local',
  neutron_subnet_cidr              => '10.1.0.0/24',
  neutron_subnet_gateway           => '10.1.0.1',
  neutron_subnet_allocation_pools  => ['start=10.1.0.16,end=10.1.0.32'],
}
