module Header = {
  @react.component
  let make = (~text: string) =>
    <div className="bg-blue-300">
      <div className="max-w-7xl mx-auto py-3 px-3 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between flex-wrap">
          <div className="w-0 flex-1 flex items-center">
            <span className="flex p-2 rounded-lg font-bold"> {text->React.string} </span>
          </div>
        </div>
      </div>
    </div>
}

module Footer = {
  @react.component
  let make = (~text: string) =>
    <footer> <div className="flex justify-center border-t-2"> {text->React.string} </div> </footer>
}

module Page = {
  @react.component
  let make = (~children: 'children) => <div className="flex flex-col h-screen"> {children} </div>
}

module Main = {
  @react.component
  let make = (~children: 'children) => <main className="flex-grow mb-auto h-10"> {children} </main>
}
