unit PitchEnv;

interface

{$POINTERMATH ON}

uses env;

const
  LG_N = 6;
  N = 1 shl LG_N;

type
TPitchEnv = record
class var
  unit_        : integer;
var
  FRates,
  FLevels      : TEnvArray;
  FLevel,
  FTargetLevel : integer;
  FIsRising    : Boolean;
  FIndex,
  FInc         : integer;
  FIsDown      : Boolean;

  constructor Create( sample_rate : Double);
  procedure SetValues(const aRates, aLevels : TEnvArray);
  function getSample:integer;
  procedure KeyDown( aIsDown : Boolean);
  procedure Advance( aNewIndex : integer);
  procedure getPosition(var aStep : byte);
end;

const
  pitchenv_rate : array[0..99] of byte = (
    1, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12,
    12, 13, 13, 14, 14, 15, 16, 16, 17, 18, 18, 19, 20, 21, 22, 23, 24,
    25, 26, 27, 28, 30, 31, 33, 34, 36, 37, 38, 39, 41, 42, 44, 46, 47,
    49, 51, 53, 54, 56, 58, 60, 62, 64, 66, 68, 70, 72, 74, 76, 79, 82,
    85, 88, 91, 94, 98, 102, 106, 110, 115, 120, 125, 130, 135, 141, 147,
    153, 159, 165, 171, 178, 185, 193, 202, 211, 232, 243, 254, 255 );

  pitchenv_tab : array[0..99] of shortint = (
    -128, -116, -104, -95, -85, -76, -68, -61, -56, -52, -49, -46, -43,
    -41, -39, -37, -35, -33, -32, -31, -30, -29, -28, -27, -26, -25, -24,
    -23, -22, -21, -20, -19, -18, -17, -16, -15, -14, -13, -12, -11, -10,
    -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
    11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27,
    28, 29, 30, 31, 32, 33, 34, 35, 38, 40, 43, 46, 49, 53, 58, 65, 73,
    82, 92, 103, 115, 127 );

implementation


{ PitchEnv }

constructor TPitchEnv.Create(sample_rate: Double);
begin
  unit_ := trunc(N * (1 shl 24) / (21.3 * sample_rate) + 0.5);
end;

procedure TPitchEnv.SetValues(const aRates, aLevels: TEnvArray);
var
  i: integer;
begin
  for i := 0 to high(FRates) do
  begin
    FRates[i]  := aRates[i];
    FLevels[i] := aLevels[i];
  end;
  FLevel := pitchenv_tab[aLevels[3]] shl 19;
  FIsDown  := true;
  Advance(0);
end;

function TPitchEnv.getSample: integer;
begin
  if (FIndex < 3) or (((FIndex < 4) and (not FIsDown))) then
  begin
    if FIsRising then
    begin
      FLevel := FLevel + FInc;
      if FLevel >= FTargetLevel then
      begin
        FLevel := FTargetLevel;
        Advance(FIndex + 1);
      end;
    end
    else
    begin // !rising
      FLevel := FLevel - FInc;
      if FLevel <= FTargetLevel then
      begin
        FLevel := FTargetLevel;
        Advance(FIndex + 1);
      end;
    end;
  end;
  Result := FLevel;
end;

procedure TPitchEnv.KeyDown(aIsDown: Boolean);
begin
  if FIsDown <> aIsDown then
  begin
    FIsDown := aIsDown;
    if aIsDown then
      Advance(0)
    else
      Advance(3)
  end;
end;

procedure TPitchEnv.Advance(aNewIndex: integer);
var
  newlevel: integer;
begin
  FIndex := aNewIndex;
  if FIndex < 4 then
  begin
    newlevel     := FLevels[FIndex];
    FTargetLevel := pitchenv_tab[newlevel] shl 19;
    FIsRising      := (FTargetLevel > FLevel);
    FInc         := pitchenv_rate[FRates[FIndex]] * unit_;
  end;
end;

procedure TPitchEnv.getPosition(var aStep : byte);
begin
  aStep := FIndex;
end;





end.
