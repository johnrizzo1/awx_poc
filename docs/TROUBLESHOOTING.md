# AWX POC Troubleshooting Guide

This guide helps resolve common issues encountered when setting up and using the AWX POC environment.

## Table of Contents

1. [Vagrant Issues](#vagrant-issues)
2. [VM Issues](#vm-issues)
3. [Ansible Issues](#ansible-issues)
4. [AWX Installation Issues](#awx-installation-issues)
5. [AWX Runtime Issues](#awx-runtime-issues)
6. [Network Issues](#network-issues)
7. [SSH/Authentication Issues](#sshauthentication-issues)
8. [Performance Issues](#performance-issues)

## Vagrant Issues

### Issue: Vagrant command not found

**Symptoms**: `bash: vagrant: command not found`

**Solution**:
```bash
# Verify Vagrant installation
which vagrant

# If not installed, install Vagrant
wget https://releases.hashicorp.com/vagrant/2.4.0/vagrant_2.4.0_linux_amd64.zip
unzip vagrant_2.4.0_linux_amd64.zip
sudo mv vagrant /usr/local/bin/

# Verify
vagrant --version
```

### Issue: libvirt provider not available

**Symptoms**: `No usable default provider could be found for your system`

**Solution**:
```bash
# Install libvirt and vagrant-libvirt plugin
# Ubuntu/Debian
sudo apt update
sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils
sudo systemctl enable --now libvirtd

# RHEL/CentOS/AlmaLinux
sudo dnf install qemu-kvm libvirt virt-install bridge-utils
sudo systemctl enable --now libvirtd

# Add user to libvirt group
sudo usermod -aG libvirt $USER
newgrp libvirt

# Install vagrant-libvirt plugin
vagrant plugin install vagrant-libvirt

# Verify
virsh version
vagrant plugin list | grep libvirt
```

### Issue: Vagrant box download fails

**Symptoms**: `Failed to download box image`

**Solution**:
```bash
# Manually download boxes
vagrant box add almalinux/9
vagrant box add ubuntu/jammy64
vagrant box add centos/stream9

# Or specify version
vagrant box add almalinux/9 --box-version 9.3.20231113

# Check downloaded boxes
vagrant box list
```

### Issue: Vagrant up hangs

**Symptoms**: VM creation hangs at "Waiting for machine to boot"

**Solution**:
```bash
# Destroy and retry
vagrant destroy -f
vagrant up

# Check libvirt logs
sudo journalctl -u libvirtd -f

# Check VM console
virsh console awx-server

# List running VMs
virsh list --all

# Check VM logs
virsh dumpxml awx-server
```

## VM Issues

### Issue: Insufficient memory

**Symptoms**: VM fails to start, "Not enough memory" error

**Solution**:
```bash
# Check available memory
free -h

# Reduce VM memory in Vagrantfile
# Edit memory values:
vb.memory = "2048"  # For AWX (minimum)
vb.memory = "512"   # For clients (minimum)

# Or start VMs one at a time
vagrant up awx-server
vagrant up client-alma
```

### Issue: VM stuck in "running" but not accessible

**Symptoms**: `vagrant status` shows running but SSH fails

**Solution**:
```bash
# Check VM in libvirt
virsh list --all

# Check VM state
virsh domstate awx-server

# Force shutdown and restart
vagrant halt -f awx-server
vagrant up awx-server

# If still stuck, destroy and recreate
vagrant destroy -f awx-server
vagrant up awx-server

# Check libvirt network
virsh net-list --all
virsh net-info default
```

### Issue: Disk space full

**Symptoms**: "No space left on device" errors

**Solution**:
```bash
# Check disk space
df -h

# Clean up Vagrant boxes
vagrant box prune

# Remove old VMs
vagrant destroy -f

# Clean Docker images (on AWX server)
vagrant ssh awx-server
sudo docker system prune -a

# Clean libvirt storage pools
virsh pool-list --all
virsh vol-list default
# Delete unused volumes if needed
```

## Ansible Issues

### Issue: Ansible not found

**Symptoms**: `ansible-playbook: command not found`

**Solution**:
```bash
# Install Ansible
pip3 install ansible

# Or via package manager
sudo apt install ansible  # Ubuntu/Debian
sudo dnf install ansible  # RHEL/CentOS/AlmaLinux

# Verify
ansible --version
```

### Issue: Missing Ansible collections

**Symptoms**: `couldn't resolve module/action 'community.docker.docker_compose'`

**Solution**:
```bash
# Install required collections
ansible-galaxy collection install community.general
ansible-galaxy collection install community.docker
ansible-galaxy collection install community.crypto
ansible-galaxy collection install ansible.posix

# Verify installation
ansible-galaxy collection list
```

### Issue: SSH connection refused

**Symptoms**: `Failed to connect to the host via ssh`

**Solution**:
```bash
# Verify VM is running
vagrant status

# Test SSH manually
vagrant ssh awx-server

# Check SSH key
ls -la ~/.vagrant.d/insecure_private_key

# Reload SSH config
vagrant reload awx-server --provision
```

### Issue: Permission denied (publickey)

**Symptoms**: Ansible fails with SSH permission denied

**Solution**:
```bash
# Verify SSH key permissions
chmod 600 ~/.vagrant.d/insecure_private_key

# Test SSH connection
ssh -i ~/.vagrant.d/insecure_private_key vagrant@192.168.56.10

# Re-provision with correct keys
vagrant provision awx-server
```

## AWX Installation Issues

### Issue: Docker installation fails

**Symptoms**: Docker commands not found or service won't start

**Solution**:
```bash
vagrant ssh awx-server

# Check Docker status
sudo systemctl status docker

# Restart Docker
sudo systemctl restart docker

# Reinstall Docker
sudo dnf remove docker-ce docker-ce-cli containerd.io
sudo dnf install docker-ce docker-ce-cli containerd.io

# Verify
sudo docker --version
sudo docker ps
```

### Issue: Docker Compose not found

**Symptoms**: `docker-compose: command not found`

**Solution**:
```bash
vagrant ssh awx-server

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify
docker-compose --version
```

### Issue: AWX containers won't start

**Symptoms**: Containers exit immediately or fail to start

**Solution**:
```bash
vagrant ssh awx-server

# Check container logs
sudo docker-compose -f /opt/awx/docker-compose.yml logs

# Check container status
sudo docker ps -a

# Restart containers
sudo docker-compose -f /opt/awx/docker-compose.yml down
sudo docker-compose -f /opt/awx/docker-compose.yml up -d

# Check for port conflicts
sudo netstat -tulpn | grep :80
```

### Issue: PostgreSQL connection fails

**Symptoms**: AWX can't connect to database

**Solution**:
```bash
vagrant ssh awx-server

# Check PostgreSQL container
sudo docker ps | grep postgres

# Check PostgreSQL logs
sudo docker logs awx_postgres

# Verify database credentials in docker-compose.yml
sudo cat /opt/awx/docker-compose.yml

# Restart PostgreSQL
sudo docker restart awx_postgres
```

### Issue: AWX web interface not accessible

**Symptoms**: Cannot access http://192.168.56.10

**Solution**:
```bash
vagrant ssh awx-server

# Check if AWX is running
sudo docker ps

# Check AWX logs
sudo docker logs awx_web

# Check firewall
sudo firewall-cmd --list-all

# Add firewall rule if needed
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --reload

# Test locally
curl http://localhost:80/api/v2/ping/

# Check from host
curl http://192.168.56.10/api/v2/ping/
```

## AWX Runtime Issues

### Issue: Jobs fail with "No hosts matched"

**Symptoms**: Job runs but reports no hosts matched

**Solution**:
1. Check inventory in AWX UI
2. Verify hosts are added to inventory
3. Check host variables (ansible_host)
4. Verify limit pattern in job template
5. Test with `--limit all`

### Issue: Jobs fail with authentication errors

**Symptoms**: "Permission denied (publickey)" in job output

**Solution**:
```bash
# Verify SSH key distribution
ansible-playbook ansible/playbooks/distribute-awx-key.yml

# Test SSH from AWX server
vagrant ssh awx-server
sudo ssh -i /root/.ssh/awx_rsa vagrant@192.168.56.11

# Check authorized_keys on clients
vagrant ssh client-alma
cat ~/.ssh/authorized_keys
```

### Issue: Jobs timeout

**Symptoms**: Jobs run but timeout before completion

**Solution**:
1. Increase job timeout in template settings
2. Check network connectivity to hosts
3. Verify playbook isn't hanging
4. Check for slow package downloads
5. Test playbook manually:
   ```bash
   vagrant ssh awx-server
   cd /var/lib/awx/projects/demo-playbooks
   ansible-playbook -i inventory system-update.yml -v
   ```

### Issue: Playbook not found

**Symptoms**: "Could not find playbook" error

**Solution**:
```bash
vagrant ssh awx-server

# Check project directory
ls -la /var/lib/awx/projects/demo-playbooks/

# Verify playbook exists
cat /var/lib/awx/projects/demo-playbooks/system-update.yml

# Check permissions
sudo chown -R awx:awx /var/lib/awx/projects/

# Sync project in AWX UI
```

## Network Issues

### Issue: VMs can't communicate

**Symptoms**: Ping fails between VMs

**Solution**:
```bash
# Check VM network configuration
vagrant ssh awx-server
ip addr show

# Verify private network
ping 192.168.56.11
ping 192.168.56.12
ping 192.168.56.13

# Check firewall rules
sudo firewall-cmd --list-all

# Allow ICMP
sudo firewall-cmd --permanent --add-service=icmp
sudo firewall-cmd --reload
```

### Issue: No internet access from VMs

**Symptoms**: Package downloads fail, can't reach external sites

**Solution**:
```bash
vagrant ssh awx-server

# Check DNS
cat /etc/resolv.conf
ping 8.8.8.8
ping google.com

# Check NAT network
ip route show

# Restart network
sudo systemctl restart NetworkManager

# Or reload VM
exit
vagrant reload awx-server
```

### Issue: Port conflicts

**Symptoms**: "Port 80 already in use" or similar

**Solution**:
```bash
# Check what's using the port
sudo netstat -tulpn | grep :80
sudo lsof -i :80

# Stop conflicting service
sudo systemctl stop httpd
sudo systemctl stop nginx

# Or change AWX port in group_vars/awx_server.yml
awx_port: 8080
```

## SSH/Authentication Issues

### Issue: SSH key not accepted

**Symptoms**: "Permission denied (publickey)"

**Solution**:
```bash
# Check key permissions
ls -la ~/.ssh/
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# Verify key is added
cat ~/.ssh/authorized_keys

# Check SSH config
sudo cat /etc/ssh/sshd_config | grep PubkeyAuthentication

# Restart SSH
sudo systemctl restart sshd
```

### Issue: AWX can't authenticate to clients

**Symptoms**: Jobs fail with authentication errors

**Solution**:
```bash
# Re-run key distribution
ansible-playbook ansible/playbooks/distribute-awx-key.yml

# Verify credential in AWX
# Check Resources → Credentials → SSH Credential

# Test manually
vagrant ssh awx-server
sudo ssh -i /root/.ssh/awx_rsa vagrant@192.168.56.11
```

## Performance Issues

### Issue: Slow VM performance

**Symptoms**: VMs are sluggish, high CPU usage

**Solution**:
```bash
# Check host resources
top
free -h
df -h

# Reduce VM resources if needed
# Edit Vagrantfile:
vb.memory = "2048"  # Reduce from 4096
vb.cpus = 1         # Reduce from 2

# Enable VirtualBox optimizations
vb.customize ["modifyvm", :id, "--ioapic", "on"]
vb.customize ["modifyvm", :id, "--cpuexecutioncap", "80"]
```

### Issue: Slow playbook execution

**Symptoms**: Playbooks take very long to complete

**Solution**:
```bash
# Enable pipelining in ansible.cfg
pipelining = True

# Increase forks
forks = 10

# Use faster gathering
gathering = smart
fact_caching = jsonfile

# Disable host key checking
host_key_checking = False
```

## Getting Help

### Collect Diagnostic Information

```bash
# System info
uname -a
free -h
df -h

# Vagrant info
vagrant version
vagrant global-status

# VM status
vagrant status

# Ansible info
ansible --version
ansible-galaxy collection list

# AWX logs
vagrant ssh awx-server
sudo docker-compose -f /opt/awx/docker-compose.yml logs --tail=100

# Network info
ip addr show
ip route show
```

### Enable Debug Mode

```bash
# Vagrant debug
VAGRANT_LOG=debug vagrant up

# Ansible verbose
ansible-playbook playbook.yml -vvv

# AWX debug logs
vagrant ssh awx-server
sudo docker-compose -f /opt/awx/docker-compose.yml logs -f
```

### Reset Environment

If all else fails, start fresh:

```bash
# Destroy everything
vagrant destroy -f

# Clean up
vagrant box prune
rm -rf .vagrant/

# Start over
vagrant up
```

## Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| "Box not found" | Box not downloaded | `vagrant box add <box-name>` |
| "Port collision" | Port already in use | Change port or stop conflicting service |
| "No space left" | Disk full | Clean up disk space |
| "Connection timeout" | Network/firewall issue | Check network and firewall |
| "Module not found" | Missing Ansible collection | Install required collection |
| "Permission denied" | SSH key issue | Check key permissions and distribution |

## Additional Resources

- [Vagrant Documentation](https://www.vagrantup.com/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [AWX Documentation](https://ansible.readthedocs.io/projects/awx/en/latest/)
- [Docker Documentation](https://docs.docker.com/)

For further assistance, check the project's issue tracker or community forums.