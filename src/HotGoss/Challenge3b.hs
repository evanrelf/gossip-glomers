module HotGoss.Challenge3b (main) where

import Data.Aeson (FromJSON, ToJSON)
import Data.Data (Data)
import HotGoss.Protocol
import HotGoss.Union
import Prelude hiding (Read, on)

import qualified Data.HashSet as HashSet

data Broadcast = Broadcast
  { msgId :: MessageId
  , inReplyTo :: Omitted
  , message :: Word
  }
  deriving stock (Generic, Data, Show)
  deriving (ToJSON, FromJSON) via MessageBodyJson Broadcast

data BroadcastOk = BroadcastOk
  { msgId :: MessageId
  , inReplyTo :: MessageId
  }
  deriving stock (Generic, Data, Show)
  deriving (ToJSON, FromJSON) via MessageBodyJson BroadcastOk

data Read = Read
  { msgId :: MessageId
  , inReplyTo :: Omitted
  }
  deriving stock (Generic, Data, Show)
  deriving (ToJSON, FromJSON) via MessageBodyJson Read

data ReadOk = ReadOk
  { msgId :: MessageId
  , inReplyTo :: MessageId
  , messages :: HashSet Word
  }
  deriving stock (Generic, Data, Show)
  deriving (ToJSON, FromJSON) via MessageBodyJson ReadOk

data Topology = Topology
  { msgId :: MessageId
  , inReplyTo :: Omitted
  , topology :: HashMap NodeId (HashSet NodeId)
  }
  deriving stock (Generic, Data, Show)
  deriving (ToJSON, FromJSON) via MessageBodyJson Topology

data TopologyOk = TopologyOk
  { msgId :: MessageId
  , inReplyTo :: MessageId
  }
  deriving stock (Generic, Data, Show)
  deriving (ToJSON, FromJSON) via MessageBodyJson TopologyOk

main :: IO ()
main = do
  messagesRef <- newIORef HashSet.empty

  (getMessageId, _, _) <- handleInit

  handle_ @Topology \body -> do
    -- TODO: body.topology
    msgId <- getMessageId
    pure TopologyOk
      { msgId
      , inReplyTo = body.msgId
      }

  let handleBroadcast :: Broadcast -> IO BroadcastOk
      handleBroadcast body = do
        msgId <- getMessageId
        atomicModifyIORef' messagesRef \ms -> (HashSet.insert body.message ms, ())
        pure BroadcastOk
          { msgId
          , inReplyTo = body.msgId
          }

  let handleRead :: Read -> IO ReadOk
      handleRead body = do
        msgId <- getMessageId
        messages <- readIORef messagesRef
        pure ReadOk
          { msgId
          , inReplyTo = body.msgId
          , messages
          }

  forever $ handle_ @_ @(Union '[BroadcastOk, ReadOk]) $
    case_
      `on` (\msg -> handleRead msg <&> inject)
      `on` (\msg -> handleBroadcast msg <&> inject)
