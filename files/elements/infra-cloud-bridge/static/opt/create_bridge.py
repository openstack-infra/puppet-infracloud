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


def configure_bridge(interface, vlan_id, network_info, bridge_gateway):
    if vlan_id:
        net_name = "%s.%s" % (interface, vlan_id)
        vlan_content = 'vlan-raw-device %s' % interface
        bridge_name = 'br-vlan%s' % vlan_id
    else:
        net_name = interface
        vlan_content = ''
        bridge_name = 'br-vlan%s' % interface

    network_file = '/etc/network/interfaces.d/%s.cfg' % net_name

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
    gateway {bridge_gateway}
    dns-nameservers {nameservers}
    post-up route add default via {gateway} dev {bridge_name}
"""

    file_content = file_content.format(
        net_name=net_name, vlan_content=vlan_content,
        bridge_name=bridge_name,
        ipv4_address=network_info['networks'][0]['ip_address'],
        netmask=network_info['networks'][0]['netmask'],
        bridge_gateway=bridge_gateway,
        gateway=network_info['networks'][0]['routes'][0]['gateway'],
        nameservers=' '.join(network_info['networks'][0]['dns_nameservers']))

    with open(network_file, 'w') as target_file:
        target_file.write(file_content)

    subprocess.call(['ifup', bridge_name])


def main():
    network_info_file = '/mnt/config/openstack/latest/network_info.json'
    sys_root = '/sys/class/net'
    interfaces = [f for f in os.listdir(sys_root) if f != 'lo']

    network_info = {}
    if os.path.exists(network_info_file):
        network_info = json.load(open(network_info_file))

    if network_info:
        vlan_id = None
        # check if we have some vlan
        for link in network_info['links']:
            if 'vlan_id' in link:
                vlan_id = link['vlan_id']
                break

        # if we have vlan, we need to configure the matching file
        current_eth = interfaces[0]
        bridge_name = 'br-%s' % current_eth
        if vlan_id:
            for interface in interfaces:
                if '.' + vlan_id in interface:
                    current_eth = interface.replace('.' + vlan_id, '')
                    bridge_name = 'br-vlan%s' % vlan_id
                    break

        # read bridge gateway from config file
        with open('/opt/.bridge_gateway', 'r') as f:
            bridge_gateway = f.readline()

        # only configure if does not exist
        if bridge_name not in interfaces:
            configure_bridge(current_eth, vlan_id, network_info, bridge_gateway)


if __name__ == '__main__':
    sys.exit(main())
