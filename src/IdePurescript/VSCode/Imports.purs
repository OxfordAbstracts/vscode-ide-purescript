module IdePurescript.VSCode.Imports where

import Prelude
import IdePurescript.VSCode.Types
import VSCode.Input
import VSCode.Window
import Control.Monad.Eff.Console (log)
import Control.Monad.Aff (runAff)
import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Ref (readRef, writeRef, Ref)
import Data.Maybe (Maybe(..))
import Data.Nullable (toNullable)
import IdePurescript.Modules (State, ImportResult(AmbiguousImport, UpdatedImports), addModuleImport, addExplicitImport)
import IdePurescript.PscIde (getAvailableModules)
import PscIde.Command as C

launchAffSilent = runAff (const $ pure unit) (const $ pure unit)

addIdentImportCmd :: forall eff. Ref State -> Int -> Eff (MainEff eff) Unit
addIdentImportCmd modulesState port = do
  ed <- getActiveTextEditor
  state <- readRef modulesState
  case ed of 
    Just ed' -> launchAffSilent $ do
      ident <- getInput (defaultInputOptions { prompt = toNullable $ Just "Identifier" })
      path <- liftEffM $ getPath ed'
      text <- liftEffM $ getText ed'
      addIdentImport state ed' path text Nothing ident
    Nothing -> pure unit
  where
    addIdentImport state editor path text moduleName ident = do
      { state: newState, result: output} <- addExplicitImport state port path text moduleName ident
      liftEffM $ writeRef modulesState newState
      case output of
        UpdatedImports out -> do
          void $ setText editor out
        AmbiguousImport opts -> do
          mod <- showQuickPick ((\(C.Completion { "module'": mod }) -> mod) <$> opts)
          liftEffM $ log $ show mod
          case mod of
            Just _ -> addIdentImport state editor path text mod ident
            _ -> pure unit

addModuleImportCmd :: forall eff. Ref State -> Int -> Eff (MainEff eff) Unit
addModuleImportCmd modulesState port =
  launchAffSilent $ do
    modules <- getAvailableModules port
    mod <- showQuickPick modules
    state <- liftEffM $ readRef modulesState
    ed <- liftEffM $ getActiveTextEditor
    case mod, ed of
      Just moduleName, Just ed' -> do
        path <- liftEffM $ getPath ed'
        text <- liftEffM $ getText ed'
        do
          output <- addModuleImport state port path text moduleName
          case output of
            Just { result } -> do
              void $ setText ed' result
            _ -> pure unit
      _, _ -> pure unit