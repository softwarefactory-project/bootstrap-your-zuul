let BootstrapYourZuul = ../package.dhall

in  BootstrapYourZuul.Config::{
    , name = "local"
    , label = Some "centos-7"
    , sql = Some "sqlreporter"
    , connections = [ BootstrapYourZuul.Connection.gerrit "local" ]
    }
