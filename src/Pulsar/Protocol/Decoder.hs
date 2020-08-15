{-# LANGUAGE LambdaCase, TupleSections #-}

module Pulsar.Protocol.Decoder where

import qualified Data.Binary                   as B
import qualified Data.Binary.Get               as B
import qualified Data.ByteString.Lazy          as BL
import qualified Data.ByteString.Char8         as C
import qualified Data.ByteString.Lazy.Char8    as CL
import           Data.Digest.CRC32C             ( crc32c )
import           Data.Int                       ( Int32 )
import           Data.Maybe                     ( fromMaybe )
import qualified Data.ProtoLens.Encoding       as PL
import qualified Data.ProtoLens.Encoding.Bytes as PL
import           Proto.PulsarApi                ( BaseCommand )
import           Pulsar.Protocol.Frame

parseFrame :: B.Get Frame
parseFrame = do
  ts <- B.getInt32be
  cs <- B.getInt32be
  ms <- B.getLazyByteString (fromIntegral cs)
  let simpleCmd = SimpleCommand ts cs ms
  B.isEmpty >>= \case
    True  -> return $ SimpleFrame simpleCmd
    False -> do
      mn <- B.getWord16be
      cm <- B.getWord32be
      ms <- B.getInt32be
      md <- B.getLazyByteString . fromIntegral $ ms
      pl <- B.getLazyByteString . fromIntegral $ ts - (10 + ms + cs)
      let payloadCmd = PayloadCommand mn cm ms md pl
      return $! PayloadFrame simpleCmd payloadCmd

-- TODO: Consider the payload as well
decodeBaseCommand
  :: CL.ByteString -> Either String (BaseCommand, Maybe Metadata)
decodeBaseCommand bytes = case B.runGet parseFrame bytes of
  SimpleFrame s ->
    (, Nothing) <$> PL.decodeMessage (CL.toStrict $ frameMessage s)
  PayloadFrame s p -> do
    cmd  <- PL.decodeMessage (CL.toStrict $ frameMessage s)
    meta <- PL.decodeMessage (CL.toStrict $ frameMetadata p)
    return (cmd, Just $ Right meta)
