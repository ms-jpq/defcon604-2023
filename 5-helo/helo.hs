#!/usr/bin/env -S -- runhaskell

import           System.Environment (getProgName)
import           System.FilePath    ((</>))
import           System.Process     (callProcess)
import           Text.Printf        (printf)

main = do
  name <- getProgName
  let path = "5-helo" </> name
  _ <- putStrLn $ printf "HELO :: VIA -- %s" name
  _ <- putStrLn "cannot into chdir"
  callProcess "bat" ["--", path]
