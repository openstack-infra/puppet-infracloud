InfraCloud Development
======================

This example provides a set of DIB elements, libvirt templates, and
instructions for creating a local development environment that simulates the
InfraCloud production environment. This means the networking and everything
ansible sets up in preparation for running puppet apply, including a dummy
hiera database. It also includes a script to do a short smoke test.

Setup
-----

These instructions assume libvirt and disk-image-builder are already installed,
and that there is a public SSH key in ~/.ssh/id_rsa.pub for the devuser element
to copy.

Create two disk images::

  export DIB_DEV_USER_PWDLESS_SUDO=yes
  export ELEMENTS_PATH=$HOME/infracloud-development/elements
  DIB_ROLE=controller disk-image-create -u ubuntu devuser system-config puppet \
    motd smoke-test infracloud-static-net vm cloud-init-nocloud \
    -o "/tmp/infracloud-controller.qcow2" --image-size 20 \
    -p git,vim,vlan,bridge-utils
  DIB_ROLE=compute disk-image-create -u ubuntu devuser system-config puppet \
    motd infracloud-static-net vm cloud-init-nocloud \
    -o "/tmp/infracloud-compute.qcow2" --image-size 20 \
    -p git,vim,vlan,bridge-utils

These images have static IP addresses and hostnames baked into them. This
simulates the production environment for most purposes but avoids too much
complexity setting up local networks.

Define the network::

  virsh net-define definitions/network.xml

Start the network::

  virsh net-start public

Define the VMs::

  virsh define definitions/controller.xml
  virsh define definitions/compute.xml

Start the VMs::

  virsh start controller
  virsh start compute

Puppet
------

SSH into the controller::

  source functions/sshvm
  sshvm controller

Apply any puppet changes you're testing to /etc/puppet/modules/infracloud or
/opt/system-config/production.

Run puppet apply::

  puppet apply /opt/system-config/production/manifests/site.pp

Do the same on the compute node once the controller is finished::

  sshvm compute
  puppet apply /opt/system-config/production/manifests/site.pp

Test
----

Run the smoke test script::

  bash -ex /opt/smoke-test
