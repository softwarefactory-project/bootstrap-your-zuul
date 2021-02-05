#!/usr/bin/env nix-shell
#! nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/d4f19a218cbb15a242864a49f8b9f16fb7d48ec8.tar.gz
#! nix-shell --pure -i runghc -p "haskellPackages.ghcWithPackages (p: [ p.dhall p.aeson p.dhall-json p.scotty p.wai-middleware-static ])"

{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell #-}

import Data.Aeson (FromJSON)
import Data.Text.Lazy (pack)
import Dhall (embed, inject, inputExpr)
import Dhall.Core (Expr (App))
import Dhall.JSON (convertToHomogeneousMaps, defaultConversion, dhallToJSON, omitNull)
import qualified Dhall.TH
import Network.Wai.Middleware.Static
import Web.Scotty

-- | Generate Haskell Type from Dhall Type, see: https://hackage.haskell.org/package/dhall-1.38.0/docs/Dhall-TH.html
Dhall.TH.makeHaskellTypes
  [ Dhall.TH.SingleConstructor "Connections" "MakeConnections" "./BootstrapYourZuul/JsonConfig/Connections.dhall",
    Dhall.TH.SingleConstructor "Config" "MakeConfig" "./BootstrapYourZuul/JsonConfig/Type.dhall"
  ]

-- | Enable loading the Config from JSON
instance FromJSON Connections

instance FromJSON Config

main :: IO ()
main = do
  -- Load the `toConfig` function
  toConfig <- inputExpr "./BootstrapYourZuul/JsonConfig/toConfig.dhall"
  -- Load the `render` function
  render <- inputExpr "./BootstrapYourZuul/render.dhall"
  -- Start web service
  scotty 3000 $ do
    -- Add static file
    middleware $ staticPolicy (noDots >-> addBase "dist")
    get "/" $ file "dist/index.html"
    -- Add POST handler for /
    post "/api" $ do
      -- Read Config from request body
      (config :: Config) <- jsonData
      -- Convert the Config to a Dhall expression
      let configExpr = embed inject config
      -- Call the `render` function
      let renderExpr = App render $ App toConfig $ configExpr
      -- Convert back the result to JSON
      case dhallToJSON (convertToHomogeneousMaps defaultConversion renderExpr) of
        Left err -> raise (pack (show err))
        Right v -> json (omitNull v)
