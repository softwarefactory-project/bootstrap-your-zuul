# bootstrap-your-zuul

This project provides a declarative configuration to manage your zuul configuration needs.

## Overview and scope

At a high level, the scope of Bootstrap Your Zuul is to convert a list of connections and tenant settings
into:

- Zuul tenant configuration.
- Config projects ansible playbooks.
- Config projects zuul configuration:
  - pipeline
  - secret
  - job

The project includes Dhall functions and a tool to create the configurations.

## Example

Using the command line:

```yaml
# ./examples/demo.yaml
name: local
connections:
  gerrit: ["local"]
```

```bash
$ bootstrap-your-zuul ./examples/demo.yaml
* /etc/zuul/main.yaml
- tenant:
    name: local

* config/zuul.d/pipelines.yaml
- pipeline:
    name: check
    manager: independent
    success:
      local:
        Verified: 1
```

Or using the dhall function directly:

```dhall
-- ./examples/demo.dhall
let BootstrapYourZuul = ../package.dhall

in  BootstrapYourZuul.Config::{
    , name = "local"
    , sql = "sqlreporter"
    , connections = [ BootstrapYourZuul.Connection.gerrit "local" ]
    }

```

```yaml
# dhall-to-yaml <<< '(./package.dhall).render ./examples/demo.dhall'
pipelines:
  - pipeline:
      failure:
        sqlreporter: []
      manager: independent
      name: check
      success:
        local:
          Verified: 1
        sqlreporter: []
tenant:
  - tenant:
      name: local

```
