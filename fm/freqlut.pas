unit Freqlut;

interface

uses math;

const
  LG_N_SAMPLES    = 10;
  N_SAMPLES       = 1 shl LG_N_SAMPLES;
  SAMPLE_SHIFT    = 24 - LG_N_SAMPLES;
  MAX_LOGFREQ_INT = 20;

type
  TFreqlut = record
  class var
    lut: array [0 .. (N_SAMPLES + 1) - 1] of integer;
    class procedure init(sample_rate: Double); static;
    /// <summary>
    /// Note: if logfreq is more than 20.0, the results will be inaccurate. However,
    /// that will be many times the Nyquist rate.
    /// </summary>
    class function lookup(logfreq: integer): integer; static;
  end;

implementation

{ Freqlut }

class procedure TFreqlut.init(sample_rate: Double);
var
  y, inc: Double;
  i     : integer;
begin
  y     := (1 shl (24 + MAX_LOGFREQ_INT)) / sample_rate;
  inc   := power(2, 1.0 / N_SAMPLES);
  for i := 0 to N_SAMPLES + 1 - 1 do
  begin
    lut[i] := floor(y + 0.5);
    y      := y * inc;
  end;
end;

/// <summary>
/// Note: if logfreq is more than 20.0, the results will be inaccurate. However,
/// that will be many times the Nyquist rate.
/// </summary>
class function TFreqlut.lookup(logfreq: integer): integer;
var
  ix, y0, y1, lowbits, y, hibits: integer;
begin
  ix      := (logfreq and $FFFFFF) shr SAMPLE_SHIFT;
  y0      := lut[ix];
  y1      := lut[ix + 1];
  lowbits := logfreq and ((1 shl SAMPLE_SHIFT) - 1);
  y       := y0 + ((((y1 - y0) * lowbits)) shr SAMPLE_SHIFT);
  hibits  := logfreq shr 24;
  Result  := y shr (MAX_LOGFREQ_INT - hibits);
end;

end.
