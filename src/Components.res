let useInput = () => {
  let (value, setValue) = React.useState(_ => "")
  (value, newValue => setValue(_ => newValue))
}

module Input = {
  @react.component
  let make = (~name: string, ~id: string, ~placeholder: string, ~onChange: string => unit) =>
    <div>
      <label htmlFor={id} className="block text-sm font-medium text-gray-700">
        {name->React.string}
      </label>
      <div className="mt-1 relative rounded-md shadow-sm">
        <input
          type_="text"
          name={name}
          id={id}
          className="focus:ring-indigo-500 focus:border-indigo-500 block w-full pl-7 pr-12 sm:text-sm border-gray-300 rounded-md"
          placeholder={placeholder}
          onChange={form => {
            let value = ReactEvent.Form.target(form)["value"]
            onChange(value)
          }}
        />
      </div>
    </div>
}

module Button = {
  @react.component
  let make = (~name: string, ~color: string, ~onClick: unit => unit) => {
    let color_classes = switch color {
    | "yellow" => "bg-yellow-400 ring-yellow-200"
    | "blue" => "bg-blue-400 ring-blue-200"
    | _ => ""
    }
    let classes = "p-2 my-2 text-white rounded-md focus:outline-none focus:ring-2 ring-offset-2 "
    <button className={classes ++ color_classes} onClick={_ => onClick()}>
      {name->React.string}
    </button>
  }
}

module Container = {
  @react.component
  let make = (~children: 'children) => <div className="container mx-auto p-4"> {children} </div>
}

module Grid = {
  @react.component
  let make = (~size: int, ~children: 'children) => {
    let size_classes = switch size {
    | 2 => "grid-cols-2"
    | _ => ""
    }
    <div className={"grid gap-4 " ++ size_classes}> {children} </div>
  }
}

module Page = {
  @react.component
  let make = (~children: 'children) => <div className="flex flex-col h-screen"> {children} </div>
}

module Header = {
  @react.component
  let make = (~text: string) => <header className="p-4 bg-blue-300"> {text->React.string} </header>
}

module Main = {
  @react.component
  let make = (~children: 'children) => <main className="p-5 overflow-y-auto"> {children} </main>
}

module Footer = {
  @react.component
  let make = (~text: string) =>
    <footer className="p-3 justify-center border-t-2"> {text->React.string} </footer>
}
