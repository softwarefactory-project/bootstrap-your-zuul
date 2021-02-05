module Config = {
  @decco
  type connections = {
    gerrit: option<list<string>>,
    pagure: option<list<string>>,
    github: option<list<string>>,
  }

  @decco
  type config = {
    name: string,
    sql: string,
    zuul_jobs: option<string>,
    connections: connections,
  }

  @decco
  type result = {
    jobs: list<Js.Json.t>,
    pipelines: list<Js.Json.t>,
  }
}
@react.component
let make = () => {
  <Components.Page>
    <Components.Header text="Bootstrap Your Zuul" />
    <Components.Main> {"Hello"->React.string} </Components.Main>
    <Components.Footer text="Powered by ReScript + Haskell + Dhall" />
  </Components.Page>
}
