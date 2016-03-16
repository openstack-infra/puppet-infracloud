# All-in-one - compute
# Apply this second

#subject=/C=AU/ST=Some-State/O=OpenStack Infra CI/CN=infracloud.local
$ssl_cert_file_contents = '-----BEGIN CERTIFICATE-----
MIICPzCCAagCCQCPiSxWO8GqIDANBgkqhkiG9w0BAQsFADBjMQswCQYDVQQGEwJB
VTETMBEGA1UECAwKU29tZS1TdGF0ZTEkMCIGA1UECgwbT3BlblN0YWNrIEluZnJh
c3RydWN0dXJlIENJMRkwFwYDVQQDDBBpbmZyYWNsb3VkLmxvY2FsMCAXDTE2MDQw
ODA1MjEwOFoYDzIxMTYwMzE1MDUyMTA4WjBjMQswCQYDVQQGEwJBVTETMBEGA1UE
CAwKU29tZS1TdGF0ZTEkMCIGA1UECgwbT3BlblN0YWNrIEluZnJhc3RydWN0dXJl
IENJMRkwFwYDVQQDDBBpbmZyYWNsb3VkLmxvY2FsMIGfMA0GCSqGSIb3DQEBAQUA
A4GNADCBiQKBgQCaqM0NGQuJ2yu86cxymeBBPKSPIV5Jw2qf8F1tVA58gnBTJGC2
6ApJQHurVq1NjLmLK20s/enDeawQQXRlJcgdt0lqOChxfgc4aZFEQ4N17uhY9DQS
YsiT8t00m7MZBrW3Chr6duzDNOCLtvvGo8sG9TZWgoIUqw42IzFscsd8wwIDAQAB
MA0GCSqGSIb3DQEBCwUAA4GBADd8JXYMBx66pQGHdyNrnS/ESA33g9JOmnZy5jv1
AWTAGnhoUoRyudRL8zefjcbTyKOLWDiD6vw2hpXPnffsvQYwdr0BMw8OeEfkVgnB
lFh8RZ1IuB+fZl26h1bddnU1yDvxZy6MeZ9o0xZMqR37yeVEjSWq0bP0E1mNpcZO
dgdQ
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
