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
  $gateway_ip,
  $ipmi_passwords,
  $ironic_db_password,
  $ironic_inventory,
  $mysql_password,
  $region = 'vanilla',
  $ssh_private_key,
  $ssh_public_key,
  $vlan,
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

  class { '::ansible':
    ansible_version => '2.1.1.0',
  }

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
    content => template('infracloud/bifrost/bifrost_global_vars.erb'),
  }

  file { '/opt/stack/baremetal.json':
    ensure  => file,
    content => template('infracloud/bifrost/inventory.json.erb'),
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

  file { '/opt/stack/elements/infra-cloud-networking/static/etc/network/interfaces.d/eth2.cfg':
    ensure  => file,
    content => template('infracloud/bifrost/interfaces.d/eth2.cfg.erb'),
    require => File['/opt/stack/elements'],
  }
  file { "/opt/stack/elements/infra-cloud-networking/static/etc/network/interfaces.d/eth2.${vlan}.cfg":
    ensure  => file,
    content => template('infracloud/bifrost/interfaces.d/eth2.tag.cfg.erb'),
    require => File['/opt/stack/elements'],
  }
  file { "/opt/stack/elements/infra-cloud-networking/static/etc/network/interfaces.d/br-vlan${vlan}.cfg":
    ensure  => file,
    content => template('infracloud/bifrost/interfaces.d/br-vlan.tag.cfg.erb'),
    require => File['/opt/stack/elements'],
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
      Package['uuid-runtime'],
      Class['::mysql::server'],
    ],
  }
}
