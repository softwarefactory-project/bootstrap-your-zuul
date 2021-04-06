let BootstrapYourZuul = ../package.dhall

in  BootstrapYourZuul.Config::{
    , name = "local"
    , label = Some "centos-7"
    , connections = [ BootstrapYourZuul.Connection.gerrit "local" ]
    }
