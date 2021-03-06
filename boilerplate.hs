{-# LANGUAGE OverloadedStrings #-}

import Network.HTTP.Conduit (simpleHttp) -- из пакета http-conduit
import qualified Data.ByteString.Lazy.Char8 as L -- если захотим работать с данными, полученными из simpleHttp
import qualified Data.Text as T -- представление юникодной строки в хаскелле
import Data.Text (replace) -- берём из модуля Data.Text только функцию replace (многие ф-ии из него перекрывают станартные из Prelude)
import Text.HTML.DOM (parseLBS) -- из пакета html-conduit
import Text.XML.Cursor (Cursor, attributeIs, content, element, fromDocument, child, ($//), (&|), (&//), (&/), (>=>)) -- из пакета xml-conduit, для работы с DOM-деревом документа

n = T.pack "\r\n" -- перевод строки в плохой вёрстке сайта cyber.mephi.ru

url = "http://cyber.mephi.ru/Faculty.html" -- преподаватели кафедры

{-
  Аналог XPath записи для поиска нужной нам информации. Выбираются все теги td с бэкграундом, внутри которых находятся ссылки
  &// Ищет среди всех потомков, а &/ - в детях
-}
findNodes :: Cursor -> [Cursor]
findNodes = element "TD" >=> attributeIs "bgcolor" "#e1e4e6" &// element "B" &// element "A" >=> child

{-
  Извлечь контент из узла. Для извлечения ссылок на страницы преподавателей нужно использовать функцию attribute
-}
extractData :: Cursor -> T.Text
extractData = T.concat . content

{-
  Извлекаем содержимое страницы, парсим её и возвращаем курсор на корень DOM-дерева
-}
cursorFor :: String -> IO Cursor -- тут тип важен
cursorFor u = do
     page <- simpleHttp u
     return $ fromDocument $ parseLBS page

main = do
  cursor <- cursorFor url
  let infoNodes = cursor $// findNodes &| extractData
      replaceBr = replace n T.empty
      filterNodes = map (T.unpack . replaceBr) . take 45
  mapM_ putStrLn $ filterNodes infoNodes
