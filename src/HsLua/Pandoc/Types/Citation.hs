{-# LANGUAGE OverloadedStrings    #-}
{- |
Copyright               : © 2021 Albert Krewinkel
SPDX-License-Identifier : MIT
Maintainer              : Albert Krewinkel <tarleb+pandoc@moltkeplatz.de>

Marshaling/unmarshaling functions and constructor for 'Citation' values.
-}
module HsLua.Pandoc.Types.Citation
  ( -- * Citation
    peekCitation
  , pushCitation
  , typeCitation
  , mkCitation
    -- * CitationMode
  , peekCitationMode
  , pushCitationMode
  ) where

import Control.Applicative (optional)
import Data.Maybe (fromMaybe)
import HsLua as Lua
import {-# SOURCE #-}HsLua.Pandoc.Types.Inline (peekInlinesFuzzy, pushInlines)
import Text.Pandoc.Definition (Inline, Citation (..), CitationMode (..))

-- | Pushes a Citation value as userdata object.
pushCitation :: LuaError e
             => Pusher e Citation
pushCitation = pushUD typeCitation
{-# INLINE pushCitation #-}

-- | Retrieves a Citation value.
peekCitation :: LuaError e
             => Peeker e Citation
peekCitation = peekUD  typeCitation
{-# INLINE peekCitation #-}

-- | Citation object type.
typeCitation :: LuaError e
             => DocumentedType e Citation
typeCitation = deftype "Citation"
  [ operation Eq $ lambda
    ### liftPure2 (==)
    <#> parameter (optional . peekCitation) "Citation" "a" ""
    <#> parameter (optional . peekCitation) "Citation" "b" ""
    =#> functionResult pushBool "boolean" "true iff the citations are equal"

  , operation Tostring $ lambda
    ### liftPure show
    <#> parameter peekCitation "Citation" "citation" ""
    =#> functionResult pushString "string" "native Haskell representation"
  ]
  [ property "id" "citation ID / key"
      (pushText, citationId)
      (peekText, \citation cid -> citation{ citationId = cid })
  , property "mode" "citation mode"
      (pushCitationMode, citationMode)
      (peekCitationMode, \citation mode -> citation{ citationMode = mode })
  , property "prefix" "citation prefix"
      (pushInlines, citationPrefix)
      (peekInlinesFuzzy, \citation prefix -> citation{ citationPrefix = prefix })
  , property "suffix" "citation suffix"
      (pushInlines, citationSuffix)
      (peekInlinesFuzzy, \citation suffix -> citation{ citationSuffix = suffix })
  , property "note_num" "note number"
      (pushIntegral, citationNoteNum)
      (peekIntegral, \citation noteNum -> citation{ citationNoteNum = noteNum })
  , property "hash" "hash number"
      (pushIntegral, citationHash)
      (peekIntegral, \citation hash -> citation{ citationHash = hash })
  , method $ defun "clone"
    ### return
    <#> udparam typeCitation "obj" ""
    =#> functionResult pushCitation "Citation" "copy of obj"
  ]
{-# INLINABLE typeCitation #-}

-- | Constructor function for 'Citation' elements.
mkCitation :: LuaError e => DocumentedFunction e
mkCitation = defun "Citation"
  ### (\cid mode mprefix msuffix mnote_num mhash ->
         cid `seq` mode `seq` mprefix `seq` msuffix `seq`
         mnote_num `seq` mhash `seq` return $! Citation
           { citationId = cid
           , citationMode = mode
           , citationPrefix = fromMaybe mempty mprefix
           , citationSuffix = fromMaybe mempty msuffix
           , citationNoteNum = fromMaybe 0 mnote_num
           , citationHash = fromMaybe 0 mhash
           })
  <#> parameter peekText "string" "cid" "citation ID (e.g. bibtex key)"
  <#> parameter peekCitationMode "CitationMode" "mode" "citation rendering mode"
  <#> optionalParameter peekInlinesFuzzy "prefix" "Inlines" ""
  <#> optionalParameter peekInlinesFuzzy "suffix" "Inlines" ""
  <#> optionalParameter peekIntegral "note_num" "integer" "note number"
  <#> optionalParameter peekIntegral "hash" "integer" "hash number"
  =#> functionResult pushCitation "Citation" "new citation object"
  #? "Creates a single citation."

-- | Retrieves a Citation value from a string.
peekCitationMode :: LuaError e => Peeker e CitationMode
peekCitationMode = peekRead
{-# INLINE peekCitationMode #-}

-- | Pushes a CitationMode value as string.
pushCitationMode :: LuaError e => Pusher e CitationMode
pushCitationMode = pushString . show
{-# INLINE pushCitationMode #-}