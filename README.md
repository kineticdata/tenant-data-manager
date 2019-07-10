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

The following properties must be provided to the tenant data manager when installing a tenant space.

* action -     **install**
* slug -       **my-space**                 # the space slug to create
* host -       **https://kinops-test.io**   # the URL of the core server
* subdomains - **true**                     # whether subdomains are used for tenant spaces
* log_level -  **info**                     # SDK log level passed to templates scripts
* components                                # Map of platform component configurations
  * core
    * space
      * name    - **My Space**              # Name of the space to create
  * task
    * license                               # Full content of the license
    * username - **admin**                  # Name of the task configurator admin user
    * password - **KINETIC_TASK_CONFIGURATOR_PASSWORD** # Environment variable name for the task configurator admin password
    * container
      * image - **kineticdata/task**        # Name of the docker image to use for Kinetic Task
      * tag - **4.4.0**                     # Tag of the docker image to use for Kinetic Task
* templates                                 # Array of templates that will be called
  * url - **https://github.com/kineticdata/platform-template-base.git** # URL of the template repository in GitHub
  * branch | tag | commit - **develop**     # Git branch name, tag name, or commit hash
  * script - **install.rb**                 # Optional name of script to run in the template, default: `#{action}.rb`
  * script-args - **{}**                   # Optional arguments passed to the template script, default: `{}`

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
    "subdomains" :true,
    "log_level": "info",
    "components": {
      "core": {
        "space": {
          "name": "My Space"
        }
      },
      "task": {
        "license": null,
        "username": "admin",
        "password": "KINETIC_TASK_CONFIGURATOR_PASSWORD",
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
    ]
  }'
```

### Decommission Action

The following properties must be provided to the tenant data manager when decommissioning a tenant space.

* action -     **decommission**
* slug -       **my-space**                 # the space slug to decommission
* host -       **https://kinops-test.io**   # the URL of the core server
* subdomains - **true**                     # whether subdomains are used for tenant spaces
* log_level -  **info**                     # SDK log level passed to templates scripts

#### cURL example to decommission tenant

```sh
curl -X POST \
  http://localhost:4567/decommission \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
    "action": "decommission",
    "slug": "my-space",
    "host": "https://kinops-test.io",
    "subdomains" :true,
    "log_level": "info"
  }'
```

### Repair Action

The following properties must be provided to the tenant data manager when repairing a tenant space.

* action -     **repair**
* slug -       **my-space**                 # the space slug to repair
* host -       **https://kinops-test.io**   # the URL of the core server
* subdomains - **true**                     # whether subdomains are used for tenant spaces
* log_level -  **info**                     # SDK log level passed to templates scripts
* components                                # Map of platform component configurations
  * task
    * username - **admin**                  # Name of the task configurator admin user
    * password - **KINETIC_TASK_CONFIGURATOR_PASSWORD** # Environment variable name for the task configurator admin password
    * container
      * image - **kineticdata/task**        # Name of the docker image to use for Kinetic Task
      * tag - **4.4.0**            # Tag of the docker image to use for Kinetic Task
* templates                                 # Array of templates that will be called
  * url - **https://github.com/kineticdata/platform-template-base.git** # URL of the template repository in GitHub
  * branch | tag | commit - **develop**     # Git branch name, tag name, or commit hash
  * script - **repair.rb**                  # Optional name of script to run in the template, default: `#{action}.rb`
  * script-args - **{}**                    # Optional arguments passed to the template script, default: `{}`

#### cURL example to repair tenant

```sh
curl -X POST \
  http://localhost:4567/repair \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
    "action": "repair",
    "slug": "my-space",
    "host": "https://kinops-test.io",
    "subdomains" :true,
    "log_level": "info",
    "components": {
      "task": {
        "username": "admin",
        "password": "KINETIC_TASK_CONFIGURATOR_PASSWORD",
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
    ]
  }'
```

### Uninstall Action

The following properties must be provided to the tenant data manager when uninstalling a tenant space.

* action -     **uninstall**
* slug -       **my-space**                 # the space slug to uninstall
* host -       **https://kinops-test.io**   # the URL of the core server
* subdomains - **true**                     # whether subdomains are used for tenant spaces
* log_level -  **info**                     # SDK log level passed to templates scripts

#### cURL example to uninstall tenant

```sh
curl -X POST \
  http://localhost:4567/decommission \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
    "action": "decommission",
    "slug": "my-space",
    "host": "https://kinops-test.io",
    "subdomains" :true,
    "log_level": "info"
  }'
```

### Upgrade Action

The following properties must be provided to the tenant data manager when upgrading a tenant space.

* action -     **upgrade**
* slug -       **my-space**                 # the space slug to upgrade
* host -       **https://kinops-test.io**   # the URL of the core server
* subdomains - **true**                     # whether subdomains are used for tenant spaces
* log_level -  **info**                     # SDK log level passed to templates scripts
* components                                # Map of platform component configurations
  * task
    * username - **admin**                  # Name of the task configurator admin user
    * password - **KINETIC_TASK_CONFIGURATOR_PASSWORD** # Environment variable name for the task configurator admin password
    * container
      * image - **kineticdata/task**        # Name of the docker image to use for Kinetic Task
      * tag - **4.4.0**            # Tag of the docker image to use for Kinetic Task
* templates                                 # Array of templates that will be called
  * url - **https://github.com/kineticdata/platform-template-base.git** # URL of the template repository in GitHub
  * branch | tag | commit - **develop**     # Git branch name, tag name, or commit hash
  * script - **upgrade.rb**                 # Optional name of script to run in the template, default: `#{action}.rb`
  * script-args - **{}**                    # Optional arguments passed to the template script, default: `{}`

#### cURL example to upgrade tenant

```sh
curl -X POST \
  http://localhost:4567/upgrade \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
    "action": "upgrade",
    "slug": "my-space",
    "host": "https://kinops-test.io",
    "subdomains" :true,
    "log_level": "info",
    "components": {
      "task": {
        "username": "admin",
        "password": "KINETIC_TASK_CONFIGURATOR_PASSWORD",
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
    ]
  }'
```
