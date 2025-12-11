program main;

{$mode objfpc}{$H+}

uses
 SysUtils, bigint;

var
  TestCount, PassCount: Integer;

procedure Check(condition: Boolean; const message: string); overload;
begin
  Inc(TestCount);
  if condition then
  begin
    Inc(PassCount);
    Writeln('  [PASS] ', message);
  end
  else
  begin
    Writeln('  [FAIL] ', message);
  end;
end;

procedure Check(value: string; expected: string; const message: string); overload;
var
  condition: Boolean;
begin
  condition := value = expected;
  Inc(TestCount);
  if condition then
  begin
    Inc(PassCount);
    Writeln('  [PASS] ', message);
  end
  else
  begin
    Writeln('  [FAIL] ', message, ' - Expected: "', expected, '", Got: "', value, '"');
  end;
end;

procedure Check(value: Integer; expected: Integer; const message: string); overload;
var
  condition: Boolean;
begin
  condition := value = expected;
  Inc(TestCount);
  if condition then
  begin
    Inc(PassCount);
    Writeln('  [PASS] ', message);
  end
  else
  begin
    Writeln('  [FAIL] ', message, ' - Expected: ', expected, ', Got: ', value);
  end;
end;

procedure Check(value: TDigit; expected: TDigit; const message: string); overload;
var
  condition: Boolean;
begin
  condition := value = expected;
  Inc(TestCount);
  if condition then
  begin
    Inc(PassCount);
    Writeln('  [PASS] ', message);
  end
  else
  begin
    Writeln('  [FAIL] ', message, ' - Expected: ', UIntToStr(expected), ', Got: ', UIntToStr(value));
  end;
end;

procedure Check(value: TBigInt; expected: TBigInt; const message: string); overload;
var
  condition: Boolean;
begin
  condition := BigIntCompare(value, expected) = 0;
  Inc(TestCount);
  if condition then
  begin
    Inc(PassCount);
    Writeln('  [PASS] ', message);
  end
  else
  begin
    Writeln('  [FAIL] ', message, ' - Expected: ', BigIntToStr(expected), ', Got: ', BigIntToStr(value));
  end;
end;

procedure PrintTestSummary;
begin
  Writeln;
  Writeln('--- Test Summary ---');
  Writeln('Total tests: ', TestCount);
  Writeln('Passed: ', PassCount);
  Writeln('Failed: ', TestCount - PassCount);
  Writeln('--------------------');
  if TestCount <> PassCount then
    Halt(1); // Exit with error code if any test failed
end;

procedure TestConversionAndComparison;
var
  a, b, c: TBigInt;
  s: string;
  val: Int64;
begin
  Writeln('--- Testing Conversion and Comparison ---');

  // Test BigIntFromStr and BigIntToStr
  BigIntFromStr(a, '12345678901234567890');
  s := a.AsString;
  Check(s, '12345678901234567890', 'BigIntFromStr/BigIntToStr positive');
  BigIntFree(a);

  BigIntFromStr(a, '-98765432109876543210');
  s := a.AsString;
  Check(s, '-98765432109876543210', 'BigIntFromStr/BigIntToStr negative');
  BigIntFree(a);

  BigIntFromStr(a, '0');
  s := a.AsString;
  Check(s, '0', 'BigIntFromStr/BigIntToStr zero');
  Check(a.SignValue, 0, 'Zero sign check');
  BigIntFree(a);

  // Test BigIntFromInt64
  BigIntFromInt64(a, 12345);
  s := a.AsString;
  Check(s, '12345', 'BigIntFromInt64 positive');
  BigIntFree(a);

  BigIntFromInt64(a, -54321);
  s := a.AsString;
  Check(s, '-54321', 'BigIntFromInt64 negative');
  BigIntFree(a);
  
  BigIntFromInt64(a, High(Int64));
  s := a.AsString;
  Check(s, '9223372036854775807', 'BigIntFromInt64 High(Int64)');
  BigIntFree(a);

  BigIntFromInt64(a, Low(Int64));
  s := a.AsString;
  Check(s, '-9223372036854775808', 'BigIntFromInt64 Low(Int64)');
  BigIntFree(a);

  // Test BigIntCompare
  BigIntFromStr(a, '100');
  BigIntFromStr(b, '100');
  BigIntFromStr(c, '200');
  Check(a = b, 'BigIntCompare equal');
  Check(a < c, 'BigIntCompare less');
  Check(c > a, 'BigIntCompare greater');

  BigIntFromStr(b, '-100');
  Check(a > b, 'BigIntCompare positive vs negative');
  Check(b < a, 'BigIntCompare negative vs positive');
  
  BigIntFromStr(c, '-200');
  Check(b > c, 'BigIntCompare negative vs more negative');
  Check(c < b, 'BigIntCompare more negative vs negative');

  BigIntFree(a);
  BigIntFree(b);
  BigIntFree(c);
end;

procedure TestArithmetic;
var
  a, b, res, expected: TBigInt;
begin
  Writeln('--- Testing Arithmetic ---');

  // Addition
  BigIntFromStr(a, '100');
  BigIntFromStr(b, '200');
  BigIntFromStr(expected, '300');
  res := a + b;
  Check(res, expected, 'Add positive + positive');
  
  BigIntFromStr(a, '-100');
  BigIntFromStr(b, '-200');
  BigIntFromStr(expected, '-300');
  res := a + b;
  Check(res, expected, 'Add negative + negative');

  BigIntFromStr(a, '100');
  BigIntFromStr(b, '-200');
  BigIntFromStr(expected, '-100');
  res := a + b;
  Check(res, expected, 'Add positive + negative (negative result)');
  
  BigIntFromStr(a, '200');
  BigIntFromStr(b, '-100');
  BigIntFromStr(expected, '100');
  res := a + b;
  Check(res, expected, 'Add positive + negative (positive result)');

  // Subtraction
  BigIntFromStr(a, '300');
  BigIntFromStr(b, '100');
  BigIntFromStr(expected, '200');
  res := a - b;
  Check(res, expected, 'Sub positive - positive');
  
  BigIntFromStr(a, '-300');
  BigIntFromStr(b, '-100');
  BigIntFromStr(expected, '-200');
  res := a - b;
  Check(res, expected, 'Sub negative - negative');
  
  BigIntFromStr(a, '100');
  BigIntFromStr(b, '-100');
  BigIntFromStr(expected, '200');
  res := a - b;
  Check(res, expected, 'Sub positive - negative');

  // Multiplication
  BigIntFromStr(a, '123');
  BigIntFromStr(b, '456');
  BigIntFromStr(expected, '56088');
  res := a * b;
  Check(res, expected, 'Mul positive * positive');
  
  BigIntFromStr(a, '-123');
  BigIntFromStr(b, '456');
  BigIntFromStr(expected, '-56088');
  res := a * b;
  Check(res, expected, 'Mul negative * positive');
  
  BigIntFromStr(a, '-123');
  BigIntFromStr(b, '-456');
  BigIntFromStr(expected, '56088');
  res := a * b;
  Check(res, expected, 'Mul negative * negative');
  
  BigIntFromStr(b, '0');
  BigIntFromStr(expected, '0');
  res := a * b;
  Check(res, expected, 'Mul anything by zero');

  BigIntFree(a);
  BigIntFree(b);
  BigIntFree(res);
  BigIntFree(expected);
end;

procedure TestShifts;
var
  a, b, res, expected: TBigInt;
  s: string;
begin
  Writeln('--- Testing Shifts ---');

  // BigIntSHL
  BigIntFromStr(a, '1');
  res := a shl 32;
  s := res.AsString;
  Check(s, '4294967296', 'SHL by DigitBits');

  // BigIntSHR
  BigIntFromStr(a, '4294967296');
  res := a shr 31;
  s := res.AsString;
  Check(s, '2', 'SHR by DigitBits - 1');
  
  res := a shr 32;
  s := res.AsString;
  Check(s, '1', 'SHR by DigitBits');

  // BigIntShift
  BigIntFromStr(a, '12345');
  res := a shl 2;
  Check(res.AsString, '49380', 'Left shift by BigInt');
  
  BigIntFromStr(a, '12345');
  res := a shr 2;
  Check(res.AsString, '3086', 'Right shift by BigInt');

  BigIntFree(a);
  BigIntFree(b);
  BigIntFree(res);
  BigIntFree(expected);
end;

procedure TestStringRepresentations;
var
  a: TBigInt;
  s: string;
begin
  Writeln('--- Testing String Representations ---');

  // Hexadecimal
  BigIntFromInt64(a, 255);
  s := BigIntToHexStr(a);
  Check(s, 'FF', 'Hex positive');
  
  BigIntFromInt64(a, -1);
  s := BigIntToHexStr(a);
  Check(s, 'FF', 'Hex negative -1 (8-bit)');

  BigIntFromInt64(a, -2);
  s := BigIntToHexStr(a);
  Check(s, 'FE', 'Hex negative -2 (8-bit)');

  BigIntFromInt64(a, -300);
  s := BigIntToHexStr(a);
  Check(s, 'FED4', 'Hex negative -300 (16-bit)');

  BigIntFromInt64(a, -32768);
  s := BigIntToHexStr(a);
  Check(s, '8000', 'Hex negative -32768 (16-bit)');
  
  // Binary
  BigIntFromInt64(a, 10);
  s := BigIntToBinStr(a);
  Check(s, '1010', 'Bin positive');

  BigIntFromInt64(a, -1);
  s := BigIntToBinStr(a);
  Check(s, '11111111', 'Bin negative -1 (8-bit)');
  
  BigIntFromInt64(a, -10);
  s := BigIntToBinStr(a);
  Check(s, '11110110', 'Bin negative -10 (8-bit)');
  
  BigIntFree(a);
end;

procedure TestAliasingAndFastPaths;
var
  a, b, c, expected, expected_q, expected_r: TBigInt;
begin
  Writeln('--- Testing Aliasing and Fast Paths ---');

  //--- ADDITION ALIASING ---
  Writeln('  Testing Addition Aliasing (a := a + b)');
  // Positive + Positive
  BigIntFromStr(a, '100'); BigIntFromStr(b, '50'); BigIntFromStr(expected, '150');
  a := a + b; Check(a, expected, '  a := a + b (pos + pos)');
  // Negative + Negative
  BigIntFromStr(a, '-100'); BigIntFromStr(b, '-50'); BigIntFromStr(expected, '-150');
  a := a + b; Check(a, expected, '  a := a + b (neg + neg)');
  // Positive + Negative -> Positive
  BigIntFromStr(a, '100'); BigIntFromStr(b, '-50'); BigIntFromStr(expected, '50');
  a := a + b; Check(a, expected, '  a := a + b (pos + neg -> pos)');
  // Positive + Negative -> Negative
  BigIntFromStr(a, '50'); BigIntFromStr(b, '-100'); BigIntFromStr(expected, '-50');
  a := a + b; Check(a, expected, '  a := a + b (pos + neg -> neg)');
  // Positive + Negative -> Zero
  BigIntFromStr(a, '100'); BigIntFromStr(b, '-100'); BigIntFromStr(expected, '0');
  a := a + b; Check(a, expected, '  a := a + b (pos + neg -> zero)');

  Writeln('  Testing Addition Aliasing (b := a + b)');
  // Positive + Positive
  BigIntFromStr(a, '100'); BigIntFromStr(b, '50'); BigIntFromStr(expected, '150');
  b := a + b; Check(b, expected, '  b := a + b (pos + pos)');
  
  //--- SUBTRACTION ALIASING ---
  Writeln('  Testing Subtraction Aliasing (a := a - b)');
  // Positive - Positive -> Positive
  BigIntFromStr(a, '100'); BigIntFromStr(b, '50'); BigIntFromStr(expected, '50');
  a := a - b; Check(a, expected, '  a := a - b (pos - pos -> pos)');
  // Positive - Positive -> Negative
  BigIntFromStr(a, '50'); BigIntFromStr(b, '100'); BigIntFromStr(expected, '-50');
  a := a - b; Check(a, expected, '  a := a - b (pos - pos -> neg)');
  // Positive - Positive -> Zero
  BigIntFromStr(a, '100'); BigIntFromStr(b, '100'); BigIntFromStr(expected, '0');
  a := a - b; Check(a, expected, '  a := a - b (pos - pos -> zero)');
  // Negative - Negative
  BigIntFromStr(a, '-100'); BigIntFromStr(b, '-50'); BigIntFromStr(expected, '-50');
  a := a - b; Check(a, expected, '  a := a - b (neg - neg)');
  // Positive - Negative
  BigIntFromStr(a, '100'); BigIntFromStr(b, '-50'); BigIntFromStr(expected, '150');
  a := a - b; Check(a, expected, '  a := a - b (pos - neg)');
  // Negative - Positive
  BigIntFromStr(a, '-100'); BigIntFromStr(b, '50'); BigIntFromStr(expected, '-150');
  a := a - b; Check(a, expected, '  a := a - b (neg - pos)');

  Writeln('  Testing Subtraction Aliasing (b := a - b)');
  BigIntFromStr(a, '100'); BigIntFromStr(b, '50'); BigIntFromStr(expected, '50');
  b := a - b; Check(b, expected, '  b := a - b (pos - pos)');

  //--- MULTIPLICATION ALIASING ---
  Writeln('  Testing Multiplication Aliasing (a := a * b)');
  // Positive * Positive
  BigIntFromStr(a, '10'); BigIntFromStr(b, '5'); BigIntFromStr(expected, '50');
  a := a * b; Check(a, expected, '  a := a * b (pos * pos)');
  // Negative * Positive
  BigIntFromStr(a, '-10'); BigIntFromStr(b, '5'); BigIntFromStr(expected, '-50');
  a := a * b; Check(a, expected, '  a := a * b (neg * pos)');
  // Negative * Negative
  BigIntFromStr(a, '-10'); BigIntFromStr(b, '-5'); BigIntFromStr(expected, '50');
  a := a * b; Check(a, expected, '  a := a * b (neg * neg)');
  // Multiply by Zero
  BigIntFromStr(a, '10'); BigIntFromStr(b, '0'); BigIntFromStr(expected, '0');
  a := a * b; Check(a, expected, '  a := a * b (mul by zero)');

  Writeln('  Testing Multiplication Aliasing (b := a * b)');
  BigIntFromStr(a, '10'); BigIntFromStr(b, '5'); BigIntFromStr(expected, '50');
  b := a * b; Check(b, expected, '  b := a * b (pos * pos)');

  //--- DIVISION ALIASING ---
  Writeln('  Testing Division Aliasing (a := a div b)');
  BigIntFromStr(a, '100'); BigIntFromStr(b, '10'); BigIntFromStr(expected_q, '10');
  a := a div b; Check(a, expected_q, '  a := a div b');

  //--- MODULUS ALIASING ---
  Writeln('  Testing Modulus Aliasing (a := a mod b)');
  BigIntFromStr(a, '105'); BigIntFromStr(b, '10'); BigIntFromStr(expected_r, '5');
  a := a mod b; Check(a, expected_r, '  a := a mod b');
  
  // Fast path for Mul
  Writeln('  Testing Fast Paths');
  BigIntFromInt64(a, 100000);
  BigIntFromInt64(b, 200000);
  BigIntFromInt64(c, 20000000000);
  a := a * b;
  Check(a, c, 'Mul fast path (Int64 range)');
  
  BigIntFree(a);
  BigIntFree(b);
  BigIntFree(c);
  BigIntFree(expected);
  BigIntFree(expected_q);
  BigIntFree(expected_r);
end;

procedure TestKnuthPrimitives;
var
  q, r: TDigit;
begin
  Writeln('--- Testing Knuth Primitives ---');
  
  // Test CountLeadingZeroBits
  Check(CountLeadingZeroBits(0), 32, 'CLZ(0)');
  Check(CountLeadingZeroBits(1), 31, 'CLZ(1)');
  Check(CountLeadingZeroBits($80000000), 0, 'CLZ(MSB set)');
  Check(CountLeadingZeroBits($FFFFFFFF), 0, 'CLZ(all set)');
  Check(CountLeadingZeroBits($0000000F), 28, 'CLZ(4 LSBs set)');

  // Test DivDoubleByDigit
  DivDoubleByDigit(q, r, 0, 100, 10);
  Check(q, 10, 'DivDoubleByDigit: q simple');
  Check(r, 0, 'DivDoubleByDigit: r simple');
  
  DivDoubleByDigit(q, r, 1, 0, $FFFFFFFF);
  Check(q, TDigit(TDoubleDigit(4294967296) div TDoubleDigit(4294967295)), 'DivDoubleByDigit: q overflow case');
  Check(r, TDigit(TDoubleDigit(4294967296) mod TDoubleDigit(4294967295)), 'DivDoubleByDigit: r overflow case');
  
  DivDoubleByDigit(q, r, 1, 1, 2);
  Check(q, $80000000, 'DivDoubleByDigit: q half');
  Check(r, 1, 'DivDoubleByDigit: r half');
end;

procedure TestDivision;
var
  u, v, q, r, expected_q, expected_r: TBigInt;
begin
  Writeln('--- Testing Division ---');
  
  // Simple case (fast path)
  BigIntFromStr(u, '1000');
  BigIntFromStr(v, '10');
  BigIntFromStr(expected_q, '100');
  BigIntFromStr(expected_r, '0');
  q := u div v;
  r := u mod v;
  Check(q, expected_q, 'Div: 1000 / 10 (q)');
  Check(r, expected_r, 'Div: 1000 / 10 (r)');

  // Case with remainder (fast path)
  BigIntFromStr(u, '1005');
  BigIntFromStr(v, '10');
  BigIntFromStr(expected_q, '100');
  BigIntFromStr(expected_r, '5');
  q := u div v;
  r := u mod v;
  Check(q, expected_q, 'Div: 1005 / 10 (q)');
  Check(r, expected_r, 'Div: 1005 / 10 (r)');
  
  // Special case Low(Int64) / -1 (fast path)
  BigIntFromInt64(u, Low(Int64));
  BigIntFromInt64(v, -1);
  BigIntFromStr(expected_q, '9223372036854775808');
  BigIntFromInt64(expected_r, 0);
  q := u div v;
  r := u mod v;
  Check(q, expected_q, 'Div: Low(Int64) / -1 (q)');
  Check(r, expected_r, 'Div: Low(Int64) / -1 (r)');

  // Large numbers (Knuth path)
  BigIntFromStr(u, '123456789012345678901234567890');
  BigIntFromStr(v, '1234567890');
  BigIntFromStr(expected_q, '100000000010000000001');
  BigIntFromStr(expected_r, '0');
  q := u div v;
  r := u mod v;
  Check(q, expected_q, 'Div: Large numbers (q)');
  Check(r, expected_r, 'Div: Large numbers (r)');

  // 2-digit by 2-digit case (Knuth path)
  BigIntFromStr(u, '18446744073709551615'); // (2^64)-1
  BigIntFromStr(v, '4294967297');           // (2^32)+1
  BigIntFromStr(expected_q, '4294967295');   // (2^32)-1
  BigIntFromStr(expected_r, '0');
  q := u div v;
  r := u mod v;
  Check(q, expected_q, 'Div: (2^64)-1 / (2^32)+1 (q)');
  Check(r, expected_r, 'Div: (2^64)-1 / (2^32)+1 (r)');

  // Negative dividend (fast path)
  BigIntFromStr(u, '-1005');
  BigIntFromStr(v, '10');
  BigIntFromStr(expected_q, '-100');
  BigIntFromStr(expected_r, '-5');
  q := u div v;
  r := u mod v;
  Check(q, expected_q, 'Div: -1005 / 10 (q)');
  Check(r, expected_r, 'Div: -1005 / 10 (r)');
  
  // Negative divisor (fast path)
  BigIntFromStr(u, '1005');
  BigIntFromStr(v, '-10');
  BigIntFromStr(expected_q, '-100');
  BigIntFromStr(expected_r, '5');
  q := u div v;
  r := u mod v;
  Check(q, expected_q, 'Div: 1005 / -10 (q)');
  Check(r, expected_r, 'Div: 1005 / -10 (r)');
  
  // Both negative (fast path)
  BigIntFromStr(u, '-1005');
  BigIntFromStr(v, '-10');
  BigIntFromStr(expected_q, '100');
  BigIntFromStr(expected_r, '-5');
  q := u div v;
  r := u mod v;
  Check(q, expected_q, 'Div: -1005 / -10 (q)');
  Check(r, expected_r, 'Div: -1005 / -10 (r)');

  // Dividend smaller than divisor (fast path)
  BigIntFromStr(u, '10');
  BigIntFromStr(v, '100');
  BigIntFromStr(expected_q, '0');
  BigIntFromStr(expected_r, '10');
  q := u div v;
  r := u mod v;
  Check(q, expected_q, 'Div: 10 / 100 (q)');
  Check(r, expected_r, 'Div: 10 / 100 (r)');
  
  // Division by zero (fast path)
  BigIntFromStr(u, '10');
  BigIntFromStr(v, '0');
  BigIntFromStr(expected_q, '0');
  BigIntFromStr(expected_r, '10');
  q := u div v;
  r := u mod v;
  Check(q, expected_q, 'Div: 10 / 0 (q)');
  Check(r, expected_r, 'Div: 10 / 0 (r)');

  BigIntFree(u);
  BigIntFree(v);
  BigIntFree(q);
  BigIntFree(r);
  BigIntFree(expected_q);
  BigIntFree(expected_r);
end;

procedure TestSelfOperations;
var
  a, q, r, expected, expected_q, expected_r: TBigInt;
begin
  Writeln('--- Testing Self Operations ---');

  // a := a + a
  BigIntFromStr(a, '123');
  BigIntFromStr(expected, '246');
  a := a + a;
  Check(a, expected, 'Self-addition: a := a + a');
  BigIntFree(a);
  BigIntFree(expected);

  // a := a - a
  BigIntFromStr(a, '123');
  BigIntFromStr(expected, '0');
  a := a - a;
  Check(a, expected, 'Self-subtraction: a := a - a');
  BigIntFree(a);
  BigIntFree(expected);

  // a := a * a
  BigIntFromStr(a, '123');
  BigIntFromStr(expected, '15129');
  a := a * a;
  Check(a, expected, 'Self-multiplication: a := a * a');
  BigIntFree(a);
  BigIntFree(expected);

  // a := a / a
  BigIntFromStr(a, '123');
  BigIntFromStr(expected_q, '1');
  BigIntFromStr(expected_r, '0');
  q := a div a;
  r := a mod a;
  Check(q, expected_q, 'Self-division: a := a / a (quotient)');
  Check(r, expected_r, 'Self-division: a := a / a (remainder)');
  BigIntFree(a);
  BigIntFree(expected_q);
  BigIntFree(expected_r);
end;

procedure TestMixedOperations;
var
  a, b, c, expected: TBigInt;
  i, j: int64;
begin
  Writeln('--- Testing Mixed Operations ---');
  
  // BigInt + int64
  BigIntFromStr(a, '1000000000000');
  i := 500000000000;
  BigIntFromStr(expected, '1500000000000');
  a := a + i;
  Check(a, expected, 'BigInt + int64');
  
  // int64 + BigInt
  BigIntFromStr(a, '1000000000000');
  i := 500000000000;
  BigIntFromStr(expected, '1500000000000');
  b := i + a;
  Check(b, expected, 'int64 + BigInt');
  
  // BigInt - int64
  BigIntFromStr(a, '1000000000000');
  i := 500000000000;
  BigIntFromStr(expected, '500000000000');
  a := a - i;
  Check(a, expected, 'BigInt - int64');
  
  // int64 - BigInt
  BigIntFromStr(a, '500000000000');
  i := 1000000000000;
  BigIntFromStr(expected, '500000000000');
  b := i - a;
  Check(b, expected, 'int64 - BigInt');
  
  // BigInt * int64
  BigIntFromStr(a, '1000000');
  i := 1000;
  BigIntFromStr(expected, '1000000000');
  a := a * i;
  Check(a, expected, 'BigInt * int64');
  
  // int64 * BigInt
  BigIntFromStr(a, '1000000');
  i := 1000;
  BigIntFromStr(expected, '1000000000');
  b := i * a;
  Check(b, expected, 'int64 * BigInt');
  
  // BigInt div int64
  BigIntFromStr(a, '1000000000');
  i := 1000;
  BigIntFromStr(expected, '1000000');
  a := a div i;
  Check(a, expected, 'BigInt div int64');
  
  // int64 div BigInt
  BigIntFromStr(a, '1000');
  i := 1000000000;
  BigIntFromStr(expected, '1000000');
  b := i div a;
  Check(b, expected, 'int64 div BigInt');
  
  // BigInt mod int64
  BigIntFromStr(a, '1000000005');
  i := 1000;
  BigIntFromStr(expected, '5');
  a := a mod i;
  Check(a, expected, 'BigInt mod int64');
  
  // int64 mod BigInt
  BigIntFromStr(a, '100');
  i := 1000;
  BigIntFromStr(expected, '0');  // 1000 mod 100 = 0
  b := i mod a;
  Check(b, expected, 'int64 mod BigInt (zero remainder)');
  
  BigIntFromStr(a, '300');
  i := 1000;
  BigIntFromStr(expected, '100');  // 1000 mod 300 = 100
  b := i mod a;
  Check(b, expected, 'int64 mod BigInt (non-zero remainder)');
  
  // Complex mixed expression: a := a - b div a
  BigIntFromStr(a, '1000');
  BigIntFromStr(b, '200');
  BigIntFromStr(expected, '1000');  // 1000 - (200 div 1000) = 1000 - 0 = 1000
  a := a - b div a;
  Check(a, expected, 'Complex mixed: a := a - b div a');
  
  // More complex: a := a * b + i div j
  BigIntFromStr(a, '100');
  BigIntFromStr(b, '20');
  i := 500;
  j := 10;
  BigIntFromStr(expected, '2050');  // 100 * 20 + (500 div 10) = 2000 + 50 = 2050
  a := a * b + i div j;
  Check(a, expected, 'Complex mixed: a := a * b + i div j');
  
  BigIntFree(a);
  BigIntFree(b);
  BigIntFree(c);
  BigIntFree(expected);
end;

begin
  TestCount := 0;
  PassCount := 0;
  
  TestConversionAndComparison;
  TestArithmetic;
  TestShifts;
  TestStringRepresentations;
  TestAliasingAndFastPaths;
  TestKnuthPrimitives;
  TestDivision;
  TestSelfOperations;
  TestMixedOperations;

  PrintTestSummary;
  readln;
end.
