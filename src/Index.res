// Use this Reason entrypoint to start the rendering.
// The App component is defined in a dedicated module.

module RealApp = App.Main(RemoteAPI.BsFetch)

switch ReactDOM.querySelector("#root") {
| Some(root) => ReactDOM.render(<RealApp />, root)
| None => Js.log("oops!")
}
