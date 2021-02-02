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
    failure:
      sqlreporter: []
    manager: independent
    success:
      local:
        Verified: 1
      sqlreporter: []

- pipeline:
    name: gate
    failure:
      sqlreporter: []
    manager: dependent
    precedence: high
    success:
      local:
        Verified: 2
        submit: true
      sqlreporter: []

* config/zuul.d/jobs.yaml
- job:
    name: base
    parent: null
    description: The base job.
    pre-run:
    post-run:
    extra-vars:
      zuul_use_fetch_output: true
    - playbooks/base/post.yaml
    - playbooks/base/pre.yaml
    roles:
    - zuul: opendev.org/zuul/zuul-jobs
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
jobs:
  - job:
      description: The base job.
      extra-vars:
        zuul_use_fetch_output: true
      name: base
      parent: null
      post-run:
        - playbooks/base/post.yaml
      pre-run:
        - playbooks/base/pre.yaml
      roles:
        - zuul: opendev.org/zuul/zuul-jobs
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
  - pipeline:
      failure:
        sqlreporter: []
      manager: dependent
      name: gate
      precedence: high
      success:
        local:
          Verified: 2
          submit: true
        sqlreporter: []
tenant:
  - tenant:
      name: local

```
