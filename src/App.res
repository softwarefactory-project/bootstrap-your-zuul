@bs.module("js-yaml") external yaml_dump: 'obj => string = "dump"

let maybeAdd = (xs: option<list<'a>>, x: option<'a>) =>
  switch x {
  | Some(x) =>
    Some(
      switch xs {
      | Some(xs) => xs->Belt.List.add(x)
      | None => list{x}
      },
    )
  | None => xs
  }

module Config = {
  @decco
  type connections = {
    gerrit: option<list<string>>,
    pagure: option<list<string>>,
    github: option<list<string>>,
  }

  let emptyConnections = {
    gerrit: None,
    pagure: None,
    github: None,
  }

  @decco
  type config = {
    name: string,
    sql: string,
    zuul_jobs: option<string>,
    connections: connections,
  }

  let emptyConfig = {
    name: "",
    sql: "",
    zuul_jobs: None,
    connections: emptyConnections,
  }

  type connection = Gerrit(string) | Pagure(string)

  @decco
  type zuul_config = {
    jobs: array<Js.Json.t>,
    pipelines: array<Js.Json.t>,
  }

  module ZuulConfig = {
    @react.component
    let make = (~config: config, ~postHook: Api.posthook_t<config, zuul_config>) => {
      // The hook to query the api
      let (zuul_config, post) = postHook

      // Debounch update
      React.useEffect1(() => {
        let handler = Js.Global.setTimeout(() => post(config), 500)

        Some(() => Js.Global.clearTimeout(handler))
      }, [config])

      switch zuul_config {
      | RemoteData.NotAsked => <p> {"NotAsked"->React.string} </p>
      | RemoteData.Loading(None) => <p> {"Loading..."->React.string} </p>
      | RemoteData.Failure(title) => <p> {("Oops: " ++ title)->React.string} </p>
      | RemoteData.Loading(Some(zuul_config))
      | RemoteData.Success(zuul_config) =>
        <pre> {zuul_config.pipelines->yaml_dump->React.string} </pre>
      }
    }
  }
  module Form = {
    let connection = (idx: int, onChange: string => unit) => {
      let id = "conn-" ++ Js.Int.toString(idx)
      <Components.Input key={id} id={id} name="Connection" placeholder="Name" onChange={onChange} />
    }

    @react.component
    let make = (~postHook: Api.posthook_t<config, zuul_config>) => {
      // The Bootstrap Your Zuul config state
      let (config, setConfig) = React.useState(_ => emptyConfig)

      // Maintains a list of (component, value)
      let (connections, setConnections) = React.useState(_ => list{})
      let updateConnection = (idx, newValue) =>
        setConnections(connections => {
          // Update a connection value
          let newConnections =
            connections->Belt.List.mapWithIndex((pos, (elem, value)) => (
              elem,
              pos == idx ? newValue->Some : value,
            ))

          // Add connection to the config
          let rec configConnections = (xs, acc) =>
            switch xs {
            | list{} => acc
            | list{(_elem, value), ...rest} =>
              // TODO: support other connection type
              rest->configConnections({
                ...acc,
                gerrit: acc.gerrit->maybeAdd(value),
              })
            }

          // Update the config
          setConfig(config => {
            ...config,
            connections: newConnections->configConnections(emptyConnections),
          })

          // Return the new connections state
          newConnections
        })

      // The tenant name
      let setTenant = name => setConfig(config => {...config, name: name})
      let inputTenant =
        <Components.Input
          name="Tenant" id="tenant-name" placeholder="Tenant name" onChange={setTenant}
        />

      // The sql connection name
      let setSql = name => setConfig(config => {...config, sql: name})
      let inputSql =
        <Components.Input
          name="Sql Reporter" id="sql-reporter" placeholder="Sql connection name" onChange={setSql}
        />

      // Add connection button
      let addClick = () => {
        let idx = connections->Belt.List.length
        let newConn = connection(idx, name => updateConnection(idx, name))
        setConnections(xs => {
          xs->Belt.List.add((newConn, None))
        })
      }
      let addButton = <Components.Button name="Add connection" color="blue" onClick={addClick} />

      // Remove connection button
      let delClick = () => {
        setConnections(xs =>
          switch xs->Belt.List.drop(1) {
          | None => list{}
          | Some(l) => l
          }
        )
      }
      let delButton =
        <Components.Button name="Remove connection" color="yellow" onClick={delClick} />
      let showDelButton = switch connections {
      | list{} => React.null
      | _ => delButton
      }

      let connectionsElement =
        connections->Belt.List.map(((elem, _value)) => elem)->Belt.List.toArray->React.array
      Js.log4("Config", config, "Connections", connections)
      <Components.Grid size=2>
        <Components.Container>
          inputTenant inputSql connectionsElement addButton showDelButton
        </Components.Container>
        <Components.Container> <ZuulConfig config postHook /> </Components.Container>
      </Components.Grid>
    }
  }
}

module Main = (Fetcher: Api.Fetcher) => {
  module API = Api.API(Fetcher)
  @react.component
  let make = () => {
    <Components.Page>
      <Components.Header text="Bootstrap Your Zuul" />
      <Components.Main>
        {"Welcome"->React.string}
        <Components.Container>
          <Config.Form
            postHook={API.Hook.usePost("/api", Config.config_encode, Config.zuul_config_decode)}
          />
        </Components.Container>
      </Components.Main>
      <Components.Footer text="Powered by ReScript + Haskell + Dhall" />
    </Components.Page>
  }
}
