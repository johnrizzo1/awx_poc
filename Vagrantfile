# -*- mode: ruby -*-
# vi: set ft=ruby :

# Configuration
VAGRANTFILE_API_VERSION = "2"

# Client configuration - adjust these numbers as needed
CLIENTS = {
  "alma" => {
    count: 1,
    box: "almalinux/9",
    base_ip: "192.168.56.11"
  },
  "ubuntu" => {
    count: 1,
    box: "generic/ubuntu2204",
    base_ip: "192.168.56.12"
  },
  "centos" => {
    count: 1,
    box: "centos/stream9",
    base_ip: "192.168.56.13"
  }
}

# Resource allocation
AWX_MEMORY = 4096
AWX_CPUS = 2
CLIENT_MEMORY = 2048
CLIENT_CPUS = 2

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Global configuration
  config.vm.box_check_update = false
  config.ssh.insert_key = false
  
  # Disable default synced folder
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # AWX Server
  config.vm.define "awx-server", primary: true do |awx|
    awx.vm.box = "almalinux/9"
    awx.vm.hostname = "awx-server"
    awx.vm.network "private_network", ip: "192.168.56.10"
    
    awx.vm.provider "libvirt" do |libvirt|
      libvirt.memory = AWX_MEMORY
      libvirt.cpus = AWX_CPUS
      libvirt.title = "awx-server"
    end
  end

  # Client nodes - iterate over each client type
  CLIENTS.each do |client_type, config_data|
    (1..config_data[:count]).each do |i|
      # Calculate IP address
      ip_parts = config_data[:base_ip].split('.')
      ip_last_octet = ip_parts[3].to_i + (i - 1)
      ip_address = "#{ip_parts[0]}.#{ip_parts[1]}.#{ip_parts[2]}.#{ip_last_octet}"
      
      # Generate unique VM name
      vm_name = config_data[:count] > 1 ? "client-#{client_type}-#{i}" : "client-#{client_type}"
      
      config.vm.define vm_name do |client|
        client.vm.box = config_data[:box]
        client.vm.hostname = vm_name
        client.vm.network "private_network", ip: ip_address
        
        client.vm.provider "libvirt" do |libvirt|
          libvirt.memory = CLIENT_MEMORY
          libvirt.cpus = CLIENT_CPUS
          libvirt.title = vm_name
        end
      end
    end
  end

  # Provision all VMs with Ansible after all are created
  # This runs only once after the last VM is up
  config.vm.define "client-centos", primary: false do |node|
    node.vm.provision "ansible" do |ansible|
      ansible.limit = "all"
      ansible.playbook = "ansible/playbooks/site.yml"
      ansible.inventory_path = "ansible/inventory/hosts.yml"
      ansible.verbose = "v"
      ansible.groups = {
        "awx_server" => ["awx-server"],
        "clients" => ["client-alma", "client-ubuntu", "client-centos"],
        "rhel_family" => ["client-alma", "client-centos"],
        "debian_family" => ["client-ubuntu"],
        "almalinux" => ["client-alma"],
        "ubuntu" => ["client-ubuntu"],
        "centos" => ["client-centos"]
      }
    end
  end
end