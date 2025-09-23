#!/usr/bin/env bash

# Create Capsule Install Project Structure
# This script creates the directory structure and blank stub YAML files
# for the capsule-install automation project

# Set the project root directory name
PROJECT_ROOT="capsule-install"

echo "Creating Capsule Install Project Structure..."
echo "==========================================="

# Create the main project directory
mkdir -p "$PROJECT_ROOT"
cd "$PROJECT_ROOT"

# Create main directory structure
echo "Creating directory structure..."
mkdir -p group_vars
mkdir -p collections
mkdir -p roles

# Create role directories with tasks subdirectories
echo "Creating role structures..."
for role in prep_capsule_registration register_capsule configure_capsule_repos parse_install_instructions install_capsule; do
    mkdir -p "roles/$role/tasks"
    mkdir -p "roles/$role/defaults"
    mkdir -p "roles/$role/handlers"
    mkdir -p "roles/$role/meta"
    
    # Create blank main.yml for each role's tasks
    echo "---" > "roles/$role/tasks/main.yml"
    echo "# Role: $role" >> "roles/$role/tasks/main.yml"
    echo "# Tasks for $role" >> "roles/$role/tasks/main.yml"
    echo "" >> "roles/$role/tasks/main.yml"
    
    # Create blank defaults/main.yml
    echo "---" > "roles/$role/defaults/main.yml"
    echo "# Default variables for $role role" >> "roles/$role/defaults/main.yml"
    echo "" >> "roles/$role/defaults/main.yml"
    
    # Create blank handlers/main.yml
    echo "---" > "roles/$role/handlers/main.yml"
    echo "# Handlers for $role role" >> "roles/$role/handlers/main.yml"
    echo "" >> "roles/$role/handlers/main.yml"
    
    # Create blank meta/main.yml
    echo "---" > "roles/$role/meta/main.yml"
    echo "# Meta information for $role role" >> "roles/$role/meta/main.yml"
    echo "dependencies: []" >> "roles/$role/meta/main.yml"
    echo "" >> "roles/$role/meta/main.yml"
    
    echo "  Created role: $role"
done

# Create main playbook files
echo "Creating main playbook files..."

# Main playbook (default/dev environment)
cat > capsule-install.yml << 'EOF'
---
# Capsule Installation Playbook - Default (Dev) Environment
# This playbook automates the installation of Red Hat Satellite Capsule servers

EOF

# Test environment playbook
cat > capsule-install-test.yml << 'EOF'
---
# Capsule Installation Playbook - Test Environment
# This playbook automates the installation of Red Hat Satellite Capsule servers

EOF

# Production environment playbook
cat > capsule-install-prod.yml << 'EOF'
---
# Capsule Installation Playbook - Production Environment
# This playbook automates the installation of Red Hat Satellite Capsule servers

EOF

# EAD environment playbook
cat > capsule-install-ead.yml << 'EOF'
---
# Capsule Installation Playbook - EAD Environment
# This playbook automates the installation of Red Hat Satellite Capsule servers

EOF

echo "  Created main playbooks"

# Create group_vars files
echo "Creating group_vars files..."

# Default variables (dev environment)
cat > group_vars/all.yml << 'EOF'
---
# Default Group Variables for Capsule Installation
# Development Environment Configuration

EOF

# Test environment variables
cat > group_vars/test_env.yml << 'EOF'
---
# Test Environment Variables for Capsule Installation

EOF

# Production environment variables
cat > group_vars/prod_env.yml << 'EOF'
---
# Production Environment Variables for Capsule Installation

EOF

# EAD environment variables
cat > group_vars/ead_env.yml << 'EOF'
---
# EAD Environment Variables for Capsule Installation

EOF

echo "  Created group_vars files"

# Create collections requirements file
echo "Creating collections requirements..."
cat > collections/requirements.yml << 'EOF'
---
# Ansible Collections required for Red Hat Satellite Capsule Installation

collections:

EOF

echo "  Created collections/requirements.yml"

# Create README file
echo "Creating README..."
cat > README.md << 'EOF'
# Capsule Installation Automation

This project automates the installation of Red Hat Satellite Capsule servers.

## Overview

This automation picks up where the satellite install project leaves off, 
using the certificate tarballs and installation instructions that were 
generated and distributed to install Capsule servers.

## Prerequisites

- Certificate files distributed by satellite-install project
- Activation key "satellite-infrastructure" configured in Satellite
- Direct network connectivity to Satellite server

## Usage

Run the appropriate playbook for your environment:
- `capsule-install.yml` - Development environment
- `capsule-install-test.yml` - Test environment  
- `capsule-install-prod.yml` - Production environment
- `capsule-install-ead.yml` - EAD environment

## Project Structure

See the capsule_install_primer.md for detailed specifications.

EOF

echo "  Created README.md"

# Create .gitignore file
echo "Creating .gitignore..."
cat > .gitignore << 'EOF'
# Ansible runtime and backup files
*.retry
*.orig
*.tmp
*.backup
*~

# Python bytecode
__pycache__/
*.py[cod]
*$py.class

# Ansible vault password files
.vault_pass
vault_password_file

# IDE files
.vscode/
.idea/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Local testing
test/
testing/
scratch/

# Credentials (should never be committed)
credentials/
*.pem
*.key
*.crt

EOF

echo "  Created .gitignore"

# Create ansible.cfg file
echo "Creating ansible.cfg..."
cat > ansible.cfg << 'EOF'
[defaults]
host_key_checking = False
retry_files_enabled = False
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts
fact_caching_timeout = 86400
stdout_callback = yaml
callback_whitelist = profile_tasks, timer
deprecation_warnings = False
interpreter_python = /usr/bin/python3

[ssh_connection]
pipelining = True
control_path = /tmp/ansible-ssh-%%h-%%p-%%r

EOF

echo "  Created ansible.cfg"

# Create a sample inventory directory structure
echo "Creating inventory structure..."
mkdir -p inventories/dev
mkdir -p inventories/test
mkdir -p inventories/prod
mkdir -p inventories/ead

# Create blank inventory files
for env in dev test prod ead; do
    cat > "inventories/$env/hosts.yml" << EOF
---
# $env environment inventory
all:
  hosts:
  children:
    capsules:
      hosts:

EOF
    echo "  Created inventories/$env/hosts.yml"
done

# Final summary
echo ""
echo "==========================================="
echo "Project structure created successfully!"
echo ""
echo "Directory structure:"
echo ""
tree -L 3 -I '__pycache__|*.pyc' 2>/dev/null || {
    echo "$PROJECT_ROOT/"
    echo "├── ansible.cfg"
    echo "├── capsule-install.yml"
    echo "├── capsule-install-test.yml"
    echo "├── capsule-install-prod.yml"
    echo "├── capsule-install-ead.yml"
    echo "├── collections/"
    echo "│   └── requirements.yml"
    echo "├── group_vars/"
    echo "│   ├── all.yml"
    echo "│   ├── test_env.yml"
    echo "│   ├── prod_env.yml"
    echo "│   └── ead_env.yml"
    echo "├── inventories/"
    echo "│   ├── dev/"
    echo "│   ├── test/"
    echo "│   ├── prod/"
    echo "│   └── ead/"
    echo "├── roles/"
    echo "│   ├── prep_capsule_registration/"
    echo "│   ├── register_capsule/"
    echo "│   ├── configure_capsule_repos/"
    echo "│   ├── parse_install_instructions/"
    echo "│   └── install_capsule/"
    echo "├── README.md"
    echo "└── .gitignore"
}

echo ""
echo "Next steps:"
echo "1. Review the created structure"
echo "2. Copy generated code into the stub files"
echo "3. Update group_vars with environment-specific values"
echo "4. Configure inventories for each environment"
echo ""
echo "All stub files have been created and are ready for content!"