--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Hakyll


--------------------------------------------------------------------------------
main :: IO ()
main = hakyllWith config $ do
    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match "index.md" $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" defaultContext'
            >>= relativizeUrls

    match "templates/*" $ compile templateBodyCompiler

config :: Configuration
config = defaultConfiguration
  { destinationDirectory = "docs"
  }

--------------------------------------------------------------------------------
defaultContext' :: Context String
defaultContext' =
    modificationTimeField "updated" "%B %e, %Y" `mappend`
    defaultContext

postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext'
