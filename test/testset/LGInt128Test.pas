unit LGInt128Test;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  LGInt128;

type

  { TUInt128Test }

  TUInt128Test = class(TTestCase)
  published
    procedure Lo_Hi;
    procedure IsZero;
    procedure SetZero;
    procedure Negate;
    procedure IsOdd;
    procedure PopCount;
    procedure IsTwoPower;
    procedure BitLength;
    procedure ToStringTest;
    procedure ToHexString;
    procedure TryParse;
    procedure CompareValue;
    procedure CompareDWord;
    procedure AssignDWord;
    procedure AssignString;
    procedure AsString;
    procedure IncValue;
    procedure DecValue;
    procedure ShiftLeft;
    procedure ShiftRight;
    procedure NotValue;
    procedure AndValue;
    procedure AndDWord;
    procedure OrValue;
    procedure OrDWord;
    procedure XorValue;
    procedure XorDWord;
    procedure AddValue;
    procedure AddDWord;
    procedure SubValue;
    procedure SubDWord;
    procedure UnaryMinus;
    procedure MulValue;
    procedure MulDWord;
    procedure DivValue;
    procedure DivDWord;
    procedure ModValue;
    procedure ModDWord;
    procedure DivRemValue;
    procedure DivRemDWord;
  end;

implementation

procedure TUInt128Test.Lo_Hi;
var
  I: TUInt128;
begin
  {%H-}I.DWords[0] := $11111111;
  I.DWords[1] := $22222222;
  I.DWords[2] := $33333333;
  I.DWords[3] := $44444444;
  AssertTrue(I.Lo = $2222222211111111);
  AssertTrue(I.Hi = $4444444433333333);
end;

procedure TUInt128Test.IsZero;
var
  I: TUInt128;
  J: Integer;
begin
  I := Default(TUInt128);
  for J := 0 to Pred(SizeOf(I)) do
    begin
      AssertTrue(I.IsZero);
      I.Bytes[J] := 1;
      AssertFalse(I.IsZero);
      I.Bytes[J] := 0;
    end;
end;

procedure TUInt128Test.SetZero;
var
  I: TUInt128;
  J: Integer;
begin
  FillChar(I{%H-}, SizeOf(I), $ff);
  AssertFalse(I.IsZero);
  I.SetZero;
  for J := 0 to 3 do
    AssertTrue(I.DWords[J] = 0);
  AssertTrue(I.IsZero);
end;

procedure TUInt128Test.Negate;
var
  I: TUInt128;
  J: Integer;
begin
  I := Default(TUInt128);
  I.Negate;
  for J := 0 to 3 do
    AssertTrue(I.DWords[J] = 0);

  I.DWords[0] := 1;
  I.Negate;
  for J := 0 to 3 do
    AssertTrue(I.DWords[J] = High(DWord));
  I.Negate;
  AssertTrue(I.DWords[0] = 1);
  for J := 1 to 3 do
    AssertTrue(I.DWords[J] = 0);

  I.DWords[0] := 0;
  I.DWords[1] := 5;
  I.Negate;
  AssertTrue(I.DWords[0] = 0);
  AssertTrue(I.DWords[1] = DWord(-5));
  for J := 2 to 3 do
    AssertTrue(I.DWords[J] = High(DWord));
  I.Negate;
  AssertTrue(I.DWords[0] = 0);
  AssertTrue(I.DWords[1] = 5);
  for J := 2 to 3 do
    AssertTrue(I.DWords[J] = 0);

  I.DWords[1] := 0;
  I.DWords[3] := $80000000;
  I.Negate;
  for J := 0 to 2 do
    AssertTrue(I.DWords[J] = 0);
  AssertTrue(I.DWords[3] = $80000000);
  I.Negate;
  for J := 0 to 2 do
    AssertTrue(I.DWords[J] = 0);
  AssertTrue(I.DWords[3] = $80000000);
end;

procedure TUInt128Test.IsOdd;
var
  I: TUInt128;
begin
  I := Default(TUInt128);
  AssertFalse(I.IsOdd);
  I.DWords[0] := 5;
  AssertTrue(I.IsOdd);
  I.DWords[0] := 8;
  AssertFalse(I.IsOdd);
end;

procedure TUInt128Test.PopCount;
var
  I: TUInt128;
  J: Integer;
begin
  I := I.MaxValue;
  AssertTrue(I.PopCount = 128);
  I := Default(TUInt128);
  AssertTrue(I.PopCount = 0);
  for J := 0 to Pred(SizeOf(I)) do
    begin
      I.Bytes[J] := $ff;
      AssertTrue(I.PopCount = 8);
      I.Bytes[J] := 0;
    end;
end;

procedure TUInt128Test.IsTwoPower;
var
  I: TUInt128;
  J: Integer;
begin
  I := Default(TUInt128);
  AssertFalse(I.IsTwoPower);
  for J := 0 to Pred(BitSizeOf(I)) do
    begin
      I.Bits[J] := True;
      AssertTrue(I.IsTwoPower);
      I.Bits[J] := False;
    end;
  I.DWords[3] := $c0000000;
  AssertFalse(I.IsTwoPower);
end;

procedure TUInt128Test.BitLength;
var
  I: TUInt128;
  J: Integer;
begin
  I := Default(TUInt128);
  AssertTrue(I.BitLength = 0);
  for J := 0 to Pred(BitSizeOf(I)) do
    begin
      I.Bits[J] := True;
      AssertTrue(I.BitLength = Succ(J));
      I.Bits[J] := False;
    end;
end;

procedure TUInt128Test.ToStringTest;
var
  I: TUInt128;
begin
  I := Default(TUInt128);
  AssertTrue(I.ToString = '0');

  I := I.Encode(100, 0);
  AssertTrue(I.ToString = '100');

  I := I.Encode(High(QWord), 0);
  AssertTrue(I.ToString = '18446744073709551615');
  I := I.MaxValue;
  AssertTrue(I.ToString = '340282366920938463463374607431768211455');
end;

procedure TUInt128Test.ToHexString;
var
  I: TUInt128;
begin
  I := Default(TUInt128);
  AssertTrue(I.ToHexString = '00000000000000000000000000000000');
  AssertTrue(I.ToHexString(True) = '$00000000000000000000000000000000');
  AssertTrue(I.ToHexString(1) = '0');
  AssertTrue(I.ToHexString(1, True) = '$0');
  AssertTrue(I.ToHexString(7) = '0000000');
  AssertTrue(I.ToHexString(40) = '0000000000000000000000000000000000000000');

  I := I.Encode(High(QWord), 0);
  AssertTrue(I.ToHexString = '0000000000000000FFFFFFFFFFFFFFFF');
  AssertTrue(I.ToHexString(1) = 'FFFFFFFFFFFFFFFF');
  AssertTrue(I.ToHexString(20) = '0000FFFFFFFFFFFFFFFF');
  AssertTrue(I.ToHexString(22, True) = '$000000FFFFFFFFFFFFFFFF');

  I := I.MaxValue;
  AssertTrue(I.ToHexString = 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
  AssertTrue(I.ToHexString(True) = '$FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
  AssertTrue(I.ToHexString(22) = 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
  AssertTrue(I.ToHexString(42, True) = '$0000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
end;

procedure TUInt128Test.TryParse;
var
  I: TUInt128;
begin
  AssertFalse(TUInt128.TryParse('', I));
  AssertFalse(TUInt128.TryParse('0x', I));
  AssertFalse(TUInt128.TryParse('x', I));
  AssertFalse(TUInt128.TryParse('-', I));
  AssertFalse(TUInt128.TryParse('0-', I));

  AssertTrue(TUInt128.TryParse('0', I));
  AssertTrue(I.IsZero);

  AssertTrue(TUInt128.TryParse('110', I));
  AssertTrue(I.ToString = '110');

  AssertTrue(TUInt128.TryParse('x11f', I));
  AssertTrue(I.ToHexString(1) = '11F');
  AssertTrue(TUInt128.TryParse('0x11f', I));
  AssertTrue(I.ToHexString(1) = '11F');
  AssertTrue(TUInt128.TryParse('0X11f', I));
  AssertTrue(I.ToHexString(1) = '11F');


  AssertTrue(TUInt128.TryParse('18446744073709551615', I));
  AssertTrue(I.ToString = '18446744073709551615');

  AssertTrue(TUInt128.TryParse('$ffffffffffffffff', I));
  AssertTrue(I.ToHexString(1) = 'FFFFFFFFFFFFFFFF');

  AssertTrue(TUInt128.TryParse('340282366920938463463374607431768211455', I));
  AssertTrue(I.ToString = '340282366920938463463374607431768211455');
end;

procedure TUInt128Test.CompareValue;
var
  I, J: TUInt128;
begin
  I := Default(TUInt128);
  J := Default(TUInt128);
  AssertTrue(I = J);
  AssertTrue(I >= J);
  AssertFalse(I > J);
  AssertTrue(I <= J);
  AssertFalse(I < J);

  I := TUInt128.Encode(1, 0);
  AssertFalse(I = J);
  AssertTrue(I >= J);
  AssertTrue(I > J);
  AssertFalse(I <= J);
  AssertFalse(I < J);

  J := TUInt128.Encode(0, 1);
  AssertFalse(I = J);
  AssertFalse(I >= J);
  AssertFalse(I > J);
  AssertTrue(I <= J);
  AssertTrue(I < J);

  I := TUInt128.Encode(0, 1);
  AssertTrue(I = J);
  AssertTrue(I >= J);
  AssertFalse(I > J);
  AssertTrue(I <= J);
  AssertFalse(I < J);
end;

procedure TUInt128Test.CompareDWord;
var
  I: TUInt128;
  d: DWord;
begin
  I := Default(TUInt128);
  d := 0;
  AssertTrue(I = d);
  AssertTrue(I >= d);
  AssertFalse(I > d);
  AssertTrue(I <= d);
  AssertFalse(I < d);

  I := TUInt128.Encode(1, 0);
  AssertFalse(I = d);
  AssertTrue(I >= d);
  AssertTrue(I > d);
  AssertFalse(I <= d);
  AssertFalse(I < d);

  d := d.MaxValue;
  AssertFalse(I = d);
  AssertFalse(I >= d);
  AssertFalse(I > d);
  AssertTrue(I <= d);
  AssertTrue(I < d);

  I := TUInt128.Encode(0, 1);
  AssertFalse(I = d);
  AssertTrue(I >= d);
  AssertTrue(I > d);
  AssertFalse(I <= d);
  AssertFalse(I < d);
end;

procedure TUInt128Test.AssignDWord;
var
  I: TUInt128;
  d: DWord;
begin
  d := 0;
  I := d;
  AssertTrue(I.IsZero);

  d := 100001;
  I := d;
  AssertTrue(I.ToString = '100001');

  d := DWord.MaxValue;
  I := d;
  AssertTrue(I.ToString = d.MaxValue.ToString);
end;

procedure TUInt128Test.AssignString;
var
  I: TUInt128;
begin
  I := '0';
  AssertTrue(I.IsZero);

  I := '10001';
  AssertTrue(I.ToString = '10001');

  I := '0X11f';
  AssertTrue(I.ToHexString(1) = '11F');


  I := '340282366920938463463374607431768211122';
  AssertTrue(I.ToString = '340282366920938463463374607431768211122');
end;

procedure TUInt128Test.AsString;
var
  I: TUInt128;
  s: string;
begin
  I := Default(TUInt128);
  s := I;
  AssertTrue(s = '0');

  I := I.Encode(10001, 0);
  s := I;
  AssertTrue(s = '10001');

  I := I.MaxValue;
  s := I;
  AssertTrue(s = '340282366920938463463374607431768211455');
end;

procedure TUInt128Test.IncValue;
var
  I: TUInt128;
  J: Integer;
begin
  I := Default(TUInt128);
  Inc(I);
  AssertTrue(I.DWords[0] = 1);
  for J := 1 to 3 do
    AssertTrue(I.DWords[J] = 0);
  Inc(I);
  AssertTrue(I.DWords[0] = 2);
  for J := 1 to 3 do
    AssertTrue(I.DWords[J] = 0);

  I := I.Encode(High(QWord), 0);
  Inc(I);
  for J := 0 to 1 do
    AssertTrue(I.DWords[J] = 0);
  AssertTrue(I.DWords[2] = 1);
  AssertTrue(I.DWords[3] = 0);
  I := I.MaxValue;
  Inc(I);
  AssertTrue(I.IsZero);
end;

procedure TUInt128Test.DecValue;
var
  I: TUInt128;
begin
  I := Default(TUInt128);
  Dec(I);
  AssertTrue(I = I.MaxValue);

  I := I.Encode(1, 0);
  Dec(I);
  AssertTrue(I.IsZero);

  I := I.Encode(0, 1);
  Dec(I);
  AssertTrue(I.Hi = 0);
  AssertTrue(I.Lo = High(QWord));
end;

procedure TUInt128Test.ShiftLeft;
var
  I, Expect: TUInt128;
  J: Integer;
begin
  I := Default(TUInt128);
  for J := 1 to Pred(BitSizeOf(I)) do
    AssertTrue(I shl J = 0);
  I := 1;
  AssertTrue(I shl 0 = 1);
  AssertTrue(I shl BitSizeOf(I) = 1);
  Expect := 0;
  for J := 0 to Pred(BitSizeOf(I)) do
    begin
      Expect.Bits[J] := True;
      AssertTrue(I shl J = Expect);
      Expect.Bits[J] := False;
    end;
end;

procedure TUInt128Test.ShiftRight;
var
  I, Expect: TUInt128;
  J: Integer;
begin
  I := TUInt128(1) shl 127;
  AssertTrue(I.ToHexString = '80000000000000000000000000000000');
  AssertTrue(I shr 0 = I);
  AssertTrue(I shr BitSizeOf(I) = I);
  Expect := 0;
  for J := 0 to Pred(BitSizeOf(I)) do
    begin
      Expect.Bits[Pred(BitSizeOf(I)) - J] := True;
      AssertTrue(I shr J = Expect);
      Expect.Bits[Pred(BitSizeOf(I)) - J] := False;
    end;
end;

procedure TUInt128Test.NotValue;
var
  I: TUInt128;
begin
  I := not Default(TUInt128);
  AssertTrue(I = I.MaxValue);
  I := not I;
  AssertTrue(I.IsZero);

  I := not I.Encode(1, 0, 0, $80000000);
  AssertTrue((I.DWords[0] = $fffffffe) and (I.DWords[1] = High(DWord)) and
             (I.DWords[2] = High(DWord)) and (I.DWords[3] = $7fffffff));
  I := not I;
  AssertTrue((I.DWords[0] = 1) and (I.DWords[1] = 0) and
             (I.DWords[2] = 0) and (I.DWords[3] = $80000000));
end;

procedure TUInt128Test.AndValue;
var
  I, J: TUInt128;
begin
  I := I.MaxValue and Default(TUInt128);
  AssertTrue(I.IsZero);
  J := 1;
  AssertTrue(I.MaxValue and J = J);
  J := J shl 127;
  AssertTrue(I.MaxValue and J = J);
  AssertTrue(TUInt128(1) and J = 0);
end;

procedure TUInt128Test.AndDWord;
var
  I: TUInt128;
  d: DWord;
begin
  d := 0;
  AssertTrue(I.MaxValue and d = 0);
  d := 1;
  AssertTrue(I.MaxValue and d = 1);
  d := High(DWord);
  AssertTrue(I.MaxValue and d = High(DWord));
  I := Default(TUInt128);
  AssertTrue(I and d = 0);
end;

procedure TUInt128Test.OrValue;
var
  I: TUInt128;
begin
  AssertTrue(I.MaxValue or Default(TUInt128) = I.MaxValue);
  AssertTrue(TUInt128(1) or Default(TUInt128) = 1);
  I := TUInt128(1) shl 127;
  AssertTrue(I or Default(TUInt128) = I);
end;

procedure TUInt128Test.OrDWord;
var
  I: TUInt128;
  d: DWord = 0;
begin
  AssertTrue(I.MaxValue or d = I.MaxValue);
  d := 1;
  AssertTrue(Default(TUInt128) or d = 1);
  d := High(DWord);
  AssertTrue(Default(TUInt128) or d = d);
end;

procedure TUInt128Test.XorValue;
var
  I, J, ExpectI, ExpectJ: TUInt128;
begin
  AssertTrue(I.MaxValue xor Default(TUInt128) = I.MaxValue);
  AssertTrue(I.MaxValue xor I.MaxValue = 0);

  I := 1;
  AssertTrue(I xor Default(TUInt128) = 1);
  AssertTrue(I xor I = 0);

  ExpectI := TUInt128.Encode(1, 1, 1, 1);
  ExpectJ := TUInt128.Encode(1000, 10, 10000, 100);
  I := ExpectJ;
  J := ExpectI;
  I := I xor J;
  J := I xor J;
  I := I xor J;
  AssertTrue(I = ExpectI);
  AssertTrue(J = ExpectJ);
end;

procedure TUInt128Test.XorDWord;
var
  I: TUInt128;
  d: DWord = 0;
begin
  AssertTrue(I.MaxValue xor d = I.MaxValue);
  d := 1;
  AssertTrue(Default(TUInt128) xor d = 1);
  d := High(DWord);
  AssertTrue(I.MaxValue xor d = I.Encode(0, High(DWord), High(DWord), High(DWord)));
end;

procedure TUInt128Test.AddValue;
var
  I: TUInt128;
begin
  AssertTrue(Default(TUInt128) + Default(TUInt128) = Default(TUInt128));
  AssertTrue(Default(TUInt128) + TUInt128(1) = 1);
  AssertTrue(TUInt128(1) + TUInt128(1) = 2);
  I := TUInt128.Encode(High(QWord), 0);
  AssertTrue(I + I = TUInt128.Encode(High(QWord) - 1, 1));
  I := TUInt128.MaxValue;
  AssertTrue(I + I = TUInt128.Encode(High(QWord) - 1, High(QWord)));
  AssertTrue(I + I + TUInt128(2) = 0);
end;

procedure TUInt128Test.AddDWord;
var
  d: DWord = 0;
begin
  AssertTrue(Default(TUInt128) + d = Default(TUInt128));
  d := 1;
  AssertTrue(Default(TUInt128) + d = 1);
  d := High(DWord);
  AssertTrue(Default(TUInt128) + d = High(DWord));
  AssertTrue(TUInt128(1) + d = TUInt128.Encode(0, 1, 0, 0));
end;

procedure TUInt128Test.SubValue;
begin
  AssertTrue(Default(TUInt128) - Default(TUInt128) = Default(TUInt128));
  AssertTrue(TUInt128.MaxValue - Default(TUInt128) = TUInt128.MaxValue);
  AssertTrue(TUInt128.MaxValue - TUInt128.MaxValue = 0);
  AssertTrue(Default(TUInt128) - TUInt128.MaxValue = 1);
  AssertTrue(TUInt128.MaxValue - TUInt128.Encode(High(QWord), 0) = TUInt128.Encode(0, High(QWord)));
end;

procedure TUInt128Test.SubDWord;
var
  d: DWord = 0;
begin
  AssertTrue(Default(TUInt128) - d = Default(TUInt128));
  AssertTrue(TUInt128.MaxValue - d = TUInt128.MaxValue);
  d := 1;
  AssertTrue(TUInt128(1) - d = 0);
  AssertTrue(Default(TUInt128) - d = TUInt128.MaxValue);
  d := High(DWord);
  AssertTrue(TUInt128.MaxValue - d = TUInt128.Encode(0, High(DWord), High(DWord), High(DWord)));
end;

procedure TUInt128Test.UnaryMinus;
var
  I: TUInt128;
begin
  AssertTrue(-Default(TUInt128) = Default(TUInt128));
  AssertTrue(-TUInt128.MaxValue = 1);
  I := I.Encode(100, 10, 1, 3);
  AssertTrue(-I = Default(TUInt128) - I);
  AssertTrue(-(-I) = I);
end;

procedure TUInt128Test.MulValue;
var
  a, b, p: TUInt128;
begin
  AssertTrue(Default(TUInt128) * Default(TUInt128) = Default(TUInt128));
  AssertTrue(TUInt128.MaxValue * Default(TUInt128) = Default(TUInt128));
  AssertTrue(Default(TUInt128) * TUInt128.MaxValue = Default(TUInt128));
  AssertTrue(TUInt128.MaxValue * TUInt128(1) = TUInt128.MaxValue);
  AssertTrue(TUInt128(1) * TUInt128.MaxValue = TUInt128.MaxValue);
  a := '$123456789abcdef';
  b := 'x10000000000000000';
  p := '0x123456789abcdef0000000000000000';
  AssertTrue(a * b = p);
  a := '17293822565881444215';
  b := '1387108685230112567';
  p := '23988411481962661854847013020980949905';
  AssertTrue(a * b = p);
end;

procedure TUInt128Test.MulDWord;
var
  a, p: TUInt128;
  d: DWord = 0;
begin
  AssertTrue(Default(TUInt128) * d = Default(TUInt128));
  AssertTrue(TUInt128.MaxValue * d = Default(TUInt128));
  d := 1;
  AssertTrue(Default(TUInt128) * d = Default(TUInt128));
  AssertTrue(TUInt128.MaxValue * d = TUInt128.MaxValue);
  a := '$123456789abcdef123456';
  d := $10000000;
  p := '$123456789abcdef1234560000000';
  AssertTrue(a * d = p);
end;

procedure TUInt128Test.DivValue;
var
  a, d, q: TUInt128;
  raised: Boolean = False;
begin
  a := 1;
  d := Default(TUInt128);
  try
    a := a div d;
  except
    raised := True;
  end;
  AssertTrue(raised);

  AssertTrue(Default(TUInt128) div TUInt128.MaxValue = Default(TUInt128));
  AssertTrue(TUInt128.MaxValue div TUInt128(1) = TUInt128.MaxValue);
  a := '23988411481962661854847013020980949995';
  AssertTrue(a div TUInt128(1) = a);
  AssertTrue(a div a = 1);

  a := '0x123456789abcdef123456789abcdef0';
  d := 'x10000000000000000';
  q := '$123456789abcdef';
  AssertTrue(a div d = q);

  a := '23988411481962661854847013020980949995';
  d := '17293822565881444215';
  q := '1387108685230112567';
  AssertTrue(a div d = q);
end;

procedure TUInt128Test.DivDWord;
var
  a, q: TUInt128;
  d: DWord = 0;
  raised: Boolean = False;
begin
  a := 1;
  try
    a := a div d;
  except
    raised := True;
  end;
  AssertTrue(raised);

  d := 1;
  AssertTrue(Default(TUInt128) div d = Default(TUInt128));
  AssertTrue(TUInt128.MaxValue div d = TUInt128.MaxValue);
  a := '23988411481962661854847013020980949995';
  AssertTrue(a div d = a);

  a := '$123456789abcdef123456789abcdef0';
  d := $10000000;
  q := '$123456789abcdef123456789';
  AssertTrue(a div d = q);
end;

procedure TUInt128Test.ModValue;
var
  a, d, r: TUInt128;
  raised: Boolean = False;
begin
  a := 1;
  d := Default(TUInt128);
  try
    a := a mod d;
  except
    raised := True;
  end;
  AssertTrue(raised);

  AssertTrue(Default(TUInt128) mod TUInt128.MaxValue = Default(TUInt128));
  AssertTrue(TUInt128.MaxValue mod TUInt128(1) = Default(TUInt128));
  a := '0x123456789abcdef123456789abcdefe7';
  d := 'x1000000000000000000';
  r := 'xf123456789abcdefe7';
  AssertTrue(a mod d = r);
  AssertTrue(a mod a = 0);

  a := '85070591730234615865843651857942050679';
  d := '90670358808300873580343';
  r := '75000038304000606409340';
  AssertTrue(a mod d = r);
end;

procedure TUInt128Test.ModDWord;
var
  a: TUInt128;
  d: DWord = 0;
  raised: Boolean = False;
begin
  a := 1;
  d := 0;
  try
    a := a mod d;
  except
    raised := True;
  end;
  AssertTrue(raised);

  d := 1;
  AssertTrue(TUInt128.MaxValue mod TUInt128(1) = 0);
  a := '0x123456789abcdef123456789abcdefe7';
  d := $10000000;
  AssertTrue(a mod d = $bcdefe7);
end;

procedure TUInt128Test.DivRemValue;
var
  a, d, q, r: TUInt128;
begin
  a := '85070591730234615865843651857942050679';
  d := '90670358808300873580343';
  TUInt128.DivRem(a, d, q, r);
  AssertTrue(q = TUInt128('938240378094173'));
  AssertTrue(r = TUInt128('75000038304000606409340'));
  AssertTrue(q * d + r = a);
end;

procedure TUInt128Test.DivRemDWord;
var
  a, q: TUInt128;
  d, r: DWord;
begin
  a := '85070591730234615865843651857942050679';
  d := 3147295697;
  r := TUInt128.DivRem(a, d, q);
  AssertTrue(q = TUInt128('27029742331273112615272530542'));
  AssertTrue(r = 804372905);
  AssertTrue(q * d + r = a);
end;



initialization

  RegisterTest(TUInt128Test);

end.

