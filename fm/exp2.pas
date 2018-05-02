unit Exp2;

interface

type
  TExp2 = class
    class constructor init;
    class function lookup(x: integer): integer; inline; static;
  end;

function dtanh(y: Double): Double;

type
  Tanh = class
    class constructor init;
    class function lookup(x: integer): integer; inline; static;
  end;

const
  EXP2_LG_N_SAMPLES = 10;
  EXP2_N_SAMPLES    = (1 shl EXP2_LG_N_SAMPLES);
  TANH_LG_N_SAMPLES = 10;
  TANH_N_SAMPLES    = (1 shl TANH_LG_N_SAMPLES);

var
  SHIFT  : integer = 24 - EXP2_LG_N_SAMPLES;
  step   : Double  = 4.0 / TANH_N_SAMPLES;
  exp2tab: array [0 .. (EXP2_N_SAMPLES shl 1) - 1] of integer;
  tanhtab: array [0 .. (TANH_N_SAMPLES shl 1) - 1] of integer;

implementation

uses Math;

{ Exp2 }

class constructor TExp2.init;
var
  inc, y: Double;
  i     : integer;
begin
  inc := Power(2, 1 / EXP2_N_SAMPLES);
  y   := 1 shl 30;

  for i := 0 to EXP2_N_SAMPLES - 1 do
  begin
    exp2tab[(i shl 1) + 1] := floor(y + 0.5);
    y := y * inc;
  end;

  for i := 0 to EXP2_N_SAMPLES - 1 - 1 do
  begin
    exp2tab[i shl 1] := exp2tab[(i shl 1) + 3] - exp2tab[(i shl 1) + 1];
  end;

  exp2tab[(EXP2_N_SAMPLES shl 1) - 2] := (1 shl 31) - exp2tab[(EXP2_N_SAMPLES shl 1) - 1];
end;

class function TExp2.lookup(x: integer): integer;
var
  lowbits, x_int, dy, y0, y: integer;
begin
  lowbits := x and ((1 shl SHIFT) - 1);
  x_int   := (x shr (SHIFT - 1)) and ((EXP2_N_SAMPLES - 1) shl 1);
  dy      := exp2tab[x_int];
  y0      := exp2tab[x_int + 1];
  y       := y0 + ((dy * lowbits) shr SHIFT);
  Result  := y shr (6 - (x shr 24));
end;

function dtanh(y: Double): Double;
begin
  Result := 1 - y * y;
end;

{ Tanh }

class constructor Tanh.init;
var
  y                 : Double;
  k1, k2, k3, k4, dy: Double;
  i, lasty          : integer;
begin
  y     := 0;
  for i := 0 to TANH_N_SAMPLES - 1 do
  begin
    tanhtab[(i shl 1) + 1] := trunc((1 shl 24) * y + 0.5);
    k1 := dtanh(y);
    k2 := dtanh(y + 0.5 * step * k1);
    k3 := dtanh(y + 0.5 * step * k2);
    k4 := dtanh(y + step * k3);
    dy := (step / 6) * (k1 + k4 + 2 * (k2 + k3));
    y  := y + dy;
  end;

  for i := 0 to TANH_N_SAMPLES - 1 - 1 do
  begin
    tanhtab[i shl 1] := tanhtab[(i shl 1) + 3] - tanhtab[(i shl 1) + 1];
  end;

  lasty := trunc((1 shl 24) * y + 0.5);
  tanhtab[(TANH_N_SAMPLES shl 1) - 2] := lasty - tanhtab[(TANH_N_SAMPLES shl 1) - 1];
end;

class function Tanh.lookup(x: integer): integer;
var
  signum, sx, lowbits, x_int, dy, y0, y: integer;
begin
  signum := x shr 31;
  x      := x xor signum;
  if x >= (4 shl 24) then
  begin
    if x >= (17 shl 23) then
    begin
      Exit(signum xor (1 shl 24));
    end;
    sx := (-48408812 * x) shr 24;
    Exit(signum xor ((1 shl 24) - 2 * TExp2.lookup(sx)));
  end
  else
  begin
    lowbits := x and ((1 shl SHIFT) - 1);
    x_int   := (x shr (SHIFT - 1)) and ((TANH_N_SAMPLES - 1) shl 1);
    dy      := tanhtab[x_int];
    y0      := tanhtab[x_int + 1];
    y       := y0 + ((dy * lowbits) shr SHIFT);
    Exit(y xor signum);
  end;
end;

end.
