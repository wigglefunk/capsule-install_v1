# Satellite Configuration Export / Import — Project Primer

## Objective
Create a baseline post configuration for Satellite 6.17 using ansible and AAP. The credentials for all requirements are in AAP and injected a runtime.
Favor the use the redhat.satellite collection, but also use the Satellite 6.17 API, or hammer commands for building standard setups for:
creating organization(s) : the names will vary. Could be a single, could be a list
creating lifecycle environment(s) : variable for certain. For this effort it will only be one other following library
enabling a standard bunch of repository_sets: for this testing effort, it will be rhel 8 and rhel 9 repository sets.
create a weekly sync plan and add the enabled repositories to the sync plan.Randomize the sync day and time. exclude Saturday,Sunday,Monday. Randomize the start time between 9AM and 9:45PM EST
creating a base content view: variable for the name and the repositories to be added to the content view
add repositories
publish the content view
promote the content view
create a base activation key for that content view
You are to generate a full Ansible project (playbooks, roles, AAP job templates, folder layout, variable structure, and README) that implements a **configuration-level export → normalization → import** flow for Red Hat Satellite 6.17. This project will later be used in both a connected network (for testing) and a disconnected/closed network.

You must ensure that:

- All references to Satellite entities (repositories, content views, lifecycle environments, etc.) are **name-based**, not reliant on numeric IDs (because IDs differ across installations).
- The project uses the `redhat.satellite` Ansible collection for interacting with the Satellite API.
- The project is compatible with AAP (Ansible Automation Platform) and can be wired into workflows and credentials.
- The design supports injecting credentials (username / password) via AAP credentials, not hard-coded.
- Variables allow specifying **source Satellite** (from which to export) and **target Satellite** (to which to import) without relying on inventory groups.
- The process is modular: export-playbook, normalization-role, import-playbook (and potential extensions).
- The README documents how to wire this in AAP (job templates, workflow).

You should include in the primer a reference to the relevant module sets and documentation so that the LLM or implementer knows what modules exist and how to use them.

---

## References & Useful Documentation

- Red Hat Satellite Ansible Collection — official documentation / module set and module names  
  → *Red Hat Satellite Ansible Collection* catalog documentation  
  → *Managing Satellite with Ansible Collections* in the Satellite admin guide (6.17)   

- The Foreman / Katello (theforeman.foreman) Ansible collection (stronger examples, analogous modules)  
  → *TheForeman.Foreman collection doc* (repository, repository_set, repository_info, etc.)  
  → *Foreman Ansible Modules README / module list*  

- Changelog of `redhat.satellite` collection (noting that modules were renamed to remove `foreman_*` or `katello_*` prefixes)   

These references help the agent or AI know available module names and usage patterns.

---

## High-Level Workflow / Architecture

1. **Export Playbook**  
   - Connect to **source Satellite** (API)  
   - Fetch PER Organization (using `*_info` modules) the list of:
     - repository sets  
     - lifecycle environments  
     - content views  
     - (optionally others—e.g. content view filters, global parameters, activation keys)  
   - Write raw export data (with full data including IDs) into a YAML file (`exported_raw.yml`).

2. **Normalization Role**  
   - Input: `exported_raw.yml`  
   - Output: `normalized_config.yml` — a name-based representation with:
     - repository sets expressed as `{ product_name, repo_set_name, basearch, releasever }`, no IDs  
     - lifecycle environments as `{ name, prior_name }`  
     - content views as `{ name, description, list_of_repo_set_names }`  
   - (Optionally: include other entities similarly normalized).

3. **Import Playbook**  
   - Input: `normalized_config.yml`  
   - Connect to **target Satellite** (API)  
   - Steps:
     a. Create / enable repository sets (by name + product)  
     b. Create lifecycle environments (by name + prior name)  
     c. Resolve repository-set names to numeric IDs via `redhat.satellite.repository_info` on target  
     d. Create content views (by name, with repository IDs)  
     e. (Optionally: further tasks — publish, promote, filters, activation keys, etc.)

4. **AAP Integration**  
   - Project uses credential injection for Satellite username/password, passed as `app_username` and `app_password`  
   - Variables to define:
     - `satellite_source_url`, `satellite_target_url`  
     - `satellite_org`  
   - AAP Job Templates:
     - Export  
     - Normalize  
     - Import  
   - Workflow Template chaining the three in sequence

5. **README + Documentation**  
   - How to bootstrap the project in AAP  
   - How to run export / normalize / import manually  
   - Notes about disconnected environments (package sync, content export/import)  
   - Extension points

---

## Detailed Prompt Instructions (for the agent)

When you (the AI or agent) see this primer, you should:

1. Generate a **directory tree layout** (playbooks/, roles/, vars/, README.md, etc.).
2. Create `vars/common.yml` capturing AAP-injected credentials and Satellite URLs.
3. Write **export_satellite_config.yml** (playbook) using `redhat.satellite.*_info` modules to fetch data.
4. Create a **role** `normalize_satellite_export` with `tasks/main.yml` and a Jinja template to transform raw data to name-based normalized structure.
5. Write **import_satellite_config.yml** (playbook) that:
   - Uses normalized structure
   - Ensures repository sets exist using `redhat.satellite.repository_set`
   - Ensures lifecycle environments using `redhat.satellite.lifecycle_environment`
   - Looks up repo-set IDs via `redhat.satellite.repository_info`
   - Builds a name→ID map
   - Creates content views via `redhat.satellite.content_view` using the resolved IDs
6. Generate a **README.md** explaining:
   - Purpose  
   - Prerequisites (installing `redhat.satellite` collection, version compatibility)  
   - Step-by-step instructions for using AAP:
     1. Upload project to source control accessible to AAP  
     2. Create AAP credentials (`app_username` / `app_password`)  
     3. Create three Job Templates (Export, Normalize, Import)  
     4. Create a Workflow template chaining Export → Normalize → Import  
   - How to test on a live network before using in disconnected zone  
   - Caveats (e.g. only configuration is migrated, not package content; addressing content sync separately)

7. Optionally, you can include stub tasks for extension (e.g. content view publish, promotion, content export/import) with comments “TO DO”.

8. Use module names from `redhat.satellite` (per official collection) and reference that they originally map to certain `theforeman.foreman` modules before prefix change.  
   - For example, mention the mapping: `theforeman.foreman.repository_set` → `redhat.satellite.repository_set` after renaming. Use the changelog note as guidance. :contentReference[oaicite:5]{index=5}  
   - Also mention you can consult the Foreman collection docs for examples: e.g. `theforeman.foreman.repository_set_info`, `theforeman.foreman.repository_info` etc. :contentReference[oaicite:6]{index=6}  

9. Provide direct links (in the primer) for implementers to consult:
   - The Foreman / Katello Ansible collection docs: https://docs.ansible.com/ansible/latest/collections/theforeman/foreman/index.html :contentReference[oaicite:7]{index=7}  
   - Red Hat Satellite Ansible Collection docs: https://catalog.redhat.com/en/software/collection/redhat/satellite#documentation :contentReference[oaicite:8]{index=8}  

10. Produce output in valid YAML / Jinja syntax and structure so it can be used directly in AAP.  

---

## Additional Notes & Considerations

- The `redhat.satellite` collection must be installed on the control system (or AAP environment) — e.g. via `ansible-galaxy collection install redhat.satellite` or via RPM on Satellite itself. :contentReference[oaicite:9]{index=9}  
- The modules in `redhat.satellite` correspond to formerly named Foreman/Katello modules with prefix removal. See changelog notes. :contentReference[oaicite:10]{index=10}  
- Because `theforeman.foreman` collection has richer examples and documentation, you may draw analogies from it (e.g. `theforeman.foreman.repository_set`, `repository_info`, `repository_set_info`). :contentReference[oaicite:11]{index=11}  
- The primer should command the agent to use **name resolution** (lookups) on target rather than carrying over IDs.  
- The project should be version-controllable, idempotent, and modular.  

---
Example of our cohesive group_vars that are used in many Ansible based Satellite projects.This is for style an usage reference it is not an edict, but it is noted with items that are constants:
---
# Default Group Variables for Capsule Installation
# Development Environment Configuration
# These variables are reused from satellite-install project where applicable

# ============================================================================
# SATELLITE CONFIGURATION (Reused from satellite-install)
# ============================================================================

# Satellite Server Configuration
sat_version: "6.17"
satellite_fqdn: "devsatellite.example.com"  # constant variable
satellite_shortname: "devsatellite"         # constant variable
satellite_server_url: "https://{{ satellite_fqdn }}"  # constant variable

# Credentials (from AAP - standard across ALL environments)
# These are used for ALL redhat.satellite collection authentication
satellite_setup_username: "{{ app_username }}"     # From AAP credential # constant variable and value
satellite_initial_admin_password: "{{ app_password }}"  # From AAP credential # constant variable and value

# Organization and Location
satellite_org: "EO_ITRA"
satellite_location: "default_location"
itra_default_env: "EO_ITRA_ALL"
capsule_download_policy: "on_demand"  # Capsule content download policy
# Python interpreter (ensure consistency)
ansible_python_interpreter: /usr/bin/python3

# ============================================================================
# CAPSULE CONFIGURATION
# ============================================================================

# Capsule version (future-proofing)
cap_version: "6.17"

# Hosts that are Capsules (exact FQDNs)
capsule_fqdns:
  - devcapsule.example.com

# Load Balancer Configuration
# List which Capsules will be behind a load balancer (if any)
loadbalanced_capsules: []

# The load balancer FQDN (only required if loadbalanced_capsules has entries)
capsule_loadbalancer_fqdn: ""

# ============================================================================
# CAPSULE REGISTRATION SETTINGS
# ============================================================================

# Activation key for Capsule registration
# This key must exist in Satellite with appropriate content view
capsule_activation_key: "satellite-infrastructure" # constant

# Registration options
capsule_force_registration: true        # Override existing registration
capsule_enable_remote_execution: true   # Always enable remote execution
capsule_setup_insights: false          # Never enable insights

# Registration command timeout
registration_timeout: 300  # 5 minutes

# ============================================================================
# REPOSITORY CONFIGURATION
# ============================================================================

# Capsule-specific repositories to enable after registration
# Using cap_version for future-proofing
capsule_repos_to_enable:   # constant
  - "rhel-{{ rhel_major_version }}-for-x86_64-baseos-rpms"
  - "rhel-{{ rhel_major_version }}-for-x86_64-appstream-rpms"
  - "satellite-capsule-{{ cap_version }}-for-rhel-{{ rhel_major_version }}-x86_64-rpms"
  - "satellite-maintenance-{{ cap_version }}-for-rhel-{{ rhel_major_version }}-x86_64-rpms"

# ============================================================================
# INSTALLATION SETTINGS
# ============================================================================

# Installation control
capsule_installer_timeout: 3600        # 1 hour for installer to complete
capsule_service_start_timeout: 300     # 5 minutes for services to start
force_reinstall: false                  # Skip if already installed unless true

# Certificate and instruction file paths (from satellite-install distribution)
capsule_cert_base_path: "/root/capsule_cert" 

# ============================================================================
# SYSTEM CONFIGURATION
# ============================================================================

# DNS Configuration
validate_dns: true  # constant variable and value
dns_timeout: 20     # constant variable and value

# Package cleanup
remove_katello_ca_consumer: true  # Clean old katello packages before registration

# Verification settings
verify_capsule_after_install: true
capsule_health_check_retries: 3
capsule_health_check_delay: 30

# ============================================================================
# PACKAGE REQUIREMENTS
# ============================================================================

# Required packages for Capsule operation
capsule_required_packages:
  - satellite-capsule
  - chrony
  - sos
  - tmux
  - bash-completion
  - tree
  - yum-utils
  - dnf-utils

# ============================================================================
# DEBUG AND LOGGING
# ============================================================================

# Debug output control
capsule_debug_output: true
save_installation_logs: true
installation_log_path: "/var/log/capsule-installation"

# ============================================================================
# NOTES
# ============================================================================
# - All Capsules have direct network access to Satellite (no proxy for registration)
# - The activation key must exist and be properly configured before running
# - Certificate files must be distributed by satellite-install project
# - Storage volumes should already be configured from satellite-install project