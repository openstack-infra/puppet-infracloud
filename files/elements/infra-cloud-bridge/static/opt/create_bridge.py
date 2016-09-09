#!/usr/bin/python
# Copyright (c) 2016 Yolanda Robla
# Copyright (c) 2016 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import json
import os
import platform
import subprocess
import sys

from glean import systemlock
from glean.cmd import get_config_drive_interfaces, get_sys_interfaces


def configure_bridge_debian(interface, interface_name, bridge_name, vlan_raw_device=None):
    if 'vlan_id' in interface:
        vlan_content = 'vlan-raw-device %s' % vlan_raw_device
    else:
        vlan_content = ''

    network_file = '/etc/network/interfaces.d/%s.cfg' % interface_name
    bridge_file = '/etc/network/interfaces.d/%s.cfg' % bridge_name

    # generate interface content depending on data
    interface_file_content = """
auto {net_name}
iface {net_name} inet manual
{vlan_content}
"""

    interface_file_content = interface_file_content.format(
        net_name=interface_name,
        vlan_content=vlan_content)

    with open(network_file, 'w') as target_file:
        target_file.write(interface_file_content)

    # generate bridge content depending on data
    bridge_file_content = """
auto {bridge_name}
iface {bridge_name} inet static
    bridge_ports {net_name}
    bridge_hello 2
    bridge_maxage 12
    bridge_stp off
    address {ipv4_address}
    netmask {netmask}
    gateway {gateway}
    dns-nameservers {nameservers}
"""

    bridge_file_content = bridge_file_content.format(
        bridge_name=bridge_name,
        net_name=inteface_name,
        ipv4_address=interface['ip_address'],
        netmask=interface['netmask'],
        gateway=interface['routes'][0]['gateway'],
        nameservers=' '.join(interface['dns_nameservers']))

    with open(bridge_file, 'w') as target_file:
        target_file.write(bridge_file_content)

    # turn down pre-existing interface and start the bridge
    # because at this point, glean has already configured
    # previous interface that needs to be overriden.
    # This will only happen at first time that the bridge
    # is configured, because on reboots, we won't reach this
    # configure_bridge method
    subprocess.call(['ifdown', interface_name])
    subprocess.call(['ifup', bridge_name])


def configure_bridge_rh(interface, interface_name, bridge_name, vlan_raw_device=None):
    if 'vlan_id' in interface:
        vlan_content = 'VLAN=YES'
    else:
        vlan_content = ''

    network_file = '/etc/sysconfig/network-scripts/ifcfg-%s' % interface_name
    bridge_file = '/etc/sysconfig/network-scripts/ifcfg-%s' % bridge_name

    # generate interface content depending on data
    interface_file_content = """
DEVICE={net_name}
BOOTPROTO=none
ONBOOT=yes
NM_CONTROLLED=no
TYPE=Ethernet
{vlan_content}
BRIDGE={bridge_name}
"""

    interface_file_content = interface_file_content.format(
        net_name=interface_name,
        vlan_content=vlan_content,
        bridge_name=bridge_name)

    with open(network_file, 'w') as target_file:
        target_file.write(interface_file_content)

    # generate bridge content depending on data
    bridge_file_content = """
DEVICE={bridge_name}
TYPE=Bridge
IPADDR={ipv4_address}
NETMASK={netmask}
GATEWAY={gateway}
STP=off
HELLO=2
MAXAGE=12
DNS={nameservers}
"""

    bridge_file_content = bridge_file_content.format(
        bridge_name=bridge_name,
        ipv4_address=interface['ip_address'],
        netmask=interface['netmask'],
        gateway=interface['routes'][0]['gateway'],
        nameservers=' '.join(interface['dns_nameservers']))

    with open(bridge_file, 'w') as target_file:
        target_file.write(bridge_file_content)

    # start the bridge at first boot
    subprocess.call(['ifup', bridge_name])


# mock object to interact with glean
class MockArgs(object):
    pass


def main():
    network_info_file = '/mnt/config/openstack/latest/network_info.json'

    # detect the platform where we are
    distro = platform.dist()[0].lower()

    params = MockArgs()
    setattr(params, 'root', '/')
    setattr(params, 'noop', False)
    setattr(params, 'distro', distro)
    sys_interfaces = get_sys_interfaces(None, params)

    network_info = {}
    if os.path.exists(network_info_file):
        network_info = json.load(open(network_info_file))

    if not network_info:
        # we do not have entries on configdrive, skip
        sys.exit(0)

    interfaces = get_config_drive_interfaces(network_info)
    if len(interfaces) == 1:
        interface = interfaces[interfaces.keys()[0]]
        interface_name = sys_interfaces[interface['id']]
    else:
        interface = interfaces[[i for i in interfaces.keys()
                                if 'vlan_id' in interfaces[i]][0]]
        interface_name = sys_interfaces[interface['mac_address']]

    if 'vlan_id' in interface:
        if interface['vlan_id'] in interface_name:
            # if we find the entry for the already configured vlan, trim it
            interface_name = interface_name.replace(
                '.' + interface['vlan_id'], '')

        vlan_raw_device = interface_name
        interface_name = "{0}.{1}".format(
            vlan_raw_device, interface['vlan_id'])

        bridge_name = 'br-vlan%s' % interface['vlan_id']

        # only configure bridge if not exists
        if not os.path.exists('/sys/class/net/%s' % bridge_name):
            if distro in ('debian', 'ubuntu'):
                configure_bridge_debian(interface, interface_name,
                                        bridge_name, vlan_raw_device)
            else:
                configure_bridge_rh(interface, interface_name,
                                    bridge_name, vlan_raw_device)
    else:
        bridge_name = 'br-%s' % interface_name
        if not os.path.exists('/sys/class/net/%s' % bridge_name):
            if distro in ('debian', 'ubuntu'):
                configure_bridge_debian(interface, interface_name,
                                        bridge_name)
            else:
                configure_bridge_rh(interface, interface_name,
                                    bridge_name)

if __name__ == '__main__':
    with systemlock.Lock('/tmp/glean.lock'):
        sys.exit(main())
