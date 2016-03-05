require 'spec_helper_acceptance'

describe 'allinone', :if => os[:family] == 'ubuntu' do

  fixtures_path = File.join(File.dirname(__FILE__), 'fixtures')
  controller_path = File.join(fixtures_path, 'allinone_controller.pp')
  compute_path = File.join(fixtures_path, 'allinone_compute.pp')
  controller_pp = File.read(controller_path)
  compute_pp = File.read(compute_path)

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

  # The controller and compute are meant to run on separate nodes, so
  # applying them together gives duplicate definition errors. Otherwise
  # they should be able to cohabitate a single node.
  it 'should apply the controller with no errors' do
    apply_manifest(controller_pp, catch_failures: true)
  end
  it 'should apply the compute with no errors' do
    apply_manifest(compute_pp, catch_failures: true)
  end

  it 'should be idempotent' do
    apply_manifest(controller_pp, catch_changes: true)
    apply_manifest(compute_pp, catch_changes: true)
  end
end
