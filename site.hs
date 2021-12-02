--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Text.Pandoc.Options (writerHTMLMathMethod, HTMLMathMethod(MathML))
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

-- Use this if I want to use deferent rendering method for math
-- myPandocCompiler :: Compiler (Item String)
-- myPandocCompiler = pandocCompilerWith reader writer
--    where
--        reader = defaultHakyllReaderOptions
--        writer = defaultHakyllWriterOptions { writerHTMLMathMethod = MathML Nothing }


--------------------------------------------------------------------------------
defaultContext' :: Context String
defaultContext' =
    modificationTimeField "updated" "%B %e, %Y" `mappend`
    defaultContext

postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext'
