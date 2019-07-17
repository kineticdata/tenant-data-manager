# Tenant Data Manager

The tenant data manager is responsible for creating a space in Kinetic Core, creating a Kinetic Task environment for the space, and configuring all the necessary data components for the space to function properly.

The tenant data manager is currently running as a web application with a REST API that accepts HTTP POST requests from within the kubernetes cluser.

The service runs on TCP port 4567.

## Health

Responds with a `running` status if the service is running.

`GET /`

cURL example:

```sh
curl http://localhost:4567
```

## Version

Responds with the service version.

`GET /version`

cURL example:

```sh
curl http://localhost:4567/version
```

## Actions

The following actions are currently supported by the tenant data manager web application:

* install - use this command when creating a new tenant space
* decommission - use this command to remove a tenant space, does not delete the task database
* repair - use this command to restore the integrations between all the platform components
* uninstall - use this command to delete the task database
* upgrade - use this command when upgrading template data

For each of the templates passed with the action data, the action script will call a corresponding action script in the template. The default template script can be overridden by passing in the name of the script, and any additional arguments that the template script may require.

For instance, if the `install` action is called, by default the tenant data manager application will call the `install.rb` script in the template repository.

### Install Action

The following properties may be provided to the tenant data manager when installing a tenant space.

* action -     **install**                  # name of the action
* slug -       **my-space**                 # the space slug to create
* host -       **https://kinops-test.io**   # the URL of the core server
* subdomains - **false**                    # Optional flag to disable subdomains for tenant spaces
* http_options                              # Optional HTTP configuration hash
  * log_level -  **info**                   # Optional log level passed to template scripts
  * log_output - **STDERR**                 # Optional log output location passed to template scripts
  * gateway_retry_limit - **-1**            # Optional max number of times to retry a bad gateway
  * gateway_retry_delay - **1.0**           # Optional number of seconds to delay before retrying a bad gateway
  * max_redirects - **5**                   # Optional max number of times to redirect
  * ssl_verify_mode - **peer**              # Optional flag to enable peer certificate validation when https is used for the host
  * ssl_ca_file - **/app/cert/tls.crt**     # Optional location of certificate, required for peer validation
* components                                # Map of platform component configurations
  * core
    * space
      * name    - **My Space**              # Name of the space to create
  * task
    * license                               # Full content of the license
    * container
      * image - **kineticdata/task**        # Name of the docker image to use for Kinetic Task
      * tag - **4.4.0**                     # Tag of the docker image to use for Kinetic Task
* templates                                 # Array of templates that will be called
  * url - **https://github.com/kineticdata/platform-template-base.git** # URL of the template repository in GitHub
  * branch | tag | commit - **develop**     # Git branch name, tag name, or commit hash
  * script - **install.rb**                 # Optional name of script to run in the template, default: `#{action}.rb`
  * script-args - **{}**                    # Optional arguments passed to the template script, default: `{}`
* templateData                              # Optional data to pass to all template scripts
  * users
    * username: joe.user
      email: joe.user@example.com
      attributes: []
    * username: jane.user
* templateDataSecrets                       # Optional data stored in secrets files, passed to all template scripts
  * key: name-of-secrets-file

#### cURL example to install tenant

```sh
curl -X POST \
  http://localhost:4567/install \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
    "action": "install",
    "slug": "my-space",
    "host": "https://kinops-test.io",
    "http_options": {
      "log_level": "info",
      "log_output": "STDERR",
      "ssl_ca_file" => "/app/cert/tls.crt",
      "ssl_verify_mode" => "peer"
    },
    "components": {
      "core": {
        "space": {
          "name": "My Space"
        }
      },
      "task": {
        "license": null,
        "container": {
          "image": "kineticdata/task",
          "tag": "4.4.0"
        }
      }
    },
    "templates": [
      {
        "url": "https://github.com/kineticdata/platform-template-base.git",
        "branch":"develop"
      }
    ],
    "templateData": {
      "users": []
    },
    "templateDataSecrets": {
      "smtp": "smtp-default"
    }
  }'
```

### Decommission Action

The following properties must be provided to the tenant data manager when decommissioning a tenant space.

* action -     **decommission**
* slug -       **my-space**                 # the space slug to decommission
* host -       **https://kinops-test.io**   # the URL of the core server
* http_options                              # Optional HTTP configuration hash
  * log_level -  **info**                   # Optional log level passed to template scripts
  * log_output - **STDERR**                 # Optional log output location passed to template scripts
  * gateway_retry_limit - **-1**            # Optional max number of times to retry a bad gateway
  * gateway_retry_delay - **1.0**           # Optional number of seconds to delay before retrying a bad gateway
  * max_redirects - **5**                   # Optional max number of times to redirect
  * ssl_verify_mode - **none**              # Optional flag to enable peer certificate validation
  * ssl_ca_file                             # Optional location of certificate, required for peer validation

#### cURL example to decommission tenant

```sh
curl -X POST \
  http://localhost:4567/decommission \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
    "action": "decommission",
    "slug": "my-space",
    "host": "https://kinops-test.io"
  }'
```

### Uninstall Action

The following properties must be provided to the tenant data manager when uninstalling a tenant space.

* action -     **uninstall**
* slug -       **my-space**                 # the space slug to uninstall
* host -       **https://kinops-test.io**   # the URL of the core server
* http_options                              # Optional HTTP configuration hash
  * log_level -  **info**                   # Optional log level passed to template scripts
  * log_output - **STDERR**                 # Optional log output location passed to template scripts
  * gateway_retry_limit - **-1**             # Optional max number of times to retry a bad gateway
  * gateway_retry_delay - **1.0**           # Optional number of seconds to delay before retrying a bad gateway
  * max_redirects - **5**                   # Optional max number of times to redirect
  * ssl_verify_mode - **none**              # Optional flag to enable peer certificate validation
  * ssl_ca_file                             # Optional location of certificate, required for peer validation

#### cURL example to uninstall tenant

```sh
curl -X POST \
  http://localhost:4567/decommission \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
    "action": "decommission",
    "slug": "my-space",
    "host": "https://kinops-test.io"
  }'
```
