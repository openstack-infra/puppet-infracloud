# All-in-one - compute
# Apply this second

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

class { '::infracloud::compute':
  nova_rabbit_password          => 'XXX',
  neutron_rabbit_password       => 'XXX',
  neutron_admin_password        => 'XXX',
  ssl_cert_file_contents        => $ssl_cert_file_contents,
  br_name                       => 'br-vlan2',
  controller_public_address     => 'infracloud.local',
  virt_type                     => 'qemu',
}
