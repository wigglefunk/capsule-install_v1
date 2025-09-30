# Capsule Installation Automation

This project automates the installation of Red Hat Satellite 6.17 Capsule servers.

## Overview

This automation picks up where the satellite-install project leaves off, using the certificate tarballs and installation instructions that were generated and distributed to install Capsule servers.

The automation handles:
- Capsule registration to Satellite using activation keys
- Repository configuration
- Certificate-based installation
- Both standard and load-balanced Capsule configurations
- Complete verification and health checks

## Prerequisites

### Infrastructure Requirements
- RHEL 9.x servers provisioned for Capsules
- Certificate files distributed by satellite-install project:
  - `/root/capsule_cert/<capsule_fqdn>-certs.tar`
  - `/root/capsule_cert/<capsule_fqdn>-install.txt`
- Storage volumes configured (from satellite-install project)
- Direct network connectivity to Satellite server (no proxy)

### Satellite Configuration
- Activation key `satellite-infrastructure` must exist in Satellite
- Activation key must be associated with appropriate content view
- Required Capsule repositories synchronized in Satellite:
  - RHEL 9 BaseOS
  - RHEL 9 AppStream
  - Satellite Capsule 6.17
  - Satellite Maintenance 6.17

### Ansible Automation Platform
- AAP 2.x configured
- Required collections installed (see `collections/requirements.yml`)
- Credentials configured:
  - `app_username` - Satellite admin username
  - `app_password` - Satellite admin password

### Controller Requirements
- **Hammer CLI** must be installed and configured
- Hammer credentials pre-configured in `/root/.hammer/cli.modules.d/foreman.yml`
- Root access required for Hammer commands

## Project Structure

```
capsule-install/
├── capsule-install.yml          # Development environment
├── capsule-install-test.yml     # Test environment
├── capsule-install-prod.yml     # Production environment
├── capsule-install-ead.yml      # EAD environment
├── group_vars/
│   ├── all.yml                  # Default (dev) variables
│   ├── test_env.yml             # Test environment
│   ├── prod_env.yml             # Production environment
│   └── ead_env.yml              # EAD environment
├── roles/
│   ├── prep_capsule_registration/    # Clean existing registrations
│   ├── register_capsule/             # Register to Satellite
│   ├── configure_capsule_repos/      # Enable repositories
│   ├── parse_install_instructions/   # Extract installer command
│   └── install_capsule/              # Execute installation
└── collections/
    └── requirements.yml
```

## Usage

### Quick Start

1. **Verify Prerequisites**
   ```bash
   # Test Hammer CLI
   sudo hammer ping
   sudo hammer capsule list
   
   # Verify certificate files exist
   ls -la /root/capsule_cert/
   ```

2. **Run for Development Environment**
   ```bash
   ansible-playbook capsule-install.yml \
     --limit devcapsule.example.com
   ```

3. **Run for Other Environments**
   ```bash
   # Test
   ansible-playbook capsule-install-test.yml \
     --limit testcapsule.example.com
   
   # Production (always check mode first!)
   ansible-playbook capsule-install-prod.yml \
     --limit prodcapsule.example.com \
     --check
   ```

### Configuration

Key variables in `group_vars/all.yml`:

```yaml
# Satellite Configuration
satellite_version: "6.17"
satellite_fqdn: "satellite.example.com"
satellite_org: "EO_ITRA"
satellite_location: "default_location"

# Capsule Lists
capsule_fqdns:
  - devcapsule.example.com

# Load-balanced Capsules (optional)
loadbalanced_capsules: []
capsule_loadbalancer_fqdn: ""

# Registration
capsule_activation_key: "satellite-infrastructure"
capsule_enable_remote_execution: true
capsule_setup_insights: false
```

## Automation Workflow

### Phase 1: Pre-Registration Cleanup
**Role:** `prep_capsule_registration`
- Removes existing katello-ca-consumer packages
- Cleans subscription-manager state
- Ensures clean state for registration

### Phase 2: Capsule Registration
**Role:** `register_capsule`
- Generates registration command using `redhat.satellite.registration_command`
- Registers Capsule to Satellite using activation key
- Verifies registration with `hammer host info`
- Confirms connectivity to Satellite API

### Phase 3: Repository Configuration
**Role:** `configure_capsule_repos`
- Disables all repositories
- Enables only required Capsule repositories
- Verifies package availability

### Phase 4: Parse Installation Instructions
**Role:** `parse_install_instructions`
- Reads installation instruction file
- Extracts `satellite-installer` command
- Appends load-balancer options if needed
- Prepares final installation command

### Phase 5: Capsule Installation
**Role:** `install_capsule`
- Executes `satellite-installer` with proper parameters
- Monitors installation progress (30-60 minutes)
- Verifies services start correctly:
  - foreman-proxy
  - httpd
  - pulpcore-api
  - pulpcore-content
- Confirms Capsule appears in Satellite using `hammer capsule info`
- Tests Capsule API endpoint

## Load Balancer Support

The automation supports Capsules behind a load balancer:

```yaml
# In group_vars
capsule_fqdns:
  - prodcapsule1.example.com
  - prodcapsule2.example.com

loadbalanced_capsules:
  - prodcapsule1.example.com
  - prodcapsule2.example.com

capsule_loadbalancer_fqdn: "capsule.loadbalancer.com"
```

**Important:** Load-balanced Capsules require custom SSL certificates with:
- Capsule FQDN as CN or in SAN
- Load balancer FQDN in SAN (Subject Alternative Name)

## Verification

### Post-Installation Checks

The automation automatically verifies:
- ✅ All Capsule services are running
- ✅ Capsule is registered in Satellite
- ✅ Capsule API responds on port 9090
- ✅ Host is properly registered

### Manual Verification

```bash
# On controller (as root)
sudo hammer capsule list
sudo hammer capsule info --name "capsule.example.com"

# On Capsule server
systemctl status foreman-proxy
systemctl status httpd
subscription-manager identity
```

## Idempotency

The playbooks are fully idempotent and can be safely re-run:
- Existing registrations are detected and preserved
- Services already running are left as-is
- Installation steps are skipped if already completed

## Troubleshooting

### Common Issues

**Issue:** Hammer command not found
```bash
# Solution: Install Hammer CLI
dnf install -y rubygem-hammer_cli rubygem-hammer_cli_foreman
```

**Issue:** Authentication failed
```bash
# Solution: Verify Hammer configuration
sudo cat /root/.hammer/cli.modules.d/foreman.yml
sudo hammer ping
```

**Issue:** Certificate files not found
```bash
# Solution: Verify files were distributed
ls -la /root/capsule_cert/
# Should contain: <fqdn>-certs.tar and <fqdn>-install.txt
```

**Issue:** Capsule not appearing in Satellite
```bash
# Solution: Check Satellite connectivity and wait longer
sudo hammer capsule list
# Installation takes 30-60 minutes
```

### Debug Mode

Enable verbose output:
```yaml
# In group_vars/all.yml
capsule_debug_output: true
save_installation_logs: true
```

Logs are saved to: `/var/log/capsule-installation/`

## Technical Details

### Hammer CLI Configuration

This automation uses pre-configured Hammer CLI:
- **No username/password parameters needed** in commands
- **Root access required** (`become: true`)
- **Runs on controller** (`delegate_to: localhost`)

Example:
```yaml
# Correct pattern for this environment
- name: Get Capsule info
  ansible.builtin.command: hammer capsule info --name "{{ name }}"
  become: true
  delegate_to: localhost
```

### Authentication Patterns

**Satellite API calls:**
```yaml
ansible.builtin.uri:
  url: "{{ satellite_server_url }}/api/status"
  user: "{{ satellite_setup_username }}"
  password: "{{ satellite_initial_admin_password }}"
  force_basic_auth: true
```

**Capsule public API (no auth):**
```yaml
ansible.builtin.uri:
  url: "https://{{ capsule_fqdn }}:9090/features"
  # No authentication needed
```

### Module Defaults

All playbooks use module defaults for `redhat.satellite` collection:
```yaml
module_defaults:
  group/redhat.satellite.satellite:
    server_url: "{{ satellite_server_url }}"
    username: "{{ satellite_setup_username }}"
    password: "{{ satellite_initial_admin_password }}"
    validate_certs: false
```

## Documentation

- `capsule_install_primer.md` - Detailed project specifications
- `CORRECTIONS_SUMMARY.md` - All corrections applied to code
- `HAMMER_CONFIGURATION_NOTES.md` - Hammer CLI usage guide
- `URI_AUTHENTICATION_FIX.md` - Authentication requirements
- `VERIFICATION_COMMANDS_REFERENCE.md` - Testing commands
- `FINAL_IMPLEMENTATION_GUIDE.md` - Complete deployment guide

## Requirements

### Ansible Collections
```yaml
collections:
  - name: redhat.satellite
    version: ">=3.0.0"
  - name: community.general
    version: ">=6.0.0"
```

### Python Requirements
- Python 3.9+
- requests
- PyYAML

## Support

For issues or questions:
1. Check troubleshooting section above
2. Review logs in `/var/log/capsule-installation/`
3. Verify all prerequisites are met
4. Check Hammer CLI configuration

## License

Internal use only - Red Hat Satellite 6.17 automation

---

**Note:** This automation requires a functioning Satellite server with the satellite-install project completed first.