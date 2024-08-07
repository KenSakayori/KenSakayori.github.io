--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import Data.Monoid (mappend)
import Control.Monad.Except (throwError)


import Text.Blaze.Html5 ((!))
import qualified Text.Blaze.Html5 as H
import qualified Text.Blaze.Html5.Attributes as A
import Text.Pandoc.Options (writerHTMLMathMethod, HTMLMathMethod(MathML))
import Hakyll
import Text.Sass as Sass


--------------------------------------------------------------------------------
main :: IO ()
main = hakyllWith config $ do
    tags <- buildTags "blog/posts/*" (fromCapture "tags/*.html")
    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "txt/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route $ setExtension "css"
        compile (fmap compressCss <$> scssCompiler)

    match "scripts/*" $ do
        route $ setExtension "js"
        -- TODO minimize js
        compile copyFileCompiler

    match "index.md" $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" myContext
            >>= relativizeUrls

    match "blog/posts/*" $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/posts.html" (postContext tags)
            >>= relativizeUrls

    create ["blog.html"] $ do
        route idRoute
        compile $ do
            posts <- loadAll "blog/posts/*"
            sorted <- recentFirst posts
            itemTpl <- loadBody "templates/post-item.html"
            list <- applyTemplateList itemTpl (postContext tags) sorted
            makeItem list
                >>= loadAndApplyTemplate "templates/post-list.html" defaultContext
                >>= loadAndApplyTemplate "templates/default.html" blogContext
                >>= relativizeUrls


    match "templates/*" $ compile templateBodyCompiler

--------------------------------------------------------------------------------
myContext :: Context String
myContext =
    boolField "isindex" (\i -> (toFilePath $ itemIdentifier i) == "index.md") `mappend`
    modificationTimeField "updated" "%B %e, %Y" `mappend`
    defaultContext

postContext :: Tags -> Context String
postContext tags  =
    mkTagsField tags `mappend`
    -- tagsField "tags" tags `mappend`
    dateField "date" "%B %e, %Y" `mappend`
    myContext


-- TODO Remove the overlap with myContext
blogContext :: Context String
blogContext =
  constField "title" "Blog" `mappend`
  constField "h1" "Blog Posts" `mappend`
  boolField "isindex" (\i -> (toFilePath $ itemIdentifier i) == "index.md") `mappend`
  defaultContext


-- | Create the `tags` field
mkTagsField :: Tags -> Context a
mkTagsField tags = tagsFieldWith getTags noLink mconcat destField tags
  where
    -- renders without adding a hyperlink
    destField = "tags"
    noLink :: String -> (Maybe FilePath) -> Maybe H.Html
    noLink tag _ = Just $ H.span ! A.class_ "tag" $ H.toHtml tag

config :: Configuration
config = defaultConfiguration
  { destinationDirectory = "docs"
  }

-- | Compile a scss file into a css
scssCompiler :: Compiler (Item String)
scssCompiler = getResourceBody >>= renderScss


renderScss :: Item String -> Compiler (Item String)
renderScss itm =
    do
        x <- unsafeCompiler $ go (itemBody itm)
        case x of
            Left err -> throwError [err]
            Right res -> makeItem res
    where
    go :: String -> IO (Either String String)
    go str = do
        x <- Sass.compileString str Sass.def
        case x of
            Left err -> do 
                msg <- Sass.errorMessage err
                return (Left msg)
            Right res -> return (Right res)

-- Use this if I want to use deferent rendering method for math
-- myPandocCompiler :: Compiler (Item String)
-- myPandocCompiler = pandocCompilerWith reader writer
--    where
--        reader = defaultHakyllReaderOptions
--        writer = defaultHakyllWriterOptions { writerHTMLMathMethod = MathML Nothing }
