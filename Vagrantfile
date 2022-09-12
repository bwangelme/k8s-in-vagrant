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
  (1..$num_instances).each do |i|
    config.vm.define "k8s-node#{i}" do |node|
      node.vm.box = "ubuntu/focal64"
      node.vm.hostname = "k8s-node#{i}"
      node.vm.synced_folder "/home/xuyundong/Github", "/code"
      # Ranges: 192.168.56.0/21
      ip = "192.168.56.#{i+10}"
      node.vm.network "private_network", ip: ip
      node.vm.provider "virtualbox" do |vb|
        vb.memory = "4096"
        vb.cpus = 2
        vb.name = "k8s-node#{i}"
      end
      # node.vm.provision "shell", path: "install.sh", args: [i]
    end
  end
end
