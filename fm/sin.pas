unit Sin;

interface


type
TSin = class
  class function lookup( phase : integer):integer;static; inline;
  class constructor init;
  function compute( phase : integer):integer;
  function compute10( phase : integer):integer;
end;


const
  SIN_LG_N_SAMPLES = 10;
  SIN_N_SAMPLES    = 1 shl SIN_LG_N_SAMPLES;     //2048
  SHIFT            = 24 - SIN_LG_N_SAMPLES; //14
  R                = 1 shl 29;
  C0               = 1 shl 24;
  C1               = 331121857 shr 2;
  C2               = 1084885537 shr 4;
  C3               = 1310449902 shr 6;
  C10_0            = 1 shl 30;
  C10_2            = -1324675874; // scaled * 4
  C10_4            = 1089501821;
  C10_6            = -1433689867;
  C10_8            = 1009356886;
  C10_10           = -421101352;

var
  sintab           : array[0..(SIN_N_SAMPLES shl 1)-1] of int64;

implementation

uses Math;

{ TSin }


class function TSin.lookup( phase : integer):integer;
var
  lowbits,
  phase_int,
  dy,
  y0        : integer;
begin
  lowbits   := phase and ((1  shl  SHIFT) - 1);
  phase_int := (phase  shr  (SHIFT - 1)) and ((SIN_N_SAMPLES - 1)  shl  1);
  dy        := sintab[phase_int];
  y0        := sintab[phase_int + 1];
  Result    := y0 + ((dy * lowbits)  shr  SHIFT);
end;


class constructor TSin.init;
var
  dphase : Double;
  c, s, u, v, i, t : int64;
begin
  dphase := 2 * PI / SIN_N_SAMPLES;
  c      := floor(System.Cos(dphase) * (1  shl  30) + 0.5);
  s      := floor(system.Sin(dphase) * (1  shl  30) + 0.5);
  u      := 1  shl  30;
  v      := 0;
  for i := 0 to SIN_N_SAMPLES div 2-1 do
  begin
    sintab[(i  shl  1) + 1] := (v + 32)  shr  6;
    sintab[((i + SIN_N_SAMPLES div 2)  shl  1) + 1] := -((v + 32)  shr  6);
    t := (u * s + v * c + R)  shr  30;
    u := (u * c - v * s + R)  shr  30;
    v := t;
  end;
  for i := 0 to SIN_N_SAMPLES - 1-1 do
  begin
    sintab[i  shl  1] := sintab[(i  shl  1) + 3] - sintab[(i  shl  1) + 1];
  end;
  sintab[(SIN_N_SAMPLES  shl  1) - 2] := -sintab[(SIN_N_SAMPLES  shl  1) - 1];
end;


function TSin.compute( phase : integer):integer;
var
  x, x2, x4, x6, y : integer;
begin
  x := (phase and ((1  shl  23) - 1)) - (1  shl  22);
  x2 := (x * x)  shr  22;
  x4 := (x2 * x2)  shr  24;
  x6 := (x2 * x4)  shr  24;
  y  := C0 -
      ((C1 * x2)  shr  24) +
      ((C2 * x4)  shr  24) -
      ((C3 * x6)  shr  24);
  y      := y xor (-((phase  shr  23) and 1));
  Result := y;
end;


function TSin.compute10( phase : integer):integer;
var
  x : integer; x2,y:int64;
begin
  x := (phase and ((1  shl  29) - 1)) - (1  shl  28);
  x2 := (x * x)  shr  26;
  y := (((((((((((((((C10_10
    * x2)  shr  34) + C10_8)
    * x2)  shr  34) + C10_6)
    * x2)  shr  34) + C10_4)
    * x2)  shr  32) + C10_2)
    * x2)  shr  30) + C10_0);
  y      := y xor (-((phase  shr  29) and 1));
  Result := y;
end;





end.

