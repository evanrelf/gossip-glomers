{-# LANGUAGE DuplicateRecordFields #-}

module HotGoss.Protocol
  ( Message (..)
  , Init (..)
  , InitOk (..)
  )
where

import Data.Aeson
import Data.Aeson.Types (Parser)
import Prelude hiding (init)

data Message a = Message
  { source :: Text
  , destination :: Text
  , body :: a
  }
  deriving stock (Show)

instance ToJSON a => ToJSON (Message a) where
  toJSON :: Message a -> Value
  toJSON message =
    object
      [ "src" .= message.source
      , "dest" .= message.destination
      , "body" .= message.body
      ]

instance FromJSON a => FromJSON (Message a) where
  parseJSON :: Value -> Parser (Message a)
  parseJSON =
    withObject "Message" \o -> do
      source <- o .: "src"
      destination <- o .: "dest"
      body <- o .: "body"
      pure Message{ source, destination, body }

data Init = Init
  { messageId :: Maybe Word
  , nodeId :: Text
  , nodeIds :: [Text]
  }
  deriving stock (Show)

instance ToJSON Init where
  toJSON :: Init -> Value
  toJSON init =
    object
      [ "type" .= ("init" :: Text)
      , "msg_id" .= init.messageId
      , "node_id" .= init.nodeId
      , "node_ids" .= init.nodeIds
      ]

instance FromJSON Init where
  parseJSON :: Value -> Parser Init
  parseJSON =
    withObject "Init" \o -> do
      type_ :: Text <- o .: "type"
      guard (type_ == "init")
      messageId <- o .: "msg_id"
      nodeId <- o .: "node_id"
      nodeIds <- o .: "node_ids"
      pure Init{ messageId, nodeId, nodeIds }

newtype InitOk = InitOk
  { inReplyTo :: Word
  }
  deriving stock (Show)

instance ToJSON InitOk where
  toJSON :: InitOk -> Value
  toJSON initOk =
    object
      [ "type" .= ("init_ok" :: Text)
      , "in_reply_to" .= initOk.inReplyTo
      ]

instance FromJSON InitOk where
  parseJSON :: Value -> Parser InitOk
  parseJSON =
    withObject "InitOk" \o -> do
      type_ :: Text <- o .: "type"
      guard (type_ == "init_ok")
      inReplyTo <- o .: "in_reply_to"
      pure InitOk{ inReplyTo }
