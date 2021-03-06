-- Interpret using this command:
--    podman run -it --rm -v $(pwd):/data:Z quay.io/software-factory/shake-factory
--
-- Learn more at: https://softwarefactory-project.io/cgit/software-factory/shake-factory/tree/README.md

import Development.Shake
import ShakeFactory
import ShakeFactory.Dhall

main :: IO ()
main = shakeMain $ do
  want ["README.md", "package.dhall"]
  "README.md" %> dhallReadmeAction
  "package.dhall" %> dhallTopLevelPackageAction "./BootstrapYourZuul/package.dhall"
  "//package.dhall" %> dhallPackageAction
  "//default.dhall" %> dhallDefaultAction
  dhallDocsRules "bootstrap-your-zuul"
  dhallReleaseRules "./BootstrapYourZuul/package.dhall"
  cleanRules
