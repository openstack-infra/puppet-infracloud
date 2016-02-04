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
import subprocess
import sys

from glean import systemlock
from glean.cmd import get_config_drive_interfaces, get_sys_interfaces


def configure_bridge(interface, interface_name, bridge_name, vlan_raw_device):
    if interface['vlan_id']:
        vlan_content = 'vlan-raw-device %s' % vlan_raw_device
    else:
        vlan_content = ''

    network_file = '/etc/network/interfaces.d/%s.cfg' % interface_name

    # generate content depending on data
    file_content = """
auto {net_name}
iface {net_name} inet manual
{vlan_content}

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
    post-up route add default {gateway} metric 0

"""

    file_content = file_content.format(
        net_name=interface_name, vlan_content=vlan_content,
        bridge_name=bridge_name,
        ipv4_address=interface['ip_address'],
        netmask=interface['netmask'],
        gateway=interface['routes'][0]['gateway'],
        nameservers=' '.join(interface['dns_nameservers']))

    with open(network_file, 'w') as target_file:
        target_file.write(file_content)


# mock object to interact with glean
class MockArgs(object):
    pass


def main():
    network_info_file = '/mnt/config/openstack/latest/network_info.json'

    params = MockArgs()
    setattr(params, 'root', '/')
    setattr(params, 'noop', False)
    sys_interfaces = get_sys_interfaces(None, params)

    network_info = {}
    if os.path.exists(network_info_file):
        network_info = json.load(open(network_info_file))

    if not network_info:
        # we do not have entries on configdrive, skip
        sys.exit(0)

    interfaces = get_config_drive_interfaces(network_info)
    interface = interfaces[interfaces.keys()[0]]
    interface_name = sys_interfaces[interfaces.keys()[0]]

    if 'vlan_id' in interface:
        if interface['vlan_id'] in interface_name:
            # if we find the entry for the already configured vlan, trim it
            interface_name = interface_name.replace(
                '.' + interface['vlan_id'], '')

        vlan_raw_device = interface_name
        interface_name = "{0}.{1}".format(
            vlan_raw_device, interface['vlan_id'])

    # generate bridge name
    if 'vlan_id' in interface:
        bridge_name = 'br-vlan%s' % interface['vlan_id']
    else:
        bridge_name = 'br-eth'

    # only configure bridge if not exists
    if not os.path.exists('/etc/network/interfaces.d/%s.cfg' % bridge_name):
        configure_bridge(interface, interface_name,
                         bridge_name, vlan_raw_device)

if __name__ == '__main__':
    with systemlock.Lock('/tmp/glean.lock'):
        sys.exit(main())
