{
  Модуль `bigint` предоставляет реализацию длинной арифметики для целых чисел
  произвольной точности. Поддерживаются все основные арифметические и побитовые
  операции, а также операции сравнения и преобразования в строку.

  Основные возможности:
  - Хранение чисел произвольного размера.
  - Перегрузка операторов для удобной работы (+, -, *, div, mod, shl, shr).
  - Взаимодействие со стандартными целочисленными типами (Int64).
  - Эффективные алгоритмы для умножения (Карацуба) и деления (Кнут).
  - Управление памятью с балансом между скоростью и экономией.
}
unit bigint;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

type
  { Базовый "разряд" длинного числа. Все числа хранятся как массив таких разряд
ов. }
  TDigit = uint32;
  { Удвоенный "разряд", используется для предотвращения переполнения в промежут
очных вычислениях. }
  TDoubleDigit = uint64;

const
  { Количество бит в одном разряде. }
  DigitBits  = SizeOf(TDigit) * 8;
  { Максимальное значение, которое может хранить один разряд. }
  MaxDigit   = High(TDigit);
  { Константа для количества бит, используется в некоторых алгоритмах. }
  DIGIT_BITS = 32;
  { Размер блока для преобразования из строки. Число 10^9 - последнее, умещающе
еся в TDigit. }
  BlockSize = 9;
  { Предварительно вычисленные степени 10 для ускорения преобразования из строк
и. }
  PowersOf10: array[1..BlockSize] of TDigit =
    (10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000, 1000000000);

type
  {
    Основная структура для представления длинного целого числа.
    Использует расширенную запись (advanced record), что позволяет
    добавлять методы и операторы.
  }
  TBigInt = record
  private
    { Знак числа: +1 для положительных, -1 для отрицательных, 0 для нуля. }
    Sign:   shortint;
    { Динамический массив "разрядов", хранящий абсолютное значение числа в форм
ате little-endian
      (младшие разряды в начале массива). }
    Digits: array of TDigit;
    { Реальная длина числа в разрядах (без учёта ведущих нулей в массиве). }
    Length: SizeInt;
    { Внутренние функции для получения строковых представлений. }
    function GetAsString: string;
    function GetAsHexString: string;
    function GetAsBinString: string;
  public
    { Процедура инициализации. Приводит число к каноническому нулю. }
    procedure Init;
    { Свойства для получения строковых представлений числа. }
    property AsString: string read GetAsString;
    property AsHEX: string read GetAsHexString;
    property AsBin: string read GetAsBinString;
    { Свойство для получения знака числа. }
    property SignValue: shortint read Sign;

    // --- Перегрузка операторов ---

    // Операции со смешанными типами (TBigInt и Int64)
    class operator +(const a: TBigInt; b: int64): TBigInt;
    class operator +(a: int64; const b: TBigInt): TBigInt;
    class operator -(const a: TBigInt; b: int64): TBigInt;
    class operator -(a: int64; const b: TBigInt): TBigInt;
    class operator *(const a: TBigInt; b: int64): TBigInt;
    class operator *(a: int64; const b: TBigInt): TBigInt;
    class operator div(const a: TBigInt; b: int64): TBigInt;
    class operator div(a: int64; const b: TBigInt): TBigInt;
    class operator mod(const a: TBigInt; b: int64): TBigInt;
    class operator mod(a: int64; const b: TBigInt): TBigInt;
    // Операции между двумя TBigInt
    class operator +(const a, b: TBigInt): TBigInt;
    class operator -(const a, b: TBigInt): TBigInt;
    class operator *(const a, b: TBigInt): TBigInt;
    class operator div(const a, b: TBigInt): TBigInt;
    class operator mod(const a, b: TBigInt): TBigInt;
    // Побитовые сдвиги
    class operator shl(const a: TBigInt; b: integer): TBigInt;
    class operator shr(const a: TBigInt; b: integer): TBigInt;
    // Операторы сравнения
    class operator =(const a, b: TBigInt): boolean;
    class operator <>(const a, b: TBigInt): boolean;
    class operator <(const a, b: TBigInt): boolean;
    class operator >(const a, b: TBigInt): boolean;
    class operator <=(const a, b: TBigInt): boolean;
    class operator >=(const a, b: TBigInt): boolean;
    // Операторы сравнения с Int64
    class operator =(const a: TBigInt; b: int64): boolean;
    class operator =(a: int64; const b: TBigInt): boolean;
    class operator <>(const a: TBigInt; b: int64): boolean;
    class operator <>(a: int64; const b: TBigInt): boolean;
    class operator <(const a: TBigInt; b: int64): boolean;
    class operator <(a: int64; const b: TBigInt): boolean;
    class operator >(const a: TBigInt; b: int64): boolean;
    class operator >(a: int64; const b: TBigInt): boolean;
    class operator <=(const a: TBigInt; b: int64): boolean;
    class operator <=(a: int64; const b: TBigInt): boolean;
    class operator >=(const a: TBigInt; b: int64): boolean;
    class operator >=(a: int64; const b: TBigInt): boolean;

    // Операции со смешанными типами (TBigInt и UInt64)
    class operator +(const a: TBigInt; b: UInt64): TBigInt;
    class operator +(a: UInt64; const b: TBigInt): TBigInt;
    class operator -(const a: TBigInt; b: UInt64): TBigInt;
    class operator -(a: UInt64; const b: TBigInt): TBigInt;
    class operator *(const a: TBigInt; b: UInt64): TBigInt;
    class operator *(a: UInt64; const b: TBigInt): TBigInt;
    class operator div(const a: TBigInt; b: UInt64): TBigInt;
    class operator div(a: UInt64; const b: TBigInt): TBigInt;
    class operator mod(const a: TBigInt; b: UInt64): TBigInt;
    class operator mod(a: UInt64; const b: TBigInt): TBigInt;
    // Операторы сравнения с UInt64
    class operator =(const a: TBigInt; b: UInt64): boolean;
    class operator =(a: UInt64; const b: TBigInt): boolean;
    class operator <>(const a: TBigInt; b: UInt64): boolean;
    class operator <>(a: UInt64; const b: TBigInt): boolean;
    class operator <(const a: TBigInt; b: UInt64): boolean;
    class operator <(a: UInt64; const b: TBigInt): boolean;
    class operator >(const a: TBigInt; b: UInt64): boolean;
    class operator >(a: UInt64; const b: TBigInt): boolean;
    class operator <=(const a: TBigInt; b: UInt64): boolean;
    class operator <=(a: UInt64; const b: TBigInt): boolean;
    class operator >=(const a: TBigInt; b: UInt64): boolean;
    class operator >=(a: UInt64; const b: TBigInt): boolean;

    // Побитовые логические операторы
    class operator not(const a: TBigInt): TBigInt;
    class operator and(const a, b: TBigInt): TBigInt;
    class operator or(const a, b: TBigInt): TBigInt;
    class operator xor(const a, b: TBigInt): TBigInt;
  end;

{ Создаёт TBigInt из строкового представления десятичного числа. }
procedure BigIntFromStr(var a: TBigInt; const s: string);
{ Освобождает память, занимаемую числом, и сбрасывает его в ноль. }
procedure BigIntFree(var a: TBigInt);
{ Создаёт TBigInt из 64-битного целого числа. }
procedure BigIntFromInt64(var a: TBigInt; const Value: int64);
{ Создаёт TBigInt из 64-битного беззнакового целого числа. }
procedure BigIntFromUInt64(var a: TBigInt; const Value: UInt64);
{ Преобразует TBigInt в десятичную строку. }
function BigIntToStr(const a: TBigInt): string;
{ Сравнивает два TBigInt. Возвращает >0 если a>b, <0 если a<b, 0 если a=b. }
function BigIntCompare(const a, b: TBigInt): integer;
{ Преобразует TBigInt в шестнадцатеричную строку (в дополнительном коде для отр
ицательных). }
function BigIntToHexStr(const a: TBigInt): string;
{ Создаёт TBigInt из шестнадцатеричной строки (поддерживается дополнительный ко
д). }
procedure BigIntFromHexStr(var a: TBigInt; const s: string);
{ Преобразует TBigInt в двоичную строку (в дополнительном коде для отрицательны
х). }
function BigIntToBinStr(const a: TBigInt): string;
{ Создаёт TBigInt из двоичной строки (поддерживается дополнительный код). }
procedure BigIntFromBinStr(var a: TBigInt; const s: string);
{ Складывает два TBigInt, результат в `res`. }
procedure BigIntAdd(var res: TBigInt; const a_in, b_in: TBigInt);
{ Вычитает одно TBigInt из другого, результат в `res`. }
procedure BigIntSub(var res: TBigInt; const a, b: TBigInt);
{ Перемножает два TBigInt, результат в `res`. }
procedure BigIntMul(var res: TBigInt; const a, b: TBigInt);
{ Подсчитывает количество ведущих нулей в разряде. }
function CountLeadingZeroBits(d: TDigit): integer;
{ Делит 64-битное число (hi:lo) на 32-битный разряд, возвращает частное и остат
ок. }
procedure DivDoubleByDigit(out q: TDigit; out r: TDigit; hi, lo, d: TDigit);
{ Создаёт TBigInt со значением 2^exponent. }
procedure BigIntPowerOf2(var a: TBigInt; const exponent: cardinal);
{ Создаёт TBigInt со значением 10^exponent. }
procedure BigIntPowerOf10(var a: TBigInt; const exponent: cardinal);

{
  --- Перегрузка стандартных функций ---
}
{ Увеличивает TBigInt на 1 или на заданное значение. }
procedure BigIntInc(var a: TBigInt; const n: int64 = 1);
{ Уменьшает TBigInt на 1 или на заданное значение. }
procedure BigIntDec(var a: TBigInt; const n: int64 = 1);
{ Возвращает абсолютное значение TBigInt. }
function BigIntAbs(const a: TBigInt): TBigInt;
{ Возвращает знак TBigInt (-1, 0, 1). }
function BigIntSign(const a: TBigInt): shortint;
{ Генерирует случайное TBigInt в диапазоне [0..Limit-1]. }
function BigIntRandom(const Limit: TBigInt): TBigInt;


{
  --- Потоковые парсеры ---
}

{
  Парсит TBigInt из строки PChar, пропуская пробелы внутри числа.
  - P: Указатель на начало строки.
  - ResAddr: Указатель на символ, следующий за последним символом числа.
  - Возвращает: Считанное число. В случае ошибки возвращает 0, и ResAddr = P.
}
function ParseDecimalBigIntFromPChar(P: PChar; out ResAddr: PChar): TBigInt;
function ParseHexBigIntFromPChar(P: PChar; out ResAddr: PChar): TBigInt;
function ParseBinBigIntFromPChar(P: PChar; out ResAddr: PChar): TBigInt;

{
  Парсит TBigInt из строки PWideChar, пропуская пробелы внутри числа.
  - P: Указатель на начало строки.
  - ResAddr: Указатель на символ, следующий за последним символом числа.
  - Возвращает: Считанное число. В случае ошибки возвращает 0, и ResAddr = P.
}
function ParseDecimalBigIntFromPWideChar(P: PWideChar; out ResAddr: PWideChar):
TBigInt;
function ParseHexBigIntFromPWideChar(P: PWideChar; out ResAddr: PWideChar): TBigInt;
function ParseBinBigIntFromPWideChar(P: PWideChar; out ResAddr: PWideChar): TBigInt;


implementation

const
  { Набор пробельных символов, которые следует пропускать при парсинге. }
  WhitespaceChars: set of char = [#9, #10, #13, #32]; // Tab, LF, CR, Space

// --- Прототипы внутренних процедур ---
procedure BigIntInit(var a: TBigInt); forward;
procedure BigIntCopy(var dest: TBigInt; const Source: TBigInt); forward;
procedure BigIntMulDigit(var res: TBigInt; const a: TBigInt; m: TDigit); forward;
function TryBigIntToUInt64(const a: TBigInt; out Value: uint64): boolean; forward;
procedure BigIntSHL(var res: TBigInt; const a: TBigInt; bits: cardinal); forward;
procedure BigIntSHR(var res: TBigInt; const a: TBigInt; bits: cardinal); forward;
procedure BigIntMulKaratsuba(var res: TBigInt; const a, b: TBigInt); forward;
procedure _BigIntMulKaratsubaRecursive(var res: TBigInt; const a, b: TBigInt;
  var scratch: array of TBigInt); forward;
function BigIntDivModDigit(var quot: TBigInt; const a: TBigInt; divisor: TDigit): TDigit; forward;
procedure BigIntSplit(var hi, lo: TBigInt; const a: TBigInt; m: SizeInt); forward;
procedure BigIntDivPow2(var res: TBigInt; const a: TBigInt; n: cardinal); forward;
procedure BigIntModPow2(var res: TBigInt; const a: TBigInt; n: cardinal); forward;
procedure BigIntShift(var res: TBigInt; const a: TBigInt; const b: TBigInt); forward;
procedure BigIntDivModKnuth(var q, r: TBigInt; const u_in, v_in: TBigInt); forward;
procedure BigIntDivMod(var q, r: TBigInt; const u, v: TBigInt); forward;
procedure _BigIntAddAbs_Unsafe(var res: TBigInt; const a, b: TBigInt); forward;
procedure _BigIntSubAbs_Unsafe(var res: TBigInt; const a, b: TBigInt); forward;
procedure BigIntSqr_School(var res: TBigInt; const a: TBigInt); forward;

{
  --- Реализация методов и операторов для TBigInt ---
}

procedure TBigInt.Init;
begin
  BigIntInit(Self);
end;

class operator TBigInt.+(const a, b: TBigInt): TBigInt;
begin
  Result.Init;
  BigIntAdd(Result, a, b);
end;

class operator TBigInt.+(const a: TBigInt; b: int64): TBigInt;
var
  tempB: TBigInt;
begin
  Result.Init;
  tempB.Init;
  BigIntFromInt64(tempB, b);
  BigIntAdd(Result, a, tempB);
end;

class operator TBigInt.+(a: int64; const b: TBigInt): TBigInt;
var
  tempA: TBigInt;
begin
  Result.Init;
  tempA.Init;
  BigIntFromInt64(tempA, a);
  BigIntAdd(Result, tempA, b);
end;

class operator TBigInt.-(const a, b: TBigInt): TBigInt;
begin
  Result.Init;
  BigIntSub(Result, a, b);
end;

class operator TBigInt.-(const a: TBigInt; b: int64): TBigInt;
var
  tempB: TBigInt;
begin
  Result.Init;
  tempB.Init;
  BigIntFromInt64(tempB, b);
  BigIntSub(Result, a, tempB);
end;

class operator TBigInt.-(a: int64; const b: TBigInt): TBigInt;
var
  tempA: TBigInt;
begin
  Result.Init;
  tempA.Init;
  BigIntFromInt64(tempA, a);
  BigIntSub(Result, tempA, b);
end;

class operator TBigInt.*(const a, b: TBigInt): TBigInt;
begin
  Result.Init;
  BigIntMul(Result, a, b);
end;

class operator TBigInt.*(const a: TBigInt; b: int64): TBigInt;
var
  tempB: TBigInt;
begin
  Result.Init;
  tempB.Init;
  BigIntFromInt64(tempB, b);
  BigIntMul(Result, a, tempB);
end;

class operator TBigInt.*(a: int64; const b: TBigInt): TBigInt;
var
  tempA: TBigInt;
begin
  Result.Init;
  tempA.Init;
  BigIntFromInt64(tempA, a);
  BigIntMul(Result, tempA, b);
end;

class operator TBigInt.div(const a, b: TBigInt): TBigInt;
var
  r: TBigInt;
begin
  Result.Init;
  r.Init;
  BigIntDivMod(Result, r, a, b);
end;

class operator TBigInt.div(const a: TBigInt; b: int64): TBigInt;
var
  tempB, r: TBigInt;
begin
  Result.Init;
  tempB.Init;
  r.Init;
  BigIntFromInt64(tempB, b);
  BigIntDivMod(Result, r, a, tempB);
end;

class operator TBigInt.div(a: int64; const b: TBigInt): TBigInt;
var
  tempA, r: TBigInt;
begin
  Result.Init;
  tempA.Init;
  r.Init;
  BigIntFromInt64(tempA, a);
  BigIntDivMod(Result, r, tempA, b);
end;

class operator TBigInt.mod(const a, b: TBigInt): TBigInt;
var
  q: TBigInt;
begin
  Result.Init;
  q.Init;
  BigIntDivMod(q, Result, a, b);
end;

class operator TBigInt.mod(const a: TBigInt; b: int64): TBigInt;
var
  tempB, q: TBigInt;
begin
  Result.Init;
  tempB.Init;
  q.Init;
  BigIntFromInt64(tempB, b);
  BigIntDivMod(q, Result, a, tempB);
end;

class operator TBigInt.mod(a: int64; const b: TBigInt): TBigInt;
var
  tempA, q: TBigInt;
begin
  Result.Init;
  tempA.Init;
  q.Init;
  BigIntFromInt64(tempA, a);
  BigIntDivMod(q, Result, tempA, b);
end;

class operator TBigInt.shl(const a: TBigInt; b: integer): TBigInt;
begin
  Result.Init;
  BigIntSHL(Result, a, b);
end;

class operator TBigInt.shr(const a: TBigInt; b: integer): TBigInt;
begin
  Result.Init;
  BigIntSHR(Result, a, b);
end;

class operator TBigInt.=(const a, b: TBigInt): boolean;
begin
  Result := BigIntCompare(a, b) = 0;
end;

class operator TBigInt.<>(const a, b: TBigInt): boolean;
begin
  Result := BigIntCompare(a, b) <> 0;
end;

class operator TBigInt.<(const a, b: TBigInt): boolean;
begin
  Result := BigIntCompare(a, b) < 0;
end;

class operator TBigInt.>(const a, b: TBigInt): boolean;
begin
  Result := BigIntCompare(a, b) > 0;
end;

class operator TBigInt.<=(const a, b: TBigInt): boolean;
begin
  Result := BigIntCompare(a, b) <= 0;
end;

class operator TBigInt.>=(const a, b: TBigInt): boolean;
begin
  Result := BigIntCompare(a, b) >= 0;
end;

// --- Операторы сравнения с Int64 ---

class operator TBigInt.=(const a: TBigInt; b: int64): boolean;
var tempB: TBigInt;
begin
  tempB.Init; BigIntFromInt64(tempB, b); Result := BigIntCompare(a, tempB) = 0;
end;
class operator TBigInt.=(a: int64; const b: TBigInt): boolean;
var tempA: TBigInt;
begin
  tempA.Init; BigIntFromInt64(tempA, a); Result := BigIntCompare(tempA, b) = 0;
end;

class operator TBigInt.<>(const a: TBigInt; b: int64): boolean;
var tempB: TBigInt;
begin
  tempB.Init; BigIntFromInt64(tempB, b); Result := BigIntCompare(a, tempB) <> 0;
end;
class operator TBigInt.<>(a: int64; const b: TBigInt): boolean;
var tempA: TBigInt;
begin
  tempA.Init; BigIntFromInt64(tempA, a); Result := BigIntCompare(tempA, b) <> 0;
end;

class operator TBigInt.<(const a: TBigInt; b: int64): boolean;
var tempB: TBigInt;
begin
  tempB.Init; BigIntFromInt64(tempB, b); Result := BigIntCompare(a, tempB) < 0;
end;
class operator TBigInt.<(a: int64; const b: TBigInt): boolean;
var tempA: TBigInt;
begin
  tempA.Init; BigIntFromInt64(tempA, a); Result := BigIntCompare(tempA, b) < 0;
end;

class operator TBigInt.>(const a: TBigInt; b: int64): boolean;
var tempB: TBigInt;
begin
  tempB.Init; BigIntFromInt64(tempB, b); Result := BigIntCompare(a, tempB) > 0;
end;
class operator TBigInt.>(a: int64; const b: TBigInt): boolean;
var tempA: TBigInt;
begin
  tempA.Init; BigIntFromInt64(tempA, a); Result := BigIntCompare(tempA, b) > 0;
end;

class operator TBigInt.<=(const a: TBigInt; b: int64): boolean;
var tempB: TBigInt;
begin
  tempB.Init; BigIntFromInt64(tempB, b); Result := BigIntCompare(a, tempB) <= 0;
end;
class operator TBigInt.<=(a: int64; const b: TBigInt): boolean;
var tempA: TBigInt;
begin
  tempA.Init; BigIntFromInt64(tempA, a); Result := BigIntCompare(tempA, b) <= 0;
end;

class operator TBigInt.>=(const a: TBigInt; b: int64): boolean;
var tempB: TBigInt;
begin
  tempB.Init; BigIntFromInt64(tempB, b); Result := BigIntCompare(a, tempB) >= 0;
end;
class operator TBigInt.>=(a: int64; const b: TBigInt): boolean;
var tempA: TBigInt;
begin
  tempA.Init; BigIntFromInt64(tempA, a); Result := BigIntCompare(tempA, b) >= 0;
end;


function TBigInt.GetAsString: string;
begin
  Result := BigIntToStr(Self);
end;

function TBigInt.GetAsHexString: string;
begin
  Result := BigIntToHexStr(Self);
end;

function TBigInt.GetAsBinString: string;
begin
  Result := BigIntToBinStr(Self);
end;

// --- Операторы со смешанными типами (TBigInt и UInt64) ---

class operator TBigInt.+(const a: TBigInt; b: UInt64): TBigInt;
var
  tempB: TBigInt;
begin
  Result.Init;
  tempB.Init;
  BigIntFromUInt64(tempB, b);
  BigIntAdd(Result, a, tempB);
end;

class operator TBigInt.+(a: UInt64; const b: TBigInt): TBigInt;
var
  tempA: TBigInt;
begin
  Result.Init;
  tempA.Init;
  BigIntFromUInt64(tempA, a);
  BigIntAdd(Result, tempA, b);
end;

class operator TBigInt.-(const a: TBigInt; b: UInt64): TBigInt;
var
  tempB: TBigInt;
begin
  Result.Init;
  tempB.Init;
  BigIntFromUInt64(tempB, b);
  BigIntSub(Result, a, tempB);
end;

class operator TBigInt.-(a: UInt64; const b: TBigInt): TBigInt;
var
  tempA: TBigInt;
begin
  Result.Init;
  tempA.Init;
  BigIntFromUInt64(tempA, a);
  BigIntSub(Result, tempA, b);
end;

class operator TBigInt.*(const a: TBigInt; b: UInt64): TBigInt;
var
  tempB: TBigInt;
begin
  Result.Init;
  tempB.Init;
  BigIntFromUInt64(tempB, b);
  BigIntMul(Result, a, tempB);
end;

class operator TBigInt.*(a: UInt64; const b: TBigInt): TBigInt;
var
  tempA: TBigInt;
begin
  Result.Init;
  tempA.Init;
  BigIntFromUInt64(tempA, a);
  BigIntMul(Result, tempA, b);
end;

class operator TBigInt.div(const a: TBigInt; b: UInt64): TBigInt;
var tempB, r: TBigInt;
begin
  Result.Init; tempB.Init; r.Init;
  BigIntFromUInt64(tempB, b); BigIntDivMod(Result, r, a, tempB);
end;

class operator TBigInt.div(a: UInt64; const b: TBigInt): TBigInt;
var tempA, r: TBigInt;
begin
  Result.Init; tempA.Init; r.Init;
  BigIntFromUInt64(tempA, a); BigIntDivMod(Result, r, tempA, b);
end;

class operator TBigInt.mod(const a: TBigInt; b: UInt64): TBigInt;
var tempB, q: TBigInt;
begin
  Result.Init; tempB.Init; q.Init;
  BigIntFromUInt64(tempB, b); BigIntDivMod(q, Result, a, tempB);
end;

class operator TBigInt.mod(a: UInt64; const b: TBigInt): TBigInt;
var tempA, q: TBigInt;
begin
  Result.Init; tempA.Init; q.Init;
  BigIntFromUInt64(tempA, a); BigIntDivMod(q, Result, tempA, b);
end;

// --- Операторы сравнения с UInt64 ---

class operator TBigInt.=(const a: TBigInt; b: UInt64): boolean;
var tempB: TBigInt;
begin tempB.Init; BigIntFromUInt64(tempB, b); Result := BigIntCompare(a, tempB)
= 0; end;

class operator TBigInt.=(a: UInt64; const b: TBigInt): boolean;
var tempA: TBigInt;
begin tempA.Init; BigIntFromUInt64(tempA, a); Result := BigIntCompare(tempA, b)
= 0; end;

class operator TBigInt.<>(const a: TBigInt; b: UInt64): boolean;
var tempB: TBigInt;
begin tempB.Init; BigIntFromUInt64(tempB, b); Result := BigIntCompare(a, tempB)
<> 0; end;

class operator TBigInt.<>(a: UInt64; const b: TBigInt): boolean;
var tempA: TBigInt;
begin tempA.Init; BigIntFromUInt64(tempA, a); Result := BigIntCompare(tempA, b)
<> 0; end;

class operator TBigInt.<(const a: TBigInt; b: UInt64): boolean;
var tempB: TBigInt;
begin tempB.Init; BigIntFromUInt64(tempB, b); Result := BigIntCompare(a, tempB)
< 0; end;

class operator TBigInt.<(a: UInt64; const b: TBigInt): boolean;
var tempA: TBigInt;
begin tempA.Init; BigIntFromUInt64(tempA, a); Result := BigIntCompare(tempA, b)
< 0; end;

class operator TBigInt.>(const a: TBigInt; b: UInt64): boolean;
var tempB: TBigInt;
begin tempB.Init; BigIntFromUInt64(tempB, b); Result := BigIntCompare(a, tempB)
> 0; end;

class operator TBigInt.>(a: UInt64; const b: TBigInt): boolean;
var tempA: TBigInt;
begin tempA.Init; BigIntFromUInt64(tempA, a); Result := BigIntCompare(tempA, b)
> 0; end;

class operator TBigInt.<=(const a: TBigInt; b: UInt64): boolean;
var tempB: TBigInt;
begin tempB.Init; BigIntFromUInt64(tempB, b); Result := BigIntCompare(a, tempB)
<= 0; end;

class operator TBigInt.<=(a: UInt64; const b: TBigInt): boolean;
var tempA: TBigInt;
begin tempA.Init; BigIntFromUInt64(tempA, a); Result := BigIntCompare(tempA, b)
<= 0; end;

class operator TBigInt.>=(const a: TBigInt; b: UInt64): boolean;
var tempB: TBigInt;
begin tempB.Init; BigIntFromUInt64(tempB, b); Result := BigIntCompare(a, tempB)
>= 0; end;

class operator TBigInt.>=(a: UInt64; const b: TBigInt): boolean;
var tempA: TBigInt;
begin tempA.Init; BigIntFromUInt64(tempA, a); Result := BigIntCompare(tempA, b)
>= 0; end;


{
  --- Внутренние вспомогательные функции ---
}

{ Вспомогательная функция: преобразует небольшую строку в TDigit. }
function _StrToInt(const s: string): TDigit;
var
  res: TDigit;
  i:   integer;
begin
  res := 0;
  for i := 1 to System.Length(s) do
    res  := res * 10 + (Ord(s[i]) - Ord('0'));
  Result := res;
end;

{ Вспомогательная функция: преобразует TDigit в строку. }
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


{
  Приводит число к каноническому виду:
  - Удаляет ведущие нули из массива Digits, корректируя Length.
  - Если число равно нулю, устанавливает Sign = 0 и Length = 1.
  - Корректно обрабатывает неинициализированные числа (Digits = nil).
}
procedure Normalize(var a: TBigInt);
begin
  if not Assigned(a.Digits) then
  begin
    a.Sign := 0;
    a.Length := 0;
    Exit;
  end;

  while (a.Length > 1) and (a.Digits[a.Length - 1] = 0) do
    Dec(a.Length);
  if (a.Length = 1) and (a.Digits[0] = 0) then
    a.Sign := 0;
end;

{
  Устанавливает новую длину для массива Digits.
  - Если newLength больше текущей ёмкости, увеличивает массив.
  - Использует гибридную стратегию роста: x2 для маленьких чисел (быстро),
    x1.5 для больших (экономно по памяти).
  - Если newLength значительно меньше ёмкости, урезает массив для экономии памя
ти.
}
procedure SetIntLength(var a: TBigInt; newLength: SizeInt);
const
  // Не урезать буфер, если экономия будет незначительной.
  SHRINK_THRESHOLD = 16; // 16 * 4 байта = 64 байта
var
  currentCapacity, newCapacity: SizeInt;
begin
  currentCapacity := System.Length(a.Digits);

  if newLength > currentCapacity then
  begin
    newCapacity := currentCapacity;
    if newCapacity = 0 then
      newCapacity := 4;
    while newCapacity < newLength do
    begin
      // Для небольших чисел удваиваем буфер для скорости (меньше перераспределений).
      // Для больших чисел используем более медленный рост (1.5x) для экономии памяти.
      if newCapacity > 256 then // Порог = 256 * 4 байта = 1 КБ
      begin
        // Рост в 1.5 раза, с проверкой на переполнение
        if newCapacity > High(SizeInt) - (newCapacity div 2) then
        begin
          newCapacity := newLength;
          Break;
        end;
        newCapacity := newCapacity + (newCapacity div 2);
      end
      else
      begin
        // Рост в 2 раза, с проверкой на переполнение
        if newCapacity > High(SizeInt) div 2 then
        begin
          newCapacity := newLength;
          Break;
        end;
        newCapacity := newCapacity * 2;
      end;
    end;
    System.SetLength(a.Digits, newCapacity);
  end
  else if (newLength > SHRINK_THRESHOLD) and (newLength < currentCapacity div 4)
 then
  begin
    // Урезаем буфер, если он стал слишком большим.
    newCapacity := newLength * 2;
    System.SetLength(a.Digits, newCapacity);
  end;
  a.Length := newLength;
end;

{
  --- Основные процедуры ---
}

{ Инициализирует TBigInt как канонический ноль. }
procedure BigIntInit(var a: TBigInt);
begin
  a.Sign   := 0;
  a.Digits := nil;
  a.Length := 0;
end;

{ Освобождает память, занимаемую TBigInt. }
procedure BigIntFree(var a: TBigInt);
begin
  a.Digits := nil;
  a.Length := 0;
  a.Sign   := 0;
end;

{ Копирует значение из Source в dest. Защищено от копирования в самого себя. }
procedure BigIntCopy(var dest: TBigInt; const Source: TBigInt);
begin
  if @dest = @Source then Exit;

  if not Assigned(Source.Digits) or (Source.Sign = 0) then
  begin
    BigIntInit(dest); // Гарантируем, что копия нуля - это канонический ноль
    Exit;
  end;

  SetIntLength(dest, Source.Length);
  dest.Sign := Source.Sign;
  if Source.Length > 0 then
    System.Move(Source.Digits[0], dest.Digits[0], Source.Length * SizeOf(TDigit)
);
end;

{ Умножает TBigInt на один "разряд" (TDigit). }
procedure BigIntMulDigit(var res: TBigInt; const a: TBigInt; m: TDigit);
var
  i:     SizeInt;
  carry, p: TDoubleDigit;
  tempA: TBigInt;
  pA:    ^TBigInt;
begin
  if @res = @a then
  begin
    tempA.Init;
    BigIntCopy(tempA, a);
    pA := @tempA;
  end
  else
  begin
    pA := @a;
  end;

  if (pA^.Sign = 0) or (m = 0) then
  begin
    SetIntLength(res, 1);
    res.Digits[0] := 0;
    res.Sign      := 0;
    Exit;
  end;

  SetIntLength(res, pA^.Length + 1);
  carry := 0;
  for i := 0 to pA^.Length - 1 do
  begin
    p     := TDoubleDigit(pA^.Digits[i]) * m + carry;
    res.Digits[i] := p and MaxDigit;
    carry := p shr DigitBits;
  end;
  res.Digits[pA^.Length] := carry;
  res.Sign := pA^.Sign;
  Normalize(res);
end;

{
  Создаёт TBigInt из строки.
  - Обрабатывает знак ('+' или '-').
  - Для ускорения парсит строку блоками по 9 цифр (BlockSize).
}
procedure BigIntFromStr(var a: TBigInt; const s: string);
var
  isNegative:  boolean;
  startIndex, blockLength: integer;
  blockValue:  TDigit;
  blockStr:    string;
  blockBigInt: TBigInt;
begin
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

  SetIntLength(a, 1);
  a.Digits[0] := 0;
  a.Sign      := 0;

  blockBigInt.Init;

  while startIndex <= System.Length(s) do
  begin
    blockLength := System.Length(s) - startIndex + 1;
    if blockLength > BlockSize then
      blockLength := BlockSize;
    blockStr      := System.Copy(s, startIndex, blockLength);
    blockValue    := _StrToInt(blockStr);

    if a.Sign <> 0 then
    begin
      if blockLength > 0 then
        BigIntMulDigit(a, a, PowersOf10[blockLength]);
    end;

    SetIntLength(blockBigInt, 1);
    blockBigInt.Digits[0] := blockValue;
    blockBigInt.Sign      := 1;
    Normalize(blockBigInt);

    BigIntAdd(a, a, blockBigInt);

    startIndex := startIndex + blockLength;
  end;

  if isNegative then
    a.Sign := -1
  else if a.Sign <> 0 then
    a.Sign := 1;

  Normalize(a);
end;

{ Создаёт TBigInt из Int64. Обрабатывает пограничное значение Low(int64). }
procedure BigIntFromInt64(var a: TBigInt; const Value: int64);
var
  abs_val: uint64;
begin
  BigIntInit(a);

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

{ Создаёт TBigInt из UInt64. }
procedure BigIntFromUInt64(var a: TBigInt; const Value: UInt64);
begin
  BigIntInit(a);

  if Value = 0 then
  begin
    SetIntLength(a, 1);
    a.Digits[0] := 0;
    a.Sign      := 0;
    Exit;
  end;

  a.Sign  := 1;

  if Value <= MaxDigit then
  begin
    SetIntLength(a, 1);
    a.Digits[0] := Value;
  end
  else
  begin
    SetIntLength(a, 2);
    a.Digits[0] := Value and MaxDigit;
    a.Digits[1] := Value shr DigitBits;
  end;
  Normalize(a);
end;

{
  Пытается преобразовать TBigInt в UInt64.
  Возвращает True в случае успеха. Неудача при отрицательном знаке или переполн
ении.
}
function TryBigIntToUInt64(const a: TBigInt; out Value: uint64): boolean;
begin
  Result := False;
  if not Assigned(a.Digits) then
  begin
    Value := 0;
    Result := True;
    Exit;
  end;
  if (a.Sign < 0) or (a.Length > 2) then Exit;

  if a.Sign = 0 then
  begin
    Value  := 0;
    Result := True;
    Exit;
  end;

  if a.Length = 1 then
    Value := a.Digits[0]
  else
    Value := (uint64(a.Digits[1]) shl DigitBits) or a.Digits[0];

  Result := True;
end;

{ Разделяет число 'a' на две части 'hi' и 'lo' по индексу 'm'. }
procedure BigIntSplit(var hi, lo: TBigInt; const a: TBigInt; m: SizeInt);
var
  loLen: SizeInt;
begin
  if m <= 0 then
  begin
    BigIntCopy(lo, a);
    BigIntInit(hi);
    SetIntLength(hi, 1);
    hi.Digits[0] := 0;
    hi.Sign      := 0;
    Exit;
  end;

  if a.Length > m then
  begin
    SetIntLength(hi, a.Length - m);
    System.Move(a.Digits[m], hi.Digits[0], (a.Length - m) * SizeOf(TDigit));
    hi.Sign := a.Sign;
    Normalize(hi);
  end
  else
  begin
    BigIntInit(hi);
    SetIntLength(hi, 1);
    hi.Digits[0] := 0;
    hi.Sign      := 0;
  end;

  loLen := a.Length;
  if loLen > m then
    loLen := m;

  SetIntLength(lo, loLen);
  if loLen > 0 then
    System.Move(a.Digits[0], lo.Digits[0], loLen * SizeOf(TDigit));
  lo.Sign := a.Sign;
  Normalize(lo);
end;

{
  Пытается преобразовать TBigInt в Int64.
  Возвращает True в случае успеха. Неудача при переполнении.
}
function TryBigIntToInt64(const a: TBigInt; out Value: int64): boolean;
var
  abs_val: uint64;
begin
  Result := False;
  if not Assigned(a.Digits) then
  begin
    Value := 0;
    Result := True;
    Exit;
  end;

  if a.Length > 2 then Exit;

  if a.Sign = 0 then
  begin
    Value  := 0;
    Result := True;
    Exit;
  end;

  if a.Length = 1 then
    abs_val := a.Digits[0]
  else
    abs_val := (uint64(a.Digits[1]) shl DigitBits) or a.Digits[0];

  if a.Sign = 1 then
  begin
    if abs_val > High(int64) then Exit;
    Value := int64(abs_val);
  end
  else
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

{
  Преобразует TBigInt в десятичную строку.
  Использует быстрый алгоритм деления на степени 10.
}
function BigIntToStr(const a: TBigInt): string;
const
  divisor = 1000000000;
var
  temp, quot: TBigInt;
  res, s: string;
  rem: TDigit;
begin
  if not Assigned(a.Digits) or (a.Sign = 0) then Exit('0');

  temp.Init;
  BigIntCopy(temp, a);
  temp.Sign := 1;

  res := '';

  quot.Init;
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

  if a.Sign = -1 then
    res := '-' + res;

  Exit(res);
end;

{ Выполняет побитовый сдвиг влево (<<). }
procedure BigIntSHL(var res: TBigInt; const a: TBigInt; bits: cardinal);
var
  tempA: TBigInt;
  pA:    ^TBigInt;
  wordShift, bitShift: cardinal;
  i:     SizeInt;
  carry, p: TDoubleDigit;
  newLength: SizeInt;
begin
  if @res = @a then
  begin
    tempA.Init;
    BigIntCopy(tempA, a);
    pA := @tempA;
  end
  else
  begin
    pA := @a;
  end;

  if (pA^.Sign = 0) or (bits = 0) or not Assigned(pA^.Digits) then
  begin
    if @res <> @pA^ then
      BigIntCopy(res, pA^);
    Exit;
  end;

  wordShift := bits div DigitBits;
  bitShift  := bits mod DigitBits;

  carry := (TDoubleDigit(pA^.Digits[pA^.Length - 1]) shl bitShift) shr DigitBits
;
  if carry > 0 then
    newLength := pA^.Length + wordShift + 1
  else
    newLength := pA^.Length + wordShift;

  SetIntLength(res, newLength);
  res.Sign := pA^.Sign;

  for i := 0 to wordShift - 1 do
    res.Digits[i] := 0;

  if bitShift = 0 then
  begin
    for i := 0 to pA^.Length - 1 do
      res.Digits[i + wordShift] := pA^.Digits[i];
  end
  else
  begin
    carry := 0;
    for i := 0 to pA^.Length - 1 do
    begin
      p     := (TDoubleDigit(pA^.Digits[i]) shl bitShift) or carry;
      res.Digits[i + wordShift] := p and MaxDigit;
      carry := p shr DigitBits;
    end;
    if carry > 0 then
      res.Digits[pA^.Length + wordShift] := carry;
  end;

  Normalize(res);
end;

{ Выполняет побитовый сдвиг вправо (>>). }
procedure BigIntSHR(var res: TBigInt; const a: TBigInt; bits: cardinal);
var
  tempA: TBigInt;
  pA:    ^TBigInt;
  wordShift, bitShift: cardinal;
  i:     SizeInt;
  carry, p: TDoubleDigit;
  newLength: SizeInt;
begin
  if @res = @a then
  begin
    tempA.Init;
    BigIntCopy(tempA, a);
    pA := @tempA;
  end
  else
  begin
    pA := @a;
  end;

  if (pA^.Sign = 0) or (bits = 0) or not Assigned(pA^.Digits) then
  begin
    if @res <> @pA^ then
      BigIntCopy(res, pA^);
    Exit;
  end;

  wordShift := bits div DigitBits;
  bitShift  := bits mod DigitBits;

  if wordShift >= pA^.Length then
  begin
    SetIntLength(res, 1);
    res.Digits[0] := 0;
    res.Sign      := 0;
  end
  else
  begin
    newLength := pA^.Length - wordShift;
    SetIntLength(res, newLength);
    res.Sign := pA^.Sign;

    if bitShift = 0 then
    begin
      for i := 0 to newLength - 1 do
        res.Digits[i] := pA^.Digits[i + wordShift];
    end
    else
    begin
      carry := 0;
      for i := newLength - 1 downto 0 do
      begin
        p     := (TDoubleDigit(pA^.Digits[i + wordShift]) shr bitShift) or carry
;
        res.Digits[i] := p and MaxDigit;
        carry := TDoubleDigit(pA^.Digits[i + wordShift]) shl (DigitBits - bitShift);
      end;
    end;
    Normalize(res);
  end;
end;

{ Сравнивает абсолютные значения двух TBigInt. }
function CompareAbs(const a, b: TBigInt): integer;
var
  i: integer;
  lenA, lenB: SizeInt;
begin
  if Assigned(a.Digits) then lenA := a.Length else lenA := 0;
  if Assigned(b.Digits) then lenB := b.Length else lenB := 0;

  if lenA > lenB then Exit(1);
  if lenA < lenB then Exit(-1);
  if lenA = 0 then Exit(0);

  for i := lenA - 1 downto 0 do
  begin
    if a.Digits[i] > b.Digits[i] then Exit(1);
    if a.Digits[i] < b.Digits[i] then Exit(-1);
  end;
  Exit(0);
end;

{ Складывает абсолютные значения двух TBigInt. }
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

{ Вычитает абсолютное значение 'b' из 'a' (a должно быть >= b). }
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

{
  Сложение двух TBigInt с учётом знака.
  - Использует быстрый путь для Int64, если возможно.
  - Если знаки одинаковые, складывает модули.
  - Если знаки разные, вычитает модуль меньшего из большего.
}
procedure BigIntAdd(var res: TBigInt; const a_in, b_in: TBigInt);
var
  temp:  TBigInt;
  cmp:   integer;
  valA, valB: int64;
  p_res: ^TBigInt;
begin
  // Оптимизация для a + a -> a * 2
  if @a_in = @b_in then
  begin
    BigIntSHL(res, a_in, 1);
    Exit;
  end;

  if (@res = @a_in) or (@res = @b_in) then
  begin
    temp.Init;
    p_res := @temp;
  end
  else
  begin
    p_res := @res;
  end;

  if TryBigIntToInt64(a_in, valA) and TryBigIntToInt64(b_in, valB) then
  begin
    if not ((valA > 0) and (valB > 0) and (valA > High(int64) - valB)) and
      not ((valA < 0) and (valB < 0) and (valA < Low(int64) - valB)) then
    begin
      BigIntFromInt64(p_res^, valA + valB);
      if p_res = @temp then BigIntCopy(res, temp);
      Exit;
    end;
  end;

  if not Assigned(a_in.Digits) or (a_in.Sign = 0) then
  begin
    BigIntCopy(p_res^, b_in);
    if p_res = @temp then BigIntCopy(res, temp);
    Exit;
  end;
  if not Assigned(b_in.Digits) or (b_in.Sign = 0) then
  begin
    BigIntCopy(p_res^, a_in);
    if p_res = @temp then BigIntCopy(res, temp);
    Exit;
  end;

  if a_in.Sign = b_in.Sign then
  begin
    BigIntAddAbs(p_res^, a_in, b_in);
    p_res^.Sign := a_in.Sign;
  end
  else
  begin
    cmp := CompareAbs(a_in, b_in);
    if cmp > 0 then
    begin
      BigIntSubAbs(p_res^, a_in, b_in);
      p_res^.Sign := a_in.Sign;
    end
    else if cmp < 0 then
    begin
      BigIntSubAbs(p_res^, b_in, a_in);
      p_res^.Sign := b_in.Sign;
    end
    else
    begin
      SetIntLength(p_res^, 1);
      p_res^.Digits[0] := 0;
      p_res^.Sign      := 0;
    end;
  end;

  if p_res = @temp then
    BigIntCopy(res, temp);
end;

{
  Вычитание двух TBigInt с учётом знака.
  - Использует быстрый путь для Int64, если возможно.
  - Сводится к сложению, если знаки разные (a - (-b) = a + b).
  - Если знаки одинаковые, вычитает модули.
}
procedure BigIntSub(var res: TBigInt; const a, b: TBigInt);
var
  temp:  TBigInt;
  cmp:   integer;
  valA, valB: int64;
  p_res: ^TBigInt;
begin
  // Оптимизация для a - a -> 0
  if @a = @b then
  begin
    BigIntFromInt64(res, 0);
    Exit;
  end;

  if (@res = @a) or (@res = @b) then
  begin
    temp.Init;
    p_res := @temp;
  end
  else
  begin
    p_res := @res;
  end;

  if TryBigIntToInt64(a, valA) and TryBigIntToInt64(b, valB) then
  begin
    if not ((valA > 0) and (valB < 0) and (valA > High(int64) + valB)) and
      not ((valA < 0) and (valB > 0) and (valA < Low(int64) + valB)) then
    begin
      BigIntFromInt64(p_res^, valA - valB);
      if p_res = @temp then BigIntCopy(res, temp);
      Exit;
    end;
  end;

  if not Assigned(b.Digits) or (b.Sign = 0) then
  begin
    BigIntCopy(p_res^, a);
    if p_res = @temp then BigIntCopy(res, temp);
    Exit;
  end;

  if not Assigned(a.Digits) or (a.Sign = 0) then
  begin
    BigIntCopy(p_res^, b);
    p_res^.Sign := -b.Sign;
    if p_res = @temp then BigIntCopy(res, temp);
    Exit;
  end;

  if a.Sign <> b.Sign then
  begin
    BigIntAddAbs(p_res^, a, b);
    p_res^.Sign := a.Sign;
  end
  else
  begin
    cmp := CompareAbs(a, b);
    if cmp > 0 then
    begin
      BigIntSubAbs(p_res^, a, b);
      p_res^.Sign := a.Sign;
    end
    else if cmp < 0 then
    begin
      BigIntSubAbs(p_res^, b, a);
      p_res^.Sign := -a.Sign;
    end
    else
    begin
      SetIntLength(p_res^, 1);
      p_res^.Digits[0] := 0;
      p_res^.Sign      := 0;
    end;
  end;

  if p_res = @temp then
    BigIntCopy(res, temp);
end;

{
  Оптимизированное "школьное" возведение в квадрат.
  Работает быстрее, чем a*a, за счёт сокращения избыточных вычислений.
}
procedure BigIntSqr_School(var res: TBigInt; const a: TBigInt);
var
    i, j, len: SizeInt;
    carry: TDoubleDigit;
    newLength: SizeInt;
    tempA: TBigInt;
    ptrA: ^TBigInt;
    p, p2, prod, s, two_prod_hi, two_prod_lo: TDoubleDigit;
begin
    if @res = @a then
    begin
        tempA.Init;
        BigIntCopy(tempA, a);
        ptrA := @tempA;
    end
    else
    begin
        ptrA := @a;
    end;
    len := ptrA^.Length;

    if (ptrA^.Sign = 0) or not Assigned(ptrA^.Digits) then
    begin
        SetIntLength(res, 1);
        res.Digits[0] := 0;
        res.Sign      := 0;
        Exit;
    end;

    newLength := len * 2;
    SetIntLength(res, newLength);
    System.FillChar(res.Digits[0], newLength * SizeOf(TDigit), 0);

    for i := 0 to len - 1 do
    begin
        p := TDoubleDigit(ptrA^.Digits[i]);
        p2 := p * p;

        // p2 = a[i] * a[i]
        // Add the lower part to the result, and carry over the upper part.
        p := TDoubleDigit(res.Digits[2*i]) + (p2 and MaxDigit);
        res.Digits[2*i] := p and MaxDigit;
        carry := p shr DigitBits;
        carry += (p2 shr DigitBits);

        for j := i + 1 to len - 1 do
        begin
            // prod = a[i] * a[j]
            prod := TDoubleDigit(ptrA^.Digits[i]) * ptrA^.Digits[j];

            // Safely calculate 2 * prod, splitting it into high and low parts
            two_prod_lo := (prod and MaxDigit) shl 1;
            two_prod_hi := (prod shr DigitBits) * 2 + (two_prod_lo shr DigitBits
);
            two_prod_lo := two_prod_lo and MaxDigit;

            // Add the existing digit, the carry from the previous step, and the low part of 2*prod
            s := TDoubleDigit(res.Digits[i+j]) + carry + two_prod_lo;

            // The new digit is the low part of the sum
            res.Digits[i+j] := s and MaxDigit;

            // The new carry is the high part of the sum plus the high part of 2*prod
            carry := (s shr DigitBits) + two_prod_hi;
        end;

        j := i + len;
        while carry > 0 do
        begin
            p := TDoubleDigit(res.Digits[j]) + carry;
            res.Digits[j] := p and MaxDigit;
            carry := p shr DigitBits;
            Inc(j);
        end;
    end;

    res.Sign := 1;
    Normalize(res);
end;


{ Простое "школьное" умножение столбиком. Используется для небольших чисел. }
procedure BigIntMul_School(var res: TBigInt; const a, b: TBigInt);
var
  i, j:      SizeInt;
  carry, p:  TDoubleDigit;
  newLength: SizeInt;
  tempA, tempB: TBigInt;
  ptrA, ptrB: ^TBigInt;
begin
  if @res = @a then
  begin
    tempA.Init;
    BigIntCopy(tempA, a);
    ptrA := @tempA;
  end
  else
  begin
    ptrA := @a;
  end;

  if @res = @b then
  begin
    tempB.Init;
    BigIntCopy(tempB, b);
    ptrB := @tempB;
  end
  else
  begin
    ptrB := @b;
  end;

  if (ptrA^.Sign = 0) or (ptrB^.Sign = 0) or not Assigned(ptrA^.Digits) or not Assigned(ptrB^.Digits) then
  begin
    SetIntLength(res, 1);
    res.Digits[0] := 0;
    res.Sign      := 0;
  end
  else
  begin
    newLength := ptrA^.Length + ptrB^.Length;
    SetIntLength(res, newLength);

    for i := 0 to newLength - 1 do
      res.Digits[i] := 0;

    for i := 0 to ptrA^.Length - 1 do
    begin
      carry := 0;
      for j := 0 to ptrB^.Length - 1 do
      begin
        p     := TDoubleDigit(ptrA^.Digits[i]) * ptrB^.Digits[j] + res.Digits[i
+ j] + carry;
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
end;

{
  Основная процедура умножения.
  - Выбирает алгоритм в зависимости от размера чисел:
    - Быстрый путь для Int64.
    - Школьное умножение для маленьких чисел.
    - Алгоритм Карацубы для больших чисел (более эффективен асимптотически).
}
procedure BigIntMul(var res: TBigInt; const a, b: TBigInt);
const
  KARATSUBA_THRESHOLD = 32;
var
  valA, valB: int64;
begin
  // Оптимизация для a * a
  if @a = @b then
  begin
    if (a.Length < KARATSUBA_THRESHOLD) then
      BigIntSqr_School(res, a)
    else
      BigIntMulKaratsuba(res, a, a); // Карацуба для квадрата тоже эффективна
    Exit;
  end;

  if (a.Sign = 0) or (b.Sign = 0) or not Assigned(a.Digits) or not Assigned(b.Digits) then
  begin
    SetIntLength(res, 1);
    res.Digits[0] := 0;
    res.Sign      := 0;
    Exit;
  end;

  if TryBigIntToInt64(a, valA) and TryBigIntToInt64(b, valB) then
  begin
    if not ((valA > 0) and (valB > 0) and (valA > High(int64) div valB)) and
      not ((valA < 0) and (valB < 0) and (valA < High(int64) div valB)) and
      not ((valA > 0) and (valB < 0) and (valB < Low(int64) div valA)) and
      not ((valA < 0) and (valB > 0) and (valA < Low(int64) div valB)) then
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

{ Рекурсивная реализация умножения Карацубы. }
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

  p_a_lo := @scratch[0];
  p_a_hi := @scratch[1];
  p_b_lo := @scratch[2];
  p_b_hi := @scratch[3];
  p_p0   := @scratch[4];
  p_p1   := @scratch[5];
  p_p2   := @scratch[6];
  p_t1   := @scratch[7];
  p_t2   := @scratch[8];

  BigIntSplit(p_a_hi^, p_a_lo^, a, m);
  BigIntSplit(p_b_hi^, p_b_lo^, b, m);

  _BigIntMulKaratsubaRecursive(p_p0^, p_a_lo^, p_b_lo^, scratch);
  _BigIntMulKaratsubaRecursive(p_p2^, p_a_hi^, p_b_hi^, scratch);

  _BigIntAddAbs_Unsafe(p_t1^, p_a_lo^, p_a_hi^);
  Normalize(p_t1^);
  _BigIntAddAbs_Unsafe(p_t2^, p_b_lo^, p_b_hi^);
  Normalize(p_t2^);
  _BigIntMulKaratsubaRecursive(p_p1^, p_t1^, p_t2^, scratch);

  _BigIntSubAbs_Unsafe(p_p1^, p_p1^, p_p0^);
  Normalize(p_p1^);
  _BigIntSubAbs_Unsafe(p_p1^, p_p1^, p_p2^);
  Normalize(p_p1^);

  BigIntSHL(p_p2^, p_p2^, m2 * DigitBits);
  BigIntSHL(p_p1^, p_p1^, m * DigitBits);

  temp.Init;
  _BigIntAddAbs_Unsafe(temp, p_p0^, p_p1^);
  _BigIntAddAbs_Unsafe(temp, temp, p_p2^);
  Normalize(temp);

  if a.Sign = b.Sign then
    temp.Sign := 1
  else
    temp.Sign := -1;

  BigIntCopy(res, temp);
end;

{ Функция-обёртка для умножения Карацубы. Выделяет временную память. }
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
end;

{
  Основная функция сравнения.
  - Использует быстрый путь для Int64.
  - Затем сравнивает знаки.
  - Если знаки одинаковые, сравнивает абсолютные значения.
}
function BigIntCompare(const a, b: TBigInt): integer;
var
  valA, valB: int64;
begin
  if TryBigIntToInt64(a, valA) and TryBigIntToInt64(b, valB) then
  begin
    if valA > valB then Exit(1);
    if valA < valB then Exit(-1);
    Exit(0);
  end;

  if a.Sign > b.Sign then Exit(1);
  if a.Sign < b.Sign then Exit(-1);
  if a.Sign = 0 then Exit(0);

  if a.Sign = 1 then
    Exit(CompareAbs(a, b))
  else
    Exit(-CompareAbs(a, b));
end;

{ Делит TBigInt на один "разряд" (TDigit), возвращает остаток. }
function BigIntDivModDigit(var quot: TBigInt; const a: TBigInt; divisor: TDigit)
: TDigit;
var
  rem:  TDoubleDigit;
  i:    integer;
  temp: TBigInt;
begin
  if divisor = 0 then
  begin
    // Деление на ноль - в идеале должно быть исключение.
    BigIntCopy(quot, a);
    Exit(0);
  end;

  if divisor = 1 then
  begin
    BigIntCopy(quot, a);
    Exit(0);
  end;

  temp.Init;
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

  Result := rem;
end;

{ Деление TBigInt на степень двойки (реализуется как сдвиг вправо). }
procedure BigIntDivPow2(var res: TBigInt; const a: TBigInt; n: cardinal);
begin
  BigIntSHR(res, a, n);
end;

{ Взятие остатка от деления TBigInt на степень двойки (реализуется через битову
ю маску). }
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
    Exit;
  end;

  for i := wordCount to res.Length - 1 do
    res.Digits[i] := 0;

  if bitCount > 0 then
  begin
    mask := (TDigit(1) shl bitCount) - 1;
    res.Digits[wordCount - 1] := res.Digits[wordCount - 1] and mask;
  end;

  Normalize(res);
end;

{ Проверяет, является ли число степенью двойки. }
function IsPowerOfTwo(const a: TBigInt): boolean;
var
  i:     SizeInt;
  digit: TDigit;
  setBits: integer;
begin
  if not Assigned(a.Digits) or (a.Sign <= 0) then Exit(False);

  setBits := 0;
  for i := 0 to a.Length - 1 do
  begin
    digit := a.Digits[i];
    if digit <> 0 then
    begin
      if setBits > 0 then Exit(False);
      if (digit and (digit - 1)) <> 0 then Exit(False);
      setBits := 1;
    end;
  end;

  Exit(setBits = 1);
end;

{ Подсчитывает количество бит в числе (длину в битах). }
function bitCount(const a: TBigInt): integer;
var
  lastDigit: TDigit;
  Count:     integer;
begin
  if not Assigned(a.Digits) or (a.Sign = 0) then Exit(0);

  Count     := (a.Length - 1) * DigitBits;
  lastDigit := a.Digits[a.Length - 1];

  while lastDigit > 0 do
  begin
    Inc(Count);
    lastDigit := lastDigit shr 1;
  end;

  Exit(Count);
end;

{ Округляет число бит до стандартной ширины (8, 16, 32...). }
function RoundUpToStandardWidth(n: integer): integer;
begin
  Result := 8;
  while Result < n do
    Result := Result * 2;
end;

{
  Базовая функция для преобразования в строку по основанию, равному степени 2
  (например, 2, 16). Используется для Hex и Bin представлений.
  Для отрицательных чисел вычисляет дополнительный код.
}
function BigIntToBasePow2Str(const a: TBigInt; bitsPerChar: cardinal; const chars: string): string;
var
  temp, remainder, powerOf2, a_abs: TBigInt;
  res:   string;
  remainder_val: TDigit;
  Width: integer;
begin
  if not Assigned(a.Digits) or (a.Sign = 0) then Exit('0');

  temp.Init;
  remainder.Init;

  if a.Sign = 1 then
  begin
    BigIntCopy(temp, a);
  end
  else // a.Sign = -1
  begin
    a_abs.Init;
    BigIntCopy(a_abs, a);
    a_abs.Sign := 1;

    Width := bitCount(a_abs);
    if not IsPowerOfTwo(a_abs) then
      Inc(Width);

    Width := RoundUpToStandardWidth(Width);

    powerOf2.Init;
    SetIntLength(powerOf2, 1);
    powerOf2.Digits[0] := 1;
    powerOf2.Sign      := 1;
    BigIntSHL(powerOf2, powerOf2, Width);

    BigIntSub(temp, powerOf2, a_abs);
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

  Exit(res);
end;

{ Преобразует TBigInt в шестнадцатеричную строку.
  Для положительных чисел, если старший бит старшего полубайта установлен,
  добавляется ведущий '0' для однозначного определения знака. }
function BigIntToHexStr(const a: TBigInt): string;
var
  s: string;
  val: TDigit;
  charVal: integer;
begin
  s := BigIntToBasePow2Str(a, 4, '0123456789ABCDEF');
  if (a.Sign > 0) and (Length(s) > 0) then
  begin
    charVal := Ord(UpCase(s[1]));
    if charVal > Ord('9') then val := charVal - Ord('A') + 10
    else val := charVal - Ord('0');
    if val >= 8 then
      s := '0' + s;
  end;
  Result := s;
end;

{ Преобразует TBigInt в двоичную строку.
  Для положительных чисел, если строка начинается с '1',
  добавляется ведущий '0'. }
function BigIntToBinStr(const a: TBigInt): string;
var
  s: string;
begin
  s := BigIntToBasePow2Str(a, 1, '01');
  if (a.Sign > 0) and (Length(s) > 0) and (s[1] = '1') then
  begin
    s := '0' + s;
  end;
  Result := s;
end;

{
  Реализует побитовый сдвиг, где величина сдвига также является TBigInt.
  Положительное b - сдвиг влево, отрицательное - вправо.
}
procedure BigIntShift(var res: TBigInt; const a: TBigInt; const b: TBigInt);
var
  shift_amount: uint64;
  ok:    boolean;
  abs_b: TBigInt;
  shift_cardinal: cardinal;
begin
  if not Assigned(a.Digits) or (a.Sign = 0) then
  begin
    BigIntFromInt64(res, 0);
    Exit;
  end;

  if not Assigned(b.Digits) or (b.Sign = 0) then
  begin
    BigIntCopy(res, a);
    Exit;
  end;

  abs_b.Init;
  BigIntCopy(abs_b, b);
  abs_b.Sign := 1;

  ok := TryBigIntToUInt64(abs_b, shift_amount);

  if not ok then
  begin
    if b.Sign > 0 then
      BigIntSHL(res, a, High(cardinal))
    else
      BigIntFromInt64(res, 0);
    Exit;
  end;

  if shift_amount > High(cardinal) then
  begin
    if b.Sign > 0 then
      BigIntSHL(res, a, High(cardinal))
    else
      BigIntFromInt64(res, 0);
    Exit;
  end;

  shift_cardinal := cardinal(shift_amount);

  if b.Sign > 0 then
    BigIntSHL(res, a, shift_cardinal)
  else
    BigIntSHR(res, a, shift_cardinal);
end;

{ Подсчитывает количество ведущих нулей в разряде.
  Реализовано через быстрый алгоритм с битовыми операциями. }
function CountLeadingZeroBits(d: TDigit): integer; inline;
var
  n:  integer;
  ux: uint32;
begin
  ux := d;
  if ux = 0 then
  begin
    Result := DIGIT_BITS;
    Exit;
  end;
  n := 0;
  if (ux and $FFFF0000) = 0 then
  begin
    Inc(n, 16);
    ux := ux shl 16;
  end;
  if (ux and $FF000000) = 0 then
  begin
    Inc(n, 8);
    ux := ux shl 8;
  end;
  if (ux and $F0000000) = 0 then
  begin
    Inc(n, 4);
    ux := ux shl 4;
  end;
  if (ux and $C0000000) = 0 then
  begin
    Inc(n, 2);
    ux := ux shl 2;
  end;
  if (ux and $80000000) = 0 then
    Inc(n, 1);
  Result := n;
end;

{ Делит 64-битное число (hi:lo) на 32-битный разряд. }
procedure DivDoubleByDigit(out q: TDigit; out r: TDigit; hi, lo, d: TDigit);
var
  dividend: TDoubleDigit;
begin
  dividend := (TDoubleDigit(hi) shl DigitBits) or lo;
  q := dividend div d;
  r := dividend mod d;
end;

{
  Реализация деления по алгоритму Кнута (Algorithm D).
  Эффективен для больших чисел.
}
procedure BigIntDivModKnuth(var q, r: TBigInt; const u_in, v_in: TBigInt);
var
  u, v:   TBigInt;
  q_hat, r_hat, rem_digit: TDigit;
  shift:  integer;
  j, i:   integer;
  uj2, uj1, uj: TDigit;
  v1, v2: TDigit;
  mul_carry, add_carry: TDoubleDigit;
  sub_borrow: TDoubleDigit;
  p:      TDoubleDigit;
  p_sub:  int64;
  final_q_sign, final_r_sign: shortint;
begin
  final_r_sign := u_in.Sign;
  if u_in.Sign = v_in.Sign then
    final_q_sign := 1
  else
    final_q_sign := -1;

  if not Assigned(u_in.Digits) or (u_in.Sign = 0) then
  begin
    BigIntFromInt64(q, 0);
    BigIntFromInt64(r, 0);
    Exit;
  end;

  if not Assigned(v_in.Digits) or (v_in.Sign = 0) then
  begin
    BigIntFromInt64(q, 0);
    BigIntCopy(r, u_in);
    Exit;
  end;

  if CompareAbs(u_in, v_in) < 0 then
  begin
    BigIntFromInt64(q, 0);
    BigIntCopy(r, u_in);
    Exit;
  end;

  u.Init;
  BigIntCopy(u, u_in);
  u.Sign := 1;
  v.Init;
  BigIntCopy(v, v_in);
  v.Sign := 1;

  if v.Length = 1 then
  begin
    rem_digit := BigIntDivModDigit(q, u, v.Digits[0]);
    q.Sign    := final_q_sign;
    Normalize(q);
    BigIntFromInt64(r, rem_digit);
    if r.Sign <> 0 then
      r.Sign := final_r_sign;
    Normalize(r);
    Exit;
  end;

  shift := CountLeadingZeroBits(v.Digits[v.Length - 1]);
  if shift > 0 then
  begin
    BigIntSHL(u, u, shift);
    BigIntSHL(v, v, shift);
  end;

  if u.Length = u_in.Length then
  begin
    SetIntLength(u, u.Length + 1);
    u.Digits[u.Length - 1] := 0;
  end;

  SetIntLength(q, u.Length - v.Length);
  q.Sign := final_q_sign;

  for j := u.Length - v.Length - 1 downto 0 do
  begin
    uj2 := u.Digits[j + v.Length];
    uj1 := u.Digits[j + v.Length - 1];
    v1  := v.Digits[v.Length - 1];

    if uj2 = v1 then
      q_hat := MaxDigit
    else
      DivDoubleByDigit(q_hat, r_hat, uj2, uj1, v1);

    if v.Length > 1 then
    begin
      uj := u.Digits[j + v.Length - 2];
      v2 := v.Digits[v.Length - 2];
      // Эта проверка корректирует первоначальную оценку q_hat.
      // Цикл выполняется редко, обычно не более 1-2 раз.
      while (TDoubleDigit(v1) < r_hat) or (TDoubleDigit(q_hat) * v2 > (TDoubleDigit(r_hat) shl DigitBits) + uj) do
      begin
        Dec(q_hat);
        r_hat := r_hat + v1;
      end;
    end;

    mul_carry  := 0;
    sub_borrow := 0;
    for i := 0 to v.Length - 1 do
    begin
      p     := TDoubleDigit(q_hat) * v.Digits[i] + mul_carry;
      mul_carry := p shr DigitBits;
      p_sub := int64(u.Digits[j + i]) - (p and MaxDigit) - sub_borrow;
      if p_sub < 0 then
      begin
        u.Digits[j + i] := p_sub + (TDoubleDigit(1) shl DigitBits);
        sub_borrow      := 1;
      end
      else
      begin
        u.Digits[j + i] := p_sub;
        sub_borrow      := 0;
      end;
    end;

    p_sub := int64(u.Digits[j + v.Length]) - mul_carry - sub_borrow;

    if p_sub < 0 then
    begin
      Dec(q_hat);
      add_carry := 0;
      for i := 0 to v.Length - 1 do
      begin
        p := TDoubleDigit(u.Digits[j + i]) + v.Digits[i] + add_carry;
        u.Digits[j + i] := p and MaxDigit;
        add_carry := p shr DigitBits;
      end;
      u.Digits[j + v.Length] := u.Digits[j + v.Length] + add_carry;
    end
    else
    begin
      u.Digits[j + v.Length] := p_sub;
    end;
    q.Digits[j] := q_hat;
  end;

  Normalize(q);
  SetIntLength(r, v.Length);
  if r.Length > 0 then
    System.Move(u.Digits[0], r.Digits[0], r.Length * SizeOf(TDigit));
  r.Sign := final_r_sign;
  Normalize(r);
  if shift > 0 then
    BigIntSHR(r, r, shift);
end;

{
  Основная процедура деления.
  - Использует быстрый путь для Int64, если возможно.
  - В противном случае вызывает деление по Кнуту.
}
procedure BigIntDivMod(var q, r: TBigInt; const u, v: TBigInt);
var
  u_val, v_val: int64;
begin
  if TryBigIntToInt64(u, u_val) and TryBigIntToInt64(v, v_val) then
  begin
    if v_val = 0 then
    begin
      BigIntFromInt64(q, 0);
      BigIntCopy(r, u);
      Exit;
    end;

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

{
  Небезопасное сложение модулей. Не выполняет проверок и нормализации.
  Используется внутри других функций для оптимизации.
}
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
end;

{
  Небезопасное вычитание модулей. Не выполняет проверок и нормализации.
  Используется внутри других функций для оптимизации.
}
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
end;

{
  Создаёт TBigInt со значением 2^exponent.
  Эффективно реализуется через установку одного бита.
}
procedure BigIntPowerOf2(var a: TBigInt; const exponent: cardinal);
var
  wordIndex, bitIndex: cardinal;
begin
  BigIntInit(a);
  a.Sign := 1;
  wordIndex := exponent div DigitBits;
  bitIndex  := exponent mod DigitBits;
  SetIntLength(a, wordIndex + 1);
  System.FillChar(a.Digits[0], (wordIndex + 1) * SizeOf(TDigit), 0);
  a.Digits[wordIndex] := TDigit(1) shl bitIndex;
  Normalize(a);
end;

{
  Создаёт TBigInt со значением 10^exponent.
  Использует алгоритм быстрого возведения в степень (exponentiation by squaring)
  для эффективного вычисления.
}
procedure BigIntPowerOf10(var a: TBigInt; const exponent: cardinal);
var
  base, temp: TBigInt;
  exp: cardinal;
begin
  if exponent = 0 then
  begin
    BigIntFromInt64(a, 1);
    Exit;
  end;

  BigIntFromInt64(a, 1);
  BigIntFromInt64(base, 10);
  exp := exponent;

  temp.Init;

  while exp > 0 do
  begin
    if (exp and 1) = 1 then // Если бит установлен
    begin
      BigIntCopy(temp, a);
      BigIntMul(a, temp, base);
    end;
    exp := exp shr 1;
    if exp > 0 then
    begin
      BigIntCopy(temp, base);
      BigIntMul(base, temp, temp);
    end;
  end;
end;

{
  Внутренняя универсальная функция для создания TBigInt из строки
  с основанием, равным степени двойки (2, 16).
}
procedure _BigIntFromBasePow2Str(var a: TBigint; const s: string; bitsPerChar: cardinal);
var
  len, totalBits, numDigits, charIndex: SizeInt;
  digit, val: TDigit;
  bitOffset, digitIndex, charVal: integer;
  isNegative: boolean;
  powerOf2: TBigInt;
begin
  BigIntInit(a);
  len := System.Length(s);
  if len = 0 then
  begin
    BigIntFromInt64(a, 0);
    Exit;
  end;

  totalBits := len * bitsPerChar;
  numDigits := (totalBits + DigitBits - 1) div DigitBits;
  SetIntLength(a, numDigits);
  System.FillChar(a.Digits[0], numDigits * SizeOf(TDigit), 0);

  // Определяем знак по первому биту
  charVal := Ord(UpCase(s[1]));
  if bitsPerChar = 4 then // Hex
  begin
    if charVal > Ord('9') then val := charVal - Ord('A') + 10
    else val := charVal - Ord('0');
  end
  else // Bin
  begin
    val := charVal - Ord('0');
  end;
  isNegative := (val and (1 shl (bitsPerChar - 1))) <> 0;

  // Парсим строку, формируя разряды
  charIndex := len;
  for digitIndex := 0 to numDigits - 1 do
  begin
    digit := 0;
    bitOffset := 0;
    while bitOffset < DigitBits do
    begin
      if charIndex < 1 then Break;
      charVal := Ord(UpCase(s[charIndex]));
      if bitsPerChar = 4 then // Hex
      begin
        if charVal > Ord('9') then val := charVal - Ord('A') + 10
        else val := charVal - Ord('0');
      end
      else // Bin
      begin
        val := charVal - Ord('0');
      end;
      digit := digit or (val shl bitOffset);
      Dec(charIndex);
      Inc(bitOffset, bitsPerChar);
    end;
    a.Digits[digitIndex] := digit;
  end;

  a.Sign := 1;
  Normalize(a);

  if isNegative then
  begin
    if a.Sign <> 0 then
    begin
      powerOf2.Init;
      BigIntPowerOf2(powerOf2, totalBits);
      BigIntSub(a, a, powerOf2);
      BigIntFree(powerOf2);
    end;
  end;
end;

{ Создаёт TBigInt из шестнадцатеричной строки. }
procedure BigIntFromHexStr(var a: TBigInt; const s: string);
begin
  _BigIntFromBasePow2Str(a, s, 4);
end;

{ Создаёт TBigInt из двоичной строки. }
procedure BigIntFromBinStr(var a: TBigInt; const s: string);
begin
  _BigIntFromBasePow2Str(a, s, 1);
end;

{
  --- Реализация потоковых парсеров ---
}

{ Вспомогательная функция: преобразует символ в его числовое значение для
  заданного основания. Возвращает -1, если символ невалиден. }
function _CharToDigit(c: char; base: integer): integer;
var
  val: integer;
begin
  val := Ord(UpCase(c));
  if (val >= Ord('0')) and (val <= Ord('9')) then
    val := val - Ord('0')
  else if (val >= Ord('A')) and (val <= Ord('F')) then
    val := val - Ord('A') + 10
  else
    Exit(-1);

  if val < base then
    Result := val
  else
    Result := -1;
end;

{
  Внутренняя универсальная функция для сканирования числа из PChar.
  - P: Указатель на начало.
  - base: Основание системы счисления (2, 10, 16).
  - startPtr: Возвращает указатель на первый значащий символ числа.
  - endPtr: Возвращает указатель на символ, следующий за последним символом чис
ла.
  - charCount: Возвращает количество значащих символов.
  - Возвращает True, если найдено валидное число, иначе False.
}
function _ScanNumber(P: PChar; base: integer; out startPtr, endPtr: PChar; out charCount: SizeInt): boolean;
var
  current: PChar;
  digit: integer;
begin
  charCount := 0;
  startPtr := P;
  endPtr := P;
  current := P;

  // Пропускаем ведущие пробелы (хотя по условию их быть не должно)
  while (current^ <> #0) and (current^ in WhitespaceChars) do
    Inc(current);

  // Находим начало числа
  startPtr := current;

  // Сканируем до конца, считая символы и пропуская пробелы
  while current^ <> #0 do
  begin
    if current^ in WhitespaceChars then
    begin
      Inc(current);
      Continue;
    end;

    digit := _CharToDigit(current^, base);
    if digit = -1 then
      Break; // Нашли нечисловой символ, конец числа

    Inc(charCount);
    Inc(current);
    endPtr := current; // Запоминаем позицию после последней валидной цифры
  end;

  Result := charCount > 0;
end;

{
  Внутренняя функция: строит TBigInt на основе предварительно
  просканированной строки PChar.
}
function _ParseBigIntFromScanned(startPtr: PChar; charCount: SizeInt; base: integer): TBigInt;
var
  p, tempP: PChar;
  a, digitB: TBigInt;
  isNegative: boolean;
  digit, tempCount, bitsPerChar: integer;
  totalBits: integer;
  powerOf2: TBigInt;
  val: Int64;
  isSmall: boolean;
begin
  BigIntInit(a);
  BigIntInit(digitB);
  p := startPtr;

  // Обработка десятичных чисел
  if base = 10 then
  begin
    BigIntFromInt64(a, 0);
    tempP := p;

    while tempP^ <> #0 do
    begin
        val := 0;
        tempCount := 0;
        // Накапливаем блок из BlockSize цифр
        while (tempP^ <> #0) and (tempCount < BlockSize) do
        begin
            if tempP^ in WhitespaceChars then
            begin
                Inc(tempP);
                Continue;
            end;
            digit := _CharToDigit(tempP^, 10);
            if digit = -1 then Break;

            val := val * 10 + digit;
            Inc(tempCount);
            Inc(tempP);
        end;

        if tempCount > 0 then
        begin
            // Если a не ноль, умножаем его на 10^tempCount
            if a.Sign <> 0 then
                BigIntMulDigit(a, a, PowersOf10[tempCount]);

            // Добавляем значение блока
            BigIntFromUInt64(digitB, val);
            BigIntAdd(a, a, digitB);
        end;

        // Если мы остановились из-за невалидного символа, выходим
        if (tempP^ <> #0) and not (tempP^ in WhitespaceChars) and (_CharToDigit(
tempP^, 10) = -1) then
            Break;
    end;

    Normalize(a);
    Exit(a);
  end;

  // Обработка 2-ичных и 16-ричных чисел (с дополнительным кодом)
  bitsPerChar := 0;
  if base = 2 then bitsPerChar := 1
  else if base = 16 then bitsPerChar := 4;

  totalBits := charCount * bitsPerChar;

  // Определяем знак по первому биту
  digit := _CharToDigit(p^, base);
  isNegative := (digit and (1 shl (bitsPerChar - 1))) <> 0;

  // Оптимизированный парсинг с накоплением в TDigit
  BigIntFromInt64(a, 0);
  tempP := p;
  while tempP^ <> #0 do
  begin
      val := 0;
      tempCount := 0;
      // Накапливаем столько символов, сколько поместится в TDigit
      while (tempP^ <> #0) and (tempCount < (DigitBits div bitsPerChar)) do
      begin
          if tempP^ in WhitespaceChars then
          begin
              Inc(tempP);
              Continue;
          end;
          digit := _CharToDigit(tempP^, base);
          if digit = -1 then Break;

          val := (val shl bitsPerChar) or TDigit(digit);
          Inc(tempCount);
          Inc(tempP);
      end;

      if tempCount > 0 then
      begin
          // Сдвигаем TBigInt на количество накопленных бит
          BigIntSHL(a, a, tempCount * bitsPerChar);
          // Добавляем накопленное значение
          BigIntFromUInt64(digitB, val);
          BigIntAdd(a, a, digitB);
      end;

      // Если мы остановились из-за невалидного символа, выходим из основного цикла
      if (tempP^ <> #0) and (_CharToDigit(tempP^, base) = -1) and not (tempP^ in
 WhitespaceChars) then
          break;
  end;

  if isNegative then
  begin
    if a.Sign <> 0 then
    begin
      powerOf2.Init;
      BigIntPowerOf2(powerOf2, totalBits);
      BigIntSub(a, a, powerOf2);
    end;
  end;

  Result := a;
end;


function ParseDecimalBigIntFromPChar(P: PChar; out ResAddr: PChar): TBigInt;
var
  startPtr, endPtr: PChar;
  charCount: SizeInt;
  p_temp: PChar;
  isNegative: boolean;
begin
  BigIntInit(Result);
  ResAddr := P;
  if (P = nil) or (P^ = #0) then
  begin
    Exit;
  end;

  p_temp := P;

  // Пропускаем ведущие пробелы
  while (p_temp^ <> #0) and (p_temp^ in WhitespaceChars) do
    Inc(p_temp);

  isNegative := p_temp^ = '-';
  if isNegative then
  begin
      Inc(p_temp);
      // Пропускаем пробелы между знаком и числом
      while (p_temp^ <> #0) and (p_temp^ in WhitespaceChars) do
        Inc(p_temp);
  end;

  if not _ScanNumber(p_temp, 10, startPtr, endPtr, charCount) then
  begin
    BigIntInit(Result);
    Exit;
  end;

  ResAddr := endPtr;
  Result := _ParseBigIntFromScanned(startPtr, charCount, 10);
  if isNegative then
    Result.Sign := -Result.Sign;
  Normalize(Result);
end;

function ParseHexBigIntFromPChar(P: PChar; out ResAddr: PChar): TBigInt;
var
  startPtr, endPtr: PChar;
  charCount: SizeInt;
begin
  BigIntInit(Result);
  ResAddr := P;
  if (P = nil) or (P^ = #0) then
  begin
    Exit;
  end;

  if not _ScanNumber(P, 16, startPtr, endPtr, charCount) then
  begin
    BigIntInit(Result);
    Exit;
  end;

  ResAddr := endPtr;
  Result := _ParseBigIntFromScanned(startPtr, charCount, 16);
end;

function ParseBinBigIntFromPChar(P: PChar; out ResAddr: PChar): TBigInt;
var
  startPtr, endPtr: PChar;
  charCount: SizeInt;
begin
  BigIntInit(Result);
  ResAddr := P;
  if (P = nil) or (P^ = #0) then
  begin
    Exit;
  end;

  if not _ScanNumber(P, 2, startPtr, endPtr, charCount) then
  begin
    BigIntInit(Result);
    Exit;
  end;

  ResAddr := endPtr;
  Result := _ParseBigIntFromScanned(startPtr, charCount, 2);
end;

function _ScanNumberW(P: PWideChar; base: integer; out startPtr, endPtr: PWideChar; out charCount: SizeInt): boolean;
var
  current: PWideChar;
  digit: integer;
begin
  charCount := 0;
  startPtr := P;
  endPtr := P;
  current := P;

  while (current^ <> #0) and (current^ in WhitespaceChars) do
    Inc(current);

  startPtr := current;

  while current^ <> #0 do
  begin
    if current^ in WhitespaceChars then
    begin
      Inc(current);
      Continue;
    end;

    digit := _CharToDigit(current^, base);
    if digit = -1 then
      Break;

    Inc(charCount);
    Inc(current);
    endPtr := current;
  end;

  Result := charCount > 0;
end;

function _ParseBigIntFromScannedW(startPtr: PWideChar; charCount: SizeInt; base:
 integer): TBigInt;
var
  p: PWideChar;
  a, digitB: TBigInt;
  isNegative: boolean;
  digit, bitsPerChar: integer;
  totalBits: integer;
  powerOf2: TBigInt;
  val: Int64;
  isSmall: boolean;
  tempP: PWideChar;
  tempCount: integer;
begin
  BigIntInit(a);
  BigIntInit(digitB);
  p := startPtr;

  if base = 10 then
  begin
    BigIntFromInt64(a, 0);
    tempP := p;

    while tempP^ <> #0 do
    begin
        val := 0;
        tempCount := 0;
        // Накапливаем блок из BlockSize цифр
        while (tempP^ <> #0) and (tempCount < BlockSize) do
        begin
            if tempP^ in WhitespaceChars then
            begin
                Inc(tempP);
                Continue;
            end;
            digit := _CharToDigit(tempP^, 10);
            if digit = -1 then Break;

            val := val * 10 + digit;
            Inc(tempCount);
            Inc(tempP);
        end;

        if tempCount > 0 then
        begin
            // Если a не ноль, умножаем его на 10^tempCount
            if a.Sign <> 0 then
                BigIntMulDigit(a, a, PowersOf10[tempCount]);

            // Добавляем значение блока
            BigIntFromUInt64(digitB, val);
            BigIntAdd(a, a, digitB);
        end;

        // Если мы остановились из-за невалидного символа, выходим
        if (tempP^ <> #0) and not (tempP^ in WhitespaceChars) and (_CharToDigit(
tempP^, 10) = -1) then
            Break;
    end;

    Normalize(a);
    Exit(a);
  end;

  bitsPerChar := 0;
  if base = 2 then bitsPerChar := 1
  else if base = 16 then bitsPerChar := 4;

  totalBits := charCount * bitsPerChar;

  digit := _CharToDigit(p^, base);
  isNegative := (digit and (1 shl (bitsPerChar - 1))) <> 0;

  // Оптимизированный парсинг с накоплением в TDigit
  BigIntFromInt64(a, 0);
  tempP := p;
  while tempP^ <> #0 do
  begin
      val := 0;
      tempCount := 0;
      // Накапливаем столько символов, сколько поместится в TDigit
      while (tempP^ <> #0) and (tempCount < (DigitBits div bitsPerChar)) do
      begin
          if tempP^ in WhitespaceChars then
          begin
              Inc(tempP);
              Continue;
          end;
          digit := _CharToDigit(tempP^, base);
          if digit = -1 then Break;

          val := (val shl bitsPerChar) or TDigit(digit);
          Inc(tempCount);
          Inc(tempP);
      end;

      if tempCount > 0 then
      begin
          // Сдвигаем TBigInt на количество накопленных бит
          BigIntSHL(a, a, tempCount * bitsPerChar);
          // Добавляем накопленное значение
          BigIntFromUInt64(digitB, val);
          BigIntAdd(a, a, digitB);
      end;

      // Если мы остановились из-за невалидного символа, выходим из основного цикла
      if (tempP^ <> #0) and (_CharToDigit(tempP^, base) = -1) and not (tempP^ in
 WhitespaceChars) then
          break;
  end;

  if isNegative then
  begin
    if a.Sign <> 0 then
    begin
      powerOf2.Init;
      BigIntPowerOf2(powerOf2, totalBits);
      BigIntSub(a, a, powerOf2);
    end;
  end;

  Result := a;
end;


function ParseDecimalBigIntFromPWideChar(P: PWideChar; out ResAddr: PWideChar):
TBigInt;
var
  startPtr, endPtr: PWideChar;
  charCount: SizeInt;
  p_temp: PWideChar;
  isNegative: boolean;
begin
  BigIntInit(Result);
  ResAddr := P;
  if (P = nil) or (P^ = #0) then
  begin
    Exit;
  end;

  p_temp := P;

  // Пропускаем ведущие пробелы
  while (p_temp^ <> #0) and (p_temp^ in WhitespaceChars) do
    Inc(p_temp);

  isNegative := p_temp^ = '-';
  if isNegative then
  begin
      Inc(p_temp);
      // Пропускаем пробелы между знаком и числом
      while (p_temp^ <> #0) and (p_temp^ in WhitespaceChars) do
        Inc(p_temp);
  end;

  if not _ScanNumberW(p_temp, 10, startPtr, endPtr, charCount) then
  begin
    BigIntInit(Result);
    Exit;
  end;

  ResAddr := endPtr;
  Result := _ParseBigIntFromScannedW(startPtr, charCount, 10);
  if isNegative then
    Result.Sign := -Result.Sign;
  Normalize(Result);
end;

function ParseHexBigIntFromPWideChar(P: PWideChar; out ResAddr: PWideChar): TBigInt;
var
  startPtr, endPtr: PWideChar;
  charCount: SizeInt;
begin
  BigIntInit(Result);
  ResAddr := P;
  if (P = nil) or (P^ = #0) then
  begin
    Exit;
  end;

  if not _ScanNumberW(P, 16, startPtr, endPtr, charCount) then
  begin
    BigIntInit(Result);
    Exit;
  end;

  ResAddr := endPtr;
  Result := _ParseBigIntFromScannedW(startPtr, charCount, 16);
end;

function ParseBinBigIntFromPWideChar(P: PWideChar; out ResAddr: PWideChar): TBigInt;
var
  startPtr, endPtr: PWideChar;
  charCount: SizeInt;
begin
  BigIntInit(Result);
  ResAddr := P;
  if (P = nil) or (P^ = #0) then
  begin
    Exit;
  end;

  if not _ScanNumberW(P, 2, startPtr, endPtr, charCount) then
  begin
    BigIntInit(Result);
    Exit;
  end;

  ResAddr := endPtr;
  Result := _ParseBigIntFromScannedW(startPtr, charCount, 2);
end;

{
  --- Реализация побитовых операторов и стандартных функций ---
}

// Преобразует число из знакового представления в битовое (дополнительный код)
// для заданной битовой длины.
procedure _BigIntToTwosComplement(var res: TBigInt; const a: TBigInt; bitLength:
 integer);
var
  powerOf2, abs_a: TBigInt;
begin
  if (a.Sign >= 0) or (bitLength <= 0) then
  begin
    BigIntCopy(res, a);
    Exit;
  end;
  // для a < 0, результат = 2^bitLength - |a|
  abs_a.Init;
  BigIntCopy(abs_a, a);
  abs_a.Sign := 1; // Получаем абсолютное значение

  powerOf2.Init;
  BigIntPowerOf2(powerOf2, bitLength);
  BigIntSub(res, powerOf2, abs_a); // Вычитаем абсолютное значение
end;

// Вспомогательная функция для выполнения побитовых операций
procedure _BigIntBitwiseOp(var res: TBigInt; const a, b: TBigInt; op: integer);
// 0=AND, 1=OR, 2=XOR
var
  lenA, lenB, maxLen, i: SizeInt;
  a_comp, b_comp: TBigInt;
  da, db, dr: TDigit;
  res_neg: boolean;
  bitLen: integer;
begin
  a_comp.Init;
  b_comp.Init;

  // Определяем необходимую битовую длину для представления
  lenA := bitCount(a);
  lenB := bitCount(b);
  if lenA > lenB then bitLen := lenA else bitLen := lenB;
  // Для отрицательных чисел нужен дополнительный бит для знака
  if (a.Sign < 0) or (b.Sign < 0) then
    bitLen := RoundUpToStandardWidth(bitLen + 1);

  // Преобразуем оба числа в дополнительный код одинаковой длины
  _BigIntToTwosComplement(a_comp, a, bitLen);
  _BigIntToTwosComplement(b_comp, b, bitLen);

  if a_comp.Length > b_comp.Length then maxLen := a_comp.Length
  else maxLen := b_comp.Length;

  SetIntLength(res, maxLen);

  // Выполняем операцию поразрядно
  for i := 0 to maxLen - 1 do
  begin
    if i < a_comp.Length then da := a_comp.Digits[i] else da := 0;
    if i < b_comp.Length then db := b_comp.Digits[i] else db := 0;

    case op of
      0: dr := da and db; // AND
      1: dr := da or db;  // OR
      2: dr := da xor db; // XOR
    else
      dr := 0;
    end;
    res.Digits[i] := dr;
  end;

  res.Sign := 1;
  Normalize(res);

  // Если хотя бы один из операндов был отрицательным, нам нужно проверить знаковый бит
  if (a.Sign < 0) or (b.Sign < 0) then
  begin
    // Проверяем знаковый бит результата
    res_neg := (res.Sign <> 0) and (bitLen > 0) and
               ((res.Digits[(bitLen - 1) div DigitBits] and (TDigit(1) shl ((bitLen - 1) mod DigitBits))) <> 0);

    // Если результат отрицательный, преобразуем его обратно в знаковое представление
    if res_neg then
    begin
      BigIntPowerOf2(a_comp, bitLen); // Используем a_comp как временную переменную
      BigIntSub(res, res, a_comp);
    end;
  end;
end;

class operator TBigInt.not(const a: TBigInt): TBigInt;
var
  one, temp: TBigInt;
begin
  // not a эквивалентно -(a + 1)
  Result.Init;
  one.Init;
  temp.Init;

  BigIntFromInt64(one, 1);
  BigIntAdd(temp, a, one);

  BigIntCopy(Result, temp);
  Result.Sign := -Result.Sign;
  Normalize(Result);
end;

class operator TBigInt.and(const a, b: TBigInt): TBigInt;
begin
  Result.Init;
  _BigIntBitwiseOp(Result, a, b, 0);
end;

class operator TBigInt.or(const a, b: TBigInt): TBigInt;
begin
  Result.Init;
  _BigIntBitwiseOp(Result, a, b, 1);
end;

class operator TBigInt.xor(const a, b: TBigInt): TBigInt;
begin
  Result.Init;
  _BigIntBitwiseOp(Result, a, b, 2);
end;

procedure BigIntInc(var a: TBigInt; const n: int64 = 1);
var
  tempN: TBigInt;
begin
  tempN.Init;
  BigIntFromInt64(tempN, n);
  BigIntAdd(a, a, tempN);
end;

procedure BigIntDec(var a: TBigInt; const n: int64 = 1);
var
  tempN: TBigInt;
begin
  tempN.Init;
  BigIntFromInt64(tempN, n);
  BigIntSub(a, a, tempN);
end;

function BigIntAbs(const a: TBigInt): TBigInt;
begin
  BigIntCopy(Result, a);
  if Result.Sign <> 0 then
    Result.Sign := 1;
end;

function BigIntSign(const a: TBigInt): shortint;
begin
  Result := a.Sign;
end;

function BigIntRandom(const Limit: TBigInt): TBigInt;
var
  bitLen, i, digitCount: integer;
  mask: TDigit;
begin
  Result.Init;
  if (not Assigned(Limit.Digits)) or (Limit.Sign <= 0) then
  begin
    BigIntFromInt64(Result, 0);
    Exit;
  end;

  bitLen := bitCount(Limit);
  digitCount := (bitLen + DigitBits - 1) div DigitBits;

  repeat
    SetIntLength(Result, digitCount);
    for i := 0 to digitCount - 1 do
    begin
      // System.Random возвращает Int64, так что используем его для генерации 32-битных разрядов
      Result.Digits[i] := System.Random(MaxDigit + 1);
    end;
    Result.Sign := 1;

    // Применяем маску, чтобы обнулить лишние старшие биты
    bitLen := bitLen mod DigitBits;
    if bitLen > 0 then
    begin
      mask := (TDigit(1) shl bitLen) - 1;
      Result.Digits[digitCount - 1] := Result.Digits[digitCount - 1] and mask;
    end;

    Normalize(Result);
  // Повторяем, если сгенерированное число оказалось >= Limit
  until BigIntCompare(Result, Limit) < 0;
end;

end.
