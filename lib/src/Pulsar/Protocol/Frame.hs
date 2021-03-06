{- An internal representation of a frame, as specified by the Pulsar protocol: http://pulsar.apache.org/docs/en/develop-binary-protocol -}
module Pulsar.Protocol.Frame where

import qualified Data.Binary                   as B
import qualified Data.ByteString.Lazy.Char8    as CL
import           Data.Int                       ( Int32 )
import           Proto.PulsarApi                ( BaseCommand
                                                , MessageMetadata
                                                )
import           Pulsar.Protocol.CheckSum       ( CheckSum )

-- The maximum allowable size of a single frame is 5 MB: http://pulsar.apache.org/docs/en/develop-binary-protocol/#framing
frameMaxSize :: Int
frameMaxSize = 5 * 1024 * 1024 -- 5mb

-- A 2-byte byte array (0x0e01) identifying the current format
frameMagicNumber :: B.Word16
frameMagicNumber = 0x0e01

data Frame = SimpleFrame SimpleCmd | PayloadFrame SimpleCmd PayloadCmd

-- Simple command: http://pulsar.apache.org/docs/en/develop-binary-protocol/#simple-commands
data SimpleCmd = SimpleCommand
  { frameTotalSize :: Int32        -- The size of the frame, counting everything that comes after it (4 bytes)
  , frameCommandSize :: Int32      -- The size of the protobuf-serialized command (4 bytes)
  , frameMessage :: CL.ByteString  -- The protobuf message serialized in a raw binary format (rather than in protobuf format)
  }

-- Payload command: http://pulsar.apache.org/docs/en/develop-binary-protocol/#payload-commands
data PayloadCmd = PayloadCommand
  { frameCheckSum :: Maybe CheckSum -- A CRC32-C checksum of everything that comes after it (4 bytes) - OPTIONAL
  , frameMetadataSize :: Int32      -- The size of the message metadata (4 bytes)
  , frameMetadata :: CL.ByteString  -- The message metadata stored as a binary protobuf message
  , framePayload :: CL.ByteString   -- Anything left in the frame is considered the payload and can include any sequence of bytes
  }

newtype Payload = Payload CL.ByteString deriving Show

data Response = SimpleResponse BaseCommand | PayloadResponse BaseCommand MessageMetadata (Maybe Payload) deriving Show

getCommand :: Response -> BaseCommand
getCommand response = case response of
  (SimpleResponse cmd     ) -> cmd
  (PayloadResponse cmd _ _) -> cmd
