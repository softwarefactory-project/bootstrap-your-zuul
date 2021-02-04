let Prelude = (../imports.dhall).Prelude

let Zuul = (../imports.dhall).Zuul

let Pipeline = ./Pipeline/package.dhall

let Job = ./Job/package.dhall

let Playbook = ./Playbook.dhall

let Config = ./Config/package.dhall

in  \(config : Config.Type) ->
      { tenant = [ { tenant.name = config.name } ]
      , jobs = Zuul.Job.wrap [ Job.base (Config.getZuulJobs config) ]
      , pipelines =
          Zuul.Pipeline.wrap
            ( Prelude.List.map
                Zuul.Pipeline.Type
                Zuul.Pipeline.Type
                (Pipeline.addSqlReporter config.sql)
                [ Pipeline.check config.connections
                , Pipeline.gate config.connections
                , Pipeline.post config.connections
                ]
            )
      , playbook_pre = Playbook.pre
      , playbook_post = Playbook.post
      }
