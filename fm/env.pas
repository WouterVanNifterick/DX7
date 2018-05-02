unit Env;

interface

uses math;

{$POINTERMATH ON}

const
  LG_N = 6;
  N    = 1 shl LG_N;

type
  TEnvArray = packed array [0 .. 3] of byte;

  TEnv = record
  const
    jumptarget = 1716;
    class var sr_multiplier: integer;

  var
    rates_       : TEnvArray;
    levels_      : TEnvArray;

    outlevel_    : integer;
    rate_scaling_: integer;
    level_       : integer;
    targetlevel_ : integer;

    rising_      : Boolean;
    ix_          : integer;
    inc_         : integer;
    down_        : Boolean;
  public
    class procedure init_sr(sampleRate: Double); static;
    procedure init(const r, l: TEnvArray; ol, rate_scaling: integer);
    function getsample: integer;
    procedure keydown(d: Boolean);
    class function scaleoutlevel(outlevel: integer): integer; static;
    procedure advance(newix: integer);
    procedure update(const r, l: TEnvArray; ol, rate_scaling: integer);
    procedure getPosition(var step: byte);
    procedure transfer(src: TEnv);
  end;

const
  levellut: array [0 .. 19] of integer = (0, 5, 9, 13, 17, 20, 23, 25, 27, 29, 31, 33, 35, 37, 39, 41, 42, 43, 45, 46);

implementation

{ Env }

class procedure TEnv.init_sr(sampleRate: Double);
begin
  sr_multiplier := round((44100.0 / sampleRate) * (1 shl 24));
end;

procedure TEnv.init(const r, l: TEnvArray; ol, rate_scaling: integer);
var
  i: integer;
begin
  for i := 0 to 3 do
  begin
    rates_[i]  := r[i];
    levels_[i] := l[i];
  end;
  outlevel_     := ol;
  rate_scaling_ := rate_scaling;
  level_        := 0;
  down_         := true;
  advance(0);
end;

function TEnv.getsample: integer;
begin
  if (ix_ < 3) or (((ix_ < 4) and (not down_))) then
  begin
    if rising_ then
    begin
      if level_ < (jumptarget shl 16) then
        level_ := jumptarget shl 16;

      level_ := level_ + ((((17 shl 24) - level_) shr 24) * inc_);
      // TODO: should probably be more accurate when inc is large
      if level_ >= targetlevel_ then
      begin
        level_ := targetlevel_;
        advance(ix_ + 1);
      end;
    end
    else
    begin // !rising
      level_ := level_ - inc_;
      if level_ <= targetlevel_ then
      begin
        level_ := targetlevel_;
        advance(ix_ + 1);
      end;
    end;
  end;
  // TODO: this would be a good place to set level to 0 when under threshold
  Result := level_;
end;

procedure TEnv.keydown(d: Boolean);
begin
  if down_ <> d then
  begin
    down_ := d;
    advance(ifthen(d, 0, 3));
  end;
end;

class function TEnv.scaleoutlevel(outlevel: integer): integer;
begin
  if outlevel >= 20 then
    Result := 28 + outlevel
  else
    Result := levellut[outlevel];
end;

procedure TEnv.advance(newix: integer);
var
  newlevel, actuallevel, qrate: integer;
begin
  ix_ := newix;
  if ix_ < 4 then
  begin
    newlevel    := levels_[ix_];
    actuallevel := scaleoutlevel(newlevel) shr 1;
    actuallevel := (actuallevel shl 6) + outlevel_ - 4256;
    if actuallevel < 16 then
      actuallevel := 16
    else
      actuallevel := actuallevel;
    // level here is same as Java impl
    targetlevel_ := actuallevel shl 16;
    rising_      := (targetlevel_ > level_);
    // rate
    qrate := (rates_[ix_] * 41) shr 6;
    qrate := qrate + rate_scaling_;
    qrate := min(qrate, 63);
    inc_  := (4 + (qrate and 3)) shl (2 + LG_N + (qrate shr 2));
    // meh, this should be fixed elsewhere
    inc_ := (inc_ * sr_multiplier) shr 24;
  end;
end;

procedure TEnv.update(const r, l: TEnvArray; ol, rate_scaling: integer);
var
  i, newlevel, actuallevel: integer;
begin
  for i := 0 to 3 do
  begin
    rates_[i]  := r[i];
    levels_[i] := l[i];
  end;
  outlevel_     := ol;
  rate_scaling_ := rate_scaling;
  if down_ then
  begin
    // for now we simply reset ourselve at level 3
    newlevel    := levels_[2];
    actuallevel := scaleoutlevel(newlevel) shr 1;
    actuallevel := (actuallevel shl 6) - 4256;
    if actuallevel < 16 then
      actuallevel := 16;

    targetlevel_ := actuallevel shl 16;
    advance(2);
  end;
end;

procedure TEnv.getPosition(var step: byte);
begin
  step := ix_;
end;

procedure TEnv.transfer(src: TEnv);
var
  i: integer;
begin
  for i := 0 to 3 do
  begin
    rates_[i]  := src.rates_[i];
    levels_[i] := src.levels_[i];
  end;
  outlevel_     := src.outlevel_;
  rate_scaling_ := src.rate_scaling_;
  level_        := src.level_;
  targetlevel_  := src.targetlevel_;
  rising_       := src.rising_;
  ix_           := src.ix_;
  inc_          := src.inc_;
  down_         := src.down_;
end;

end.
