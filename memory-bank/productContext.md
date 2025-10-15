# Product Context

This file provides a high-level overview of the project and the expected product that will be created. Initially it is based upon projectBrief.md (if provided) and all other available project-related information in the working directory. This file is intended to be updated as the project evolves, and should be used to inform all other modes of the project's goals and context.

2025-10-15 14:54:31 - Memory Bank initialized. Awaiting project information.

## Project Goal

*   Create a proof of concept (POC) for Ansible AWX using Vagrant and Ansible
*   Demonstrate AWX capabilities for managing multiple Linux distributions
*   Provide a local development/testing environment for AWX workflows

## Key Features

*   **Infrastructure as Code**: Vagrant-based VM provisioning
*   **Multi-OS Support**: Mixed client environment (AlmaLinux 9, Ubuntu, CentOS)
*   **Automated Configuration**: Ansible playbooks for complete setup
*   **AWX Server**: Full AWX installation on AlmaLinux 9
*   **Comprehensive Demo**: Showcase job templates, inventories, credentials, workflows, and other AWX features
*   **Service Management**: Demonstrate managing various services across different OS platforms

## Overall Architecture

### VM Infrastructure (4 VMs total)
1. **AWX Server** (awx-server)
   - OS: AlmaLinux 9
   - Role: AWX control plane
   - Services: AWX web UI, API, task execution

2. **Client Node 1** (client-alma)
   - OS: AlmaLinux 9
   - Role: Managed node for RHEL-family demonstrations

3. **Client Node 2** (client-ubuntu)
   - OS: Ubuntu 22.04 LTS
   - Role: Managed node for Debian-family demonstrations

4. **Client Node 3** (client-centos)
   - OS: CentOS Stream 9
   - Role: Managed node for additional RHEL-family demonstrations

### Technology Stack
- **Virtualization**: Vagrant with VirtualBox/libvirt provider
- **Configuration Management**: Ansible
- **AWX Installation**: AWX Operator (Kubernetes-based) or Docker Compose method
- **Networking**: Private network for VM communication
- **Version Control**: Git for infrastructure code

### Deployment Flow
```
Vagrant Up → VM Provisioning → Ansible Playbooks → AWX Installation → Client Configuration → AWX Setup → Demo Scenarios
```