unit EngineMkI;

interface

uses fm_op_kernel, controllers, fm_core, sin, exp2;

  function sinLog( phi : uint16):uint16;inline;
  function mkiSin( phase : integer; env : uint16):integer;inline;

{$POINTERMATH ON}
type
TEngineMkI = class(TFmCore)
  procedure compute(output, input : pinteger; phase0, freq, gain1, gain2 : integer; add : Boolean);
  procedure compute_pure(output : pinteger; phase0, freq, gain1, gain2 : integer; add : Boolean);
  procedure compute_fb(output : pinteger; phase0, freq, gain1, gain2 : integer; fb_buf : pinteger; fb_shift : integer; add : Boolean);
  /// <summary>
  ///   exclusively used for ALGO 6 with feedback
  /// </summary>
  procedure compute_fb2(output : pinteger; parms : TParamList; gain01, gain02 : integer;fb_buf : pinteger; fb_shift : integer);
  /// <summary>
  ///   exclusively used for ALGO 4 with feedback
  /// </summary>
  procedure compute_fb3(output : pinteger; parms : TParamList; gain01, gain02 : integer;fb_buf : pinteger; fb_shift : integer);
  procedure render(output : pinteger; params : TParamList;algorithm : integer; fb_buf : pinteger; feedback_shift : integer);
end;

const
  NEGATIVE_BIT      = $8000;
  ENV_BITDEPTH      = 14;
  SINLOG_BITDEPTH   = 10;
  SINLOG_TABLESIZE  = 1 shl SINLOG_BITDEPTH;
  SINEXP_BITDEPTH   = 10;
  SINEXP_TABLESIZE  = 1 shl SINEXP_BITDEPTH;
  ENV_MAX           = 1 shl ENV_BITDEPTH;
  kLevelThresh      = ENV_MAX-100;
var
  sinLogTable      : array[0..(SINLOG_TABLESIZE)-1] of uint16;
  sinExpTable      : array[0..(SINEXP_TABLESIZE)-1] of uint16;

const
  has_contents : array[0..2] of Boolean = (true, false, false);

implementation

uses System.Math, System.SysUtils, Generics.Collections;

function sinLog(phi: uint16): uint16; inline;
var
  SINLOG_TABLEFILTER, index: uint16;
begin
  SINLOG_TABLEFILTER := SINLOG_TABLESIZE - 1;
  index              := (phi and SINLOG_TABLEFILTER);
  case (phi and (SINLOG_TABLESIZE * 3)) of
                      0 : Exit(sinLogTable[index                       ]);
    SINLOG_TABLESIZE    : Exit(sinLogTable[index xor SINLOG_TABLEFILTER]);
    SINLOG_TABLESIZE * 2: Exit(sinLogTable[index                       ] or NEGATIVE_BIT)
  else                    Exit(sinLogTable[index xor SINLOG_TABLEFILTER] or NEGATIVE_BIT);
  end;
end;

function mkiSin( phase : integer; env : uint16):integer;inline;
var
  expVal        : uint16;
  isSigned      : Boolean;
  SINEXP_FILTER : uint16;
begin
    expVal := sinLog(phase  shr  (22 - SINLOG_BITDEPTH)) + (env);
    //int16_t expValShow = expVal;
    isSigned := (expVal and NEGATIVE_BIT)<>0;
    expVal  := (expVal and (not NEGATIVE_BIT));
    SINEXP_FILTER := $3FF;
    result := 4096 + sinExpTable[( expVal and SINEXP_FILTER )  xor  SINEXP_FILTER];
    //uint16_t resultB4 = result;
    result := result shr ( expVal  shr  10 ); // exp
    if isSigned  then
      Result := (-result - 1)  shl  13
    else
      Result := result  shl  13;
end;



{ EngineMkI }

procedure TEngineMkI.compute(output, input : pinteger; phase0, freq, gain1, gain2 : integer; add : Boolean);
var
  dgain, gain, phase, i, y : integer;
  Adder:PInteger;
begin
    dgain := (gain2 - gain1 + (N  shr  1))  shr  LG_N;
    gain  := gain1;
    phase := phase0;
    if add then adder := output else adder := @zeros[0];

    for i := 0 to N-1 do begin
        gain  := gain + dgain;
        y := mkiSin((phase+input[i]), gain);
        output[i] := y + adder[i];
        phase  := phase + freq;
    end;
end;


procedure TEngineMkI.compute_pure(output: pinteger; phase0, freq, gain1, gain2: integer; add: Boolean);
var
  dgain, gain, phase, i, y: integer;
  Adder : pinteger;
begin
  dgain := (gain2 - gain1 + (N shr 1)) shr LG_N;
  gain  := gain1;
  phase := phase0;
  if add then
    Adder := output
  else
    Adder := @zeros[0];

  for i := 0 to N - 1 do
  begin
    gain      := gain + dgain;
    y         := mkiSin(phase, gain);
    output[i] := y + Adder[i];
    phase     := phase + freq;
  end;
end;


procedure TEngineMkI.compute_fb(output : pinteger; phase0, freq, gain1, gain2 : integer;fb_buf : pinteger; fb_shift : integer; add : Boolean);
var
  dgain,
  gain,
  phase,
  y0,
  y,
  i,
  scaled_fb : integer;
  Adder:PInteger;
begin
  dgain := (gain2 - gain1 + (N shr 1)) shr LG_N;
  gain  := gain1;
  phase := phase0;
  if add then Adder := output
         else Adder := @zeros[0];

  y0      := fb_buf[0];
  y       := fb_buf[1];

  for i   := 0 to N - 1 do
  begin
    gain      := gain + dgain;
    scaled_fb := (y0 + y) shr (fb_shift + 1);
    y0        := y;
    y         := mkiSin((phase + scaled_fb), gain);
    output[i] := y + Adder[i];
    phase     := phase + freq;
  end;
  fb_buf[0] := y0;
  fb_buf[1] := y;
end;


/// <summary>
///   exclusively used for ALGO 6 with feedback
/// </summary>
procedure TEngineMkI.compute_fb2(output : pinteger; parms : TParamList; gain01, gain02 : integer;fb_buf : pinteger; fb_shift : integer);
var
  dgain,
  gain,
  phase     : array[0..1] of integer;
  y0,
  y,
  i,
  scaled_fb : integer;
begin
    y0                := fb_buf[0];
    y                 := fb_buf[1];
    phase[0]          := parms[0].phase;
    phase[1]          := parms[1].phase;
    parms[1].gain_out := (ENV_MAX-(parms[1].level_in  shr  (28-ENV_BITDEPTH)));
    gain[0]           := gain01;
    gain[1]           := ifthen(parms[1].gain_out = 0 , (ENV_MAX-1) , parms[1].gain_out);
    dgain[0]          := (gain02 - gain01 + (N  shr  1))  shr  LG_N;
    dgain[1]          := parms[1].gain_out - ifthen(parms[1].gain_out = 0 , ENV_MAX-1 , parms[1].gain_out);
    for i := 0 to N-1 do begin
        scaled_fb := (y0 + y)  shr  (fb_shift + 1);
        // op 0
        gain[0]  := gain[0] + (dgain[0]);
        y0 := y;
        y := mkiSin(phase[0]+scaled_fb, gain[0]);
        phase[0]  := phase[0] + (parms[0].freq);
        // op 1
        gain[1]  := gain[1] + (dgain[1]);
        y := mkiSin(phase[1]+y, gain[1]);
        phase[1]  := phase[1] + (parms[1].freq);
        output[i] := y;
    end;
    fb_buf[0] := y0;
    fb_buf[1] := y;
end;


/// <summary>
///   exclusively used for ALGO 4 with feedback
/// </summary>
procedure TEngineMkI.compute_fb3(output : pinteger; parms : TParamList; gain01, gain02 : integer;fb_buf : pinteger; fb_shift : integer);
var
  dgain,
  gain,
  phase     : array[0..2] of integer;
  y0,
  y,
  i,
  scaled_fb : integer;
begin
    y0                := fb_buf[0];
    y                 := fb_buf[1];
    phase[0]          := parms[0].phase;
    phase[1]          := parms[1].phase;
    phase[2]          := parms[2].phase;
    parms[1].gain_out := (ENV_MAX-(parms[1].level_in  shr  (28-ENV_BITDEPTH)));
    parms[2].gain_out := (ENV_MAX-(parms[2].level_in  shr  (28-ENV_BITDEPTH)));
    gain[0]           := gain01;
    gain[1]           := IfThen(parms[1].gain_out = 0 , ENV_MAX-1 , parms[1].gain_out);
    gain[2]           := IfThen(parms[2].gain_out = 0 , ENV_MAX-1 , parms[2].gain_out);
    dgain[0]          := (gain02 - gain01 + (N  shr  1))  shr  LG_N;
    dgain[1]          := parms[1].gain_out - ifthen(parms[1].gain_out = 0 , ENV_MAX-1 , parms[1].gain_out);
    dgain[2]          := parms[2].gain_out - ifthen(parms[2].gain_out = 0 , ENV_MAX-1 , parms[2].gain_out);
    for i := 0 to N-1 do begin
        scaled_fb := (y0 + y)  shr  (fb_shift + 1);
        // op 0
        gain[0]  := gain[0] + (dgain[0]);
        y0 := y;
        y := mkiSin(phase[0]+scaled_fb, gain[0]);
        phase[0]  := phase[0] + (parms[0].freq);
        // op 1
        gain[1]  := gain[1] + (dgain[1]);
        y := mkiSin(phase[1]+y, gain[1]);
        phase[1]  := phase[1] + (parms[1].freq);
        // op 2
        gain[2]  := gain[2] + (dgain[2]);
        y := mkiSin(phase[2]+y, gain[2]);
        phase[2]  := phase[2] + (parms[2].freq);
        output[i] := y;
    end;
    fb_buf[0] := y0;
    fb_buf[1] := y;
end;


procedure TEngineMkI.render(output : pinteger; params : TParamList;algorithm : integer;fb_buf : pinteger; feedback_shift : integer);
var
  alg    : ^TFmAlgorithm;
  param  : ^TFmOpParams;
  fb_on  : Boolean;
  op,
  flags  : integer;
  add    : Boolean;
  inbus,
  outbus,
  gain1,
  gain2  : integer;
  outptr : pinteger;
  has_contents:array[0..2] of Boolean;
begin
    alg := @algorithms[algorithm];

    fb_on := feedback_shift < 16;
    case algorithm of
      3, 5: if fb_on  then
              alg.ops[0] := $c4
    end;

    op := 0;
    has_contents[0] := true;
    has_contents[1] := false;
    has_contents[2] := false;


    while op < 6 do
    begin
        flags := alg.ops[op];
        add := (flags and TFmOperatorFlags.OUT_BUS_ADD) <> 0;
        param := @params[op];
        inbus := (flags  shr  4) and 3;
        outbus := flags and 3;

        if outbus = 0 then
          outptr := output
        else
          outptr := @buf_[outbus - 1];

        gain1 := ifthen(param.gain_out = 0 , ENV_MAX-1, param.gain_out);
        gain2 := ENV_MAX-(param.level_in  shr  (28-ENV_BITDEPTH));
        param.gain_out := gain2;
        if (gain1 <= kLevelThresh) or (gain2 <= kLevelThresh) then
        begin
            if not has_contents[outbus] then
            begin
              add := false;
            end;

            if (inbus = 0) or (not has_contents[inbus]) then
            begin
                // PG: this is my 'dirty' implementation of FB for 2 and 3 operators...
                if ((flags and $c0) = $c0) and fb_on then
                begin
                    case algorithm of
                      3   :
                        begin
                          // three operator feedback, process exception for ALGO 4
                          compute_fb3(outptr, params, gain1, gain2, fb_buf, min((feedback_shift+2), 16));
                          params[1].phase  := params[1].phase + (params[1].freq  shl  LG_N);
                          params[2].phase  := params[2].phase + (params[2].freq  shl  LG_N);
                          Inc(op,2);  // ignore the 2 other operators
                        end;
                      5   :
                        begin
                          // two operator feedback, process exception for ALGO 6
                          compute_fb2(outptr, params, gain1, gain2, fb_buf, min((feedback_shift+2), 16));
                          params[1].phase  := params[1].phase + (params[1].freq  shl  LG_N);
                          Inc(op); // ignore next operator
                        end
                    else
                        begin
                          // one operator feedback, normal proces
                          compute_fb(outptr, param.phase, param.freq, gain1, gain2, fb_buf, feedback_shift, add)
                        end;
                    end; // case
                end
                else
                begin
                  compute_pure(outptr, param.phase, param.freq, gain1, gain2, add);
                end;
            end
            else
            begin
                compute(outptr, @buf_[inbus - 1], param.phase, param.freq, gain1, gain2, add);
            end;
            has_contents[outbus] := true;
        end
        else
          if ( not add) then
            has_contents[outbus] := false;

        param.phase  := param.phase + (param.freq  shl  LG_N);
    end;
end;




end.
