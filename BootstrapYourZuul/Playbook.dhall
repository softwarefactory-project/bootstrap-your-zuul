let Ansible = (../imports.dhall).Ansible

let include_role =
      \(name : Text) ->
        Ansible.Task::{ include_role = Some Ansible.IncludeRole::{ name } }

let pre =
      [ Ansible.Play::{
        , hosts = "localhost"
        , tasks = Some
          [ Ansible.Task::{
            , import_role = Some Ansible.ImportRole::{
              , name = "emit-job-header"
              }
            }
          , Ansible.Task::{
            , import_role = Some Ansible.ImportRole::{ name = "log-inventory" }
            }
          ]
        }
      , Ansible.Play::{
        , hosts = "all"
        , tasks = Some [ include_role "validate-host" ]
        }
      ]

let post =
      [ Ansible.Play::{
        , hosts = "all"
        , tasks = Some [ include_role "fetch-output" ]
        }
      ]

in  { pre, post }
