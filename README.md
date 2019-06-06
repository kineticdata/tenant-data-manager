# Tenant Data Manager

A service that manages the installation, updating, and removal of all the component data for a tenant space in the Kinetic Platform.

The service runs on TCP port 4567.

## API Actions

The following API actions are supported by this service.

### Health

Responds with a `running` status if the service is running.

`GET /`

cURL example:

```sh
curl http://localhost:4567
```

### Version

Responds with the service version.

`GET /version`

cURL example:

```sh
curl http://localhost:4567/version
```

### Install Tenant Space

Creates a tenant space, sets up the tenant ingress rules, starts a Kinetic Task instance, and creates all necessary component data for this tenant space.

```
POST /install
  {
    "action":"install",
    "slug":"my-space",
    "host":"http://my-platform-server.io",
    "subdomains":true,
    "components":{
      "request-ce":{
        "username":"admin",
        "password":"SECRET!",
        "space":{
          "name":"My Space",
          "users":[
            {
              "username":"integration-user",
              "email":"DO_NOT_REPLY@my-platform-server.io",
              "spaceAdmin": true
            }
          ]
        }
      },
      "bridgehub":{
        "username":"admin",
        "password":"SECRET!"
      },
      "filehub":{
        "username":"admin",
        "password":"SECRET!"
      },
      "discussions":{
        "username":"admin",
        "password":"SECRET!",
        "oauth-client":{
          "id":"kinetic-bundle",
          "secret":"SECRET!"
        }
      },
      "task":{
        "image":"kineticdata/task:4.4.0-SNAPSHOT",
        "username":"admin",
        "password":"SECRET!",
        "db":{
          "host":"postgres",
          "port":"5432",
          "password":"SECRET!"
        }
      }
    },
    "templates":[
      {
        "url":"https://github.com/kineticdata/platform-template.git",
        "commit":"fa1a15db29333e5c56d1e3547acf6004865f4759"
      }
    ]
  }
```

cURL example:

```sh
curl -X POST \
  http://localhost:4567/install \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "action":"install",
  "slug":"my-space",
  "host":"http://my-platform-server.io",
  "subdomains":true,
  "components":{
    "request-ce":{
      "username":"admin",
      "password":"SECRET!",
      "space":{
        "name":"My Space",
        "users":[
          {
            "username":"integration-user",
            "email":"DO_NOT_REPLY@my-platform-server.io",
            "spaceAdmin": true
          }
        ]
      }
    },
    "bridgehub":{
      "username":"admin",
      "password":"SECRET!"
    },
    "filehub":{
      "username":"admin",
      "password":"SECRET!"
    },
    "discussions":{
      "username":"admin",
      "password":"SECRET!",
      "oauth-client":{
        "id":"kinetic-bundle",
        "secret":"SECRET!"
      }
    },
    "task":{
      "image":"kineticdata/task:4.4.0-SNAPSHOT",
      "username":"admin",
      "password":"SECRET!",
      "db":{
        "host":"postgres",
        "port":"5432",
        "password":"SECRET!"
      }
    }
  },
  "templates":[
    {
      "url":"https://github.com/kineticdata/platform-template.git",
      "commit":"fa1a15db29333e5c56d1e3547acf6004865f4759"
    }
  ]
}'
```

### Repair Space

Repairs an existing tenant space, updating any component data that may be linked between multiple applications.

```
POST /repair
  {
    "action":"repair",
    "slug":"my-space",
    "host":"http://my-platform-server.io",
    "subdomains":true,
    "components":{
      "request-ce":{
        "username":"admin",
        "password":"SECRET!",
        "space":{
          "name":"My Space",
          "users":[
            {
              "username":"integration-user",
              "email":"DO_NOT_REPLY@my-platform-server.io",
              "spaceAdmin": true
            }
          ]
        }
      },
      "bridgehub":{
        "username":"admin",
        "password":"SECRET!"
      },
      "filehub":{
        "username":"admin",
        "password":"SECRET!"
      },
      "discussions":{
        "username":"admin",
        "password":"SECRET!",
        "oauth-client":{
          "id":"kinetic-bundle",
          "secret":"SECRET!"
        }
      },
      "task":{
        "image":"kineticdata/task:4.4.0-SNAPSHOT",
        "username":"admin",
        "password":"SECRET!",
        "db":{
          "host":"postgres",
          "port":"5432",
          "password":"SECRET!"
        }
      }
    },
    "templates":[
      {
        "url":"https://github.com/kineticdata/platform-template.git",
        "commit":"fa1a15db29333e5c56d1e3547acf6004865f4759"
      }
    ]
  }
```

cURL example:

```sh
curl -X POST \
  http://localhost:4567/repair \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "action":"repair",
  "slug":"my-space",
  "host":"http://my-platform-server.io",
  "subdomains":true,
  "components":{
    "request-ce":{
      "username":"admin",
      "password":"SECRET!",
      "space":{
        "name":"My Space",
        "users":[
          {
            "username":"integration-user",
            "email":"DO_NOT_REPLY@my-platform-server.io",
            "spaceAdmin": true
          }
        ]
      }
    },
    "bridgehub":{
      "username":"admin",
      "password":"SECRET!"
    },
    "filehub":{
      "username":"admin",
      "password":"SECRET!"
    },
    "discussions":{
      "username":"admin",
      "password":"SECRET!",
      "oauth-client":{
        "id":"kinetic-bundle",
        "secret":"SECRET!"
      }
    },
    "task":{
      "image":"kineticdata/task:4.4.0-SNAPSHOT",
      "username":"admin",
      "password":"SECRET!",
      "db":{
        "host":"postgres",
        "port":"5432",
        "password":"SECRET!"
      }
    }
  },
  "templates":[
    {
      "url":"https://github.com/kineticdata/platform-template.git",
      "commit":"fa1a15db29333e5c56d1e3547acf6004865f4759"
    }
  ]
}'
```

### Upgrade Space

Upgrades an existing tenant space, updating any specified components.

```
POST /upgrade
  {
    ...
  }
```

### Decommission Space

Removes a tenant space and it's Kinetic Task instance from service. This action does not delete the task database or filestore files however, as this allows for the space to be restored in the future if needed.

```
POST /decommission
  {
    ...
  }
```

### Uninstall Space

Deletes the task database and filestore files for the tenant space, effective rendering the space unrecoverable.

```
POST /uninstall
  {
    ...
  }
```
