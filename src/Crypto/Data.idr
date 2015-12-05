module Crypto.Data

import Data.Fin
import Data.Vect

data BinaryDigit = O | I
%name BinaryDigit bit

bitToDecimal : BinaryDigit -> Integer
bitToDecimal O = 0
bitToDecimal I = 1

BinList : Type
BinList = List BinaryDigit
%name BinList bits

pad : Nat -> BinList -> BinList
pad n xs = let diff = n `minus` (length xs) in
               replicate diff O ++ xs

Byte : Type
Byte = Vect 8 BinaryDigit

hexCharToDecimal : Char -> Maybe Integer
hexCharToDecimal x =
  if isDigit x
  then Just $ cast $ singleton x
  else case x of
    'A' => Just 10
    'B' => Just 11
    'C' => Just 12
    'D' => Just 13
    'E' => Just 14
    'F' => Just 15
    _   => Nothing

isHexChar : Char -> Bool
isHexChar x =
  isDigit x || (x `elem` hexChars)
  where
    hexChars : List Char
    hexChars = unpack "ABCDEF"

hexToDecimal : String -> Maybe Integer
hexToDecimal x =
  let chars = reverse $ unpack $ toUpper x in
    hexToDecimal' 0 Z chars
  where
    hexToDecimal' : (acc : Integer) -> (pos : Nat) -> List Char -> Maybe Integer
    hexToDecimal' acc _ [] = Just acc
    hexToDecimal' acc pos (char::chars) =
      case hexCharToDecimal char of
        Nothing => Nothing
        Just n  => hexToDecimal' (acc + (n * (16 `pow` pos))) (pos + 1) chars

hexEx1 : hexToDecimal "1D9" = Just 473
hexEx1 = Refl

hexEx2 : hexToDecimal "80E1" = Just 32993
hexEx2 = Refl

hexEx3 : hexToDecimal "10CE" = Just 4302
hexEx3 = Refl

hexEx4 : hexToDecimal "877HOTLINEBLING" = Nothing
hexEx4 = Refl

isEven : Integer -> Bool
isEven = (==0) . (flip mod 2)

decimalToBinary' : (acc : List BinaryDigit) -> Integer -> BinList
decimalToBinary' acc 0 = O :: acc
decimalToBinary' acc 1 = I :: acc
decimalToBinary' acc n =
  if isEven n
  then decimalToBinary' (O :: acc) (n `div` 2)
  else decimalToBinary' (I :: acc) (n `div` 2)

binListShow : BinList -> String
binListShow [] = ""
binListShow (x :: xs) =
  case x of
    O => "0" ++ binListShow xs
    I => "1" ++ binListShow xs

decimalToBinary : Integer -> BinList
decimalToBinary = decimalToBinary' []

binToDecimal : BinList -> Integer
binToDecimal xs =
  binToDecimal' 0 Z $ reverse xs
  where
    binToDecimal' : (acc : Integer) -> (pos : Nat) -> BinList -> Integer
    binToDecimal' acc _ [] = acc
    binToDecimal' acc pos (bit :: bits) =
      let n = bitToDecimal bit in
        binToDecimal' (acc + (n * (2 `pow` pos))) (pos + 1) bits

binToNat : BinList -> Nat
binToNat = cast . binToDecimal

hexToBinary : Char -> Maybe BinList
hexToBinary x =
  do n <- hexCharToDecimal x
     return $ pad 4 $ decimalToBinary n

-- hex index is 4 bits
-- b64 index is 6 bits
-- LCM is 12 bits, i.e. 3 hex -> 2 b64

base64Chars : Vect 64 Char
base64Chars = fromList $ unpack
  $  "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  ++ "abcdefghijklmnopqrstuvwxyz"
  ++ "0123456789+/"

||| Divides the given list into a list of lists of (up to) `size` in length.
sizePartition : (size : Nat) -> List a -> List $ List a
sizePartition size [] = []
sizePartition size bits = (take size bits) :: (sizePartition size $ drop size bits)

||| Divides the given BinList into a list of BinLists which are all _exactly_
||| `size` in length. Pads the BinList with initial O's if necessary.
bitPartition : (size : Nat) -> BinList -> List BinList
bitPartition size bits =
  let padding = getPadding size bits
      padded = padding ++ bits in
    sizePartition size padded
  where
    getPadding : Nat -> BinList -> BinList
    getPadding size bits =
      let smallChunk = (length bits) `mod` size
          deficit = size `minus` smallChunk in
        replicate deficit O

base64Index : BinList -> Maybe Char
base64Index bits =
  let n = binToNat bits in
    do idx <- natToFin n 64
       return $ index idx base64Chars

hexToBase64 : String -> Maybe String
hexToBase64 x =
  do n <- hexToDecimal x
     bits <- Just $ decimalToBinary n
     bytes <- Just $ bitPartition 6 bits
     chars <- Just $ mapMaybe base64Index bytes
     return $ pack chars

-- hexToBase64Acceptance : hexToBase64 "49276d206b696c6c696e6720796f757220627261696e206c696b65206120706f69736f6e6f7573206d757368726f6f6d" = Just "SSdtIGtpbGxpbmcgeW91ciBicmFpbiBsaWtlIGEgcG9pc29ub3VzIG11c2hyb29t"
-- hexToBase64Acceptance = ?acceptance