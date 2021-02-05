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

* playbooks/base/pre.yaml
- hosts: localhost
  tasks:
  - import_role:
      name: emit-job-header
  - import_role:
      name: log-inventory

- hosts: all
  tasks:
  - include_role:
      name: validate-host

* playbooks/base/post.yaml
- hosts: all
  tasks:
  - include_role:
      name: fetch-output
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
  - pipeline:
      description: This pipeline runs jobs that operate after each change is merged.
      failure:
        sqlreporter: []
      manager: supercedent
      name: post
      post-review: true
      precedence: high
      success:
        sqlreporter: []
      trigger:
        local:
          - event:
              - ref-updated
            ref:
              - "^refs/heads/.*$"
  - pipeline:
      description: |
        This pipeline runs jobs that operate after each change is merged
        in order to promote artifacts generated in the gate
        pipeline.
      failure:
        local: {}
        sqlreporter: []
      manager: supercedent
      name: promote
      post-review: true
      precedence: high
      success:
        local: {}
        sqlreporter: []
      trigger:
        local:
          - event:
              - change-merged
playbook_post:
  - hosts: all
    tasks:
      - include_role:
          name: fetch-output
playbook_pre:
  - hosts: localhost
    tasks:
      - import_role:
          name: emit-job-header
      - import_role:
          name: log-inventory
  - hosts: all
    tasks:
      - include_role:
          name: validate-host
tenant:
  - tenant:
      name: local

```

Some pipeline are custom, for example to create a periodic trigger:

```yaml
# dhall-to-yaml <<< 'let BYZ = ./package.dhall in [{pipeline = BYZ.Pipeline.periodic BYZ.Pipeline.Frequency.daily BYZ.Zuul.Pipeline.Reporter.Smtp.default}]'

- pipeline:
    description: Jobs in this queue are triggered daily
    failure:
      smtp: {}
    manager: independent
    name: periodic-daily
    post-review: true
    precedence: low
    trigger:
      timer:
        - time: "0 0 * * * *"
```

## Contribute

### Web Interface

Build the web interface:

```ShellSession
pnpm install
pnpm start
pnpm serve # in another term
```

Distribute the web interface:

```ShellSession
pnpm dist
```
