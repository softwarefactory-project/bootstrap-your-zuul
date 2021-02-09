let BootstrapYourZuul = ../package.dhall

in  BootstrapYourZuul.Config::{
    , name = "local"
    , sql = Some "sqlreporter"
    , connections = [ BootstrapYourZuul.Connection.gerrit "local" ]
    }
