unit bigint;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

type
  TDigit = uint32;
  TDoubleDigit = uint64;

const
  DigitBits = SizeOf(TDigit) * 8;
  MaxDigit  = High(TDigit);

type
  TBigInt = record
  private
    Sign:   shortint;        // +1 for positive, -1 for negative, 0 for zero
    Digits: array of TDigit; // Absolute value in little-endian
    Length: SizeInt;         // Real length (without leading zeros)
    function GetAsString: string;
  public
    procedure Init;
    property AsString: string read GetAsString;
    property SignValue: shortint read Sign;
    // Mixed operations with int64
    class operator +(a: TBigInt; b: int64): TBigInt;
    class operator +(a: int64; b: TBigInt): TBigInt;
    class operator -(a: TBigInt; b: int64): TBigInt;
    class operator -(a: int64; b: TBigInt): TBigInt;
    class operator *(a: TBigInt; b: int64): TBigInt;
    class operator *(a: int64; b: TBigInt): TBigInt;
    class operator div(a: TBigInt; b: int64): TBigInt;
    class operator div(a: int64; b: TBigInt): TBigInt;
    class operator mod(a: TBigInt; b: int64): TBigInt;
    class operator mod(a: int64; b: TBigInt): TBigInt;
    // BigInt-BigInt operations
    class operator +(a, b: TBigInt): TBigInt;
    class operator -(a, b: TBigInt): TBigInt;
    class operator *(a, b: TBigInt): TBigInt;
    class operator div(a, b: TBigInt): TBigInt;
    class operator mod(a, b: TBigInt): TBigInt;
    class operator shl(a: TBigInt; b: integer): TBigInt;
    class operator shr(a: TBigInt; b: integer): TBigInt;
    class operator =(a, b: TBigInt): boolean;
    class operator <>(a, b: TBigInt): boolean;
    class operator <(a, b: TBigInt): boolean;
    class operator >(a, b: TBigInt): boolean;
    class operator <=(a, b: TBigInt): boolean;
    class operator >=(a, b: TBigInt): boolean;
  end;

procedure BigIntFromStr(var a: TBigInt; const s: string);
procedure BigIntFree(var a: TBigInt);
procedure BigIntFromInt64(var a: TBigInt; const Value: int64);
function BigIntToStr(const a: TBigInt): string;
function BigIntCompare(const a, b: TBigInt): integer;
function BigIntToHexStr(const a: TBigInt): string;
function BigIntToBinStr(const a: TBigInt): string;
procedure BigIntAdd(var res: TBigInt; const a_in, b_in: TBigInt);
procedure BigIntSub(var res: TBigInt; const a, b: TBigInt);
procedure BigIntMul(var res: TBigInt; const a, b: TBigInt);
function CountLeadingZeroBits(d: TDigit): integer;
procedure DivDoubleByDigit(out q: TDigit; out r: TDigit; hi, lo, d: TDigit);

implementation

procedure BigIntInit(var a: TBigInt); forward;
procedure BigIntCopy(var dest: TBigInt; const Source: TBigInt); forward;
procedure BigIntMulDigit(var res: TBigInt; const a: TBigInt; m: TDigit); forward;
function TryBigIntToUInt64(const a: TBigInt; out Value: uint64): boolean; forward;
procedure BigIntSHL(var res: TBigInt; const a: TBigInt; bits: cardinal); forward;
procedure BigIntSHR(var res: TBigInt; const a: TBigInt; bits: cardinal); forward;
procedure BigIntMulKaratsuba(var res: TBigInt; const a, b: TBigInt); forward;
procedure _BigIntMulKaratsubaRecursive(var res: TBigInt; const a, b: TBigInt; var scratch: array of TBigInt); forward;
function BigIntDivModDigit(var quot: TBigInt; const a: TBigInt; divisor: TDigit): TDigit; forward;
procedure BigIntSplit(var hi, lo: TBigInt; const a: TBigInt; m: SizeInt); forward;
procedure BigIntDivPow2(var res: TBigInt; const a: TBigInt; n: cardinal); forward;
procedure BigIntModPow2(var res: TBigInt; const a: TBigInt; n: cardinal); forward;
procedure BigIntShift(var res: TBigInt; const a: TBigInt; const b: TBigInt); forward;
procedure BigIntDivModKnuth(var q, r: TBigInt; const u_in, v_in: TBigInt); forward;
procedure BigIntDivMod(var q, r: TBigInt; const u, v: TBigInt); forward;
procedure _BigIntAddAbs_Unsafe(var res: TBigInt; const a, b: TBigInt); forward;
procedure _BigIntSubAbs_Unsafe(var res: TBigInt; const a, b: TBigInt); forward;

{ TBigInt }

procedure TBigInt.Init;
begin
  BigIntInit(Self);
end;

class operator TBigInt.+(a, b: TBigInt): TBigInt;
begin
  BigIntAdd(Result, a, b);
end;

class operator TBigInt.+(a: TBigInt; b: int64): TBigInt;
var
  tempB: TBigInt;
begin
  BigIntFromInt64(tempB, b);
  BigIntAdd(Result, a, tempB);
  BigIntFree(tempB);
end;

class operator TBigInt.+(a: int64; b: TBigInt): TBigInt;
var
  tempA: TBigInt;
begin
  BigIntFromInt64(tempA, a);
  BigIntAdd(Result, tempA, b);
  BigIntFree(tempA);
end;

class operator TBigInt.-(a, b: TBigInt): TBigInt;
begin
  BigIntSub(Result, a, b);
end;

class operator TBigInt.-(a: TBigInt; b: int64): TBigInt;
var
  tempB: TBigInt;
begin
  BigIntFromInt64(tempB, b);
  BigIntSub(Result, a, tempB);
  BigIntFree(tempB);
end;

class operator TBigInt.-(a: int64; b: TBigInt): TBigInt;
var
  tempA: TBigInt;
begin
  BigIntFromInt64(tempA, a);
  BigIntSub(Result, tempA, b);
  BigIntFree(tempA);
end;

class operator TBigInt.*(a, b: TBigInt): TBigInt;
begin
  BigIntMul(Result, a, b);
end;

class operator TBigInt.*(a: TBigInt; b: int64): TBigInt;
var
  tempB: TBigInt;
begin
  BigIntFromInt64(tempB, b);
  BigIntMul(Result, a, tempB);
  BigIntFree(tempB);
end;

class operator TBigInt.*(a: int64; b: TBigInt): TBigInt;
var
  tempA: TBigInt;
begin
  BigIntFromInt64(tempA, a);
  BigIntMul(Result, tempA, b);
  BigIntFree(tempA);
end;

class operator TBigInt.div(a, b: TBigInt): TBigInt;
var
  r: TBigInt;
begin
  BigIntDivMod(Result, r, a, b);
  BigIntFree(r);
end;

class operator TBigInt.div(a: TBigInt; b: int64): TBigInt;
var
  tempB, r: TBigInt;
begin
  BigIntFromInt64(tempB, b);
  BigIntDivMod(Result, r, a, tempB);
  BigIntFree(tempB);
  BigIntFree(r);
end;

class operator TBigInt.div(a: int64; b: TBigInt): TBigInt;
var
  tempA, r: TBigInt;
begin
  BigIntFromInt64(tempA, a);
  BigIntDivMod(Result, r, tempA, b);
  BigIntFree(tempA);
  BigIntFree(r);
end;

class operator TBigInt.mod(a, b: TBigInt): TBigInt;
var
  q: TBigInt;
begin
  BigIntDivMod(q, Result, a, b);
  BigIntFree(q);
end;

class operator TBigInt.mod(a: TBigInt; b: int64): TBigInt;
var
  tempB, q: TBigInt;
begin
  BigIntFromInt64(tempB, b);
  BigIntDivMod(q, Result, a, tempB);
  BigIntFree(tempB);
  BigIntFree(q);
end;

class operator TBigInt.mod(a: int64; b: TBigInt): TBigInt;
var
  tempA, q: TBigInt;
begin
  BigIntFromInt64(tempA, a);
  BigIntDivMod(q, Result, tempA, b);
  BigIntFree(tempA);
  BigIntFree(q);
end;

class operator TBigInt.shl(a: TBigInt; b: integer): TBigInt;
begin
  BigIntSHL(Result, a, b);
end;

class operator TBigInt.shr(a: TBigInt; b: integer): TBigInt;
begin
  BigIntSHR(Result, a, b);
end;

class operator TBigInt.=(a, b: TBigInt): boolean;
begin
  Result := BigIntCompare(a, b) = 0;
end;

class operator TBigInt.<>(a, b: TBigInt): boolean;
begin
  Result := BigIntCompare(a, b) <> 0;
end;

class operator TBigInt.<(a, b: TBigInt): boolean;
begin
  Result := BigIntCompare(a, b) < 0;
end;

class operator TBigInt.>(a, b: TBigInt): boolean;
begin
  Result := BigIntCompare(a, b) > 0;
end;

class operator TBigInt.<=(a, b: TBigInt): boolean;
begin
  Result := BigIntCompare(a, b) <= 0;
end;

class operator TBigInt.>=(a, b: TBigInt): boolean;
begin
  Result := BigIntCompare(a, b) >= 0;
end;

function TBigInt.GetAsString: string;
begin
  Result := BigIntToStr(Self);
end;

function _StrToInt(const s: string): TDigit;
var
  res: TDigit;
  i: integer;
begin
  res := 0;
  for i := 1 to System.Length(s) do
    res := res * 10 + (Ord(s[i]) - Ord('0'));
  Result := res;
end;

function _IntToStr(n: TDigit): string;
var
  s: string;
  d: TDigit;
begin
  if n = 0 then Exit('0');
  s := '';
  d := n;
  while d > 0 do
  begin
    s := Chr(d mod 10 + Ord('0')) + s;
    d := d div 10;
  end;
  Result := s;
end;


// Internal procedure to normalize a TBigInt (remove leading zeros)
procedure Normalize(var a: TBigInt);
begin
  while (a.Length > 1) and (a.Digits[a.Length - 1] = 0) do
    Dec(a.Length);
  if (a.Length = 1) and (a.Digits[0] = 0) then
    a.Sign := 0;
end;

// Internal procedure to set the length of the Digits array
procedure SetIntLength(var a: TBigInt; newLength: SizeInt);
var
  newCapacity: SizeInt;
begin
  if newLength > System.Length(a.Digits) then
  begin
    newCapacity := System.Length(a.Digits);
    if newCapacity = 0 then
      newCapacity := 1;
    while newCapacity < newLength do
    begin
      if newCapacity > High(newCapacity) div 2 then
      begin
        // Prevent overflow - set to maximum reasonable size
        newCapacity := newLength;
        Break;
      end;
      newCapacity := newCapacity * 2;
    end;
    System.SetLength(a.Digits, newCapacity);
  end;
  a.Length := newLength;
end;


procedure BigIntInit(var a: TBigInt);
begin
  a.Sign   := 0;
  a.Digits := nil;
  a.Length := 0;
end;

procedure BigIntFree(var a: TBigInt);
begin
  Finalize(a.Digits);
  a.Digits := nil;
  a.Length := 0;
  a.Sign   := 0;
end;

procedure BigIntCopy(var dest: TBigInt; const Source: TBigInt);
var
  i: SizeInt;
begin
  if @dest = @Source then Exit;
  BigIntFree(dest);
  SetIntLength(dest, Source.Length);
  dest.Sign := Source.Sign;
  for i := 0 to Source.Length - 1 do
    dest.Digits[i] := Source.Digits[i];
end;

procedure BigIntMulDigit(var res: TBigInt; const a: TBigInt; m: TDigit);
var
  i:    SizeInt;
  carry, p: TDoubleDigit;
begin
  if (a.Sign = 0) or (m = 0) then
  begin
    SetIntLength(res, 1);
    res.Digits[0] := 0;
    res.Sign      := 0;
    Exit;
  end;

  SetIntLength(res, a.Length + 1);
  carry := 0;
  for i := 0 to a.Length - 1 do
  begin
    p     := TDoubleDigit(a.Digits[i]) * m + carry;
    res.Digits[i] := p and MaxDigit;
    carry := p shr DigitBits;
  end;
  res.Digits[a.Length] := carry;
  res.Sign := a.Sign;
  Normalize(res);
end;

procedure BigIntFromStr(var a: TBigInt; const s: string);
const
  BlockSize = 9;
  PowersOf10: array[1..BlockSize] of TDigit =
    (10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000, 1000000000);
var
  isNegative:  boolean;
  startIndex, blockLength: integer;
  blockValue:  TDigit;
  blockStr:    string;
  blockBigInt: TBigInt;
begin
  BigIntFree(a);
  BigIntInit(a);

  if (s = '') or (s = '0') then
  begin
    SetIntLength(a, 1);
    a.Digits[0] := 0;
    a.Sign      := 0;
    Exit;
  end;

  startIndex := 1;
  isNegative := s[1] = '-';
  if isNegative or (s[1] = '+') then
    startIndex := 2;

  // Initialize the number to zero
  SetIntLength(a, 1);
  a.Digits[0] := 0;
  a.Sign      := 0;

  BigIntInit(blockBigInt);

  while startIndex <= System.Length(s) do
  begin
    blockLength := System.Length(s) - startIndex + 1;
    if blockLength > BlockSize then
      blockLength := BlockSize;
    blockStr    := System.Copy(s, startIndex, blockLength);
    blockValue  := _StrToInt(blockStr);

    // Multiply the current result by 10^blockLength
    if a.Sign <> 0 then
    begin
      if blockLength > 0 then
        BigIntMulDigit(a, a, PowersOf10[blockLength]);
    end;

    // Add the value of the block
    SetIntLength(blockBigInt, 1);
    blockBigInt.Digits[0] := blockValue;
    blockBigInt.Sign      := 1;
    Normalize(blockBigInt);

    BigIntAdd(a, a, blockBigInt);

    startIndex := startIndex + blockLength;
  end;

  if isNegative then
    a.Sign := -1
  else
    a.Sign := 1;

  Normalize(a);

  BigIntFree(blockBigInt);
end;

procedure BigIntFromInt64(var a: TBigInt; const Value: int64);
var
  abs_val: uint64;
begin
  BigIntFree(a);

  if Value = 0 then
  begin
    SetIntLength(a, 1);
    a.Digits[0] := 0;
    a.Sign      := 0;
    Exit;
  end;

  if Value > 0 then
  begin
    a.Sign  := 1;
    abs_val := Value;
  end
  else
  begin
    a.Sign := -1;
    if Value = Low(int64) then
      // Special case, since -Low(Int64) causes an overflow
      abs_val := uint64(High(int64)) + 1
    else
      abs_val := -Value;
  end;

  if abs_val <= MaxDigit then
  begin
    SetIntLength(a, 1);
    a.Digits[0] := abs_val;
  end
  else
  begin
    SetIntLength(a, 2);
    a.Digits[0] := abs_val and MaxDigit;
    a.Digits[1] := abs_val shr DigitBits;
  end;
  Normalize(a);
end;

// Helper function to safely convert a TBigInt to a UInt64
function TryBigIntToUInt64(const a: TBigInt; out Value: uint64): boolean;
begin
  Result := False;
  if (a.Sign < 0) or (a.Length > 2) then Exit;

  if a.Sign = 0 then
  begin
    Value  := 0;
    Result := True;
    Exit;
  end;

  if a.Length = 1 then
    Value := a.Digits[0]
  else // a.Length = 2
    Value := (uint64(a.Digits[1]) shl DigitBits) or a.Digits[0];

  Result := True;
end;

procedure BigIntSplit(var hi, lo: TBigInt; const a: TBigInt; m: SizeInt);
var
  loLen: SizeInt;
begin
  if m <= 0 then
  begin
    // Invalid split - put everything in lo
    BigIntCopy(lo, a);
    SetIntLength(hi, 1);
    hi.Digits[0] := 0;
    hi.Sign := 0;
    Exit;
  end;
  
  if a.Length > m then
  begin
    SetIntLength(hi, a.Length - m);
    if (a.Length - m) > 0 then
      System.Move(a.Digits[m], hi.Digits[0], (a.Length - m) * SizeOf(TDigit))
    else
      hi.Digits[0] := 0;
    hi.Sign := a.Sign; // The sign must be inherited
    Normalize(hi);
  end
  else
  begin
    SetIntLength(hi, 1);
    hi.Digits[0] := 0;
    hi.Sign      := 0;
  end;

  loLen := a.Length;
  if loLen > m then
    loLen := m;

  SetIntLength(lo, loLen);
  if loLen > 0 then
    System.Move(a.Digits[0], lo.Digits[0], loLen * SizeOf(TDigit))
  else
    lo.Digits[0] := 0;
  lo.Sign := a.Sign; // And here too
  Normalize(lo);
end;


// Helper function to safely convert a TBigInt to an Int64
function TryBigIntToInt64(const a: TBigInt; out Value: int64): boolean;
var
  abs_val: uint64;
begin
  Result := False;
  if a.Length > 2 then Exit;

  if a.Sign = 0 then
  begin
    Value  := 0;
    Result := True;
    Exit;
  end;

  if a.Length = 1 then
    abs_val := a.Digits[0]
  else // a.Length = 2
    abs_val := (uint64(a.Digits[1]) shl DigitBits) or a.Digits[0];

  if a.Sign = 1 then
  begin
    if abs_val > High(int64) then Exit;
    Value := int64(abs_val);
  end
  else // a.Sign = -1
  begin
    if abs_val = (uint64(High(int64)) + 1) then
    begin
      Value  := Low(int64);
      Result := True;
      Exit;
    end;
    if abs_val > High(int64) then Exit;
    Value := -int64(abs_val);
  end;

  Result := True;
end;

function BigIntToStr(const a: TBigInt): string;
const
  divisor = 1000000000;
var
  temp, quot: TBigInt;
  res, s: string;
  rem: TDigit;
begin
  if a.Sign = 0 then
    Exit('0');

  BigIntInit(temp);
  BigIntCopy(temp, a);

  res := '';

  BigIntInit(quot);
  repeat
    rem := BigIntDivModDigit(quot, temp, divisor);

    s := _IntToStr(rem);

    if quot.Sign <> 0 then
    begin
      while System.Length(s) < 9 do
        s := '0' + s;
    end;

    res := s + res;

    BigIntCopy(temp, quot);

  until temp.Sign = 0;

  BigIntFree(quot);

  if a.Sign = -1 then
    res := '-' + res;

  BigIntFree(temp);
  Exit(res);
end;

procedure BigIntSHL(var res: TBigInt; const a: TBigInt; bits: cardinal);
var
  wordShift, bitShift: cardinal;
  i:    SizeInt;
  carry, p: TDoubleDigit;
  newLength: SizeInt;
begin
  if (a.Sign = 0) or (bits = 0) then
  begin
    if @res <> @a then
      BigIntCopy(res, a);
    Exit;
  end;

  wordShift := bits div DigitBits;
  bitShift  := bits mod DigitBits;

  carry := (TDoubleDigit(a.Digits[a.Length - 1]) shl bitShift) shr DigitBits;
  if carry > 0 then
    newLength := a.Length + wordShift + 1
  else
    newLength := a.Length + wordShift;

  SetIntLength(res, newLength);
  res.Sign := a.Sign;

  for i := 0 to wordShift - 1 do
    res.Digits[i] := 0;

  if bitShift = 0 then
  begin
    for i := 0 to a.Length - 1 do
      res.Digits[i + wordShift] := a.Digits[i];
  end
  else
  begin
    carry := 0;
    for i := 0 to a.Length - 1 do
    begin
      p     := (TDoubleDigit(a.Digits[i]) shl bitShift) or carry;
      res.Digits[i + wordShift] := p and MaxDigit;
      carry := p shr DigitBits;
    end;
    if carry > 0 then
      res.Digits[a.Length + wordShift] := carry;
  end;

  Normalize(res);
end;

procedure BigIntSHR(var res: TBigInt; const a: TBigInt; bits: cardinal);
var
  wordShift, bitShift: cardinal;
  i:    SizeInt;
  carry, p: TDoubleDigit;
  newLength: SizeInt;
begin
  if (a.Sign = 0) or (bits = 0) then
  begin
    if @res <> @a then
      BigIntCopy(res, a);
    Exit;
  end;

  wordShift := bits div DigitBits;
  bitShift  := bits mod DigitBits;

  if wordShift >= a.Length then
  begin
    SetIntLength(res, 1);
    res.Digits[0] := 0;
    res.Sign      := 0;
  end
  else
  begin
    newLength := a.Length - wordShift;
    SetIntLength(res, newLength);
    res.Sign := a.Sign;

    if bitShift = 0 then
    begin
      for i := 0 to newLength - 1 do
        res.Digits[i] := a.Digits[i + wordShift];
    end
    else
    begin
      carry := 0;
      for i := newLength - 1 downto 0 do
      begin
        p     := (TDoubleDigit(a.Digits[i + wordShift]) shr bitShift) or carry;
        res.Digits[i] := p and MaxDigit;
        carry := TDoubleDigit(a.Digits[i + wordShift]) shl (DigitBits - bitShift);
      end;
    end;
    Normalize(res);
  end;
end;

// Helper function to compare absolute values
function CompareAbs(const a, b: TBigInt): integer;
var
  i: integer;
begin
  if a.Length > b.Length then Exit(1);
  if a.Length < b.Length then Exit(-1);
  for i := a.Length - 1 downto 0 do
  begin
    if a.Digits[i] > b.Digits[i] then Exit(1);
    if a.Digits[i] < b.Digits[i] then Exit(-1);
  end;
  Exit(0);
end;

// Addition of absolute values
procedure BigIntAddAbs(var res: TBigInt; const a, b: TBigInt);
var
  i:     SizeInt;
  carry: TDoubleDigit;
  p:     TDoubleDigit;
  maxLength, minLength: SizeInt;
  pMax:  ^TBigInt;
begin
  if a.Length > b.Length then
  begin
    maxLength := a.Length;
    minLength := b.Length;
    pMax      := @a;
  end
  else
  begin
    maxLength := b.Length;
    minLength := a.Length;
    pMax      := @b;
  end;

  SetIntLength(res, maxLength + 1);

  carry := 0;
  for i := 0 to minLength - 1 do
  begin
    p     := TDoubleDigit(a.Digits[i]) + b.Digits[i] + carry;
    res.Digits[i] := p and MaxDigit;
    carry := p shr DigitBits;
  end;

  for i := minLength to maxLength - 1 do
  begin
    p     := TDoubleDigit(pMax^.Digits[i]) + carry;
    res.Digits[i] := p and MaxDigit;
    carry := p shr DigitBits;
  end;

  res.Digits[maxLength] := carry;
  Normalize(res);
end;

// Subtraction of absolute values (a > b)
procedure BigIntSubAbs(var res: TBigInt; const a, b: TBigInt);
var
  i:      SizeInt;
  borrow: int64;
  p:      int64;
begin
  SetIntLength(res, a.Length);

  borrow := 0;
  for i := 0 to b.Length - 1 do
  begin
    p := int64(a.Digits[i]) - b.Digits[i] - borrow;
    if p < 0 then
    begin
      res.Digits[i] := p + (TDoubleDigit(1) shl DigitBits);
      borrow := 1;
    end
    else
    begin
      res.Digits[i] := p;
      borrow := 0;
    end;
  end;

  for i := b.Length to a.Length - 1 do
  begin
    p := int64(a.Digits[i]) - borrow;
    if p < 0 then
    begin
      res.Digits[i] := p + (TDoubleDigit(1) shl DigitBits);
      borrow := 1;
    end
    else
    begin
      res.Digits[i] := p;
      borrow := 0;
    end;
  end;
  Normalize(res);
end;


procedure BigIntAdd(var res: TBigInt; const a_in, b_in: TBigInt);
var
  cmp:  integer;
  valA, valB: int64;
begin
  // Fast path for "short" numbers
  if TryBigIntToInt64(a_in, valA) and TryBigIntToInt64(b_in, valB) then
  begin
    if not ((valA > 0) and (valB > 0) and (valA > High(int64) - valB)) and
      not ((valA < 0) and (valB < 0) and (valA < Low(int64) - valB)) then
    begin
      BigIntFromInt64(res, valA + valB);
      Exit;
    end;
  end;

  if a_in.Sign = 0 then
  begin
    if @res <> @b_in then
      BigIntCopy(res, b_in);
    Exit;
  end;
  if b_in.Sign = 0 then
  begin
    if @res <> @a_in then
      BigIntCopy(res, a_in);
    Exit;
  end;

  if a_in.Sign = b_in.Sign then
  begin
    BigIntAddAbs(res, a_in, b_in);
    res.Sign := a_in.Sign;
  end
  else
  begin
    cmp := CompareAbs(a_in, b_in);
    if cmp > 0 then
    begin
      BigIntSubAbs(res, a_in, b_in);
      res.Sign := a_in.Sign;
    end
    else if cmp < 0 then
    begin
      BigIntSubAbs(res, b_in, a_in);
      res.Sign := b_in.Sign;
    end
    else
    begin
      SetIntLength(res, 1);
      res.Digits[0] := 0;
      res.Sign      := 0;
    end;
  end;
end;

procedure BigIntSub(var res: TBigInt; const a, b: TBigInt);
var
  cmp: integer;
  valA, valB: int64;
begin
  // Fast path for "short" numbers
  if TryBigIntToInt64(a, valA) and TryBigIntToInt64(b, valB) then
  begin
    // Check for overflow before subtracting
    if not ((valA > 0) and (valB < 0) and (valA > High(int64) + valB)) and
      not ((valA < 0) and (valB > 0) and (valA < Low(int64) + valB)) then
    begin
        BigIntFromInt64(res, valA - valB);
        Exit;
    end;
  end;

  if b.Sign = 0 then
  begin
    if @res <> @a then
      BigIntCopy(res, a);
    Exit;
  end;
  
  if a.Sign = 0 then
  begin
    if @res = @b then // handle b := 0 - b
    begin
      res.Sign := -res.Sign;
    end
    else
    begin
      BigIntCopy(res, b);
      res.Sign := -b.Sign;
    end;
    Exit;
  end;

  if a.Sign <> b.Sign then // a - (-b) is a+b, (-a) - b is -(a+b)
  begin
    BigIntAddAbs(res, a, b);
    res.Sign := a.Sign;
  end
  else // signs are the same
  begin
    cmp := CompareAbs(a, b);
    if cmp > 0 then // |a| > |b|
    begin
      BigIntSubAbs(res, a, b);
      res.Sign := a.Sign;
    end
    else if cmp < 0 then // |b| > |a|
    begin
      BigIntSubAbs(res, b, a);
      res.Sign := -a.Sign; // sign is flipped, e.g. 5-8=-3, sign of 5 is +, result is -
    end
    else // a = b
    begin
      SetIntLength(res, 1);
      res.Digits[0] := 0;
      res.Sign      := 0;
    end;
  end;
end;

procedure BigIntMul_School(var res: TBigInt; const a, b: TBigInt);
var
  i, j:      SizeInt;
  carry, p:  TDoubleDigit;
  newLength: SizeInt;
  tempA, tempB: TBigInt;
  useTempA, useTempB: boolean;
  ptrA, ptrB: ^TBigInt;
begin
  // Handle aliasing: if res is the same as a or b, we need to create a temporary copy.
  useTempA := @res = @a;
  useTempB := @res = @b;

  if useTempA then
  begin
    BigIntInit(tempA);
    BigIntCopy(tempA, a);
    ptrA := @tempA;
  end
  else
  begin
    ptrA := @a;
  end;

  if useTempB then
  begin
    BigIntInit(tempB);
    BigIntCopy(tempB, b);
    ptrB := @tempB;
  end
  else
  begin
    ptrB := @b;
  end;


  if (ptrA^.Sign = 0) or (ptrB^.Sign = 0) then
  begin
    SetIntLength(res, 1);
    res.Digits[0] := 0;
    res.Sign      := 0;
  end
  else
  begin
    newLength := ptrA^.Length + ptrB^.Length;
    SetIntLength(res, newLength);

    // Zero out the result digits
    for i := 0 to newLength - 1 do
      res.Digits[i] := 0;

    for i := 0 to ptrA^.Length - 1 do
    begin
      carry := 0;
      for j := 0 to ptrB^.Length - 1 do
      begin
        p := TDoubleDigit(ptrA^.Digits[i]) * ptrB^.Digits[j] + res.Digits[i + j] + carry;
        res.Digits[i + j] := p and MaxDigit;
        carry := p shr DigitBits;
      end;
      res.Digits[i + ptrB^.Length] := carry;
    end;

    if ptrA^.Sign = ptrB^.Sign then
      res.Sign := 1
    else
      res.Sign := -1;

    Normalize(res);
  end;

  if useTempA then BigIntFree(tempA);
  if useTempB then BigIntFree(tempB);
end;

procedure BigIntMul(var res: TBigInt; const a, b: TBigInt);
const
  KARATSUBA_THRESHOLD = 32;
var
  valA, valB: int64;
begin
  if (a.Sign = 0) or (b.Sign = 0) then
  begin
    SetIntLength(res, 1);
    res.Digits[0] := 0;
    res.Sign      := 0;
    Exit;
  end;

  // Fast path for Int64
  if TryBigIntToInt64(a, valA) and TryBigIntToInt64(b, valB) then
  begin
    // Overflow check
    if (valA > 0) and (valB > 0) and (valA > High(int64) div valB) then
    begin
      // Positive overflow, use slow path
    end
    else if (valA < 0) and (valB < 0) and (valA < High(int64) div valB) then
    begin
      // Positive overflow, use slow path
    end
    else if (valA > 0) and (valB < 0) and (valB < Low(int64) div valA) then
    begin
      // Negative overflow, use slow path
    end
    else if (valA < 0) and (valB > 0) and (valA < Low(int64) div valB) then
    begin
      // Negative overflow, use slow path
    end
    else
    begin
      BigIntFromInt64(res, valA * valB);
      Exit;
    end;
  end;

  if (a.Length < KARATSUBA_THRESHOLD) or (b.Length < KARATSUBA_THRESHOLD) then
  begin
    BigIntMul_School(res, a, b);
  end
  else
  begin
    BigIntMulKaratsuba(res, a, b);
  end;
end;

procedure _BigIntMulKaratsubaRecursive(var res: TBigInt; const a, b: TBigInt;
  var scratch: array of TBigInt);
var
  m, m2: SizeInt;
  p_a_lo, p_a_hi, p_b_lo, p_b_hi, p_p0, p_p1, p_p2, p_t1, p_t2: ^TBigInt;
  temp:  TBigInt;
begin
  if (a.Sign = 0) or (b.Sign = 0) then
  begin
    SetIntLength(res, 1);
    res.Digits[0] := 0;
    res.Sign      := 0;
    Exit;
  end;

  if (a.Length < 32) or (b.Length < 32) then
  begin
    BigIntMul_School(res, a, b);
    Exit;
  end;

  if a.Length > b.Length then
    m := a.Length div 2
  else
    m := b.Length div 2;
  m2 := m * 2;

  // Use scratch space pointers
  p_a_lo := @scratch[0];
  p_a_hi := @scratch[1];
  p_b_lo := @scratch[2];
  p_b_hi := @scratch[3];
  p_p0   := @scratch[4];
  p_p1   := @scratch[5];
  p_p2   := @scratch[6];
  p_t1   := @scratch[7];
  p_t2   := @scratch[8];

  // Split the numbers
  BigIntSplit(p_a_hi^, p_a_lo^, a, m);
  BigIntSplit(p_b_hi^, p_b_lo^, b, m);

  // Recursive calls
  _BigIntMulKaratsubaRecursive(p_p0^, p_a_lo^, p_b_lo^, scratch);
  _BigIntMulKaratsubaRecursive(p_p2^, p_a_hi^, p_b_hi^, scratch);

  _BigIntAddAbs_Unsafe(p_t1^, p_a_lo^, p_a_hi^);
  Normalize(p_t1^);
  _BigIntAddAbs_Unsafe(p_t2^, p_b_lo^, p_b_hi^);
  Normalize(p_t2^);
  _BigIntMulKaratsubaRecursive(p_p1^, p_t1^, p_t2^, scratch);

  // Combine the results: p1 = p1 - p0 - p2
  _BigIntSubAbs_Unsafe(p_p1^, p_p1^, p_p0^);
  Normalize(p_p1^);
  _BigIntSubAbs_Unsafe(p_p1^, p_p1^, p_p2^);
  Normalize(p_p1^);


  // res = p2 * B^2m + p1 * B^m + p0
  BigIntSHL(p_p2^, p_p2^, m2 * DigitBits);
  BigIntSHL(p_p1^, p_p1^, m * DigitBits);

  BigIntInit(temp);
  _BigIntAddAbs_Unsafe(temp, p_p0^, p_p1^);
  _BigIntAddAbs_Unsafe(temp, temp, p_p2^);
  Normalize(temp);


  if a.Sign = b.Sign then
    temp.Sign := 1
  else
    temp.Sign := -1;

  BigIntCopy(res, temp);
  BigIntFree(temp);
end;

procedure BigIntMulKaratsuba(var res: TBigInt; const a, b: TBigInt);
var
  scratch: array of TBigInt;
  i: integer;
begin
  if (a.Sign = 0) or (b.Sign = 0) then
  begin
    SetIntLength(res, 1);
    res.Digits[0] := 0;
    res.Sign      := 0;
    Exit;
  end;

  SetLength(scratch, 9);
  for i := 0 to High(scratch) do
    BigIntInit(scratch[i]);

  _BigIntMulKaratsubaRecursive(res, a, b, scratch);

  if a.Sign = b.Sign then
    res.Sign := 1
  else
    res.Sign := -1;
  Normalize(res);

  for i := 0 to High(scratch) do
    BigIntFree(scratch[i]);
end;


function BigIntCompare(const a, b: TBigInt): integer;
var
  valA, valB: int64;
begin
  // Fast path for "short" numbers
  if TryBigIntToInt64(a, valA) and TryBigIntToInt64(b, valB) then
  begin
    if valA > valB then Exit(1);
    if valA < valB then Exit(-1);
    Exit(0);
  end;

  if a.Sign > b.Sign then Exit(1);
  if a.Sign < b.Sign then Exit(-1);
  // Signs are equal
  if a.Sign = 0 then Exit(0); // both are 0

  if a.Sign = 1 then
    Exit(CompareAbs(a, b))
  else // a.Sign = -1
    Exit(-CompareAbs(a, b));
end;

function BigIntDivModDigit(var quot: TBigInt; const a: TBigInt; divisor: TDigit): TDigit;
var
  rem:  TDoubleDigit;
  i:    integer;
  temp: TBigInt;
begin
  if divisor = 0 then
  begin
    // Handle division by zero error - return original number
    BigIntCopy(quot, a);
    Exit(0);
  end;

  BigIntInit(temp);
  SetIntLength(temp, a.Length);
  temp.Sign := a.Sign;

  rem := 0;
  for i := a.Length - 1 downto 0 do
  begin
    rem := (rem shl DigitBits) + a.Digits[i];
    temp.Digits[i] := rem div divisor;
    rem := rem mod divisor;
  end;

  Normalize(temp);
  BigIntCopy(quot, temp);
  BigIntFree(temp);

  Result := rem;
end;

procedure BigIntDivPow2(var res: TBigInt; const a: TBigInt; n: cardinal);
begin
  BigIntSHR(res, a, n);
end;

procedure BigIntModPow2(var res: TBigInt; const a: TBigInt; n: cardinal);
var
  wordCount, bitCount: cardinal;
  mask: TDigit;
  i:    SizeInt;
begin
  if n = 0 then
  begin
    SetIntLength(res, 1);
    res.Digits[0] := 0;
    res.Sign      := 0;
    Exit;
  end;

  if @res <> @a then
    BigIntCopy(res, a);

  wordCount := (n + DigitBits - 1) div DigitBits;
  bitCount  := n mod DigitBits;

  if wordCount > res.Length then
  begin
    // n is larger than the number of bits in the number, the remainder is the number itself
    Exit;
  end;

  // Zero out the higher digits
  for i := wordCount to res.Length - 1 do
    res.Digits[i] := 0;

  // Create a mask for the desired digit
  if bitCount > 0 then
  begin
    mask := (TDigit(1) shl bitCount) - 1;
    res.Digits[wordCount - 1] := res.Digits[wordCount - 1] and mask;
  end;

  Normalize(res);
end;

// Helper function to check if a number is a power of two
function IsPowerOfTwo(const a: TBigInt): boolean;
var
  i:     SizeInt;
  digit: TDigit;
  setBits: integer;
begin
  if a.Sign <= 0 then Exit(False);

  setBits := 0;
  // Check all digits for the number of set bits
  for i := 0 to a.Length - 1 do
  begin
    digit := a.Digits[i];
    if digit <> 0 then
    begin
      // If we have already found one set bit, and the current digit is not zero,
      // then there is more than one set bit.
      if setBits > 0 then Exit(False);

      // Check if the digit itself is a power of two
      if (digit and (digit - 1)) <> 0 then Exit(False);

      setBits := 1;
    end;
  end;

  Exit(setBits = 1);
end;

// Helper function to count bits
function bitCount(const a: TBigInt): integer;
var
  lastDigit: TDigit;
  Count:     integer;
begin
  if a.Sign = 0 then Exit(0);

  Count     := (a.Length - 1) * DigitBits;
  lastDigit := a.Digits[a.Length - 1];

  while lastDigit > 0 do
  begin
    Inc(Count);
    lastDigit := lastDigit shr 1;
  end;

  Exit(Count);
end;

// Helper function to round up to a power of two
function RoundUpToStandardWidth(n: integer): integer;
begin
  Result := 8;
  while Result < n do
    Result := Result * 2;
end;

// Internal function for converting to a string with a power of 2 base
function BigIntToBasePow2Str(const a: TBigInt; bitsPerChar: cardinal; const chars: string): string;
var
  temp, remainder, powerOf2, a_abs: TBigInt;
  res:   string;
  remainder_val: TDigit;
  Width: integer;
begin
  if a.Sign = 0 then Exit('0');

  BigIntInit(temp);
  BigIntInit(remainder);

  if a.Sign = 1 then
  begin
    BigIntCopy(temp, a);
  end
  else // a.Sign = -1
  begin
    BigIntInit(a_abs);
    BigIntCopy(a_abs, a);
    a_abs.Sign := 1;

    Width := bitCount(a_abs);
    if not IsPowerOfTwo(a_abs) then
      Inc(Width);

    Width := RoundUpToStandardWidth(Width);

    BigIntInit(powerOf2);
    SetIntLength(powerOf2, 1);
    powerOf2.Digits[0] := 1;
    powerOf2.Sign      := 1;
    BigIntSHL(powerOf2, powerOf2, Width);

    BigIntSub(temp, powerOf2, a_abs);

    BigIntFree(powerOf2);
    BigIntFree(a_abs);
  end;

  res := '';
  if temp.Sign = 0 then res := '0';
  while temp.Sign <> 0 do
  begin
    BigIntModPow2(remainder, temp, bitsPerChar);
    if remainder.Sign = 0 then
      remainder_val := 0
    else
      remainder_val := remainder.Digits[0];
    res := chars[remainder_val + 1] + res;
    BigIntDivPow2(temp, temp, bitsPerChar);
  end;

  BigIntFree(temp);
  BigIntFree(remainder);
  Exit(res);
end;

function BigIntToHexStr(const a: TBigInt): string;
begin
  Exit(BigIntToBasePow2Str(a, 4, '0123456789ABCDEF'));
end;

function BigIntToBinStr(const a: TBigInt): string;
begin
  Exit(BigIntToBasePow2Str(a, 1, '01'));
end;

procedure BigIntShift(var res: TBigInt; const a: TBigInt; const b: TBigInt);
var
  shift_amount: uint64;
  ok:    boolean;
  abs_b: TBigInt;
  shift_cardinal: cardinal;
begin
  if a.Sign = 0 then
  begin
    BigIntFromInt64(res, 0);
    Exit;
  end;

  if b.Sign = 0 then
  begin
    BigIntCopy(res, a);
    Exit;
  end;

  BigIntInit(abs_b);
  BigIntCopy(abs_b, b);
  abs_b.Sign := 1; // Make it positive to get magnitude

  ok := TryBigIntToUInt64(abs_b, shift_amount);
  BigIntFree(abs_b);

  if not ok then // Shift amount is too large to fit in UInt64
  begin
    if b.Sign > 0 then // Left shift by enormous amount
    begin
      // We can't represent this shift. Let's shift by max possible.
      // This will probably cause an out-of-memory error, which is a reasonable outcome.
      BigIntSHL(res, a, High(cardinal));
    end
    else // Right shift by enormous amount
    begin
      BigIntFromInt64(res, 0);
    end;
    Exit;
  end;

  // If the shift amount fits in UInt64, but is larger than High(Cardinal)
  if shift_amount > High(cardinal) then
  begin
    if b.Sign > 0 then // Left shift
    begin
      BigIntSHL(res, a, High(cardinal));
    end
    else // Right shift
    begin
      // A shift amount larger than High(Cardinal) will definitely reduce the number to 0
      BigIntFromInt64(res, 0);
    end;
    Exit;
  end;

  shift_cardinal := cardinal(shift_amount);

  if b.Sign > 0 then
  begin
    BigIntSHL(res, a, shift_cardinal);
  end
  else
  begin
    BigIntSHR(res, a, shift_cardinal);
  end;
end;

function CountLeadingZeroBits(d: TDigit): integer;
begin
  if d = 0 then
    Result := DigitBits
  else
  begin
    Result := 0;
    while (d and (TDigit(1) shl (DigitBits - 1))) = 0 do
    begin
      Inc(Result);
      d := d shl 1;
    end;
  end;
end;

procedure DivDoubleByDigit(out q: TDigit; out r: TDigit; hi, lo, d: TDigit);
var
  dividend: TDoubleDigit;
begin
  dividend := (TDoubleDigit(hi) shl DigitBits) or lo;
  q := dividend div d;
  r := dividend mod d;
end;

procedure BigIntDivModKnuth(var q, r: TBigInt; const u_in, v_in: TBigInt);
var
  u, v:   TBigInt;
  q_hat, r_hat, rem_digit: TDigit;
  q_temp, v_temp, temp: TBigInt;
  shift:  integer;
  j, i:   integer;
  uj, uj1, uj2: TDigit;
  v1, v2: TDigit;
  carry:  TDoubleDigit;
  borrow: int64;
  p:      TDoubleDigit;
  final_q_sign, final_r_sign: shortint;
  u_copy: TBigInt; // Save original u for remainder calculation
begin
  // Handle signs and simple cases first
  final_r_sign := u_in.Sign;
  if u_in.Sign = v_in.Sign then
    final_q_sign := 1
  else
    final_q_sign := -1;

  if u_in.Sign = 0 then
  begin
    BigIntFromInt64(q, 0);
    BigIntFromInt64(r, 0);
    Exit;
  end;

  if v_in.Sign = 0 then
  begin
    // Division by zero error
    BigIntFromInt64(q, 0);
    BigIntCopy(r, u_in); // Return the original dividend as remainder
    Exit;
  end;

  if CompareAbs(u_in, v_in) < 0 then
  begin
    // |u| < |v| => q = 0, r = u
    BigIntFromInt64(q, 0);
    BigIntCopy(r, u_in);
    Exit;
  end;

  // Now, prepare for the main algorithm with absolute values
  BigIntInit(u);
  BigIntCopy(u, u_in);
  u.Sign := 1;
  BigIntInit(v);
  BigIntCopy(v, v_in);
  v.Sign := 1;
  
  // Save original u for remainder calculation
  BigIntInit(u_copy);
  BigIntCopy(u_copy, u);

  if v.Length = 1 then
  begin
    rem_digit := BigIntDivModDigit(q, u, v.Digits[0]);
    q.Sign    := final_q_sign;
    Normalize(q);
    BigIntFromInt64(r, rem_digit);
    if r.Sign <> 0 then // Only set sign if non-zero
      r.Sign := final_r_sign;
    Normalize(r);
    BigIntFree(u);
    BigIntFree(v);
    BigIntFree(u_copy);
    Exit;
  end;

  // D1: Normalize
  shift := CountLeadingZeroBits(v.Digits[v.Length - 1]);
  if shift > 0 then
  begin
    BigIntSHL(u, u, shift);
    BigIntSHL(v, v, shift);
  end;

  // If shifting u added a digit
  if u.Length = u_in.Length then
  begin
    SetIntLength(u, u.Length + 1);
    u.Digits[u.Length - 1] := 0;
  end;

  // D2: Initialize
  SetIntLength(q, u.Length - v.Length);
  q.Sign := final_q_sign;

  BigIntInit(v_temp);
  BigIntInit(q_temp);
  BigIntInit(temp);

  for j := u.Length - v.Length - 1 downto 0 do
  begin
    // D3: Calculate q_hat
    uj2 := u.Digits[j + v.Length];
    uj1 := u.Digits[j + v.Length - 1];
    uj  := u.Digits[j + v.Length - 2];
    v1  := v.Digits[v.Length - 1];
    v2  := v.Digits[v.Length - 2];

    if uj2 = v1 then
      q_hat := MaxDigit
    else
      DivDoubleByDigit(q_hat, r_hat, uj2, uj1, v1);

    while TDoubleDigit(q_hat) * v2 > (TDoubleDigit(r_hat) shl DigitBits) + uj do
    begin
      Dec(q_hat);
      r_hat := r_hat + v1;
      if r_hat >= (TDoubleDigit(1) shl DigitBits) then break;
    end;

    // D4: Multiply and subtract
    SetIntLength(v_temp, v.Length + 1);
    carry := 0;
    for i := 0 to v.Length - 1 do
    begin
      p     := TDoubleDigit(q_hat) * v.Digits[i] + carry;
      v_temp.Digits[i] := p and MaxDigit;
      carry := p shr DigitBits;
    end;
    v_temp.Digits[v.Length] := carry;
    Normalize(v_temp);

    borrow := 0;
    for i := 0 to v_temp.Length - 1 do
    begin
      p := int64(u.Digits[j + i]) - v_temp.Digits[i] - borrow;
      if p < 0 then
      begin
        u.Digits[j + i] := p + (TDoubleDigit(1) shl DigitBits);
        borrow := 1;
      end
      else
      begin
        u.Digits[j + i] := p;
        borrow := 0;
      end;
    end;

    // D5: Test remainder & D6: Add back
    if borrow > 0 then
    begin
      Dec(q_hat);
      carry := 0;
      for i := 0 to v.Length - 1 do
      begin
        p     := TDoubleDigit(u.Digits[j + i]) + v.Digits[i] + carry;
        u.Digits[j + i] := p and MaxDigit;
        carry := p shr DigitBits;
      end;
      u.Digits[j + v.Length] := u.Digits[j + v.Length] + carry;
    end;
    q.Digits[j] := q_hat;
  end;

  // D8: Unnormalize
  Normalize(q);
  SetIntLength(r, v.Length);
  System.Move(u.Digits[0], r.Digits[0], v.Length * SizeOf(TDigit));
  r.Sign := final_r_sign;
  Normalize(r);
  if shift > 0 then
    BigIntSHR(r, r, shift);

  BigIntFree(u);
  BigIntFree(v);
  BigIntFree(v_temp);
  BigIntFree(q_temp);
  BigIntFree(temp);
  BigIntFree(u_copy);
end;

procedure BigIntDivMod(var q, r: TBigInt; const u, v: TBigInt);
var
  u_val, v_val: int64;
begin
  if TryBigIntToInt64(u, u_val) and TryBigIntToInt64(v, v_val) then
  begin
    if v_val = 0 then
    begin
      // Division by zero
      BigIntFromInt64(q, 0);
      BigIntCopy(r, u);
      Exit;
    end;

    // Special case for Low(Int64) / -1, which overflows
    if (u_val = Low(int64)) and (v_val = -1) then
    begin
      BigIntFromStr(q, '9223372036854775808');
      BigIntFromInt64(r, 0);
      Exit;
    end;

    BigIntFromInt64(q, u_val div v_val);
    BigIntFromInt64(r, u_val mod v_val);
  end
  else
  begin
    BigIntDivModKnuth(q, r, u, v);
  end;
end;

procedure _BigIntAddAbs_Unsafe(var res: TBigInt; const a, b: TBigInt);
var
  i:     SizeInt;
  carry: TDoubleDigit;
  p:     TDoubleDigit;
  maxLength, minLength: SizeInt;
  pMax:  ^TBigInt;
begin
  if a.Length > b.Length then
  begin
    maxLength := a.Length;
    minLength := b.Length;
    pMax      := @a;
  end
  else
  begin
    maxLength := b.Length;
    minLength := a.Length;
    pMax      := @b;
  end;

  SetIntLength(res, maxLength + 1);

  carry := 0;
  for i := 0 to minLength - 1 do
  begin
    p     := TDoubleDigit(a.Digits[i]) + b.Digits[i] + carry;
    res.Digits[i] := p and MaxDigit;
    carry := p shr DigitBits;
  end;

  for i := minLength to maxLength - 1 do
  begin
    p     := TDoubleDigit(pMax^.Digits[i]) + carry;
    res.Digits[i] := p and MaxDigit;
    carry := p shr DigitBits;
  end;

  res.Digits[maxLength] := carry;
  // No normalization, caller is responsible
end;

procedure _BigIntSubAbs_Unsafe(var res: TBigInt; const a, b: TBigInt);
var
  i:      SizeInt;
  borrow: int64;
  p:      int64;
begin
  SetIntLength(res, a.Length);

  borrow := 0;
  for i := 0 to b.Length - 1 do
  begin
    p := int64(a.Digits[i]) - b.Digits[i] - borrow;
    if p < 0 then
    begin
      res.Digits[i] := p + (TDoubleDigit(1) shl DigitBits);
      borrow := 1;
    end
    else
    begin
      res.Digits[i] := p;
      borrow := 0;
    end;
  end;

  for i := b.Length to a.Length - 1 do
  begin
    p := int64(a.Digits[i]) - borrow;
    if p < 0 then
    begin
      res.Digits[i] := p + (TDoubleDigit(1) shl DigitBits);
      borrow := 1;
    end
    else
    begin
      res.Digits[i] := p;
      borrow := 0;
    end;
  end;
  // No normalization, caller is responsible
end;

end.
