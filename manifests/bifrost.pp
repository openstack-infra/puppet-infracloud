# Copyright 2014 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
class infracloud::bifrost (
  $ironic_inventory,
  $ironic_db_password,
  $mysql_password,
  $region,
  $ipmi_passwords,
  $ssh_public_key,
  $ssh_private_key,
) {

  # The configdrive bifrost task defaults to copying the user's local public
  # ssh key. Let's make sure it's there so that bifrost doesn't error and so we
  # can log in to nodes from the baremetal host.
  file { '/root/.ssh/id_rsa':
    ensure  => present,
    mode    => '0600',
    content => $ssh_private_key,
    before  => Exec['install bifrost'],
  }

  file { '/root/.ssh/id_rsa.pub':
    ensure  => present,
    mode    => '0644',
    content => $ssh_public_key,
    before  => Exec['install bifrost'],
  }

  include ::ansible

  class { '::mysql::server':
    root_password => $mysql_password,
  }

  vcsrepo { '/opt/stack/bifrost':
    ensure   => 'latest',
    provider => 'git',
    revision => 'master',
    source   => 'https://git.openstack.org/openstack/bifrost',
  }

  file { '/etc/bifrost':
    ensure => directory,
  }

  file { '/etc/bifrost/bifrost_global_vars':
    ensure  => present,
    content => template("infracloud/bifrost/bifrost_global_vars.${region}.erb"),
  }

  file { '/opt/stack/baremetal.json':
    ensure  => file,
    content => template("infracloud/bifrost/inventory.${region}.json.erb"),
    require => Vcsrepo['/opt/stack/bifrost'],
  }

  package { 'uuid-runtime':
    ensure => installed
  }

  exec { 'install bifrost dependencies':
    command     => 'pip install -U -r /opt/stack/bifrost/requirements.txt',
    path        => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/stack/bifrost'],
  }

  file { '/opt/stack/elements':
    ensure  => directory,
    recurse => true,
    source  => 'puppet:///modules/infracloud/elements',
    require => Vcsrepo['/opt/stack/bifrost'],
    before  => Exec['install bifrost'],
  }

  vcsrepo { '/opt/project-config':
    ensure   => 'latest',
    provider => 'git',
    revision => 'master',
    source   => 'https://git.openstack.org/openstack-infra/project-config',
  }

  exec { 'install bifrost':
    environment => ['BIFROST_INVENTORY_SOURCE=/opt/stack/baremetal.json', 'HOME=/root'],
    command     => "ansible-playbook -e @/etc/bifrost/bifrost_global_vars -vvvv \
                     -i /opt/stack/bifrost/playbooks/inventory/bifrost_inventory.py \
                     /opt/stack/bifrost/playbooks/install.yaml \
                     && touch /var/run/bifrost_install_succeeded",
    path        => '/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin',
    creates     => '/var/run/bifrost_install_succeeded',
    timeout     => 1500,
    require     => [
      Exec['install bifrost dependencies'],
      File['/etc/bifrost/bifrost_global_vars'],
      Vcsrepo['/opt/stack/bifrost'],
      Vcsrepo['/opt/project-config'],
      Package['uuid-runtime'],
      Class['::mysql::server'],
    ],
  }

  # This is a temporary workaround while we work on getting glean and
  # networking init scripts working. dnsmasq was already started by bifrost,
  # but we need a second one in order to make our infra-cloud-networking
  # element work properly. Set up an alternate config file and static dhcp host
  # files, and manage the second dnsmasq as if it was a service.

  file { '/etc/dnsmasq.conf.vlan25':
    ensure  => present,
    source  => 'puppet:///modules/infracloud/dnsmasq.conf.vlan25',
    mode    => '0644',
    require => Exec['install bifrost'],
    notify  => Service['dnsmasq-vlan25'],
  }

  file { '/opt/stack/custom_playbooks':
    ensure  => directory,
    require => Exec['install bifrost'],
  }

  file { '/opt/stack/custom_playbooks/templates':
    ensure => directory,
  }

  file { '/opt/stack/custom_playbooks/deploy-public-dnsmasq.yaml':
    ensure => present,
    source => 'puppet:///modules/infracloud/deploy-public-dnsmasq.yaml'
  }

  file { '/opt/stack/custom_playbooks/templates/dhcp-host.j2':
    ensure => present,
    source => 'puppet:///modules/infracloud/dhcp-host.j2',
  }

  file { '/etc/dnsmasq.d/bifrost.dhcp-hosts.vlan25.d':
    ensure  => directory,
    require => Exec['install bifrost'],
  }

  exec { 'set up static dhcp hosts':
    environment => ['BIFROST_INVENTORY_SOURCE=/opt/stack/baremetal.json', 'HOME=/root'],
    command     => "ansible-playbook -e @/etc/bifrost/bifrost_global_vars -vvvv \
                     -i /opt/stack/bifrost/playbooks/inventory/bifrost_inventory.py \
                     /opt/stack/custom_playbooks/deploy-public-dnsmasq.yaml",
    path        => '/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin',
    unless      => 'test "$(ls -A /etc/dnsmasq.d/bifrost.dhcp-hosts.vlan25.d/)"', # onlyif directory is empty
    notify      => Service['dnsmasq-vlan25'],
    require     => [
      File['/opt/stack/custom_playbooks/deploy-public-dnsmasq.yaml'],
      File['/opt/stack/custom_playbooks/templates/dhcp-host.j2'],
      File['/etc/dnsmasq.d/bifrost.dhcp-hosts.vlan25.d'],
    ]
  }

  service { 'dnsmasq-vlan25':
    ensure     => running,
    provider   => 'base',
    binary     => '/usr/sbin/dnsmasq --conf-file=/etc/dnsmasq.conf.vlan25',
    hasstatus  => false,
    hasrestart => false,
    # This uses the process table to TERM the dnsmasq process matching the
    # pattern parameter. It does not HUP because that would not reload
    # /etc/dnsmasq.conf.vlan25.
    pattern    => 'dnsmasq --conf-file=/etc/dnsmasq.conf.vlan25'
  }
}
