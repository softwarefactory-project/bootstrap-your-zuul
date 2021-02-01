let Zuul = (../imports.dhall).Zuul

let Pipeline = ./Pipeline/package.dhall

in  \(config : ./Config/Type.dhall) ->
      { tenant = [ { tenant.name = config.name } ]
      , pipelines = Zuul.Pipeline.wrap [ Pipeline.check config.connections ]
      }
