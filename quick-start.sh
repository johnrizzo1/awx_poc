#!/bin/bash
# AWX POC Quick Start Script
# This script automates the setup of the AWX POC environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_command() {
    if command -v $1 &> /dev/null; then
        print_success "$1 is installed"
        return 0
    else
        print_error "$1 is not installed"
        return 1
    fi
}

# Main script
print_header "AWX POC Quick Start"

echo ""
print_info "Checking prerequisites..."
echo ""

# Check prerequisites
PREREQ_OK=true

if ! check_command vagrant; then
    print_warning "Install Vagrant from: https://www.vagrantup.com/downloads"
    PREREQ_OK=false
fi

if ! check_command virsh; then
    print_warning "Install libvirt: sudo apt install qemu-kvm libvirt-daemon-system (Ubuntu) or sudo dnf install qemu-kvm libvirt (RHEL)"
    PREREQ_OK=false
fi

# Check for vagrant-libvirt plugin
if ! vagrant plugin list | grep -q vagrant-libvirt; then
    print_warning "Install vagrant-libvirt plugin: vagrant plugin install vagrant-libvirt"
    PREREQ_OK=false
else
    print_success "vagrant-libvirt plugin is installed"
fi

if ! check_command ansible; then
    print_warning "Install Ansible: pip3 install ansible"
    PREREQ_OK=false
fi

if [ "$PREREQ_OK" = false ]; then
    echo ""
    print_error "Please install missing prerequisites and try again"
    exit 1
fi

echo ""
print_success "All prerequisites are installed!"

# Check system resources
echo ""
print_info "Checking system resources..."

TOTAL_MEM=$(free -g | awk '/^Mem:/{print $2}')
if [ "$TOTAL_MEM" -lt 12 ]; then
    print_warning "System has ${TOTAL_MEM}GB RAM. Recommended: 12GB+"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    print_success "System has ${TOTAL_MEM}GB RAM"
fi

# Install Ansible collections
echo ""
print_info "Installing required Ansible collections..."
ansible-galaxy collection install community.general --force > /dev/null 2>&1
ansible-galaxy collection install community.docker --force > /dev/null 2>&1
ansible-galaxy collection install community.crypto --force > /dev/null 2>&1
ansible-galaxy collection install ansible.posix --force > /dev/null 2>&1
print_success "Ansible collections installed"

# Start VMs
echo ""
print_header "Starting Virtual Machines"
echo ""
print_info "This will take 15-30 minutes on first run..."
echo ""

read -p "Start all VMs now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Starting AWX server..."
    vagrant up awx-server
    
    print_info "Starting client nodes..."
    vagrant up client-alma client-ubuntu client-centos
    
    print_success "All VMs are running!"
else
    print_info "Skipping VM startup. Run 'vagrant up' manually when ready."
    exit 0
fi

# Install AWX
echo ""
print_header "Installing AWX"
echo ""

read -p "Install AWX now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Installing AWX (this may take 10-15 minutes)..."
    ansible-playbook ansible/playbooks/awx-install.yml
    print_success "AWX installed!"
else
    print_info "Skipping AWX installation. Run manually:"
    echo "  ansible-playbook ansible/playbooks/awx-install.yml"
fi

# Configure AWX
echo ""
print_header "Configuring AWX"
echo ""

read -p "Configure AWX now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Configuring AWX..."
    ansible-playbook ansible/playbooks/awx-configure.yml
    print_success "AWX configured!"
else
    print_info "Skipping AWX configuration. Run manually:"
    echo "  ansible-playbook ansible/playbooks/awx-configure.yml"
fi

# Distribute SSH keys
echo ""
print_header "Distributing SSH Keys"
echo ""

read -p "Distribute AWX SSH keys to clients? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Distributing SSH keys..."
    ansible-playbook ansible/playbooks/distribute-awx-key.yml
    print_success "SSH keys distributed!"
else
    print_info "Skipping SSH key distribution. Run manually:"
    echo "  ansible-playbook ansible/playbooks/distribute-awx-key.yml"
fi

# Final summary
echo ""
print_header "Setup Complete!"
echo ""
print_success "AWX POC environment is ready!"
echo ""
print_info "Access AWX at: http://192.168.56.10"
print_info "Username: admin"
print_info "Password: AWXadmin123!"
echo ""
print_info "Next steps:"
echo "  1. Open http://192.168.56.10 in your browser"
echo "  2. Login with the credentials above"
echo "  3. Review the documentation in docs/"
echo "  4. Create job templates and run demos"
echo ""
print_info "Useful commands:"
echo "  vagrant status          - Check VM status"
echo "  vagrant ssh awx-server  - SSH into AWX server"
echo "  vagrant halt            - Stop all VMs"
echo "  vagrant destroy -f      - Remove all VMs"
echo ""
print_success "Happy automating!"