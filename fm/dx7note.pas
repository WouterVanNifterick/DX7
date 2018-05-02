unit Dx7Note;

interface

uses env, pitchenv, fm_core, math, freqlut, exp2, controllers, fm_op_kernel, patch,
  system.SysUtils;

  function midinote_to_logfreq( midinote : integer):integer;
  function osc_freq( midinote, mode, coarse, fine, detune : integer):integer;
  /// <summary>
  ///   See "velocity" section of notes. Returns velocity delta in microsteps.
  /// </summary>
  function ScaleVelocity( velocity, sensitivity : integer):integer;
  function ScaleRate( midinote, sensitivity : integer):integer;
  function ScaleCurve( group, depth, curve : integer):integer;
  function ScaleLevel( midinote, break_pt, left_depth, right_depth, left_curve, right_curve : integer):integer;

type
TVoiceStatus = record
var
  amp       : array[0..5] of uint32;
  ampStep   : array[0..5] of byte;
  pitchStep : byte;
end;

TDx7Note = class
  env_              : array[0..5] of TEnv;
  params_           : TParamList;
  pitchenv_         : TPitchEnv;
  basepitch_        : array[0..5] of integer;
  fb_buf_           : TFeedbackBuffer;
  fb_shift_         : integer;
  ampmodsens_       : array[0..5] of integer;
  ampmoddepth_,
  algorithm_,
  pitchmoddepth_,
  pitchmodsens_,
  op                : integer;
  constructor Create(const dx7patch : TPatchData; midinote, velocity : integer);
  procedure compute(buf : pinteger; lfo_val, lfo_delay : integer;ctrls : TControllers);
  procedure keyup;
  procedure update_dx7(const dx7patch : TPatchData; midinote, velocity : integer);
  procedure peekVoiceStatus(var status : TVoiceStatus);
  procedure transferState( src : TDx7Note);
  procedure transferSignal( src : TDx7Note);
  procedure oscSync;
end;

type
  VoiceStatus = record
    amp       : array[0..5] of uint32;
    ampStep   : array[0..5] of byte;
    pitchStep : byte;
  end;

const
  FEEDBACK_BITDEPTH = 8;
  OP_COUNT_OP4      = 4;
  OP_COUNT_DX7      = 6;
  OP_COUNT_FS1R     = 8;
  OP_COUNT          = OP_COUNT_DX7;

  coarsemul : array[0..31] of integer = (
    -16777216, 0, 16777216, 26591258, 33554432, 38955489, 43368474,
    47099600, 50331648, 53182516, 55732705, 58039632, 60145690, 62083076,
    63876816, 65546747, 67108864, 68576247, 69959732, 71268397, 72509921,
    73690858, 74816848, 75892776, 76922906, 77910978, 78860292, 79773775,
    80654032, 81503396, 82323963, 83117622 );

  velocity_data : array[0..63] of byte = (
    0, 70, 86, 97, 106, 114, 121, 126, 132, 138, 142, 148, 152, 156, 160,
    163, 166, 170, 173, 174, 178, 181, 184, 186, 189, 190, 194, 196, 198,
    200, 202, 205, 206, 209, 211, 214, 216, 218, 220, 222, 224, 225, 227,
    229, 230, 232, 233, 235, 237, 238, 240, 241, 242, 243, 244, 246, 246,
    248, 249, 250, 251, 252, 253, 254 );

  exp_scale_data : array[0..32] of byte = (
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 14, 16, 19, 23, 27, 33, 39, 47, 56,
    66, 80, 94, 110, 126, 142, 158, 174, 190, 206, 222, 238, 250 );

  pitchmodsenstab : array[0..7] of byte = (
    0, 10, 20, 33, 55, 92, 153, 255 );

  ampmodsenstab : array[0..3] of uint32 = (
    0, 4342338, 7171437, 16777216 );

implementation

function midinote_to_logfreq(midinote: integer): integer;
const
  base = 50857777; // (1 << 24) * (log(440) / log(2) - 69/12)
  step = (1 shl 24) div 12;
begin
  Result := base + step * midinote;
end;


function osc_freq(midinote, mode, coarse, fine, detune: integer): integer;
var
  logfreq: integer;
begin
  // TODO: pitch randomization
  if mode = 0 then
  begin
    logfreq := midinote_to_logfreq(midinote);
    logfreq := logfreq + (coarsemul[coarse and 31]);
    if fine <> 0 then
    begin
      // (1  shl  24) / log(2)
      logfreq := logfreq + (floor(24204406.323123 * ln(1 + 0.01 * fine) + 0.5));
    end;
    // This was measured at 7.213Hz per count at 9600Hz, but the exact
    // value is somewhat dependent on midinote. Close enough for now.
    logfreq := logfreq + (12606 * (detune - 7));
  end
  else
  begin
    // ((1  shl  24) * log(10) / log(2) * .01)  shl  3
    logfreq := (4458616 * ((coarse and 3) * 100 + fine)) shr 3;
    logfreq := logfreq + (ifthen(detune > 7, 13457 * (detune - 7), 0));
  end;
  Result := logfreq;
end;


/// <summary>
///   See "velocity" section of notes. Returns velocity delta in microsteps.
/// </summary>
function ScaleVelocity(velocity, sensitivity: integer): integer;
var
  clamped_vel, vel_value, scaled_vel: integer;
begin
  clamped_vel := max(0, min(127, velocity));
  vel_value   := velocity_data[clamped_vel shr 1] - 239;
  scaled_vel  := ((sensitivity * vel_value + 7) shr 3) shl 4;
  Result      := scaled_vel;
end;


function ScaleRate(midinote, sensitivity: integer): integer;
var
  x, qratedelta: integer;
{$IFDEF SUPER_PRECISE}
  rem: integer;
{$ENDIF}
begin
  x          := min(31, max(0, midinote div 3 - 7));
  qratedelta := (sensitivity * x) shr 3;
{$IFDEF SUPER_PRECISE}
  rem := x and 7;
  if sensitivity = 3 and rem = 3 then
    qratedelta := qratedelta - 1
  else if (sensitivity = 7 and rem > 0 and rem < 4) then
    qratedelta := qratedelta + 1;
{$ENDIF}
  Result := qratedelta;
end;


function ScaleCurve(group, depth, curve: integer): integer;
var
  scale, n_scale_data, raw_exp: integer;
begin
  if (curve = 0) or (curve = 3) then
  begin
    // linear
    scale := (group * depth * 329) shr 12;
  end
  else
  begin
    // exponential
    n_scale_data := sizeof(exp_scale_data);
    raw_exp      := exp_scale_data[min(group, n_scale_data - 1)];
    scale        := (raw_exp * depth * 329) shr 15;
  end;
  if curve < 2 then
  begin
    scale := -scale;
  end;
  Result := scale;
end;


function ScaleLevel(midinote, break_pt, left_depth, right_depth, left_curve, right_curve: integer): integer;
var
  offset: integer;
begin
  offset := midinote - break_pt - 17;
  if offset >= 0 then
  begin
    Exit(ScaleCurve((offset + 1) div 3, right_depth, right_curve));
  end
  else
  begin
    Exit(ScaleCurve(-(offset - 1) div 3, left_depth, left_curve));
  end;
end;



{ Dx7Note }

constructor TDx7Note.Create(const dx7patch : TPatchData; midinote, velocity : integer);
var
  rates,
  levels  : TEnvArray;
  op,
  off,
  i,
  outlevel,
  level_scaling,
  rate_scaling,
  mode,
  coarse,
  fine,
  detune,
  freq,
  feedback     : integer;
begin
    for op := 0 to OP_COUNT_DX7-1 do begin
        off := op * 21;
        for i := 0 to 3 do begin
            rates[i] := dx7patch[off + i];
            levels[i] := dx7patch[off + 4 + i];
        end;
        outlevel := dx7patch[off + 16];
        outlevel := TEnv.scaleoutlevel(outlevel);
        level_scaling := ScaleLevel(
                            midinote,
                            dx7patch[off + 8],
                            dx7patch[off + 9],
                            dx7patch[off + 10],
                            dx7patch[off + 11],
                            dx7patch[off + 12]);
        outlevel  := outlevel + level_scaling;
        outlevel := min(127, outlevel);
        outlevel := outlevel  shl  5;
        outlevel  := outlevel + (ScaleVelocity(velocity, dx7patch[off + 15]));
        outlevel := max(0, outlevel);
        rate_scaling := ScaleRate(midinote, dx7patch[off + 13]);
        env_[op].init(rates, levels, outlevel, rate_scaling);
        mode := dx7patch[off + 17];
        coarse := dx7patch[off + 18];
        fine := dx7patch[off + 19];
        detune := dx7patch[off + 20];
        freq := osc_freq(midinote, mode, coarse, fine, detune);
        basepitch_[op] := freq;
        ampmodsens_[op] := ampmodsenstab[dx7patch[off + 14] and 3];
    end;
    for i := 0 to 3 do begin
        rates[i] := dx7patch[126 + i];
        levels[i] := dx7patch[130 + i];
    end;
    pitchenv_.SetValues(rates, levels);
    algorithm_     := dx7patch[134];
    feedback       := dx7patch[135];
    if feedback<>0 then
      fb_shift_    := FEEDBACK_BITDEPTH - feedback
    else
      fb_shift_    := 16;
    pitchmoddepth_ := (dx7patch[139] * 165)  shr  6;
    pitchmodsens_  := pitchmodsenstab[dx7patch[143] and 7];
    ampmoddepth_   := (dx7patch[140] * 165)  shr  6;
end;


procedure TDx7Note.compute(buf : pinteger; lfo_val, lfo_delay : integer;ctrls : TControllers);
var
  senslfo,
  pmod_1,
  pmod_2 : Int64;
  pitch_mod,
  pitchbend,
  pb,
  stp       : integer;
  amod_1,
  amod_2,
  amod_3    : uint32;
  amd_mod   : Int64;
  op,
  level     : integer;
  sensamp,
  pt,
  ldiff     : uint32;
  pmd : int64;
begin
  // == PITCH ==
  pmd       := pitchmoddepth_ * lfo_delay;
  senslfo   := pitchmodsens_ * (lfo_val - (1 shl 23));
  pmod_1    := Int64(pmd * senslfo) shr 39;
  pmod_1    := abs(pmod_1);
  pmod_2    := (ctrls.pitch_mod * senslfo) shr 14;
  pmod_2    := abs(pmod_2);
  pitch_mod := max(pmod_1, pmod_2);
  pitch_mod := pitchenv_.getSample + (pitch_mod * ifthen(senslfo < 0, -1, 1));

  // ---- PITCH BEND ----
  pitchbend := ctrls.values_[kControllerPitch];
  pb        := (pitchbend - $2000);

  if pb <> 0 then
  begin
    if ctrls.values_[kControllerPitchStep] = 0 then
    begin
      pb := trunc(((pb shl 11)) * (ctrls.values_[kControllerPitchRange]) / 12.0);
    end
    else
    begin
      stp := 12 div ctrls.values_[kControllerPitchStep];
      pb  := pb * stp div 8191;
      pb  := (pb * (8191 div stp)) shl 11;
    end;
  end;

  pitch_mod := pitch_mod + pb;
  pitch_mod := pitch_mod + ctrls.masterTune;

  // == AMP MOD ==
  amod_1  := (ampmoddepth_ * lfo_delay) shr 8;
  amod_1  := (amod_1 * lfo_val) shr 24;
  amod_2  := (ctrls.amp_mod * lfo_val) shr 7;
  amd_mod := max(amod_1, amod_2);

  // == EG AMP MOD ==
  amod_3  := (ctrls.eg_mod + 1) shl 17;
  amd_mod := max((1 shl 24) - amod_3, amd_mod);

  // == OP RENDER ==
  for op := 0 to OP_COUNT - 1 do
  begin
    if not ctrls.opSwitch[op] then
    begin
      env_[op].getsample(); // advance the envelop even if it is not playing
      params_[op].level_in := 0;
    end
    else
    begin
      // int32_t gain = pow(2, 10 + level * (1.0 / (1  shl  24)));
      params_[op].freq := TFreqlut.lookup(basepitch_[op] + pitch_mod);
      level            := env_[op].getsample();
      if ampmodsens_[op] <> 0 then
      begin
        sensamp := (amd_mod * ampmodsens_[op]) shr 24;
        // TODO: mehhh.. this needs some real tuning.
        pt    := trunc(Power(2, sensamp / 262144 * 0.07 + 12.2));
        ldiff := level * (pt shl 4) shr 28;
        level := level - ldiff;
      end;
      params_[op].level_in := level;
    end;
  end;
  ctrls.core.render(buf, params_, algorithm_, fb_buf_, fb_shift_);
end;


procedure TDx7Note.keyup;
var op: integer;
begin
  for op := 0 to OP_COUNT - 1 do
    env_[op].keydown(false);

  pitchenv_.KeyDown(false);
end;


procedure TDx7Note.update_dx7(const dx7patch : TPatchData; midinote, velocity : integer);
var
  rates,
  levels : TEnvArray;

  i,
  op, off, mode,
  coarse, fine,
  detune, outlevel, feedback,
  rate_scaling, level_scaling : integer;
begin
  for op := 0 to OP_COUNT_DX7 - 1 do
  begin
    off             := op * 21;
    mode            := dx7patch[off + 17];
    coarse          := dx7patch[off + 18];
    fine            := dx7patch[off + 19];
    detune          := dx7patch[off + 20];
    basepitch_[op]  := osc_freq(midinote, mode, coarse, fine, detune);
    ampmodsens_[op] := ampmodsenstab[dx7patch[off + 14] and 3];

    for i := 0 to 3 do
    begin
      rates[i]  := dx7patch[off + i];
      levels[i] := dx7patch[off + 4 + i];
    end;

    outlevel      := dx7patch[off + 16];
    outlevel      := TEnv.scaleoutlevel(outlevel);
    level_scaling := ScaleLevel(midinote, dx7patch[off + 8], dx7patch[off + 9], dx7patch[off + 10], dx7patch[off + 11], dx7patch[off + 12]);
    outlevel      := outlevel + level_scaling;
    outlevel      := min(127, outlevel);
    outlevel      := outlevel shl 5;
    outlevel      := outlevel + (ScaleVelocity(velocity, dx7patch[off + 15]));
    outlevel      := max(0, outlevel);
    rate_scaling  := ScaleRate(midinote, dx7patch[off + 13]);
    env_[op].update(rates, levels, outlevel, rate_scaling);
  end;
  algorithm_     := dx7patch[134];
  feedback       := dx7patch[135];
  fb_shift_      := ifthen(feedback <> 0, FEEDBACK_BITDEPTH - feedback, 16);
  pitchmoddepth_ := (dx7patch[139] * 165) shr 6;
  pitchmodsens_  := pitchmodsenstab[dx7patch[143] and 7];
  ampmoddepth_   := (dx7patch[140] * 165) shr 6;
end;

procedure TDx7Note.peekVoiceStatus(var status: TVoiceStatus);
var i: integer;
begin
  for i := 0 to 5 do
  begin
    status.amp[i] := Texp2.lookup(params_[i].level_in - (14 * (1 shl 24)));
    env_[i].getPosition(&status.ampStep[i]);
  end;
  pitchenv_.getPosition(&status.pitchStep);
end;

procedure TDx7Note.transferState(src: TDx7Note);
var i: integer;
begin
  for i := 0 to 5 do
  begin
    env_[i].transfer(src.env_[i]);
    params_[i].gain_out := src.params_[i].gain_out;
    params_[i].phase    := src.params_[i].phase;
  end;
end;

procedure TDx7Note.transferSignal(src: TDx7Note);
var i: integer;
begin
  for i := 0 to 5 do
  begin
    params_[i].gain_out := src.params_[i].gain_out;
    params_[i].phase    := src.params_[i].phase;
  end;
end;

procedure TDx7Note.oscSync;
var i: integer;
begin
  for i := 0 to 5 do
  begin
    params_[i].gain_out := 0;
    params_[i].phase    := 0;
  end;
end;

end.
