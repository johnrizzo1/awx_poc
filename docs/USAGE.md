# AWX POC Usage Guide

This guide explains how to use the AWX POC environment to demonstrate various AWX capabilities.

## Table of Contents

1. [Accessing AWX](#accessing-awx)
2. [Creating Projects](#creating-projects)
3. [Creating Job Templates](#creating-job-templates)
4. [Running Jobs](#running-jobs)
5. [Creating Workflows](#creating-workflows)
6. [Demo Scenarios](#demo-scenarios)

## Accessing AWX

### Web UI Access

1. Open your browser and navigate to: http://192.168.56.10
2. Login with credentials:
   - **Username**: admin
   - **Password**: AWXadmin123! (or your custom password)

### API Access

```bash
# Get authentication token
curl -X POST http://192.168.56.10/api/v2/tokens/ \
  -u admin:AWXadmin123! \
  -H "Content-Type: application/json"

# Use token for API calls
curl -H "Authorization: Bearer <token>" \
  http://192.168.56.10/api/v2/inventories/
```

## Creating Projects

Projects in AWX define where your playbooks are stored.

### Manual Project (Using Local Playbooks)

1. Navigate to **Resources** → **Projects**
2. Click **Add**
3. Fill in the details:
   - **Name**: Demo Playbooks
   - **Organization**: Demo Organization
   - **SCM Type**: Manual
   - **Playbook Directory**: demo-playbooks
4. Click **Save**

### Git-based Project (Optional)

1. Navigate to **Resources** → **Projects**
2. Click **Add**
3. Fill in the details:
   - **Name**: My Git Project
   - **Organization**: Demo Organization
   - **SCM Type**: Git
   - **SCM URL**: https://github.com/your-repo/playbooks.git
   - **SCM Branch/Tag/Commit**: main
4. Click **Save**

## Creating Job Templates

Job templates define how to run your playbooks.

### Example: System Update Template

1. Navigate to **Resources** → **Templates**
2. Click **Add** → **Job Template**
3. Configure:
   - **Name**: System Update
   - **Job Type**: Run
   - **Inventory**: POC Inventory
   - **Project**: Demo Playbooks
   - **Playbook**: system-update.yml
   - **Credentials**: SSH Credential
   - **Privilege Escalation**: ✓ Enable
4. Click **Save**

### Example: Install Package Template (with Survey)

1. Create job template as above with:
   - **Name**: Install Package
   - **Playbook**: install-package.yml
2. Click **Survey** tab
3. Click **Add**
4. Configure survey:
   - **Question**: Package Name
   - **Answer Variable Name**: package_name
   - **Answer Type**: Text
   - **Required**: ✓
5. Click **Save**

### Example: Service Management Template

1. Create job template:
   - **Name**: Manage Service
   - **Playbook**: manage-service.yml
2. Add survey questions:
   - **Service Name** (service_name)
   - **Service State** (service_state) - Multiple Choice: started, stopped, restarted
   - **Enable on Boot** (service_enabled) - Multiple Choice: true, false

### Example: File Deployment Template

1. Create job template:
   - **Name**: Deploy File
   - **Playbook**: deploy-file.yml
2. Add survey questions:
   - **File Path** (file_path)
   - **File Content** (file_content) - Textarea

### Example: Gather Facts Template

1. Create job template:
   - **Name**: Gather System Facts
   - **Playbook**: gather-facts.yml
   - **Verbosity**: 1 (Verbose)

## Running Jobs

### Run a Simple Job

1. Navigate to **Resources** → **Templates**
2. Click the **Launch** button (🚀) next to your template
3. If survey is enabled, fill in the required information
4. Click **Launch**
5. Monitor job execution in real-time

### Run with Limit

1. Launch a job template
2. In the **Limit** field, specify hosts:
   - Single host: `client-alma`
   - Multiple hosts: `client-alma,client-ubuntu`
   - Group: `rhel_family`
3. Click **Launch**

### Run with Extra Variables

1. Launch a job template
2. Enable **Extra Variables**
3. Add variables in YAML format:
   ```yaml
   package_name: nginx
   custom_var: value
   ```
4. Click **Launch**

### Schedule Jobs

1. Navigate to your job template
2. Click **Schedules** tab
3. Click **Add**
4. Configure:
   - **Name**: Daily Update
   - **Start Date/Time**: Select date and time
   - **Repeat Frequency**: Daily
   - **Time Zone**: America/New_York
5. Click **Save**

## Creating Workflows

Workflows allow you to chain multiple job templates together.

### Example: Complete System Maintenance Workflow

1. Navigate to **Resources** → **Templates**
2. Click **Add** → **Workflow Template**
3. Configure:
   - **Name**: System Maintenance Workflow
   - **Organization**: Demo Organization
   - **Inventory**: POC Inventory
4. Click **Save**
5. Click **Visualizer** to design workflow
6. Add nodes:
   - **Node 1**: Gather Facts (always)
   - **Node 2**: System Update (on success)
   - **Node 3**: Install Package (on success)
   - **Node 4**: Manage Service (on success)
7. Connect nodes with appropriate conditions
8. Click **Save**

### Workflow with Conditional Logic

```
[Gather Facts]
     ↓ (success)
[System Update]
     ↓ (success)
[Check Service Status]
     ├─ (success) → [Restart Service]
     └─ (failure) → [Install Service] → [Start Service]
```

## Demo Scenarios

### Scenario 1: Multi-OS Package Installation

**Objective**: Install nginx on all client nodes regardless of OS

1. Create/Use "Install Package" template
2. Launch with survey:
   - Package Name: `nginx`
3. Select all hosts or use `clients` group
4. Observe how the playbook handles different package managers

### Scenario 2: Service Management Across Fleet

**Objective**: Manage services across different operating systems

1. Use "Manage Service" template
2. Launch with survey:
   - Service Name: `sshd`
   - Service State: `restarted`
   - Enable on Boot: `true`
3. Run against all clients

### Scenario 3: Configuration Deployment

**Objective**: Deploy configuration files to specific hosts

1. Use "Deploy File" template
2. Launch with survey:
   - File Path: `/etc/motd`
   - File Content: "Welcome to AWX Managed System"
3. Run against specific hosts using limit

### Scenario 4: System Inventory Collection

**Objective**: Gather and compare system information

1. Use "Gather Facts" template
2. Run against all clients
3. Review output to see system differences
4. Export results for documentation

### Scenario 5: Scheduled Maintenance

**Objective**: Automate regular maintenance tasks

1. Create workflow: "Weekly Maintenance"
   - Gather Facts
   - System Update
   - Clean Package Cache
   - Restart if needed
2. Schedule for weekly execution
3. Configure notifications for completion/failure

### Scenario 6: Role-Based Access Demo

**Objective**: Demonstrate RBAC capabilities

1. Create new user: **Resources** → **Users** → **Add**
2. Create team: **Access** → **Teams** → **Add**
3. Assign user to team
4. Grant team permissions to specific templates
5. Login as new user and verify limited access

### Scenario 7: Credential Management

**Objective**: Show secure credential handling

1. Create new credential: **Resources** → **Credentials** → **Add**
2. Types to demonstrate:
   - Machine (SSH)
   - Vault
   - Cloud (AWS, Azure, etc.)
3. Use in job templates
4. Show credential encryption

### Scenario 8: Job Notifications

**Objective**: Configure job completion notifications

1. Create notification template: **Administration** → **Notifications** → **Add**
2. Configure:
   - Type: Email, Slack, Webhook, etc.
   - Recipients/URL
3. Attach to job template
4. Run job and verify notification

## Best Practices

### Job Template Organization

- Use clear, descriptive names
- Add detailed descriptions
- Use tags for categorization
- Enable surveys for user-friendly input
- Set appropriate timeouts

### Inventory Management

- Use groups for logical organization
- Set host variables for host-specific config
- Use group variables for shared settings
- Keep inventory synchronized

### Playbook Development

- Test playbooks locally first
- Use idempotent tasks
- Add proper error handling
- Include meaningful task names
- Use tags for selective execution

### Workflow Design

- Keep workflows simple and focused
- Use convergence nodes for parallel execution
- Add approval nodes for critical operations
- Document workflow purpose and logic
- Test all paths (success/failure)

## Monitoring and Troubleshooting

### View Job Output

1. Navigate to **Views** → **Jobs**
2. Click on a job to view details
3. Review:
   - Standard Output
   - Standard Error
   - Job Events
   - Host Events

### Check Job History

1. Navigate to **Views** → **Jobs**
2. Filter by:
   - Status (Successful, Failed, Running)
   - Job Template
   - Date Range
3. Export results for reporting

### Debug Failed Jobs

1. Review job output for errors
2. Check host connectivity
3. Verify credentials
4. Test playbook manually:
   ```bash
   vagrant ssh awx-server
   cd /var/lib/awx/projects/demo-playbooks
   ansible-playbook -i inventory system-update.yml -v
   ```

## Advanced Features

### Custom Execution Environments

Create custom container images with specific dependencies:

1. Build custom image with required collections
2. Push to container registry
3. Configure in AWX: **Administration** → **Execution Environments**
4. Use in job templates

### Dynamic Inventory

Configure dynamic inventory sources:

1. **Resources** → **Inventories** → Select inventory
2. **Sources** tab → **Add**
3. Configure source (AWS, Azure, VMware, etc.)
4. Sync inventory

### Job Slicing

For large inventories, enable job slicing:

1. Edit job template
2. Set **Job Slicing**: Number of slices
3. Jobs run in parallel across slices

## Next Steps

- Explore AWX API for automation
- Create custom playbooks for your use cases
- Integrate with CI/CD pipelines
- Configure external authentication (LDAP, SAML)
- Set up high availability (multiple AWX instances)

For troubleshooting, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)