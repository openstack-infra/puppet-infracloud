# All-in-one - controller
# Apply this first
$ssl_key_file_contents = '-----BEGIN RSA PRIVATE KEY-----
MIICXQIBAAKBgQCaqM0NGQuJ2yu86cxymeBBPKSPIV5Jw2qf8F1tVA58gnBTJGC2
6ApJQHurVq1NjLmLK20s/enDeawQQXRlJcgdt0lqOChxfgc4aZFEQ4N17uhY9DQS
YsiT8t00m7MZBrW3Chr6duzDNOCLtvvGo8sG9TZWgoIUqw42IzFscsd8wwIDAQAB
AoGBAJTIhRLvoBkLvsTrSmKJQ6Keu1RybmmZ1A5vRwGxFoqTVYm2elAbZCHaJd7L
8Mak9a47pbjdwC/r8iplPZs8wIjO/QtuBPZH/5k1i73xIiegJki99Ay2js0I/vww
XJvE4tLLhEMfbdTVyy+XQv/RassduM7kQbD+01pMcLB8K8jhAkEAx3c49YUqd77Z
zK/qBnwe2k8EQxCRjtijFwswMTgV3HOtmCzpzqc2KMNjJMX4bCPCZa5N2QCKJRT5
rYB7eT9bkQJBAMZ+iHNK8NuNBeY0Tkbaxw37EyF45F4e8DSs52PtgTQyEHffzVge
SxhBLWKQ/bPr3wjqSEkG7SEr0idR+sTmIRMCQQCbyy8d9Wj6JoMPMMdlUUT31ofJ
qgNGw0Z/FSoLB3drvJ52IX5s/oV6yUGC0235aOTJbp83QwijdgKd1aCbTzVBAkB3
xLGgn39lelos5TK2Hhwtm2mXsNJa2GAn6IxWB2EGlY7KRggpO14kbG9uIf5zKceS
IYssRTmf4kkT4KtnU1RxAkAjmtNISSzC4Sfx/55TuVIyt6taSQsSi89rSUjnbecI
Yq3byURu0cpBG6pCi+6gwP7s8VDyAYZF17/JjN1SJig0
-----END RSA PRIVATE KEY-----'

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
