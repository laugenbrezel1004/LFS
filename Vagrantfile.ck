# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Debian 12 (Bookworm) als Basis-Box
  config.vm.box = "debian/bookworm64"

  # Maschinenkonfiguration
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 40960 # 40 GB RAM
    vb.cpus = 16      # 16 Kerne
    # vb.customize ["modifyvm", :id, "--vram", "128"]
    # vb.customize ["modifyvm", :id, "--graphicscontroller", "vmsvga"]
  end

  # Hostname der VM
  config.vm.hostname = "debian-lfs-dev"

  # Verzeichnis-Mapping: /mnt vom Host zu /mnt in der VM
  config.vm.synced_folder "/mnt", "/mnt"

  # Netzwerkkonfiguration (optional, für SSH-Zugang)
  config.vm.network "private_network", type: "dhcp"

  # Ansible Provisioning
  config.vm.provision "ansible_local" do |ansible|
    ansible.playbook = "playbook.yml"
    ansible.install = true
    ansible.install_mode = :default
    ansible.compatibility_mode = "2.0"
  end
end
