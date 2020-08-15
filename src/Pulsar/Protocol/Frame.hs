{-# LANGUAGE OverloadedStrings #-}

module Pulsar.Protocol.Frame where

import qualified Data.Binary                   as B
import qualified Data.ByteString.Lazy.Char8    as CL
import           Data.Int                       ( Int32 )
import           Proto.PulsarApi                ( SingleMessageMetadata
                                                , MessageMetadata
                                                )

{- MaxFrameSize is defined by the Pulsar spec with a single
 - sentence: "The maximum allowable size of a single frame is 5 MB."
 -
 - http://pulsar.apache.org/docs/en/develop-binary-protocol/#framing
 -}
--maxFrameSize = 5 * 1024 * 1024 -- 5mb

data Frame = SimpleFrame SimpleCmd | PayloadFrame SimpleCmd PayloadCmd

-- Simple command: http://pulsar.apache.org/docs/en/develop-binary-protocol/#simple-commands
data SimpleCmd = SimpleCommand
  { frameTotalSize :: Int32        -- The size of the frame, counting everything that comes after it (4 bytes)
  , frameCommandSize :: Int32      -- The size of the protobuf-serialized command (4 bytes)
  , frameMessage :: CL.ByteString  -- The protobuf message serialized in a raw binary format (rather than in protobuf format)
  }

-- Payload command: http://pulsar.apache.org/docs/en/develop-binary-protocol/#payload-commands
data PayloadCmd = PayloadCommand
  { frameMagicNumber :: B.Word16        -- A 2-byte byte array (0x0e01) identifying the current format
  , frameCheckSum :: B.Word32           -- A CRC32-C checksum of everything that comes after it (4 bytes)
  , frameMetadataSize :: CL.ByteString  -- The size of the message metadata (4 bytes)
  , frameMetadata :: CL.ByteString      -- The message metadata stored as a binary protobuf message
  , framePayload :: CL.ByteString       -- Anything left in the frame is considered the payload and can include any sequence of bytes
  }

type Metadata = Either SingleMessageMetadata MessageMetadata

newtype Payload = Payload CL.ByteString