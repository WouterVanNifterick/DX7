unit fm_op_kernel;

interface

uses math, sin;

const
  LG_N = 6;
  N    = (1 shl LG_N);

type
  TFeedbackBuffer = array [0 .. 1] of integer;

  TFmOpKernel = record
    /// <summary>
    /// This is the basic FM operator. No feedback.
    /// </summary>
    class procedure compute(output, input: Pinteger; phase0, freq, gain1, gain2: integer; add: Boolean); static;
    /// <summary>
    /// This is a sine generator, no feedback.
    /// </summary>
    class procedure compute_pure(output: Pinteger; phase0, freq, gain1, gain2: integer; add: Boolean); static;
    /// <summary>
    /// One op with feedback, no add.
    /// </summary>
    class procedure compute_fb(output: Pinteger; phase0, freq, gain1, gain2: integer; var fb_buf: TFeedbackBuffer; fb_shift: integer; add: Boolean); static;
  end;

type
  TFmOpParams = record
    level_in, gain_out, freq, phase: integer;
  end;

  TParamList = array [0 .. 5] of TFmOpParams;

implementation

{$POINTERMATH ON}
{ FmOpKernel }

class procedure TFmOpKernel.compute(output, input: Pinteger; phase0, freq, gain1, gain2: integer; add: Boolean);
var
  dgain, gain:Int64;
  phase, i, y, y1: integer;
begin
  dgain := (gain2 - gain1 + (N shr 1)) shr LG_N;
  gain  := gain1;
  phase := phase0;
  if add then
  begin
    for i := 0 to N - 1 do
    begin
      gain      := gain + dgain;
      y         := TSin.lookup(phase + input[i]);
      y1        := (y * gain) shr 24;
      output[i] := output[i] + y1;
      phase     := phase + freq;
    end;
  end
  else
  begin
    for i := 0 to N - 1 do
    begin
      gain      := gain + dgain;
      y         := TSin.lookup(phase + input[i]);
      y1        := (y * gain) shr 24;
      output[i] := y1;
      phase     := phase + freq;
    end;
  end;
end;

class procedure TFmOpKernel.compute_pure(output: Pinteger; phase0, freq, gain1, gain2: integer; add: Boolean);
var
  dgain, gain:int64;
  phase, i, y, y1: integer;
begin
  dgain := (gain2 - gain1 + (N shr 1)) shr LG_N;
  gain  := gain1;
  phase := phase0;
  if add then
  begin
    for i := 0 to N - 1 do
    begin
      gain      := gain + dgain;
      y         := TSin.lookup(phase);
      y1        := (y * gain) shr 24;
      output[i] := output[i] + y1;
      phase     := phase + freq;
    end;
  end
  else
  begin
    for i := 0 to N - 1 do
    begin
      gain      := gain + dgain;
      y         := TSin.lookup(phase);
      y1        := (y * gain) shr 24;
      output[i] := y1;
      phase     := phase + freq;
    end;
  end;
end;

class procedure TFmOpKernel.compute_fb(output: Pinteger; phase0, freq, gain1, gain2: integer; var fb_buf: TFeedbackBuffer; fb_shift: integer; add: Boolean);
var
  dgain, gain : int64;
  phase, y0, y, i, scaled_fb: integer;
begin
  dgain := (gain2 - gain1 + (N shr 1)) shr LG_N;
  gain  := gain1;
  phase := phase0;
  y0    := fb_buf[0];
  y     := fb_buf[1];
  if add then
  begin
    for i := 0 to N - 1 do
    begin
      gain      := gain + dgain;
      scaled_fb := (y0 + y) shr (fb_shift + 1);
      y0        := y;
      y         := TSin.lookup(phase + scaled_fb);
      y         := (y * gain) shr 24;
      output[i] := output[i] + y;
      phase     := phase + freq;
    end;
  end
  else
  begin
    for i := 0 to N - 1 do
    begin
      gain      := gain + dgain;
      scaled_fb := (y0 + y) shr (fb_shift + 1);
      y0        := y;
      y         := TSin.lookup(phase + scaled_fb);
      y         := (y * gain) shr 24;
      output[i] := y;
      phase     := phase + freq;
    end;
  end;
  fb_buf[0] := y0;
  fb_buf[1] := y;
end;

end.
