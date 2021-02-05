// This module should be moved to its own library
open Belt

module type Fetcher = {
  let get: string => Js.Promise.t<Belt.Result.t<option<Js.Json.t>, string>>
  let post: (string, option<Js.Json.t>) => Js.Promise.t<Belt.Result.t<option<Js.Json.t>, string>>

  let put: (string, option<Js.Json.t>) => Js.Promise.t<Belt.Result.t<option<Js.Json.t>, string>>
  let delete: string => Js.Promise.t<Belt.Result.t<Fetch.response, string>>
}

// A Fetcher implementation using `bs-fetch`
module BsFetch = {
  let handleAPICallError = (promise: Js.Promise.t<Fetch.Response.t>): Js.Promise.t<
    Belt.Result.t<Fetch.response, string>,
  > => {
    promise |> Js.Promise.then_(r =>
      r |> Fetch.Response.ok || r |> Fetch.Response.status == 404
        ? Ok(r)->Js.Promise.resolve
        : Error("API call failed: " ++ Fetch.Response.statusText(r))->Js.Promise.resolve
    )
  }

  let extractJson = (promise: Js.Promise.t<Belt.Result.t<Fetch.Response.t, string>>): Js.Promise.t<
    Belt.Result.t<option<Js.Json.t>, string>,
  > => {
    promise |> Js.Promise.then_(result =>
      switch result {
      | Ok(resp) =>
        resp
        |> Fetch.Response.json
        |> Js.Promise.then_(decoded => Ok(decoded->Some)->Js.Promise.resolve)
        |> Js.Promise.catch(_ => Ok(None)->Js.Promise.resolve)
      | Error(e) => Error(e)->Js.Promise.resolve
      }
    )
  }

  let raiseOnNok = (promise: Js.Promise.t<Fetch.Response.t>) => {
    promise |> Js.Promise.then_(r =>
      r |> Fetch.Response.ok || r |> Fetch.Response.status == 404
        ? promise
        : Js.Exn.raiseError(Fetch.Response.statusText(r))
    )
  }

  let get = (url: string): Js.Promise.t<Belt.Result.t<option<Js.Json.t>, string>> =>
    Fetch.fetch(url) |> handleAPICallError |> extractJson

  let postOrPut = (verb, url: string, body: option<Js.Json.t>): Js.Promise.t<
    Belt.Result.t<option<Js.Json.t>, string>,
  > => {
    let headers = Fetch.HeadersInit.make({
      "Accept": "*",
      "Content-Type": "application/json",
    })
    let req = switch body {
    | None => Fetch.RequestInit.make(~method_=verb, ~headers, ())
    | Some(json) =>
      Fetch.RequestInit.make(
        ~method_=verb,
        ~body=json->Js.Json.stringify->Fetch.BodyInit.make,
        ~headers,
        (),
      )
    }
    Fetch.fetchWithInit(url, req) |> handleAPICallError |> extractJson
  }
  let put = postOrPut(Put)
  let post = postOrPut(Post)
  let delete = (url: string): Js.Promise.t<Belt.Result.t<Fetch.response, string>> => {
    let req = Fetch.RequestInit.make(
      ~method_=Delete,
      ~headers=Fetch.HeadersInit.make({"Accept": "*"}),
      (),
    )
    Fetch.fetchWithInit(url, req) |> handleAPICallError
  }
}

type state_t<'a> = RemoteData.t<'a, option<'a>, string>
// The action to update the state
and action_t<'a> =
  | NetworkRequestBegin
  | NetworkRequestSuccess('a)
  | NetworkRequestError(string)

type json_t = Js.Json.t
and result_t<'a, 'b> = Result.t<'a, 'b>
type decode_t<'a> = result_t<'a, Decco.decodeError>
type decoder_t<'a> = json_t => decode_t<'a>
type encoder_t<'a> = 'a => json_t
and promise_t<'a> = Js.Promise.t<'a>
and gethook_t<'a> = (state_t<'a>, string => unit, unit => unit)
and posthook_t<'a, 'b> = (state_t<'b>, 'a => unit)
and response_t<'a> = result_t<'a, string>
and dispatch_t<'a> = action_t<'a> => unit

let note = (o: option<'a>, e: 'e): result_t<'a, 'e> =>
  switch o {
  | Some(v) => v->Ok
  | None => e->Error
  }

let deccoErrorToResponse = (r: decode_t<'a>): response_t<'a> =>
  // Convert a DeccoError to a string
  switch r {
  | Ok(v) => v->Ok
  // Todo: better format error
  | Error(e) => e.message->Error
  }

let toLoading = (data: state_t<'a>): state_t<'a> => {
  // Manage transition to the Loading state:
  //   if the data was loaded, make it Loading(some(data))
  //   otherwise, make it Loading(None)
  open RemoteData
  Loading(data |> map(d => Some(d)) |> withDefault(None))
}

let updateRemoteData = (data: state_t<'a>, action: action_t<'a>): state_t<'a> =>
  // Manage transition of the state through action
  switch action {
  | NetworkRequestBegin => data |> toLoading
  | NetworkRequestError(error) => RemoteData.Failure(error)
  | NetworkRequestSuccess(response) => RemoteData.Success(response)
  }

let responseToAction = (response: response_t<'a>): action_t<'a> =>
  // Convert a bs-fetch response to an action
  switch response {
  | Ok(r) => r->NetworkRequestSuccess
  | Error(e) => e->NetworkRequestError
  }

module API = (Fetcher: Fetcher) => {
  let putOrPost = (action, decode: decoder_t<'a>, dispatch: dispatch_t<'a>) => {
    dispatch(NetworkRequestBegin)
    open Js.Promise
    action() |> then_(resp =>
      resp
      ->Result.flatMap(mjson =>
        mjson
        ->note("Need json!")
        ->Result.flatMap(json => json->decode->deccoErrorToResponse)
        ->responseToAction
        ->dispatch
        ->Ok
      )
      ->resolve
    )
  }

  let post = (url, data) => putOrPost(() => Fetcher.post(url, data))

  module Hook = {
    let usePost = (url: string, encoder: encoder_t<'a>, decoder: decoder_t<'b>): (
      state_t<'b>,
      'a => unit,
    ) => {
      let (state, setState) = React.useState(() => RemoteData.NotAsked)
      let set_state = s => setState(_prevState => s)
      let dispatch = data =>
        post(url, data->encoder->Some, decoder, r => state->updateRemoteData(r)->set_state)->ignore
      (state, dispatch)
    }
  }
}
