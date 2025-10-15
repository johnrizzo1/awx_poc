# AWX POC Setup Guide

This guide provides detailed instructions for setting up the AWX Proof of Concept environment.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Starting the Environment](#starting-the-environment)
4. [Manual Configuration Steps](#manual-configuration-steps)
5. [Verification](#verification)

## Prerequisites

### Required Software

- **Vagrant** >= 2.3.0
  ```bash
  # Install on Linux
  wget https://releases.hashicorp.com/vagrant/2.4.0/vagrant_2.4.0_linux_amd64.zip
  unzip vagrant_2.4.0_linux_amd64.zip
  sudo mv vagrant /usr/local/bin/
  
  # Verify installation
  vagrant --version
  ```

- **libvirt** and **vagrant-libvirt plugin**
  ```bash
  # Install libvirt on Ubuntu/Debian
  sudo apt update
  sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils
  sudo systemctl enable --now libvirtd
  
  # Install on RHEL/CentOS/AlmaLinux
  sudo dnf install qemu-kvm libvirt virt-install bridge-utils
  sudo systemctl enable --now libvirtd
  
  # Add your user to libvirt group
  sudo usermod -aG libvirt $USER
  newgrp libvirt
  
  # Install vagrant-libvirt plugin
  vagrant plugin install vagrant-libvirt
  
  # Verify installation
  virsh version
  vagrant plugin list | grep libvirt
  ```

- **Ansible** >= 2.14
  ```bash
  # Install on Ubuntu/Debian
  sudo apt update
  sudo apt install ansible
  
  # Install on RHEL/CentOS/AlmaLinux
  sudo dnf install ansible
  
  # Or install via pip
  pip3 install ansible
  
  # Verify installation
  ansible --version
  ```

### System Requirements

- **RAM**: Minimum 12GB available (16GB recommended)
- **CPU**: 4+ cores recommended
- **Disk Space**: Minimum 40GB free space
- **Network**: Internet connection for downloading VM images and packages

### Ansible Collections

Install required Ansible collections:

```bash
ansible-galaxy collection install community.general
ansible-galaxy collection install community.docker
ansible-galaxy collection install community.crypto
ansible-galaxy collection install ansible.posix
```

## Initial Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd awx_poc
```

### 2. Review Configuration

Check the configuration files before starting:

- **Vagrantfile**: VM definitions and resource allocation
- **ansible/inventory/hosts.yml**: Inventory configuration
- **ansible/inventory/group_vars/**: Variable definitions

### 3. Customize Variables (Optional)

Edit `ansible/inventory/group_vars/awx_server.yml` to customize:

```yaml
# AWX Admin Credentials
awx_admin_user: admin
awx_admin_password: "YourSecurePassword"

# PostgreSQL Configuration
postgres_password: "YourPostgresPassword"

# AWX Version
awx_version: "24.6.1"
```

## Starting the Environment

### Option 1: Start All VMs at Once

```bash
# Start all VMs and run provisioning
vagrant up

# This will:
# 1. Download VM images (first time only)
# 2. Create and configure all 4 VMs
# 3. Run Ansible provisioning
# 4. Install and configure AWX
```

### Option 2: Start VMs Individually

```bash
# Start AWX server first
vagrant up awx-server

# Wait for AWX server to complete, then start clients
vagrant up client-alma
vagrant up client-ubuntu
vagrant up client-centos
```

### Expected Timeline

- **First run**: 30-45 minutes (includes image downloads)
- **Subsequent runs**: 15-20 minutes

## Manual Configuration Steps

After the VMs are up, complete these manual steps:

### 1. Install AWX

```bash
# SSH into AWX server
vagrant ssh awx-server

# Run AWX installation playbook
cd /vagrant
ansible-playbook ansible/playbooks/awx-install.yml

# Wait for AWX to start (5-10 minutes)
# Monitor with: docker-compose -f /opt/awx/docker-compose.yml logs -f
```

### 2. Configure AWX

```bash
# Run AWX configuration playbook
ansible-playbook ansible/playbooks/awx-configure.yml

# This creates:
# - Organization
# - Inventory
# - Credentials
# - Demo playbooks
```

### 3. Distribute SSH Keys

```bash
# Distribute AWX SSH key to client nodes
ansible-playbook ansible/playbooks/distribute-awx-key.yml
```

## Verification

### 1. Check VM Status

```bash
# Check all VMs are running
vagrant status

# Expected output:
# awx-server    running (libvirt)
# client-alma   running (libvirt)
# client-ubuntu running (libvirt)
# client-centos running (libvirt)
```

### 2. Verify AWX Installation

```bash
# SSH into AWX server
vagrant ssh awx-server

# Check AWX containers
sudo docker ps

# Expected containers:
# - awx_web
# - awx_task
# - awx_postgres

# Check AWX API
curl http://192.168.56.10/api/v2/ping/
```

### 3. Access AWX Web UI

1. Open browser: http://192.168.56.10
2. Login with credentials from `group_vars/awx_server.yml`
   - Default: admin / AWXadmin123!
3. Verify organization, inventory, and credentials are created

### 4. Test Client Connectivity

```bash
# From AWX server
vagrant ssh awx-server

# Test SSH to clients
sudo ssh -i /root/.ssh/awx_rsa vagrant@192.168.56.11  # client-alma
sudo ssh -i /root/.ssh/awx_rsa vagrant@192.168.56.12  # client-ubuntu
sudo ssh -i /root/.ssh/awx_rsa vagrant@192.168.56.13  # client-centos
```

## Post-Installation

### Create AWX Projects

1. In AWX UI, go to **Resources** → **Projects**
2. Click **Add**
3. Configure:
   - Name: "Demo Playbooks"
   - Organization: "Demo Organization"
   - SCM Type: "Manual"
   - Playbook Directory: "demo-playbooks"
4. Save

### Create Job Templates

1. Go to **Resources** → **Templates**
2. Click **Add** → **Job Template**
3. Configure for each demo playbook:
   - System Update
   - Install Package
   - Manage Service
   - Deploy File
   - Gather Facts

See [USAGE.md](USAGE.md) for detailed instructions on creating and running job templates.

## Useful Commands

```bash
# Start all VMs
vagrant up

# Stop all VMs
vagrant halt

# Restart a specific VM
vagrant reload awx-server

# SSH into a VM
vagrant ssh awx-server

# Destroy all VMs (clean slate)
vagrant destroy -f

# Re-provision without destroying
vagrant provision

# Check VM status
vagrant status

# View AWX logs
vagrant ssh awx-server
sudo docker-compose -f /opt/awx/docker-compose.yml logs -f

# Manage AWX service
vagrant ssh awx-server
sudo awx-manage start|stop|restart|status|logs
```

## Next Steps

- Review [USAGE.md](USAGE.md) for using AWX
- Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) if you encounter issues
- Explore AWX features and create custom job templates