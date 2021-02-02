\(config : ./Type.dhall) ->
  merge
    { None = "opendev.org/zuul/zuul-jobs", Some = \(name : Text) -> name }
    config.zuul-jobs
