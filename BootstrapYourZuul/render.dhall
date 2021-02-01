let Pipeline = ./Pipeline/package.dhall

in  \(config : ./Config/Type.dhall) ->
      { tenant = [ { tenant.name = config.name } ]
      , pipelines = [ { pipeline = Pipeline.check config.connections } ]
      }
