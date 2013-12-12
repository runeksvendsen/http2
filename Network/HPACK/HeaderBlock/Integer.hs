module Network.HPACK.HeaderBlock.Integer (
    encode
  , encodeOne
  , decode
  , decodeOne
  , parseInteger
  ) where

import Data.Array (Array, listArray, (!))
import Data.Word (Word8)

----------------------------------------------------------------

powerArray :: Array Int Int
powerArray = listArray (1,8) [1,3,7,15,31,63,127,255]

----------------------------------------------------------------

-- | Integer encoding. The first argument is N of prefix.
--
-- >>> encode 5 10
-- [10]
-- >>> encode 5 1337
-- [31,154,10]
-- >>> encode 8 42
-- [42]
encode :: Int -> Int -> [Word8]
encode n i
  | i < p     = fromIntegral i : []
  | otherwise = fromIntegral p : encode' (i - p)
  where
    p = powerArray ! n

encode' :: Int -> [Word8]
encode' i
  | i < 128   = fromIntegral i : []
  | otherwise = fromIntegral (r + 128) : encode' q
  where
    (q,r) = i `divMod` 128

----------------------------------------------------------------

-- | Integer encoding.
encodeOne :: Int -> Word8
encodeOne = fromIntegral

----------------------------------------------------------------

-- | Integer decoding. The first argument is N of prefix.
--
-- >>> decode 5 [10]
-- 10
-- >>> decode 5 [31,154,10]
-- 1337
-- >>> decode 8 [42]
-- 42
decode :: Int -> [Word8] -> Int
decode _ []     = error "decode"
decode n ws
  | i < p     = i
  | otherwise = foldr1 (\x y -> x - 128 + y * 128) is + i
  where
    p = powerArray ! n
    (i:is) = map fromIntegral ws

-- | Integer decoding.
decodeOne :: Word8 -> Int
decodeOne = fromIntegral

----------------------------------------------------------------

parseInteger :: Int -> Word8 -> [Word8] -> (Int, [Word8])
parseInteger n w ws
  | i < p     = (i, ws)
  | otherwise = (len, rest)
  where
    p = powerArray ! n
    i = fromIntegral w
    (ws', rest) = split ws
    len = decode n (w:ws')

split :: [Word8] -> ([Word8],[Word8])
split []     = error "split"
split (w:ws)
  | w >= 128  = let (xs,ys) = split ws in (w:xs, ys)
  | otherwise = ([w], ws)
