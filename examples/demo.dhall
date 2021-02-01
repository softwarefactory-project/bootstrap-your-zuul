let BootstrapYourZuul = ../package.dhall

in  BootstrapYourZuul.Config::{
    , name = "local"
    , connections = [ BootstrapYourZuul.Connection.gerrit "local" ]
    }
