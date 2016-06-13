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

    # set hostname
    shell('echo 127.0.1.1 infracloud.local infracloud >> /etc/hosts')
    shell('echo infracloud > /etc/hostname')
    shell('hostname infracloud')
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

  credentials = 'OS_USERNAME=admin'
  credentials += ' OS_PASSWORD=XXX'
  credentials += ' OS_PROJECT_NAME=openstack'
  credentials += ' OS_USER_DOMAIN_NAME=default'
  credentials += ' OS_PROJECT_DOMAIN_NAME=default'
  credentials += ' OS_IDENTITY_API_VERSION=3'
  credentials += ' OS_AUTH_URL=https://infracloud.local:5000/v3'

  it 'should have keystone projects' do
    result = shell("#{credentials} openstack project list")
    expect(result.stdout).to match(/openstack/)
    expect(result.exit_code).to eq(0)
  end

  it 'should have keystone users' do
    result = shell("#{credentials} openstack user list")
    expect(result.stdout).to match(/admin/)
    expect(result.exit_code).to eq(0)
  end

  it 'should have keystone services' do
    result = shell("#{credentials} openstack service list")
    expect(result.stdout).to match(/identity/)
    expect(result.stdout).to match(/compute/)
    expect(result.stdout).to match(/network/)
    expect(result.stdout).to match(/image/)
    expect(result.exit_code).to eq(0)
  end

  it 'should have keystone endpoints' do
    result = shell("#{credentials} openstack endpoint list")
    expect(result.stdout).to match(/infracloud.local:5000/)
    expect(result.stdout).to match(/infracloud.local:9696/)
    expect(result.stdout).to match(/infracloud.local:9292/)
    expect(result.stdout).to match(/infracloud.local:8774/)
    expect(result.exit_code).to eq(0)
  end

  it 'should have nova flavors' do
    result = shell("#{credentials} openstack flavor list")
    expect(result.stdout).to match(/m1.tiny/)
    expect(result.exit_code).to eq(0)
  end

  it 'should have nova services running' do
    result = shell("#{credentials} openstack compute service list")
    expect(result.stdout).to match(/conductor.*up/)
    expect(result.stdout).to match(/scheduler.*up/)
    expect(result.stdout).to match(/compute.*up/)
    expect(result.exit_code).to eq(0)
  end

  it 'should have a neutron network' do
    result = shell("#{credentials} openstack network list")
    expect(result.stdout).to match(/public/)
    expect(result.exit_code).to eq(0)
  end

  it 'should have a neutron subnet' do
    result = shell("#{credentials} neutron subnet-list")
    expect(result.stdout).to match(/provider-subnet-infracloud/)
    expect(result.exit_code).to eq(0)
  end

  it 'should be able to upload an image' do
    command = 'openstack image create \
      --copy-from http://download.cirros-cloud.net/0.3.1/cirros-0.3.1-x86_64-disk.img \
      --public \
      --container-format bare \
      --disk-format qcow2 \
      cirros'
    result = shell("#{credentials} #{command}")
    expect(result.exit_code).to eq(0)
    list_command = "#{credentials} openstack image list --long"
    timeout = 60
    end_time = Time.now + timeout
    image_list = shell(list_command)
    while image_list.stdout =~ /saving/ && Time.now() < end_time
      sleep(10)
      image_list = shell(list_command)
    end
    expect(image_list.stdout).to match(/cirros.*active/)
    expect(image_list.exit_code).to eq(0)
  end

  it 'should be able to upload a keypair' do
    shell('ssh-keygen -f ~/.ssh/id_rsa -q -N ""')
    result = shell("#{credentials} openstack keypair create --public-key ~/.ssh/id_rsa.pub newkey")
    expect(result.exit_code).to eq(0)
    result = shell("#{credentials} openstack keypair list")
    expect(result.stdout).to match('newkey')
    expect(result.exit_code).to eq(0)
  end

  it 'should be able to boot a node' do
    result = shell("#{credentials} openstack server create --flavor 1 --image cirros --key-name newkey testnode")
    expect(result.exit_code).to eq(0)
    sleep(8) # command returns immediately but node needs time to boot
    result = shell("#{credentials} openstack server list")
    expect(result.stdout).to match(/testnode.*ACTIVE/)
    expect(result.exit_code).to eq(0)
  end
end
