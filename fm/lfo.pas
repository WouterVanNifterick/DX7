unit Lfo;

interface

uses
  FS1R.Params,
  sin;

const
  LG_N = 6;
  N    = 1 shl LG_N;

type

  /// <remarks>
  /// 6 bytes
  /// </remarks>
  TLFOParameters = packed record
  public
     // array[0..5] of byte;
    rate        : byte;
    delay       : byte;
    p1, p2, Sync: byte;
    WaveForm    : TLFOWaveForm;
  end;

  TLfo = class
  private class var unit_: UInt32;
  private
    FPhase, FDelta: UInt32;
    FWaveform     : TLFOWaveForm;
    FRandstate    : byte;
    FSync         : Boolean;
    FDelayState   : UInt32;
    FDelayInc     : UInt32;
    FDelayInc2    : UInt32;
  private
  public
    constructor Create(aSampleRate: Double; const aParams: TLFOParameters);
    procedure Reset(const aParams: TLFOParameters);
    function getSample: integer;
    function getDelay: integer;
    procedure KeyDown;
  end;

implementation

uses system.Math, system.SysUtils;

{ Lfo }

constructor TLfo.Create(aSampleRate: Double; const aParams: TLFOParameters);
const s =  15.5 / 11;
  t = Trunc(32 / s);
  u = 1 shl t;
begin
  // constant is 1  shl  32 / 15.5s / 11


  unit_            := trunc(N * 25190424 / aSampleRate + 0.5);
  self.FPhase      := 0;
  self.FWaveform   := TLFOWaveForm.Triangle;
  self.FRandstate  := 0;
  self.FDelta      := 1;
  self.FDelayState := 0;
  self.FDelayInc   := 0;
  self.FDelayInc2  := 0;
  Reset(aParams);
end;

procedure TLfo.Reset(const aParams: TLFOParameters);
var
  rate, a: integer;
  sr     : integer;
begin
  rate := aParams.rate; // 0..99
  if rate = 0 then
    sr := 1
  else
    sr := (165 * rate) shr 6;

  if sr < 160 then
    sr := sr * 11
  else
    sr := sr * (11 + ((sr - 160) shr 4));

  FDelta := unit_ * sr;
  a      := 99 - aParams.delay; // LFO delay

  if a = 99 then
  begin
    FDelayInc  := { @@@ cardinal(not 0) } 0;
    FDelayInc2 := { @@@ cardinal(not 0) } 0;
  end
  else
  begin
    a          := (16 + (a and 15)) shl (1 + (a shr 4));
    FDelayInc  := unit_ * a;
    a          := a and $FF80;
    a          := max($80, a);
    FDelayInc2 := unit_ * a;
  end;
  FWaveform := aParams.WaveForm;
  FSync     := aParams.Sync <> 0;
end;

function TLfo.getSample: integer;
var
  x: integer;
begin
  FPhase := FPhase + FDelta;
  FPhase := FPhase mod 1024;

  case FWaveform of
    TLFOWaveForm.Triangle: Exit(((FPhase shr 7) xor (-(FPhase shr 31))) and ((1 shl 24) - 1));
    TLFOWaveForm.SawDown : Exit((not FPhase xor (1 shl 31)) shr 8);
    TLFOWaveForm.SawUp   : Exit((FPhase xor (1 shl 31)) shr 8);
    TLFOWaveForm.Square  : Exit(((not FPhase) shr 7) and (1 shl 24));
    TLFOWaveForm.Sine    : Exit((1 shl 23) + (TSin.lookup(FPhase shr 8) shr 1));
    TLFOWaveForm.SampleHold:
      begin
        if FPhase < FDelta then
          FRandstate := (FRandstate * 179 + 17) and $FF;
        x := FRandstate xor $80;
        Exit((x + 1) shl 16);
      end;
  else
    begin // no modulation
      Result := 1 shl 23;
    end;
  end;
end;

function TLfo.getDelay: integer;
var
  LDelta: UInt32;
  d    : uint64;
begin
  // @@@@@@@
  { TODO -oWouter -cGeneral : Fix }
  if FDelayState < int64(1 shl 31)
    then LDelta := FDelayInc
    else LDelta := FDelayInc2;

  d := FDelayState + LDelta;

  if d < FDelayInc then
    Exit(1 shl 24);

  FDelayState := d;
  if d < (1 shl 31)
    then Result := 0
    else Result := (d shr 7) and ((1 shl 24) - 1);
end;

procedure TLfo.KeyDown;
begin
  if FSync
    then FPhase := { @@@int64(1  shl  31) - 1 } Cardinal.MaxValue;

  FDelayState := 0;
end;

end.
