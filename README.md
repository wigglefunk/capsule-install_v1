# Red Hat Satellite Capsule Installation Automation

## What This Project Does

This automation installs Red Hat Satellite Capsule servers by picking up where the satellite-install project leaves off. Think of it as the second half of a two-step process: the satellite-install project creates certificates and installation instructions, and this project uses those files to actually install the Capsules.

## Why This Automation Exists

Installing Capsule servers manually is tedious and error-prone. You need to:
- Register each server to Satellite
- Enable the correct repositories
- Parse complex installation commands
- Handle load-balanced configurations differently
- Verify everything works

This automation handles all of that consistently across development, test, and production environments.

## Prerequisites - What You Need Before Starting

### Files That Must Already Exist

The satellite-install project should have already created these files on each Capsule server:

```bash
/root/capsule_cert/capsule.example.com-certs.tar        # Certificate bundle
/root/capsule_cert/capsule.example.com-install.txt      # Installation command with OAuth keys
```

**Why these files matter:** The certificate file proves to Satellite that this is a legitimate Capsule, and the install.txt file contains the exact command (with security tokens) needed to connect this Capsule to your specific Satellite server.

### Satellite Configuration

Your Satellite server must have an activation key called `satellite-infrastructure` that:
- Points to a Content View with Capsule repositories
- Belongs to your organization (usually "EO_ITRA")
- Has the correct subscriptions attached

**Why we need this:** Activation keys are like pre-configured profiles. Instead of manually subscribing each Capsule, the activation key automatically applies the correct subscriptions and repository access.

### Infrastructure Requirements

- **RHEL 9.x servers** (freshly installed)
- **Direct network connection** from Capsule to Satellite (no proxy between them)
- **DNS working** for all server names
- **Storage already configured** (done by satellite-install project)

**Why direct network access:** Capsules talk to Satellite frequently to sync content and report status. A proxy between them adds complexity and potential failure points.

### Ansible Automation Platform (AAP) Setup

You need AAP configured with:
- **Collections installed:** `redhat.satellite` (v3.0.0+) and `community.general` (v6.0.0+)
- **Credentials configured:**
  - `app_username` - Satellite admin username
  - `app_password` - Satellite admin password

**Why AAP:** AAP provides credential management, job scheduling, and audit trails. The credentials are injected at runtime so they never appear in code.

## How the Automation Works - Step by Step

When you run this automation, here's what happens in order:

### Step 1: Host Classification (Pre-Tasks)

**What happens:**
- Ansible gathers basic facts about the server (OS version, hostname, etc.)
- Sets `rhel_major_version` from those facts (needed for repository names)
- Checks if this server is in the `capsule_fqdns` list
- Checks if it's in the `loadbalanced_capsules` list

**Why this matters:** Not every server in your inventory should be treated as a Capsule. This classification ensures the automation only runs on servers that are supposed to be Capsules, and handles load-balanced ones differently.

### Step 2: Pre-Registration Cleanup (`prep_capsule_registration`)

**What happens:**
- Checks if the server is already registered somewhere
- If yes, unregisters it cleanly
- Removes old `katello-ca-consumer` packages (from previous Satellite versions)
- Cleans the subscription-manager cache

**Why this is necessary:** Leftover registrations cause confusion. If a server is still registered to an old Satellite (or Red Hat CDN), the new registration will fail. Starting with a clean slate prevents hours of troubleshooting mysterious registration errors.

### Step 3: Capsule Registration (`register_capsule`)

**What happens:**
- Tests network connectivity to Satellite's API
- Uses the `redhat.satellite.registration_command` module to generate a registration command
- Executes that command to register the Capsule to Satellite
- Verifies registration succeeded using `subscription-manager identity`
- Confirms the host appears in Satellite using Hammer CLI

**Why we use the Satellite collection:** The `redhat.satellite` collection knows how to properly format registration commands for Satellite 6.17. It handles OAuth tokens, activation keys, and all the security parameters automatically. Doing this manually would require knowing dozens of command-line options.

**Why we verify twice:** First we check locally (subscription-manager) that the Capsule thinks it's registered. Then we check remotely (Hammer CLI on Satellite) that Satellite agrees. Both must succeed for registration to be valid.

### Step 4: Repository Configuration (`configure_capsule_repos`)

**What happens:**
- Disables ALL repositories (`subscription-manager repos --disable="*"`)
- Enables only the four repositories needed for Capsule:
  - RHEL BaseOS (operating system packages)
  - RHEL AppStream (application packages)
  - Satellite Capsule (the actual Capsule software)
  - Satellite Maintenance (update and maintenance tools)
- Verifies the `satellite-capsule` package is available

**Why disable everything first:** Servers often have dozens of repositories enabled by default. Extra repositories slow down package operations and can cause conflicts. We want only what's needed.

**Why we verify package availability:** If the repositories are enabled but the package isn't available, something is wrong with the Satellite's content (maybe the repos aren't synced). Catching this now saves time later.

### Step 5: Parse Installation Instructions (`parse_install_instructions`)

**What happens:**
- Reads the `/root/capsule_cert/capsule.example.com-install.txt` file
- Extracts the `satellite-installer` command from it
- If this is a load-balanced Capsule, appends special parameters:
  - `--certs-cname "loadbalancer.example.com"`
  - `--enable-foreman-proxy-plugin-remote-execution-script`
- Saves the final command for the next step

**Why we parse instead of running the file directly:** The instruction file contains explanatory text and options. We need to extract just the command and potentially modify it for load balancers. This parsing ensures we run the exact right command.

**Why load-balanced Capsules need extra options:** When Capsules are behind a load balancer, clients connect to the load balancer's FQDN, not the Capsule's FQDN. The `--certs-cname` parameter tells the Capsule "clients will use this other name to reach me, so accept that in SSL certificates."

### Step 6: Capsule Installation (`install_capsule`)

**What happens:**
- Verifies the certificate tarball exists
- Runs the `satellite-installer` command (this takes 30-60 minutes)
- Monitors the installation with a 1-hour timeout
- Saves all output to `/var/log/capsule-installation/capsule-installer-[timestamp].log`
- Waits 45 seconds for services to initialize
- Checks that critical services are running:
  - `foreman-proxy` (main Capsule service)
  - `httpd` (web server)
  - `pulpcore-api` (content API)
  - `pulpcore-content` (content delivery)
  - `pulpcore-worker@1` (background jobs)
- Tests the Capsule API at `https://capsule:9090/features`

**Why this takes so long:** The installer is doing a LOT - installing packages, configuring databases, generating SSL configurations, setting up web servers, and configuring dozens of services. 30-60 minutes is normal.

**Why we save logs:** When installations fail, the logs are essential for troubleshooting. We save them with timestamps so you can compare successful and failed runs.

**Why we test the API:** A Capsule isn't truly working until its API responds. This test proves the Capsule is ready for use, not just that the installer finished.

### Step 7: Configure in Satellite (`configure_capsules_in_satellite`)

**What happens:**
- Creates a lifecycle environment called "EO_ITRA_ALL" (if it doesn't exist)
- Registers each Capsule as a "Smart Proxy" in Satellite
- Associates it with the lifecycle environment
- Sets the download policy to "on_demand" (Capsule only downloads content when clients request it)

**Why this runs on the Satellite server:** Only Satellite knows about Smart Proxies. This step tells Satellite "these Capsules exist and are authorized to sync content."

**Why we need a lifecycle environment:** In Satellite, lifecycle environments organize content into stages (like "Development" → "Testing" → "Production"). Capsules must be assigned to environments to know which content to sync.

### Step 8: Final Verification (Post-Tasks)

**What happens:**
- Checks that all services are still running (they should be)
- Confirms service states
- Reports success

**Why verify again:** Services might start but then crash. This final check ensures everything is stable.

## Configuration Files Explained

### Environment-Specific Playbooks

You'll see four playbooks:
- `capsule-install.yml` (development)
- `capsule-install-test.yml` (test)
- `capsule-install-prod.yml` (production)
- `capsule-install-ead.yml` (EAD environment)

**Why separate playbooks:** Each environment has different Satellite servers and different Capsules. The playbooks are identical except they load different variable files.

### Variable Files (group_vars)

The `group_vars` directory contains:
- `all.yml` - Default (development) settings
- `test_env.yml` - Test environment overrides
- `prod_env.yml` - Production environment overrides
- `ead_env.yml` - EAD environment overrides

**Key variables you'll need to change:**

```yaml
satellite_fqdn: "satellite.example.com"        # Your Satellite server's name
capsule_fqdns:                                 # List of Capsule servers
  - capsule1.example.com
  - capsule2.example.com

loadbalanced_capsules: []                      # Capsules behind a load balancer
capsule_loadbalancer_fqdn: ""                  # Load balancer's name (if any)
```

**Why variables are environment-specific:** Your test Satellite is different from your production Satellite. Each environment file points to the correct Satellite and lists the correct Capsules for that environment.

## Load-Balanced Capsules - Special Considerations

Some environments put multiple Capsules behind a load balancer for high availability.

**Configuration example:**

```yaml
capsule_fqdns:
  - capsule1.example.com
  - capsule2.example.com

loadbalanced_capsules:
  - capsule1.example.com
  - capsule2.example.com

capsule_loadbalancer_fqdn: "capsules.example.com"
```

**CRITICAL:** The certificates for load-balanced Capsules MUST include both:
- The individual Capsule's FQDN (as CN or SAN)
- The load balancer's FQDN (in SAN - Subject Alternative Name)

**Why this matters:** Clients connect to "capsules.example.com" (the load balancer), but the actual Capsule behind it is "capsule1.example.com". SSL certificates must be valid for both names or clients will get certificate errors.

## Running the Automation

### Development Environment

```bash
ansible-playbook capsule-install.yml --limit capsule.dev.example.com
```

### Test Environment

```bash
ansible-playbook capsule-install-test.yml --limit capsule.test.example.com
```

### Production Environment (Always Test First!)

```bash
# Check what would happen (doesn't make changes)
ansible-playbook capsule-install-prod.yml --check --limit capsule.prod.example.com

# Actually run it
ansible-playbook capsule-install-prod.yml --limit capsule.prod.example.com
```

**Why use --limit:** Your inventory includes both Satellite and Capsules. The `--limit` flag tells Ansible "only run on this specific server right now." This prevents accidentally running on all servers at once.

**Why --check in production:** Check mode shows you what would change without actually changing it. Think of it as a "dry run" that lets you verify the automation will do what you expect.

## Troubleshooting Common Issues

### Problem: "Repository not found" error

**Cause:** The activation key doesn't have the right content view, or Capsule repositories aren't synced in Satellite.

**Fix:** Log into Satellite UI → Content → Activation Keys → satellite-infrastructure → verify it has a content view with Capsule repos.

### Problem: "Certificate tarball not found"

**Cause:** The satellite-install project didn't run successfully, or files weren't distributed to this Capsule.

**Fix:** Verify files exist:
```bash
ls -la /root/capsule_cert/
```
If missing, re-run the satellite-install project's certificate distribution role.

### Problem: "Registration failed"

**Cause:** Network connectivity issues between Capsule and Satellite, or Satellite services are down.

**Fix:** Test connectivity:
```bash
curl -k https://satellite.example.com/api/status
```
If that fails, check firewall rules and Satellite's service status.

### Problem: Installation hangs

**Cause:** The installer is still running (normal), or truly stuck (rare).

**Fix:** Check the log file:
```bash
tail -f /var/log/capsule-installation/capsule-installer-*.log
```
Look for "Success!" at the end. If you see errors, they'll tell you what failed.

## How This Differs from Manual Installation

**Manual installation requires:**
1. SSHing to each Capsule
2. Registering with complex subscription-manager commands
3. Finding and enabling the exact right repositories
4. Copying certificate files
5. Extracting and reading installation instructions
6. Running the installer command (which is long and complex)
7. Manually verifying services
8. Logging into Satellite UI to register the Capsule as a Smart Proxy
9. Repeating for every Capsule

**This automation does all of that in one command.** More importantly, it does it consistently. Manual installations lead to inconsistencies - maybe you enabled an extra repository on one server, or forgot a step on another. Automation ensures every Capsule is configured identically.

## Understanding Idempotency - Why You Can Run This Multiple Times

This automation is "idempotent," which means you can run it over and over, and it will:
- Skip steps that are already done
- Only change what needs changing
- End with the same result every time

**Example:** If registration already succeeded but repository configuration failed, re-running the automation will:
- Skip the registration step (already done)
- Retry the repository configuration
- Continue with the rest of the steps

**Why this matters:** Real environments are messy. Network hiccups happen. Servers reboot mid-installation. Being able to safely re-run the automation saves hours of manual cleanup.

## Technical Notes FYI

### Why We Use Fully Qualified Collection Names (FQCN)

You'll see modules written as `ansible.builtin.command` instead of just `command`.

**Reason:** Multiple Ansible collections can have modules with the same name. Using FQCN makes it absolutely clear which module you're using. This prevents bugs when collections are updated.

### Why Module Defaults Are Set

At the top of each playbook you'll see:

```yaml
module_defaults:
  group/redhat.satellite.satellite:
    server_url: "{{ satellite_server_url }}"
    username: "{{ satellite_setup_username }}"
    password: "{{ satellite_initial_admin_password }}"
    validate_certs: false
```

**Reason:** Every `redhat.satellite.*` module needs these parameters. Instead of repeating them in every task, we set them once here. This is DRY (Don't Repeat Yourself) programming - change in one place, apply everywhere.

### Why We Use 'when' Conditions on Roles

Roles are guarded with conditions like:

```yaml
when:
  - is_capsule_host
  - will_install_capsule | default(false)
```

**Reason:** Your inventory includes both Satellite and Capsule servers. These conditions ensure Capsule roles only run on Capsule servers. Without them, the automation would try to install Capsule software on the Satellite server (which would fail).

### Why We Test Both Locally and Remotely

After registration, we verify in two places:
1. On the Capsule: `subscription-manager identity`
2. On the Satellite: `hammer host info`

**Reason:** Systems can be "out of sync." The Capsule might think it's registered, but Satellite might not know about it (or vice versa). Testing both sides ensures they agree.

### Why Async Operations Are Used

The installer task uses:

```yaml
async: 3600
poll: 30
```

**Reason:** The installer takes 30-60 minutes. Normally, Ansible waits for tasks to finish. `async` tells Ansible "this will take a long time, keep checking every 30 seconds (poll) for up to 1 hour (async)." Without this, the connection would time out.

## Next Steps After Installation

Once Capsules are installed:

1. **Sync content to Capsules** - In Satellite UI, trigger content syncs so Capsules have packages
2. **Test client registration** - Register a test client to the Capsule to verify it works
3. **Configure lifecycle environments** - Assign Capsules to appropriate environments
4. **Set up content views** - Define which content each Capsule should sync

## Additional Resources

- `capsule_install_primer.md` - Detailed technical specifications
- `/var/log/capsule-installation/` - Installation logs on each Capsule
- Hammer CLI reference: `hammer --help`
- Red Hat Satellite documentation: https://access.redhat.com/documentation/en-us/red_hat_satellite/

---

**Remember:** This automation is designed to be run repeatedly. If something fails, fix the underlying issue (network, certificates, etc.) and run it again. It should pick up where it left off.