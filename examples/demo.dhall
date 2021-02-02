let BootstrapYourZuul = ../package.dhall

in  BootstrapYourZuul.Config::{
    , name = "local"
    , sql = "sqlreporter"
    , connections = [ BootstrapYourZuul.Connection.gerrit "local" ]
    }
