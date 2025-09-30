
# Part of base capsule post config EO_ITRA_ALL ENVIRONMENT CREATION on the satellite_fqdn
- name: "Create EO_ITRA_ALL lifecycle environment"
  redhat.satellite.lifecycle_environment:
    name: "{{ itra_default_env }}"
    label: "{{ itra_default_env }}"
    description: "Base working environment for 6.17 and beyond"
    prior: "Library"
    organization: "{{ satellite_org }}"
    state: present
    register: base_environment_creation


# Base Capsule post configuration on the satellite_fqdn
# This sets up EO_ITRA in Satellite
- name: "Create Smart Proxy"
  redhat.satellite.smart_proxy:
    username: "{{ satellite_setup_username }}"
    password: "{{ satellite_initial_admin_password }}"
    server_url: "https://{{ satellite_fqdn }}"
    name: "{{ ansible_fqdn }}"
    url: "https://{{ ansible_fqdn }}:9090"
    download_policy: "immediate"
    lifecycle_environments:
      - "{{ itra_default_env }}"
    organizations:
      - "{{ satellite_org }}"
    locations:
      - "{{ satellite_location }}"
    state: present
    register: capsule_create_at_sat
    

Fetch information about Hosts
Synopsis
Parameters
Examples
Return Values
Synopsis
Fetch information about Hosts
Requirements
requests
Parameters
Parameter	Choices / Defaults	Comments
ca_path
path
PEM formatted file that contains a CA certificate to be used for validation.

If the value is not specified in the task, the value of environment variable SATELLITE_CA_PATH will be used instead.

location
string
Label of the Location to scope the search for.

name
string
Name of the resource to fetch information for.

Mutually exclusive with search.

organization
string
Name of the Organization to scope the search for.

password
string
Password of the user accessing the Foreman server.

If the value is not specified in the task, the value of environment variable SATELLITE_PASSWORD will be used instead.

search
string
Search query to use

If None, and name is not set, all resources are returned.

Mutually exclusive with name.

server_url
string / required
URL of the Foreman server.

If the value is not specified in the task, the value of environment variable SATELLITE_SERVER_URL will be used instead.

use_gssapi
boolean
Choices:
true
false  ←
Use GSSAPI to perform the authentication, typically this is for Kerberos or Kerberos through Negotiate authentication.

Requires the Python library requests-gssapi  to be installed.

If the value is not specified in the task, the value of environment variable SATELLITE_USE_GSSAPI will be used instead.

username
string
Username accessing the Foreman server.

If the value is not specified in the task, the value of environment variable SATELLITE_USERNAME will be used instead.

validate_certs
boolean
Choices:
true  ←
false
Whether or not to verify the TLS certificates of the Foreman server.

If the value is not specified in the task, the value of environment variable SATELLITE_VALIDATE_CERTS will be used instead.

Examples
- name: "Show a host"
  redhat.satellite.host_info:
    username: "admin"
    password: "changeme"
    server_url: "https://satellite.example.com"
    name: "host.example.com"

- name: "Show all hosts with domain example.com"
  redhat.satellite.host_info:
    username: "admin"
    password: "changeme"
    server_url: "https://satellite.example.com"
    search: "domain = example.com"
Return Values
Key	Returned	Description
host
(dict)	success and I(name) was passed	
Details about the found host

hosts
(list)	success and I(search) was passed	
List of all found hosts and their details
module > http_proxy

Manage HTTP Proxies
Synopsis
Parameters
Examples
Return Values
Synopsis
Create, update, and delete HTTP Proxies
Requirements
requests
Parameters
Parameter	Choices / Defaults	Comments
ca_path
path
PEM formatted file that contains a CA certificate to be used for validation.

If the value is not specified in the task, the value of environment variable SATELLITE_CA_PATH will be used instead.

locations
list / elements=string
List of locations the entity should be assigned to

name
string / required
The HTTP Proxy name

organizations
list / elements=string
List of organizations the entity should be assigned to

password
string
Password of the user accessing the Foreman server.

If the value is not specified in the task, the value of environment variable SATELLITE_PASSWORD will be used instead.

proxy_password
string
Password used to authenticate with the HTTP Proxy

When this parameter is set, the module will not be idempotent.

proxy_username
string
Username used to authenticate with the HTTP Proxy

server_url
string / required
URL of the Foreman server.

If the value is not specified in the task, the value of environment variable SATELLITE_SERVER_URL will be used instead.

state
string
Choices:
present  ←
absent
State of the entity

url
string
URL of the HTTP Proxy

Required when creating a new HTTP Proxy.

use_gssapi
boolean
Choices:
true
false  ←
Use GSSAPI to perform the authentication, typically this is for Kerberos or Kerberos through Negotiate authentication.

Requires the Python library requests-gssapi  to be installed.

If the value is not specified in the task, the value of environment variable SATELLITE_USE_GSSAPI will be used instead.

username
string
Username accessing the Foreman server.

If the value is not specified in the task, the value of environment variable SATELLITE_USERNAME will be used instead.

validate_certs
boolean
Choices:
true  ←
false
Whether or not to verify the TLS certificates of the Foreman server.

If the value is not specified in the task, the value of environment variable SATELLITE_VALIDATE_CERTS will be used instead.

Examples
- name: create example.org proxy
  redhat.satellite.http_proxy:
    name: "example.org"
    url: "http://example.org:3128"
    locations:
      - "Munich"
    organizations:
      - "ACME"
    server_url: "https://satellite.example.com"
    username: "admin"
    password: "changeme"
    state: present
Return Values
Key	Returned	Description
entity
(dict)	success	
Final state of the affected entities grouped by their type.

http_proxies
(list)		
List of HTTP proxies.
module > activation_key

Manage Activation Keys
Synopsis
Parameters
Examples
Return Values
Synopsis
Create and manage activation keys
Requirements
requests
Parameters
Parameter	Choices / Defaults	Comments
auto_attach
boolean
Choices:
true
false
Set Auto-Attach on or off

ca_path
path
PEM formatted file that contains a CA certificate to be used for validation.

If the value is not specified in the task, the value of environment variable SATELLITE_CA_PATH will be used instead.

content_overrides
list / elements=dictionary
List of content overrides that include label and override state

Label refers to repository content_label.

For Red Hat products for example rhel-7-server-rpms.

For custom products it's in the format <organization_label>_<product_label>_<repository_label>, e.g. ExampleOrg_ExampleProduct_ExampleRepository.

Override state ('enabled', 'disabled', or 'default') sets initial state of repository for newly registered hosts

label
string / required
Repository content_label to override when registering hosts with the activation key

override
string / required
Choices:
enabled
disabled
default
Override value to use for the repository when registering hosts with the activation key

content_view
string
Name of the content view

description
string
Description of the activation key

host_collections
list / elements=string
List of host collections to add to activation key

lifecycle_environment
string
Name of the lifecycle environment

max_hosts
integer
Maximum number of registered content hosts.

Required if unlimited_hosts=false

name
string / required
Name of the activation key

new_name
string
Name of the new activation key when state == copied

organization
string / required
Organization that the entity is in

password
string
Password of the user accessing the Foreman server.

If the value is not specified in the task, the value of environment variable SATELLITE_PASSWORD will be used instead.

purpose_addons
list / elements=string
Sets the system purpose add-ons

purpose_role
string
Sets the system purpose role

purpose_usage
string
Sets the system purpose usage

release_version
string
Set the content release version

server_url
string / required
URL of the Foreman server.

If the value is not specified in the task, the value of environment variable SATELLITE_SERVER_URL will be used instead.

service_level
string
Choices:
Self-Support
Standard
Premium
Set the service level

state
string
Choices:
present  ←
present_with_defaults
absent
copied
State of the Activation Key

If copied the key will be copied to a new one with new_name as the name and all other fields left untouched

present_with_defaults will ensure the entity exists, but won't update existing ones

subscriptions
list / elements=dictionary
List of subscriptions that include either Name, Pool ID, or Upstream Pool ID.

Pool IDs are preferred since Names and Upstream Pool IDs are not guaranteed to be unique. The module will fail if it finds more than one match.

This parameter is not supported in SCA mode.

name
string
Name of the Subscription to be added.

Mutually exclusive with pool_id and upstream_pool_id.

pool_id
string
Pool ID of the Subscription to be added.

Mutually exclusive with name and upstream_pool_id.

Also named Candlepin Id in the CSV export of the subscriptions,

it is as well the UUID as output by hammer subscription list.

upstream_pool_id
string
Upstream Pool ID of the Subscription to be added.

Mutually exclusive with name and pool_id.

Also named Master Pools in the Red Hat Portal.

unlimited_hosts
boolean
Choices:
true
false
Can the activation key have unlimited hosts

use_gssapi
boolean
Choices:
true
false  ←
Use GSSAPI to perform the authentication, typically this is for Kerberos or Kerberos through Negotiate authentication.

Requires the Python library requests-gssapi  to be installed.

If the value is not specified in the task, the value of environment variable SATELLITE_USE_GSSAPI will be used instead.

username
string
Username accessing the Foreman server.

If the value is not specified in the task, the value of environment variable SATELLITE_USERNAME will be used instead.

validate_certs
boolean
Choices:
true  ←
false
Whether or not to verify the TLS certificates of the Foreman server.

If the value is not specified in the task, the value of environment variable SATELLITE_VALIDATE_CERTS will be used instead.

Examples
- name: "Create client activation key"
  redhat.satellite.activation_key:
    username: "admin"
    password: "changeme"
    server_url: "https://satellite.example.com"
    name: "Clients"
    organization: "Default Organization"
    lifecycle_environment: "Library"
    content_view: 'client content view'
    host_collections:
      - rhel7-servers
      - rhel7-production
    content_overrides:
      - label: rhel-7-server-rpms
        override: enabled
      - label: ExampleOrganization_ExampleCustomProduct_ExampleRepository
        override: enabled
    auto_attach: false
    release_version: 7Server
    service_level: Standard
Return Values
Key	Returned	Description
entity
(dict)	success	
Final state of the affected entities grouped by their type.

activation_keys
(list)		
List of activation keys
module > subscription_manifest

Manage Subscription Manifests
Synopsis
Parameters
Examples
Synopsis
Upload, refresh and delete Subscription Manifests
Requirements
requests
Parameters
Parameter	Choices / Defaults	Comments
ca_path
path
PEM formatted file that contains a CA certificate to be used for validation.

If the value is not specified in the task, the value of environment variable SATELLITE_CA_PATH will be used instead.

manifest_path
path
Path to the manifest zip file

This parameter will be ignored if state=absent or state=refreshed

organization
string / required
Organization that the entity is in

password
string
Password of the user accessing the Foreman server.

If the value is not specified in the task, the value of environment variable SATELLITE_PASSWORD will be used instead.

repository_url
string
URL to retrieve content from

aliases: redhat_repository_url
server_url
string / required
URL of the Foreman server.

If the value is not specified in the task, the value of environment variable SATELLITE_SERVER_URL will be used instead.

state
string
Choices:
absent
present  ←
refreshed
The state of the manifest

use_gssapi
boolean
Choices:
true
false  ←
Use GSSAPI to perform the authentication, typically this is for Kerberos or Kerberos through Negotiate authentication.

Requires the Python library requests-gssapi  to be installed.

If the value is not specified in the task, the value of environment variable SATELLITE_USE_GSSAPI will be used instead.

username
string
Username accessing the Foreman server.

If the value is not specified in the task, the value of environment variable SATELLITE_USERNAME will be used instead.

validate_certs
boolean
Choices:
true  ←
false
Whether or not to verify the TLS certificates of the Foreman server.

If the value is not specified in the task, the value of environment variable SATELLITE_VALIDATE_CERTS will be used instead.

Examples
- name: "Upload the RHEL developer edition manifest"
  redhat.satellite.subscription_manifest:
    username: "admin"
    password: "changeme"
    server_url: "https://satellite.example.com"
    organization: "Default Organization"
    state: present
    manifest_path: "/tmp/manifest.zip"