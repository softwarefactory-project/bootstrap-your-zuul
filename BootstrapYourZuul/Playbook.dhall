let Ansible = (../imports.dhall).Ansible

let include_role =
      \(name : Text) ->
        Ansible.Task::{ include_role = Some Ansible.IncludeRole::{ name } }

let block_include =
      \(name : Text) ->
        Ansible.BlockTask::{ include_role = Some Ansible.IncludeRole::{ name } }

let pre =
      [ Ansible.Play::{
        , hosts = "localhost"
        , roles = Some [ "log-inventory", "emit-job-header" ]
        }
      , Ansible.Play::{
        , hosts = "all"
        , tasks = Some
          [ include_role "validate-host"
          , Ansible.Task::{
            , block = Some
              [ block_include "validate-host"
              , block_include "prepare-workspace"
              ]
            , when = Some "ansible_connection != 'kubectl'"
            }
          , Ansible.Task::{
            , block = Some
              [ block_include "prepare-workspace-openshift"
              , block_include "remove-zuul-sshkey"
              ]
            , when = Some "ansible_connection == 'kubectl'"
            }
          ]
        }
      ]

let post =
      \(log-secret : Text) ->
        [ Ansible.Play::{
          , hosts = "localhost"
          , vars = Some
              ( Ansible.Vars.mapText
                  (toMap { fileserver = "{{ ${log-secret} }}" })
              )
          , roles = Some [ "add-fileserver" ]
          }
        , Ansible.Play::{
          , hosts = "{{ ${log-secret}.fqdn }}"
          , vars = Some
              ( Ansible.Vars.object
                  ( toMap
                      { zuul_log_compress = Ansible.Vars.bool True
                      , zuul_log_url =
                          Ansible.Vars.string "{{ ${log-secret}.url }}"
                      , zuul_logserver_root =
                          Ansible.Vars.string "{{ ${log-secret}.path }}"
                      }
                  )
              )
          , roles = Some [ "upload-logs" ]
          }
        ]

in  { pre, post }
