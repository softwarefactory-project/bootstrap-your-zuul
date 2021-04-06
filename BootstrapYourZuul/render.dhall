let Prelude = (../imports.dhall).Prelude

let Zuul = (../imports.dhall).Zuul

let Pipeline = ./Pipeline/package.dhall

let Job = ./Job/package.dhall

let Playbook = ./Playbook.dhall

let Config = ./Config/package.dhall

let --| TODO: define log settings in the Config
    log-secret =
      "site_sflogs"

in  \(config : Config.Type) ->
      { tenant = [ { tenant.name = config.name } ]
      , jobs =
          Zuul.Job.wrap
            [ Job.base config.label (Config.getZuulJobs config) [ log-secret ] ]
      , pipelines =
          Zuul.Pipeline.wrap
            [ Pipeline.check config.connections
            , Pipeline.gate config.connections
            , Pipeline.post config.connections
            , Pipeline.promote config.connections
            ]
      , playbook_pre = Playbook.pre
      , playbook_post = Playbook.post log-secret
      }
