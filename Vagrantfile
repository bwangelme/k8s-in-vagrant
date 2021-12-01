# -*- mode: ruby -*-
# vi: set ft=ruby :

# Verify whether required plugins are installed.
required_plugins = [ "vagrant-disksize" ]
required_plugins.each do |plugin|
  if not Vagrant.has_plugin?(plugin)
    raise "The vagrant plugin #{plugin} is required. Please run `vagrant plugin install #{plugin}`"
  end
end

Vagrant.configure("2") do |config|
  config.vm.box_check_update = false
  # You need install plugin vagrant-disksize on vagrant.
  # For this, do vagrant plugin install vagrant-disksize.
  config.disksize.size = "40GB"

  $num_instances = 3
  $etcd_cluster = "node1=http://172.18.10.101:2380"
  (1..$num_instances).each do |i|
    config.vm.define "k8s-node#{i}" do |node|
      node.vm.box = "ubuntu/focal64"
      node.vm.hostname = "k8s-node#{i}"
      netmask = "255.255.0.0"
      ip1 = "172.16.10.#{i+100}"
      ip2 = "172.16.20.#{i+100}"
      ip3 = "172.16.30.#{i+100}"
      node.vm.network "private_network", ip: ip1, netmask: netmask
      node.vm.network "private_network", ip: ip2, netmask: netmask
      node.vm.network "private_network", ip: ip3, netmask: netmask
      node.vm.provider "virtualbox" do |vb|
        vb.memory = "4096"
        vb.cpus = 2
        vb.name = "k8s-node#{i}"
      end
      node.vm.provision "shell", path: "install.sh", args: [i]
    end
  end
end
