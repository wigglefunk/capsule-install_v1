# Capsule Installation Automation

This project automates the installation of Red Hat Satellite Capsule servers.

## Overview

This automation picks up where the satellite-install-6_10 project leaves off, 
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

