program main;

{$mode objfpc}{$H+}

uses
  SysUtils,
  bigint;

var
  TestCount, PassCount: integer;

  procedure Check(condition: boolean; const message: string); overload;
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

  procedure Check(Value: string; expected: string; const message: string); overload;
  var
    condition: boolean;
  begin
    condition := Value = expected;
    Inc(TestCount);
    if condition then
    begin
      Inc(PassCount);
      Writeln('  [PASS] ', message);
    end
    else
    begin
      Writeln('  [FAIL] ', message, ' - Expected: "', expected, '", Got: "', Value, '"');
    end;
  end;

  procedure Check(Value: integer; expected: integer; const message: string); overload;
  var
    condition: boolean;
  begin
    condition := Value = expected;
    Inc(TestCount);
    if condition then
    begin
      Inc(PassCount);
      Writeln('  [PASS] ', message);
    end
    else
    begin
      Writeln('  [FAIL] ', message, ' - Expected: ', expected, ', Got: ', Value);
    end;
  end;

  procedure Check(Value: TDigit; expected: TDigit; const message: string); overload;
  var
    condition: boolean;
  begin
    condition := Value = expected;
    Inc(TestCount);
    if condition then
    begin
      Inc(PassCount);
      Writeln('  [PASS] ', message);
    end
    else
    begin
      Writeln('  [FAIL] ', message, ' - Expected: ', UIntToStr(expected), ', Got: ',
        UIntToStr(Value));
    end;
  end;

  procedure Check(Value: TBigInt; expected: TBigInt; const message: string); overload;
  var
    condition: boolean;
  begin
    condition := BigIntCompare(Value, expected) = 0;
    Inc(TestCount);
    if condition then
    begin
      Inc(PassCount);
      Writeln('  [PASS] ', message);
    end
    else
    begin
      Writeln('  [FAIL] ', message, ' - Expected: ', BigIntToStr(expected),
        ', Got: ', BigIntToStr(Value));
    end;
  end;

  procedure Check(Value: TBigInt; Ptr: PChar; StartPtr: PChar; ExpectedPtrOffset: PtrInt; ExpectedValue: TBigInt; const message: string); overload;
  var
    val_cond, ptr_cond: boolean;
  begin
    val_cond := BigIntCompare(Value, ExpectedValue) = 0;
    ptr_cond := (Ptr - StartPtr) = ExpectedPtrOffset;
    Inc(TestCount);
    if val_cond and ptr_cond then
    begin
      Inc(PassCount);
      Writeln('  [PASS] ', message);
    end
    else
    begin
       Write('  [FAIL] ', message);
       if not val_cond then
         Write(' - VALUE - Expected: ', BigIntToStr(ExpectedValue), ', Got: ', BigIntToStr(Value));
       if not ptr_cond then
         Write(' - POINTER - Expected offset: ', ExpectedPtrOffset, ', Got: ', (Ptr - StartPtr));
       Writeln;
    end;
  end;

  procedure Check(Value: TBigInt; Ptr: PWideChar; StartPtr: PWideChar; ExpectedPtrOffset: PtrInt; ExpectedValue: TBigInt; const message: string); overload;
  var
    val_cond, ptr_cond: boolean;
  begin
    val_cond := BigIntCompare(Value, ExpectedValue) = 0;
    ptr_cond := (Ptr - StartPtr) = ExpectedPtrOffset;
    Inc(TestCount);
    if val_cond and ptr_cond then
    begin
      Inc(PassCount);
      Writeln('  [PASS] ', message);
    end
    else
    begin
       Write('  [FAIL] ', message);
       if not val_cond then
         Write(' - VALUE - Expected: ', BigIntToStr(ExpectedValue), ', Got: ', BigIntToStr(Value));
       if not ptr_cond then
         Write(' - POINTER - Expected offset: ', ExpectedPtrOffset, ', Got: ', (Ptr - StartPtr));
       Writeln;
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
    s:   string;
  begin
    a.Init; b.Init; c.Init;
    Writeln('--- Testing Conversion and Comparison ---');

    // Test BigIntFromStr and BigIntToStr
    BigIntFromStr(a, '12345678901234567890');
    s := a.AsString;
    Check(s, '12345678901234567890', 'BigIntFromStr/BigIntToStr positive');

    BigIntFromStr(a, '-98765432109876543210');
    s := a.AsString;
    Check(s, '-98765432109876543210', 'BigIntFromStr/BigIntToStr negative');

    BigIntFromStr(a, '0');
    s := a.AsString;
    Check(s, '0', 'BigIntFromStr/BigIntToStr zero');
    Check(a.SignValue, 0, 'Zero sign check');

    // Test BigIntFromInt64
    BigIntFromInt64(a, 12345);
    s := a.AsString;
    Check(s, '12345', 'BigIntFromInt64 positive');

    BigIntFromInt64(a, -54321);
    s := a.AsString;
    Check(s, '-54321', 'BigIntFromInt64 negative');

    BigIntFromInt64(a, High(int64));
    s := a.AsString;
    Check(s, '9223372036854775807', 'BigIntFromInt64 High(Int64)');

    BigIntFromInt64(a, Low(int64));
    s := a.AsString;
    Check(s, '-9223372036854775808', 'BigIntFromInt64 Low(Int64)');

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
  end;

  procedure TestArithmetic;
  var
    a, b, res, expected: TBigInt;
  begin
    a.Init; b.Init; res.Init; expected.Init;
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
  end;

  procedure TestShifts;
  var
    a, res: TBigInt;
    s: string;
  begin
    a.Init; res.Init;
    Writeln('--- Testing Shifts ---');

    // BigIntSHL
    BigIntFromStr(a, '1');
    res := a shl 32;
    s   := res.AsString;
    Check(s, '4294967296', 'SHL by DigitBits');

    // BigIntSHR
    BigIntFromStr(a, '4294967296');
    res := a shr 31;
    s   := res.AsString;
    Check(s, '2', 'SHR by DigitBits - 1');

    res := a shr 32;
    s   := res.AsString;
    Check(s, '1', 'SHR by DigitBits');

    // BigIntShift
    BigIntFromStr(a, '12345');
    res := a shl 2;
    Check(res.AsString, '49380', 'Left shift by BigInt');

    BigIntFromStr(a, '12345');
    res := a shr 2;
    Check(res.AsString, '3086', 'Right shift by BigInt');
  end;

  procedure TestStringRepresentations;
  var
    a: TBigInt;
    s: string;
  begin
    a.Init;
    Writeln('--- Testing String Representations ---');

    // Hexadecimal
    BigIntFromInt64(a, 255);
    s := BigIntToHexStr(a);
    Check(s, '0FF', 'Hex positive');

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
    Check(s, '01010', 'Bin positive');

    BigIntFromInt64(a, -1);
    s := BigIntToBinStr(a);
    Check(s, '11111111', 'Bin negative -1 (8-bit)');

    BigIntFromInt64(a, -10);
    s := BigIntToBinStr(a);
    Check(s, '11110110', 'Bin negative -10 (8-bit)');
  end;

  procedure TestAliasingAndFastPaths;
  var
    a, b, c, expected, expected_q, expected_r: TBigInt;
  begin
    a.Init; b.Init; c.Init; expected.Init; expected_q.Init; expected_r.Init;
    Writeln('--- Testing Aliasing and Fast Paths ---');

    //--- ADDITION ALIASING ---
    Writeln('  Testing Addition Aliasing (a := a + b)');
    BigIntFromStr(a, '100');
    BigIntFromStr(b, '50');
    BigIntFromStr(expected, '150');
    a := a + b;
    Check(a, expected, '  a := a + b (pos + pos)');
    BigIntFromStr(a, '-100');
    BigIntFromStr(b, '-50');
    BigIntFromStr(expected, '-150');
    a := a + b;
    Check(a, expected, '  a := a + b (neg + neg)');
    BigIntFromStr(a, '100');
    BigIntFromStr(b, '-50');
    BigIntFromStr(expected, '50');
    a := a + b;
    Check(a, expected, '  a := a + b (pos + neg -> pos)');
    BigIntFromStr(a, '50');
    BigIntFromStr(b, '-100');
    BigIntFromStr(expected, '-50');
    a := a + b;
    Check(a, expected, '  a := a + b (pos + neg -> neg)');
    BigIntFromStr(a, '100');
    BigIntFromStr(b, '-100');
    BigIntFromStr(expected, '0');
    a := a + b;
    Check(a, expected, '  a := a + b (pos + neg -> zero)');

    Writeln('  Testing Addition Aliasing (b := a + b)');
    BigIntFromStr(a, '100');
    BigIntFromStr(b, '50');
    BigIntFromStr(expected, '150');
    b := a + b;
    Check(b, expected, '  b := a + b (pos + pos)');

    //--- SUBTRACTION ALIASING ---
    Writeln('  Testing Subtraction Aliasing (a := a - b)');
    BigIntFromStr(a, '100');
    BigIntFromStr(b, '50');
    BigIntFromStr(expected, '50');
    a := a - b;
    Check(a, expected, '  a := a - b (pos - pos -> pos)');
    BigIntFromStr(a, '50');
    BigIntFromStr(b, '100');
    BigIntFromStr(expected, '-50');
    a := a - b;
    Check(a, expected, '  a := a - b (pos - pos -> neg)');
    BigIntFromStr(a, '100');
    BigIntFromStr(b, '100');
    BigIntFromStr(expected, '0');
    a := a - b;
    Check(a, expected, '  a := a - b (pos - pos -> zero)');
    BigIntFromStr(a, '-100');
    BigIntFromStr(b, '-50');
    BigIntFromStr(expected, '-50');
    a := a - b;
    Check(a, expected, '  a := a - b (neg - neg)');
    BigIntFromStr(a, '100');
    BigIntFromStr(b, '-50');
    BigIntFromStr(expected, '150');
    a := a - b;
    Check(a, expected, '  a := a - b (pos - neg)');
    BigIntFromStr(a, '-100');
    BigIntFromStr(b, '50');
    BigIntFromStr(expected, '-150');
    a := a - b;
    Check(a, expected, '  a := a - b (neg - pos)');

    Writeln('  Testing Subtraction Aliasing (b := a - b)');
    BigIntFromStr(a, '100');
    BigIntFromStr(b, '50');
    BigIntFromStr(expected, '50');
    b := a - b;
    Check(b, expected, '  b := a - b (pos - pos)');

    //--- MULTIPLICATION ALIASING ---
    Writeln('  Testing Multiplication Aliasing (a := a * b)');
    BigIntFromStr(a, '10');
    BigIntFromStr(b, '5');
    BigIntFromStr(expected, '50');
    a := a * b;
    Check(a, expected, '  a := a * b (pos * pos)');
    BigIntFromStr(a, '-10');
    BigIntFromStr(b, '5');
    BigIntFromStr(expected, '-50');
    a := a * b;
    Check(a, expected, '  a := a * b (neg * pos)');
    BigIntFromStr(a, '-10');
    BigIntFromStr(b, '-5');
    BigIntFromStr(expected, '50');
    a := a * b;
    Check(a, expected, '  a := a * b (neg * neg)');
    BigIntFromStr(a, '10');
    BigIntFromStr(b, '0');
    BigIntFromStr(expected, '0');
    a := a * b;
    Check(a, expected, '  a := a * b (mul by zero)');

    Writeln('  Testing Multiplication Aliasing (b := a * b)');
    BigIntFromStr(a, '10');
    BigIntFromStr(b, '5');
    BigIntFromStr(expected, '50');
    b := a * b;
    Check(b, expected, '  b := a * b (pos * pos)');

    //--- DIVISION ALIASING ---
    Writeln('  Testing Division Aliasing (a := a div b)');
    BigIntFromStr(a, '100');
    BigIntFromStr(b, '10');
    BigIntFromStr(expected_q, '10');
    a := a div b;
    Check(a, expected_q, '  a := a div b');

    //--- MODULUS ALIASING ---
    Writeln('  Testing Modulus Aliasing (a := a mod b)');
    BigIntFromStr(a, '105');
    BigIntFromStr(b, '10');
    BigIntFromStr(expected_r, '5');
    a := a mod b;
    Check(a, expected_r, '  a := a mod b');

    // Fast path for Mul
    Writeln('  Testing Fast Paths');
    BigIntFromInt64(a, 100000);
    BigIntFromInt64(b, 200000);
    BigIntFromInt64(c, 20000000000);
    a := a * b;
    Check(a, c, 'Mul fast path (Int64 range)');
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
    Check(q, TDigit(TDoubleDigit(4294967296) div TDoubleDigit(4294967295)),
      'DivDoubleByDigit: q overflow case');
    Check(r, TDigit(TDoubleDigit(4294967296) mod TDoubleDigit(4294967295)),
      'DivDoubleByDigit: r overflow case');

    DivDoubleByDigit(q, r, 1, 1, 2);
    Check(q, $80000000, 'DivDoubleByDigit: q half');
    Check(r, 1, 'DivDoubleByDigit: r half');
  end;

  procedure TestDivision;
  var
    u, v, q, r, expected_q, expected_r: TBigInt;
  begin
    u.Init; v.Init; q.Init; r.Init; expected_q.Init; expected_r.Init;
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
    BigIntFromInt64(u, Low(int64));
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
  end;

  procedure TestSelfOperations;
  var
    a, q, r, expected, expected_q, expected_r: TBigInt;
  begin
    a.Init; q.Init; r.Init; expected.Init; expected_q.Init; expected_r.Init;
    Writeln('--- Testing Self Operations ---');

    // a := a + a
    BigIntFromStr(a, '123');
    BigIntFromStr(expected, '246');
    a := a + a;
    Check(a, expected, 'Self-addition: a := a + a');

    // a := a - a
    BigIntFromStr(a, '123');
    BigIntFromStr(expected, '0');
    a := a - a;
    Check(a, expected, 'Self-subtraction: a := a - a');

    // a := a * a
    BigIntFromStr(a, '123');
    BigIntFromStr(expected, '15129');
    a := a * a;
    Check(a, expected, 'Self-multiplication: a := a * a');

    // a := a / a
    BigIntFromStr(a, '123');
    BigIntFromStr(expected_q, '1');
    BigIntFromStr(expected_r, '0');
    q := a div a;
    r := a mod a;
    Check(q, expected_q, 'Self-division: a := a / a (quotient)');
    Check(r, expected_r, 'Self-division: a := a / a (remainder)');
  end;

  procedure TestMixedOperations;
  var
    a, b, expected: TBigInt;
    i, j: int64;
  begin
    a.Init; b.Init; expected.Init;
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
    BigIntFromStr(expected, '0');
    b := i mod a;
    Check(b, expected, 'int64 mod BigInt (zero remainder)');

    BigIntFromStr(a, '300');
    i := 1000;
    BigIntFromStr(expected, '100');
    b := i mod a;
    Check(b, expected, 'int64 mod BigInt (non-zero remainder)');

    // Complex mixed expression: a := a - b div a
    BigIntFromStr(a, '1000');
    BigIntFromStr(b, '200');
    BigIntFromStr(expected, '1000');
    a := a - b div a;
    Check(a, expected, 'Complex mixed: a := a - b div a');

    // More complex: a := a * b + i div j
    BigIntFromStr(a, '100');
    BigIntFromStr(b, '20');
    i := 500;
    j := 10;
    BigIntFromStr(expected, '2050');
    a := a * b + i div j;
    Check(a, expected, 'Complex mixed: a := a * b + i div j');
  end;

  procedure TestZeroInitialization;
  var
    a, b, expected: TBigInt;
  begin
    a.Init; b.Init; expected.Init;
    Writeln('--- Testing Zero Initialization (var A: TBigInt = ()) ---');

    // a is zero-initialized, b is a value
    BigIntFromInt64(b, 123);

    // Test comparison
    BigIntFromInt64(expected, 0);
    Check(a, expected, 'Zero-initialized equals canonical zero');

    // Test addition: 0 + 123
    BigIntFromInt64(expected, 123);
    a := a + b;
    Check(a, expected, 'Zero-initialized + BigInt');

    // Test subtraction: 123 - 0
    a.Init; // Reset a to zero-initialized state
    a := b - a;
    Check(a, expected, 'BigInt - Zero-initialized');
  end;

  procedure TestChainedAndMixedExpressions;
  var
    a, b, d, expected: TBigInt;
    c: int64;
  begin
    a.Init; b.Init; d.Init; expected.Init;
    Writeln('--- Testing Chained and Mixed Expressions ---');

    // B + C * D
    BigIntFromInt64(b, 10);
    c := 20;
    BigIntFromInt64(d, 3);
    BigIntFromInt64(expected, 70); // 10 + (20 * 3)
    a := b + c * d;
    Check(a, expected, 'Chained mixed: B + C * D');

    // B * C + D
    BigIntFromInt64(b, 10);
    c := 20;
    BigIntFromInt64(d, 3);
    BigIntFromStr(expected, '203'); // (10 * 20) + 3, AsString for clarity
    a := b * c + d;
    Check(a, expected, 'Chained mixed: B * C + D');

    // B + C div D
    BigIntFromInt64(b, 100);
    c := 20;
    BigIntFromInt64(d, 3);
    BigIntFromInt64(expected, 106); // 100 + (20 div 3)
    a := b + c div d;
    Check(a, expected, 'Chained mixed: B + C div D');

    // (B + C) * D
    BigIntFromInt64(b, 10);
    c := 20;
    BigIntFromInt64(d, 3);
    BigIntFromInt64(expected, 90); // (10 + 20) * 3
    a := (b + c) * d;
    Check(a, expected, 'Chained mixed: (B + C) * D');
  end;

  procedure TestHelperFunctions;
  var
    a, expected: TBigInt;
  begin
    a.Init; expected.Init;
    Writeln('--- Testing Helper Functions ---');

    // Test BigIntPowerOf2
    BigIntPowerOf2(a, 0);
    BigIntFromInt64(expected, 1);
    Check(a, expected, 'Helper: 2^0');

    BigIntPowerOf2(a, 1);
    BigIntFromInt64(expected, 2);
    Check(a, expected, 'Helper: 2^1');

    BigIntPowerOf2(a, 10);
    BigIntFromInt64(expected, 1024);
    Check(a, expected, 'Helper: 2^10');

    BigIntPowerOf2(a, 32);
    BigIntFromStr(expected, '4294967296');
    Check(a, expected, 'Helper: 2^32');

    // Test BigIntPowerOf10
    BigIntPowerOf10(a, 0);
    BigIntFromInt64(expected, 1);
    Check(a, expected, 'Helper: 10^0');

    BigIntPowerOf10(a, 1);
    BigIntFromInt64(expected, 10);
    Check(a, expected, 'Helper: 10^1');

    BigIntPowerOf10(a, 9);
    BigIntFromInt64(expected, 1000000000);
    Check(a, expected, 'Helper: 10^9');

    BigIntPowerOf10(a, 18);
    BigIntFromStr(expected, '1000000000000000000');
    Check(a, expected, 'Helper: 10^18');
  end;

  procedure TestParsingFromStrings;
  var
    a, b: TBigInt;
  begin
    a.Init; b.Init;
    Writeln('--- Testing Parsing from Hex/Bin Strings ---');

    // Hex Positive
    BigIntFromInt64(a, 255);
    BigIntFromHexStr(b, BigIntToHexStr(a));
    Check(b, a, 'Parse Hex positive');

    // Hex Negative
    BigIntFromInt64(a, -1);
    BigIntFromHexStr(b, BigIntToHexStr(a));
    Check(b, a, 'Parse Hex negative -1');

    BigIntFromInt64(a, -300);
    BigIntFromHexStr(b, BigIntToHexStr(a));
    Check(b, a, 'Parse Hex negative -300');

    // Bin Positive
    BigIntFromInt64(a, 10);
    BigIntFromBinStr(b, BigIntToBinStr(a));
    Check(b, a, 'Parse Bin positive');

    // Bin Negative
    BigIntFromInt64(a, -10);
    BigIntFromBinStr(b, BigIntToBinStr(a));
    Check(b, a, 'Parse Bin negative -10');

    // Zero
    BigIntFromInt64(a, 0);
    BigIntFromHexStr(b, BigIntToHexStr(a));
    Check(b, a, 'Parse Hex zero');
    BigIntFromBinStr(b, BigIntToBinStr(a));
    Check(b, a, 'Parse Bin zero');
  end;

  procedure TestOptimizedSelfOperations;
  var
    a, expected: TBigInt;
  begin
    a.Init; expected.Init;
    Writeln('--- Testing Optimized Self Operations ---');

    // a + a
    BigIntFromStr(a, '123456789012345678901234567890');
    BigIntFromStr(expected, '246913578024691357802469135780');
    a := a + a;
    Check(a, expected, 'Optimized a + a');

    // a - a
    BigIntFromStr(a, '123456789012345678901234567890');
    BigIntFromInt64(expected, 0);
    a := a - a;
    Check(a, expected, 'Optimized a - a');

    // a * a
    BigIntFromStr(a, '12345678901234567890');
    BigIntFromStr(expected, '152415787532388367501905199875019052100');
    a := a * a;
    Check(a, expected, 'Optimized a * a (Sqr)');
  end;

  procedure TestStreamParsers;
  var
    s: AnsiString;
    p, res_p: PChar;
    a, expected: TBigInt;
  begin
    a.Init; expected.Init;
    Writeln('--- Testing Stream Parsers ---');
    
    // --- PChar Decimal ---
    s := '12345 and the rest';
    p := PChar(s);
    BigIntFromStr(expected, '12345');
    a := ParseDecimalBigIntFromPChar(p, res_p);
    Check(a, res_p, p, 5, expected, 'PChar Dec: Simple positive');

    s := '-987 stop';
    p := PChar(s);
    BigIntFromStr(expected, '-987');
    a := ParseDecimalBigIntFromPChar(p, res_p);
    Check(a, res_p, p, 4, expected, 'PChar Dec: Simple negative');
    
    s := '1 2 3 4 5 and the rest';
    p := PChar(s);
    BigIntFromStr(expected, '12345');
    a := ParseDecimalBigIntFromPChar(p, res_p);
    Check(a, res_p, p, 9, expected, 'PChar Dec: With spaces');

    s := '   - 9 8 7 stop';
    p := PChar(s);
    BigIntFromStr(expected, '-987');
    a := ParseDecimalBigIntFromPChar(p, res_p);
    Check(a, res_p, p, 10, expected, 'PChar Dec: Negative with spaces');

    s := 'not a number';
    p := PChar(s);
    BigIntFromInt64(expected, 0);
    a := ParseDecimalBigIntFromPChar(p, res_p);
    Check(a, res_p, p, 0, expected, 'PChar Dec: Invalid string');

    // --- PChar Hex ---
    s := 'FF glorious text';
    p := PChar(s);
    BigIntFromInt64(expected, -1);
    a := ParseHexBigIntFromPChar(p, res_p);
    Check(a, res_p, p, 2, expected, 'PChar Hex: Negative -1');

    s := '7F FF';
    p := PChar(s);
    BigIntFromInt64(expected, 32767);
    a := ParseHexBigIntFromPChar(p, res_p);
    Check(a, res_p, p, 5, expected, 'PChar Hex: Positive with space');
    
    s := '8000 trailing'; // -32768
    p := PChar(s);
    BigIntFromInt64(expected, -32768);
    a := ParseHexBigIntFromPChar(p, res_p);
    Check(a, res_p, p, 4, expected, 'PChar Hex: Negative boundary');

    // --- PChar Bin ---
    s := '11111111 next'; // -1
    p := PChar(s);
    BigIntFromInt64(expected, -1);
    a := ParseBinBigIntFromPChar(p, res_p);
    Check(a, res_p, p, 8, expected, 'PChar Bin: Negative -1');
    
    s := '0111 1111 1111 1111'; // 32767
    p := PChar(s);
    BigIntFromInt64(expected, 32767);
    a := ParseBinBigIntFromPChar(p, res_p);
    Check(a, res_p, p, 19, expected, 'PChar Bin: Positive with spaces');

    // --- PChar Edge Cases ---
    s := '';
    p := PChar(s);
    BigIntFromInt64(expected, 0);
    a := ParseDecimalBigIntFromPChar(p, res_p);
    Check(a, res_p, p, 0, expected, 'PChar Dec: Empty string');

    s := '-';
    p := PChar(s);
    BigIntFromInt64(expected, 0);
    a := ParseDecimalBigIntFromPChar(p, res_p);
    Check(a, res_p, p, 0, expected, 'PChar Dec: Sign only');
    
    s := '   -   ';
    p := PChar(s);
    BigIntFromInt64(expected, 0);
    a := ParseDecimalBigIntFromPChar(p, res_p);
    Check(a, res_p, p, 0, expected, 'PChar Dec: Sign with spaces');

    // --- PChar Large Numbers ---
    s := '123456789012345678901234567890 tail';
    p := PChar(s);
    BigIntFromStr(expected, '123456789012345678901234567890');
    a := ParseDecimalBigIntFromPChar(p, res_p);
    Check(a, res_p, p, 30, expected, 'PChar Dec: Large positive');

    s := '- 987654321098765432109876543210 tail';
    p := PChar(s);
    BigIntFromStr(expected, '-987654321098765432109876543210');
    a := ParseDecimalBigIntFromPChar(p, res_p);
    Check(a, res_p, p, 32, expected, 'PChar Dec: Large negative with space');
  end;

  procedure TestStreamParsersW;
  var
    s: WideString;
    p, res_p: PWideChar;
    a, expected: TBigInt;
  begin
    a.Init; expected.Init;
    Writeln('--- Testing Stream Parsers (WideChar) ---');
    
    // --- PWideChar Decimal ---
    s := '12345 and the rest';
    p := PWideChar(s);
    BigIntFromStr(expected, '12345');
    a := ParseDecimalBigIntFromPWideChar(p, res_p);
    Check(a, res_p, p, 5, expected, 'PWideChar Dec: Simple positive');

    s := '-987 stop';
    p := PWideChar(s);
    BigIntFromStr(expected, '-987');
    a := ParseDecimalBigIntFromPWideChar(p, res_p);
    Check(a, res_p, p, 4, expected, 'PWideChar Dec: Simple negative');
    
    s := '   - 9 8 7 stop';
    p := PWideChar(s);
    BigIntFromStr(expected, '-987');
    a := ParseDecimalBigIntFromPWideChar(p, res_p);
    Check(a, res_p, p, 10, expected, 'PWideChar Dec: Negative with spaces');

    // --- PWideChar Hex ---
    s := '7F FF';
    p := PWideChar(s);
    BigIntFromInt64(expected, 32767);
    a := ParseHexBigIntFromPWideChar(p, res_p);
    Check(a, res_p, p, 5, expected, 'PWideChar Hex: Positive with space');

    // --- PWideChar Edge Cases ---
    s := '';
    p := PWideChar(s);
    BigIntFromInt64(expected, 0);
    a := ParseDecimalBigIntFromPWideChar(p, res_p);
    Check(a, res_p, p, 0, expected, 'PWideChar Dec: Empty string');

    s := '-';
    p := PWideChar(s);
    BigIntFromInt64(expected, 0);
    a := ParseDecimalBigIntFromPWideChar(p, res_p);
    Check(a, res_p, p, 0, expected, 'PWideChar Dec: Sign only');

    // --- PWideChar Large Numbers ---
    s := '123456789012345678901234567890 tail';
    p := PWideChar(s);
    BigIntFromStr(expected, '123456789012345678901234567890');
    a := ParseDecimalBigIntFromPWideChar(p, res_p);
    Check(a, res_p, p, 30, expected, 'PWideChar Dec: Large positive');
  end;

procedure TestStandardFunctions;
var
  a, b, expected: TBigInt;
begin
  a.Init; b.Init; expected.Init;
  Writeln('--- Testing Standard Functions ---');

  BigIntFromInt64(a, 10);
  BigIntInc(a);
  BigIntFromInt64(expected, 11);
  Check(a, expected, 'Inc(a)');
  BigIntInc(a, 9);
  BigIntFromInt64(expected, 20);
  Check(a, expected, 'Inc(a, 9)');
  BigIntDec(a);
  BigIntFromInt64(expected, 19);
  Check(a, expected, 'Dec(a)');
  BigIntDec(a, 9);
  BigIntFromInt64(expected, 10);
  Check(a, expected, 'Dec(a, 9)');

  BigIntFromInt64(a, -100);
  b := BigIntAbs(a);
  BigIntFromInt64(expected, 100);
  Check(b, expected, 'Abs(-100)');
  Check(BigIntSign(a), -1, 'Sign(-100)');
  Check(BigIntSign(b), 1, 'Sign(100)');
  BigIntFromInt64(a, 0);
  Check(BigIntSign(a), 0, 'Sign(0)');
end;

procedure TestBitwiseOperations;
var
  a, b, expected, res: TBigInt;
begin
  a.Init; b.Init; expected.Init; res.Init;
  Writeln('--- Testing Bitwise Operations ---');

  // NOT
  BigIntFromInt64(a, 10); // 0...01010
  BigIntFromInt64(expected, -11); // 1...10101
  res := not a;
  Check(res, expected, 'not 10');

  BigIntFromInt64(a, -11);
  BigIntFromInt64(expected, 10);
  res := not a;
  Check(res, expected, 'not -11');

  // AND
  BigIntFromStr(a, '12345');
  BigIntFromStr(b, '54321');
  BigIntFromStr(expected, '4145'); // 12345 & 54321
  res := a and b;
  Check(res, expected, '12345 and 54321');

  BigIntFromStr(a, '12345');
  BigIntFromStr(b, '-54321');
  BigIntFromStr(expected, '8201'); // 12345 & (-54321 в 32-битном 2-доп коде)
  res := a and b;
  Check(res, expected, '12345 and -54321');

  // OR
  BigIntFromStr(a, '12345');
  BigIntFromStr(b, '54321');
  BigIntFromStr(expected, '62521'); // 12345 | 54321
  res := a or b;
  Check(res, expected, '12345 or 54321');

  // XOR
  BigIntFromStr(a, '12345');
  BigIntFromStr(b, '54321');
  BigIntFromStr(expected, '58376'); // 12345 ^ 54321
  res := a xor b;
  Check(res, expected, '12345 xor 54321');
end;

procedure TestUInt64Support;
var
  a, b, expected_bi: TBigInt;
  u: UInt64;
begin
  a.Init; b.Init; expected_bi.Init;
  Writeln('--- Testing UInt64 Support ---');

  // Test BigIntFromUInt64
  BigIntFromUInt64(a, 1234567890);
  Check(a.AsString, '1234567890', 'BigIntFromUInt64 simple');

  BigIntFromUInt64(a, High(UInt64));
  Check(a.AsString, '18446744073709551615', 'BigIntFromUInt64 High(UInt64)');

  // Test Operators: TBigInt + UInt64
  BigIntFromStr(a, '1000');
  u := 500;
  BigIntFromInt64(expected_bi, 1500);
  b := a + u;
  Check(b, expected_bi, 'TBigInt + UInt64');

  // Test Operators: UInt64 + TBigInt
  b := u + a;
  Check(b, expected_bi, 'UInt64 + TBigInt');

  // Test Comparison: TBigInt = UInt64
  BigIntFromInt64(a, 1000);
  u := 1000;
  Check(a = u, 'TBigInt = UInt64');
  u := 1001;
  Check(a < u, 'TBigInt < UInt64');
  Check(u > a, 'UInt64 > TBigInt');

  // Test with High(UInt64)
  BigIntFromUInt64(a, High(UInt64));
  BigIntFromInt64(b, 1);
  b := a + b;
  BigIntFromStr(expected_bi, '18446744073709551616');
  Check(b, expected_bi, 'High(UInt64) + 1');
end;

procedure TestNewStringProperties;
var
  a: TBigInt;
begin
  a.Init;
  Writeln('--- Testing New String Properties (AsHEX, AsBin) ---');

  // Positive number
  BigIntFromInt64(a, 255);
  Check(a.AsHEX, '0FF', 'AsHEX positive');
  BigIntFromInt64(a, 10);
  Check(a.AsBin, '01010', 'AsBin positive');

  // Negative number
  BigIntFromInt64(a, -1);
  Check(a.AsHEX, 'FF', 'AsHEX negative -1');
  Check(a.AsBin, '11111111', 'AsBin negative -1');

  // Zero
  BigIntFromInt64(a, 0);
  Check(a.AsHEX, '0', 'AsHEX zero');
  Check(a.AsBin, '0', 'AsBin zero');
end;

procedure TestRandomFunction;
var
  a, limit, zero: TBigInt;
  i: integer;
begin
  a.Init; limit.Init; zero.Init;
  Writeln('--- Testing Random Function ---');
  
  BigIntFromInt64(zero, 0);

  // Test BigIntRandom
  BigIntFromInt64(limit, 1000);
  Writeln('  Generating 10 random numbers less than 1000:');
  for i := 1 to 10 do
  begin
    a := BigIntRandom(limit);
    // Проверяем, что 0 <= a < limit
    Check((BigIntCompare(a, zero) >= 0) and (BigIntCompare(a, limit) < 0), '  Random number ' + IntToStr(i) + ' in range [0..999]');
  end;

  BigIntFromUInt64(limit, High(UInt64));
  a := BigIntRandom(limit);
  Check(BigIntCompare(a, limit) < 0, 'Random number less than High(UInt64)');
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
  TestZeroInitialization;
  TestChainedAndMixedExpressions;
  TestHelperFunctions;
  TestParsingFromStrings;
  TestOptimizedSelfOperations;
  TestStreamParsers;
  TestStreamParsersW;
  TestStandardFunctions;
  TestBitwiseOperations;
  TestUInt64Support;
  TestNewStringProperties;
  TestRandomFunction;

  PrintTestSummary;
  readln;
end.
