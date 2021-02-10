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
    , label = Some "centos-7"
    , sql = Some "sqlreporter"
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
      nodeset:
        nodes:
          - label: centos-7
            name: worker
      parent: null
      post-run:
        - playbooks/base/post.yaml
      pre-run:
        - playbooks/base/pre.yaml
      roles:
        - zuul: opendev.org/zuul/zuul-jobs
      secrets:
        - site_sflogs
      timeout: 3600
pipelines:
  - pipeline:
      failure:
        local:
          Verified: -1
        sqlreporter: []
      manager: independent
      name: check
      require:
        local:
          current-patchset: true
          open: true
      start:
        local:
          Verified: 0
      success:
        local:
          Verified: 1
        sqlreporter: []
      trigger:
        local:
          - event:
              - patchset-created
          - event:
              - change-restored
          - comment:
              - "(?i)^(Patch Set [0-9]+:)?( [\\w\\\\+-]*)*(\\n\\n)?\\s*recheck"
            event:
              - comment-added
  - pipeline:
      failure:
        local:
          Verified: -2
        sqlreporter: []
      manager: dependent
      name: gate
      post-review: true
      precedence: high
      require:
        local:
          approval:
            Workflow: 1
          current-patchset: true
          open: true
      start:
        local:
          Verified: 0
      success:
        local:
          Verified: 2
          submit: true
        sqlreporter: []
      supercedes: check
      trigger:
        local:
          - approval:
              Workflow: 1
            event:
              - comment-added
          - comment:
              - "(?i)^(Patch Set [0-9]+:)?( [\\w\\\\+-]*)*(\\n\\n)?\\s*reverify"
            event:
              - comment-added
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

### Server

Build the server:

```ShellSession
cabal build
cabal run
```
