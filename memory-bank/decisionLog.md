# Decision Log

This file records architectural and implementation decisions using a list format.

2025-10-15 14:54:57 - Memory Bank initialized.

## Decision

*   Initialized Memory Bank system for project context management

## Rationale 

*   Provides structured approach to maintaining project context across sessions
*   Enables better collaboration and knowledge transfer
*   Tracks decisions, progress, and patterns systematically

## Implementation Details

*   Created five core files: productContext.md, activeContext.md, progress.md, decisionLog.md, and systemPatterns.md
*   Each file serves a specific purpose in maintaining project knowledge

[2025-10-15 15:10:58] - Project Implementation Completed

## Decision

*   Completed full implementation of AWX POC infrastructure
*   Selected Docker Compose installation method for AWX
*   Implemented comprehensive automation and documentation

## Rationale

*   Docker Compose chosen over AWX Operator for:
  - Simpler setup and maintenance
  - Lower resource requirements
  - Faster deployment for POC purposes
  - Easier troubleshooting
*   Multi-OS client setup demonstrates AWX's cross-platform capabilities
*   Comprehensive documentation ensures easy adoption and troubleshooting

## Implementation Details

*   Infrastructure: Vagrant + VirtualBox + Ansible
*   4 VMs: 1 AWX server (AlmaLinux 9) + 3 clients (AlmaLinux, Ubuntu, CentOS)
*   Network: Private network 192.168.56.0/24
*   AWX Version: 24.6.1 via Docker Compose
*   Automation: Complete playbooks for setup, installation, and configuration
*   Documentation: Setup guide, usage guide, troubleshooting guide
*   Quick-start script for automated deployment

## Outcomes

*   Fully functional AWX POC environment
*   Ready for immediate deployment and testing
*   Demonstrates comprehensive AWX capabilities
*   Includes demo scenarios and workflows
*   Complete documentation for all use cases

[2025-10-15 15:19:30] - Switched from VirtualBox to libvirt

## Decision

*   Changed virtualization provider from VirtualBox to libvirt
*   Updated all Vagrantfile provider configurations
*   Updated documentation to reflect libvirt usage

## Rationale

*   User preference for libvirt over VirtualBox
*   libvirt is more commonly used in enterprise Linux environments
*   Better integration with KVM on Linux systems
*   More suitable for production-like environments

## Implementation Details

*   Updated Vagrantfile: Changed all provider blocks from "virtualbox" to "libvirt"
*   Removed VirtualBox-specific customizations (natdnshostresolver1, natdnsproxy1)
*   Updated memory/CPU settings to use libvirt syntax (integers instead of strings)
*   Updated README.md prerequisites section
*   Updated docs/SETUP.md with libvirt installation instructions
*   Updated docs/TROUBLESHOOTING.md with libvirt-specific troubleshooting
*   Updated quick-start.sh to check for libvirt and vagrant-libvirt plugin

## Impact

*   Users must install libvirt and vagrant-libvirt plugin instead of VirtualBox
*   All functionality remains the same
*   Better performance on Linux hosts with KVM

[2025-10-15 15:23:53] - Refactored Vagrantfile for Scalability

## Decision

*   Refactored Vagrantfile to use configuration-driven approach
*   Implemented iteration-based client VM creation
*   Consolidated provisioning into single site.yml playbook

## Rationale

*   Eliminates code duplication for similar VM definitions
*   Makes it trivial to scale the number of clients of each type
*   Simplifies maintenance - change configuration, not code
*   Single provisioning block ensures all VMs are configured together
*   More professional and maintainable infrastructure as code

## Implementation Details

*   Added CLIENTS configuration hash at top of Vagrantfile:
  - Defines count, box, and base_ip for each client type
  - Easy to modify for different scales
*   Added resource allocation variables (AWX_MEMORY, AWX_CPUS, etc.)
*   Implemented loop to create clients dynamically:
  - Iterates over client types
  - Creates specified count of each type
  - Automatically assigns sequential IP addresses
  - Generates unique VM names (e.g., client-alma-1, client-alma-2)
*   Created site.yml master playbook:
  - Orchestrates all provisioning in correct order
  - Runs AWX prerequisites
  - Configures all client nodes
  - Provides clear completion summary
*   Single provisioning block at end of Vagrantfile:
  - Runs after all VMs are created
  - Provisions all machines in one operation
  - Automatically configures Ansible groups

## Benefits

*   Scale from 3 to 30+ clients by changing a single number
*   Add new OS types by adding to CLIENTS hash
*   Consistent IP addressing scheme
*   Reduced Vagrantfile size and complexity
*   Easier to understand and modify
*   Professional infrastructure as code practices

[2025-10-15 16:59:45] - Automated Complete Provisioning

## Decision

*   Updated Vagrantfile to automatically run all provisioning steps in sequence
*   Single `vagrant up` command now fully provisions entire AWX environment
*   Maintained modular playbook structure for flexibility

## Rationale

*   User experience: One command to complete setup
*   Eliminates manual steps and potential errors
*   Still allows running individual provisioning steps if needed
*   Keeps playbooks modular and maintainable
*   Better than creating a monolithic playbook

## Implementation Details

*   Added four named provisioners in Vagrantfile:
  1. "setup" - Runs site.yml (prerequisites and clients)
  2. "awx_install" - Runs awx-install.yml
  3. "awx_configure" - Runs awx-configure.yml
  4. "distribute_keys" - Runs distribute-awx-key.yml
*   Provisioners run in sequence automatically
*   Each can be run individually: `vagrant provision --provision-with <name>`
*   Updated README.md with new workflow

## Benefits

*   Complete automation: `vagrant up` does everything
*   Predictable: Always runs in correct order
*   Flexible: Can still run steps individually
*   Maintainable: Playbooks remain separate and reusable
*   User-friendly: No manual intervention required

[2025-10-15 19:08:35] - SSH Key Management Strategy Change

## Decision

*   Changed from generating new SSH keys to using Vagrant's insecure keys
*   Copy Vagrant's existing SSH key pair to root user on AWX server
*   Use these keys for AWX to manage client nodes

## Rationale

*   **Simplicity**: Vagrant already provisions all VMs with the same insecure key
*   **Reliability**: No dependency on community.crypto collection
*   **POC-appropriate**: Insecure keys are acceptable for POC/testing environments
*   **Guaranteed to work**: Keys are already in place and trusted
*   **Less complexity**: No key generation or distribution issues

## Implementation Details

*   Copy `/home/vagrant/.ssh/id_rsa` to `/root/.ssh/awx_rsa` on AWX server
*   Copy `/home/vagrant/.ssh/id_rsa.pub` to `/root/.ssh/awx_rsa.pub` on AWX server
*   Vagrant public key already exists in authorized_keys on all clients
*   Added verification step to check key exists before distribution
*   Added better error handling and SSH connection testing

## Benefits

*   No external dependencies (community.crypto collection)
*   Works immediately without key generation delays
*   Consistent with Vagrant's security model for POC environments
*   Simpler troubleshooting - keys are predictable
*   Faster provisioning - no key generation step

## Security Note

*   Vagrant insecure keys are publicly known and should NEVER be used in production
*   This approach is ONLY suitable for POC/development/testing environments
*   Production deployments should generate unique SSH keys

[2025-10-15 19:14:57] - Disabled VM-based AWX Installation

## Decision

*   Commented out all AWX installation and configuration provisioners in Vagrantfile
*   Disabled: awx_install, awx_configure, and distribute_keys provisioners
*   Kept only the "setup" provisioner for client VM configuration

## Rationale

*   User deployed AWX in a separate Kubernetes cluster
*   VM-based AWX installation no longer needed
*   Client VMs still need to be provisioned and configured
*   AWX server VM can be repurposed or removed in future

## Implementation Details

*   Commented out lines 98-120 in Vagrantfile
*   Added clear comments indicating AWX is deployed in Kubernetes
*   Provisioners can be easily re-enabled if needed
*   Client provisioning (site.yml) remains active

## Current State

*   `vagrant up` will now only:
  1. Create all VMs (awx-server + 3 clients)
  2. Run site.yml to configure prerequisites and clients
  3. Skip AWX installation, configuration, and key distribution

## Future Considerations

*   May need to create new playbook to configure clients for Kubernetes-based AWX
*   SSH key distribution will need to be handled differently
*   AWX server VM could be removed or repurposed for other services