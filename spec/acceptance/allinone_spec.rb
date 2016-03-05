require 'spec_helper_acceptance'

describe 'allinone', :if => os[:family] == 'ubuntu' do

  base_path = File.dirname(__FILE__)
  pp_path = File.join(base_path, 'fixtures')
  fixture_path = File.join(pp_path, 'allinone.pp')
  pp = File.read(fixture_path)

  before :all do
    # set up bridge
    shell('apt-get install -y vlan bridge-utils')
    shell('echo -e "auto eth0.2\niface eth0.2 inet manual\n" >> /etc/network/interfaces')
    shell('modprobe 8021q')
    shell('ifup eth0.2')
    shell('brctl addbr br-vlan2')
    shell('brctl addif br-vlan2 eth0.2')
    shell('ip addr add 10.1.0.42/255.255.240.0 dev br-vlan2')
    shell('ip link set dev br-vlan2 up')

    # set hostname so addresses are all consistent
    shell('hostname localhost')
  end

  it 'should work with no errors' do
    apply_manifest(pp, catch_failures: true)
  end

  it 'should be idempotent' do
    apply_manifest(pp, catch_changes: true)
  end
end
