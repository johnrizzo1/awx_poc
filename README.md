# AWX Proof of Concept

A comprehensive proof of concept for Ansible AWX using Vagrant and Ansible, demonstrating AWX capabilities across multiple Linux distributions.

## Overview

This project provisions a complete AWX environment with:
- 1 AWX Server (AlmaLinux 9)
- 3 Client Nodes (AlmaLinux 9, Ubuntu 22.04, CentOS Stream 9)

All infrastructure is provisioned via Vagrant and configured using Ansible playbooks.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Vagrant Environment                   │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────┐                                       │
│  │  AWX Server  │                                       │
│  │ AlmaLinux 9  │                                       │
│  │ 192.168.56.10│                                       │
│  └──────┬───────┘                                       │
│         │                                                │
│         ├──────────┬──────────────┬──────────────┐     │
│         │          │              │              │     │
│  ┌──────▼─────┐ ┌─▼──────────┐ ┌─▼──────────┐  │     │
│  │  Client 1  │ │  Client 2  │ │  Client 3  │  │     │
│  │ AlmaLinux 9│ │ Ubuntu 22  │ │ CentOS 9   │  │     │
│  │192.168.56.11│ │192.168.56.12│ │192.168.56.13│ │     │
│  └────────────┘ └────────────┘ └────────────┘  │     │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Prerequisites

- [Vagrant](https://www.vagrantup.com/) >= 2.3.0
- [libvirt](https://libvirt.org/) and vagrant-libvirt plugin
- [Ansible](https://www.ansible.com/) >= 2.14
- Minimum 12GB RAM available for VMs
- Minimum 40GB disk space

## Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd awx_poc

# Start the environment (provisions all VMs automatically)
vagrant up

# Access AWX Web UI
# URL: http://192.168.56.10
# Default credentials will be displayed after provisioning
```

## Scaling Client Nodes

The Vagrantfile is designed for easy scaling. Edit the `CLIENTS` configuration at the top of the Vagrantfile:

```ruby
CLIENTS = {
  "alma" => {
    count: 2,              # Change to create 2 AlmaLinux clients
    box: "almalinux/9",
    base_ip: "192.168.56.11"
  },
  "ubuntu" => {
    count: 3,              # Change to create 3 Ubuntu clients
    box: "ubuntu/jammy64",
    base_ip: "192.168.56.21"
  },
  "centos" => {
    count: 1,              # Keep 1 CentOS client
    box: "centos/stream9",
    base_ip: "192.168.56.31"
  }
}
```

This will automatically:
- Create the specified number of each client type
- Assign sequential IP addresses
- Configure Ansible inventory groups
- Provision all nodes with a single `vagrant up`

## Project Structure

```
awx_poc/
├── Vagrantfile                 # VM definitions
├── ansible/
│   ├── inventory/
│   │   ├── hosts.yml          # Ansible inventory
│   │   └── group_vars/        # Group variables
│   ├── playbooks/
│   │   ├── awx-prerequisites.yml
│   │   ├── awx-install.yml
│   │   ├── clients-setup.yml
│   │   └── awx-configure.yml
│   ├── roles/                 # Ansible roles
│   └── ansible.cfg            # Ansible configuration
├── docs/
│   ├── SETUP.md              # Detailed setup guide
│   ├── USAGE.md              # Usage instructions
│   └── TROUBLESHOOTING.md    # Common issues
└── README.md                 # This file
```

## VM Specifications

### Default Configuration

| VM Name      | OS              | IP Address     | RAM  | CPU | Purpose        |
|--------------|-----------------|----------------|------|-----|----------------|
| awx-server   | AlmaLinux 9     | 192.168.56.10  | 4GB  | 2   | AWX Control    |
| client-alma  | AlmaLinux 9     | 192.168.56.11+ | 1GB  | 1   | Managed Node   |
| client-ubuntu| Ubuntu 22.04    | 192.168.56.21+ | 1GB  | 1   | Managed Node   |
| client-centos| CentOS Stream 9 | 192.168.56.31+ | 1GB  | 1   | Managed Node   |

**Note**: IP addresses increment for multiple clients of the same type (e.g., 192.168.56.11, 192.168.56.12, etc.)

### Resource Customization

Edit these variables in the Vagrantfile to adjust resources:

```ruby
AWX_MEMORY = 4096      # AWX server RAM in MB
AWX_CPUS = 2           # AWX server CPU cores
CLIENT_MEMORY = 1024   # Client RAM in MB
CLIENT_CPUS = 1        # Client CPU cores
```

## Features Demonstrated

- ✅ Multi-OS inventory management
- ✅ Job templates for common tasks
- ✅ Credential management
- ✅ Workflow templates
- ✅ Role-based access control
- ✅ Survey-based job execution
- ✅ Scheduled jobs
- ✅ Notifications and logging

## Documentation

- [Setup Guide](docs/SETUP.md) - Detailed installation and configuration
- [Usage Guide](docs/USAGE.md) - How to use the AWX POC
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions

## License

MIT License - See LICENSE file for details