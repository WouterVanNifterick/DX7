unit Dexed;

{$POINTERMATH ON}

interface

uses
  System.SysUtils,
  System.Math,
  controllers, dx7note, lfo, fm_core,
  exp2,
  sin,
  freqlut,
  PluginFx,
  EngineMkI,
  EngineOpl,
  dexed_ttl,
  patch
//  trace,
//  lvtk.synth.hpp,
//  unistd,
//  limits;
;

type
  TDexedEngineResolution  = (
    DEXED_ENGINE_MODERN = 0,
    // 0
    DEXED_ENGINE_MARKI   = 1,
    // 1
    DEXED_ENGINE_OPL		 = 2
    );

  TDexedVoice = class
  private
    m_key                 : byte;
    m_rate                : Double;
    procedure &on( key, velocity : byte);
    procedure &off( velocity : byte);
  end;

  TProcessorVoice = record
  public
    midi_note,
    velocity  : byte;
    keydown,
    sustained,
    live      : Boolean;
    dx7_note  : TDx7Note;
  end;


  type

TDexed = class
  private
    _rate                 : Double;
    _k_rate_counter,
    _param_change_counter : byte;
  protected
  const
    MAX_ACTIVE_NOTES      = 32;
  var
    controllers           : TControllers;
    voiceStatus           : TVoiceStatus;
    max_notes             : byte;
    currentNote           : byte;
    sustain,
    monoMode,
    refreshVoice          : Boolean;
    engineType            : TDexedEngineResolution;
    fx                    : TPluginFx;
    lfo                   : TLfo;
    engineMsfa            : TFmCore;
    engineMkI             : TEngineMkI;
    engineOpl             : TEngineOpl;
    outbuf_               : psingle;
    bufsize_              : uint32;
    extra_buf_            : array[0..N-1] of Single;
    extra_buf_size_       : {@@@ uint32} Integer;
  public
    data_float            : array[0..172] of Single;
    data                  : TPatchData;
    audiobuf              : TArray<integer>;
    voices                : array[0..(MAX_ACTIVE_NOTES)-1] of TProcessorVoice;
  const
    DefaultPatch : array[0..172] of byte = (
      95, 29, 20, 50, 99, 95, 00, 00, 41, 00, 19, 00, 00, 03, 00, 06, 79,
      00, 01, 00, 14, 95, 20, 20, 50, 99, 95, 00, 00, 00, 00, 00, 00, 00,
      03, 00, 00, 99, 00, 01, 00, 00, 95, 29, 20, 50, 99, 95, 00, 00, 00,
      00, 00, 00, 00, 03, 00, 06, 89, 00, 01, 00, 07, 95, 20, 20, 50, 99,
      95, 00, 00, 00, 00, 00, 00, 00, 03, 00, 02, 99, 00, 01, 00, 07, 95,
      50, 35, 78, 99, 75, 00, 00, 00, 00, 00, 00, 00, 03, 00, 07, 58, 00,
      14, 00, 07, 96, 25, 25, 67, 99, 75, 00, 00, 00, 00, 00, 00, 00, 03,
      00, 02, 99, 00, 01, 00, 10, 94, 67, 95, 60, 50, 50, 50, 50, 04, 06,
      00, 34, 33, 00, 00, 00, 04, 03, 24, 00, 00, 00, 00, 00, 00, 00, 00,
      00, 00, 01, 00, 99, 00, 99, 00, 99, 00, 99, 00, 00, 01, 01, 01, 01,
      01, 01, 16 );
    procedure activate;
    procedure deactivate;
    procedure set_params;
    /// <summary>
    /// override the run() method
    /// </summary>
//    procedure run( sample_count : uint32 );
    procedure GetSamples(n_samples: uint32; buffer: psingle);
    function  ProcessMidiMessage(buf: pbyte; buf_size: uint32): Boolean;
    procedure keydown(pitch, velo: byte);
    procedure keyup(pitch: byte);
    procedure onParam(param_num: byte; param_val: Single);
    function GetParameter(param_num: byte):Single;
    function getEngineType: TDexedEngineResolution;
    procedure setEngineType(tp: TDexedEngineResolution);
    function isMonoMode: Boolean;
    procedure setMonoMode(mode: Boolean);
    procedure panic;

    procedure notes_off;
    constructor Create;
  end;

const
  PARAM_CHANGE_LEVEL    = 10; // when a sound change is recognized;



implementation


{ TDexed }

procedure TDexed.activate;
begin
//@@@  Plugin.activate();
  panic();
//@@@  controllers.values_[kControllerPitchRange] := data[155];
//@@@  controllers.values_[kControllerPitchStep]  := data[156];
end;


constructor TDexed.Create;
begin
//  inherited;
  move(DefaultPatch[0],self.data[0],Length(Self.data));
  Self.max_notes := MAX_ACTIVE_NOTES;
  Self.controllers := TControllers.Create(TFmMod.Create,TFmCore.Create);
  self.fx := TPluginFx.Create;
end;

procedure TDexed.deactivate;
begin
//@@@  Plugin.deactivate();
end;


procedure TDexed.set_params;
var
  polymono : Boolean;
  engine   : TDexedEngineResolution;
  f_gain,
  f_cutoff,
  f_reso   : Single;
begin
  _param_change_counter := 0;

  polymono := Boolean(_ports[p_polymono].integer);
  engine   := TDexedEngineResolution(_ports[p_engine].integer);
  f_gain   := _ports[p_output].integer;
  f_cutoff := _ports[p_cutoff].integer;
  f_reso   := _ports[p_resonance].integer;

  // Dexed-Unisono
  if isMonoMode <> polymono then
    setMonoMode(polymono);

  // Dexed-Engine
  if (controllers.core = nil) or (getEngineType <> engine) then
  begin
    setEngineType(engine);
    refreshVoice := true;
  end;

  // Dexed-Filter
  if fx.uiCutoff <> f_cutoff then
  begin
    fx.uiCutoff  := f_cutoff;
    refreshVoice := true;
  end;
  if fx.uiReso <> f_reso then
  begin
    fx.uiReso    := f_reso;
    refreshVoice := true;
  end;
  if fx.uiGain <> f_gain then
  begin
    fx.uiGain    := f_gain;
    refreshVoice := true;
  end;
  // OP6
  onParam( 0,_ports[p_op6_eg_rate_1].integer );
  onParam( 1,_ports[p_op6_eg_rate_2].integer);
  onParam( 2,_ports[p_op6_eg_rate_3].integer);
  onParam( 3,_ports[p_op6_eg_rate_4].integer);
  onParam( 4,_ports[p_op6_eg_level_1].integer);
  onParam( 5,_ports[p_op6_eg_level_2].integer);
  onParam( 6,_ports[p_op6_eg_level_3].integer);
  onParam( 7,_ports[p_op6_eg_level_4].integer);
  onParam( 8,_ports[p_op6_kbd_lev_scl_brk_pt].integer);
  onParam( 9,_ports[p_op6_kbd_lev_scl_lft_depth].integer);
  onParam(10,_ports[p_op6_kbd_lev_scl_rht_depth].integer);
  onParam(11,_ports[p_op6_kbd_lev_scl_lft_curve].integer);
  onParam(12,_ports[p_op6_kbd_lev_scl_rht_curve].integer);
  onParam(13,_ports[p_op6_kbd_rate_scaling].integer);
  onParam(14,_ports[p_op6_amp_mod_sensitivity].integer);
  onParam(15,_ports[p_op6_key_vel_sensitivity].integer);
  onParam(16,_ports[p_op6_operator_output_level].integer);
  onParam(17,_ports[p_op6_osc_mode].integer);
  onParam(18,_ports[p_op6_osc_freq_coarse].integer);
  onParam(19,_ports[p_op6_osc_freq_fine].integer);
  onParam(20,_ports[p_op6_osc_detune].integer+7);
  // OP5
  onParam(21,_ports[p_op5_eg_rate_1].integer);
  onParam(22,_ports[p_op5_eg_rate_2].integer);
  onParam(23,_ports[p_op5_eg_rate_3].integer);
  onParam(24,_ports[p_op5_eg_rate_4].integer);
  onParam(25,_ports[p_op5_eg_level_1].integer);
  onParam(26,_ports[p_op5_eg_level_2].integer);
  onParam(27,_ports[p_op5_eg_level_3].integer);
  onParam(28,_ports[p_op5_eg_level_4].integer);
  onParam(29,_ports[p_op5_kbd_lev_scl_brk_pt].integer);
  onParam(30,_ports[p_op5_kbd_lev_scl_lft_depth].integer);
  onParam(31,_ports[p_op5_kbd_lev_scl_rht_depth].integer);
  onParam(32,_ports[p_op5_kbd_lev_scl_lft_curve].integer);
  onParam(33,_ports[p_op5_kbd_lev_scl_rht_curve].integer);
  onParam(34,_ports[p_op5_kbd_rate_scaling].integer);
  onParam(35,_ports[p_op5_amp_mod_sensitivity].integer);
  onParam(36,_ports[p_op5_key_vel_sensitivity].integer);
  onParam(37,_ports[p_op5_operator_output_level].integer);
  onParam(38,_ports[p_op5_osc_mode].integer);
  onParam(39,_ports[p_op5_osc_freq_coarse].integer);
  onParam(40,_ports[p_op5_osc_freq_fine].integer);
  onParam(41,_ports[p_op5_osc_detune].integer+7);
  // OP4
  onParam(42,_ports[p_op4_eg_rate_1].integer);
  onParam(43,_ports[p_op4_eg_rate_2].integer);
  onParam(44,_ports[p_op4_eg_rate_3].integer);
  onParam(45,_ports[p_op4_eg_rate_4].integer);
  onParam(46,_ports[p_op4_eg_level_1].integer);
  onParam(47,_ports[p_op4_eg_level_2].integer);
  onParam(48,_ports[p_op4_eg_level_3].integer);
  onParam(49,_ports[p_op4_eg_level_4].integer);
  onParam(50,_ports[p_op4_kbd_lev_scl_brk_pt].integer);
  onParam(51,_ports[p_op4_kbd_lev_scl_lft_depth].integer);
  onParam(52,_ports[p_op4_kbd_lev_scl_rht_depth].integer);
  onParam(53,_ports[p_op4_kbd_lev_scl_lft_curve].integer);
  onParam(54,_ports[p_op4_kbd_lev_scl_rht_curve].integer);
  onParam(55,_ports[p_op4_kbd_rate_scaling].integer);
  onParam(56,_ports[p_op4_amp_mod_sensitivity].integer);
  onParam(57,_ports[p_op4_key_vel_sensitivity].integer);
  onParam(58,_ports[p_op4_operator_output_level].integer);
  onParam(59,_ports[p_op4_osc_mode].integer);
  onParam(60,_ports[p_op4_osc_freq_coarse].integer);
  onParam(61,_ports[p_op4_osc_freq_fine].integer);
  onParam(62,_ports[p_op4_osc_detune].integer+7);
  // OP3
  onParam(63,_ports[p_op3_eg_rate_1].integer);
  onParam(64,_ports[p_op3_eg_rate_2].integer);
  onParam(65,_ports[p_op3_eg_rate_3].integer);
  onParam(66,_ports[p_op3_eg_rate_4].integer);
  onParam(67,_ports[p_op3_eg_level_1].integer);
  onParam(68,_ports[p_op3_eg_level_2].integer);
  onParam(69,_ports[p_op3_eg_level_3].integer);
  onParam(70,_ports[p_op3_eg_level_4].integer);
  onParam(71,_ports[p_op3_kbd_lev_scl_brk_pt].integer);
  onParam(72,_ports[p_op3_kbd_lev_scl_lft_depth].integer);
  onParam(73,_ports[p_op3_kbd_lev_scl_rht_depth].integer);
  onParam(74,_ports[p_op3_kbd_lev_scl_lft_curve].integer);
  onParam(75,_ports[p_op3_kbd_lev_scl_rht_curve].integer);
  onParam(76,_ports[p_op3_kbd_rate_scaling].integer);
  onParam(77,_ports[p_op3_amp_mod_sensitivity].integer);
  onParam(78,_ports[p_op3_key_vel_sensitivity].integer);
  onParam(79,_ports[p_op3_operator_output_level].integer);
  onParam(80,_ports[p_op3_osc_mode].integer);
  onParam(81,_ports[p_op3_osc_freq_coarse].integer);
  onParam(82,_ports[p_op3_osc_freq_fine].integer);
  onParam(83,_ports[p_op3_osc_detune].integer+7);
  // OP2
  onParam(84,_ports[p_op2_eg_rate_1].integer);
  onParam(85,_ports[p_op2_eg_rate_2].integer);
  onParam(86,_ports[p_op2_eg_rate_3].integer);
  onParam(87,_ports[p_op2_eg_rate_4].integer);
  onParam(88,_ports[p_op2_eg_level_1].integer);
  onParam(89,_ports[p_op2_eg_level_2].integer);
  onParam(90,_ports[p_op2_eg_level_3].integer);
  onParam(91,_ports[p_op2_eg_level_4].integer);
  onParam(92,_ports[p_op2_kbd_lev_scl_brk_pt].integer);
  onParam(93,_ports[p_op2_kbd_lev_scl_lft_depth].integer);
  onParam(94,_ports[p_op2_kbd_lev_scl_rht_depth].integer);
  onParam(95,_ports[p_op2_kbd_lev_scl_lft_curve].integer);
  onParam(96,_ports[p_op2_kbd_lev_scl_rht_curve].integer);
  onParam(97,_ports[p_op2_kbd_rate_scaling].integer);
  onParam(98,_ports[p_op2_amp_mod_sensitivity].integer);
  onParam(99,_ports[p_op2_key_vel_sensitivity].integer);
  onParam(100,_ports[p_op2_operator_output_level].integer);
  onParam(101,_ports[p_op2_osc_mode].integer);
  onParam(102,_ports[p_op2_osc_freq_coarse].integer);
  onParam(103,_ports[p_op2_osc_freq_fine].integer);
  onParam(104,_ports[p_op2_osc_detune].integer+7);
  // OP1
  onParam(105,_ports[p_op1_eg_rate_1].integer);
  onParam(106,_ports[p_op1_eg_rate_2].integer);
  onParam(107,_ports[p_op1_eg_rate_3].integer);
  onParam(108,_ports[p_op1_eg_rate_4].integer);
  onParam(109,_ports[p_op1_eg_level_1].integer);
  onParam(110,_ports[p_op1_eg_level_2].integer);
  onParam(111,_ports[p_op1_eg_level_3].integer);
  onParam(112,_ports[p_op1_eg_level_4].integer);
  onParam(113,_ports[p_op1_kbd_lev_scl_brk_pt].integer);
  onParam(114,_ports[p_op1_kbd_lev_scl_lft_depth].integer);
  onParam(115,_ports[p_op1_kbd_lev_scl_rht_depth].integer);
  onParam(116,_ports[p_op1_kbd_lev_scl_lft_curve].integer);
  onParam(117,_ports[p_op1_kbd_lev_scl_rht_curve].integer);
  onParam(118,_ports[p_op1_kbd_rate_scaling].integer);
  onParam(119,_ports[p_op1_amp_mod_sensitivity].integer);
  onParam(120,_ports[p_op1_key_vel_sensitivity].integer);
  onParam(121,_ports[p_op1_operator_output_level].integer);
  onParam(122,_ports[p_op1_osc_mode].integer);
  onParam(123,_ports[p_op1_osc_freq_coarse].integer);
  onParam(124,_ports[p_op1_osc_freq_fine].integer);
  onParam(125,_ports[p_op1_osc_detune].integer+7);
  // Global for all OPs
  onParam(126,_ports[p_pitch_eg_rate_1].integer);
  onParam(127,_ports[p_pitch_eg_rate_2].integer);
  onParam(128,_ports[p_pitch_eg_rate_3].integer);
  onParam(129,_ports[p_pitch_eg_rate_4].integer);
  onParam(130,_ports[p_pitch_eg_level_1].integer);
  onParam(131,_ports[p_pitch_eg_level_2].integer);
  onParam(132,_ports[p_pitch_eg_level_3].integer);
  onParam(133,_ports[p_pitch_eg_level_4].integer);
  onParam(134,_ports[p_algorithm_num].integer-1);
  onParam(135,_ports[p_feedback].integer);
  onParam(136,_ports[p_oscillator_sync].integer);
  onParam(137,_ports[p_lfo_speed].integer);
  onParam(138,_ports[p_lfo_delay].integer);
  onParam(139,_ports[p_lfo_pitch_mod_depth].integer);
  onParam(140,_ports[p_lfo_amp_mod_depth].integer);
  onParam(141,_ports[p_lfo_sync].integer);
  onParam(142,_ports[p_lfo_waveform].integer);
  onParam(143,_ports[p_pitch_mod_sensitivity].integer);
  onParam(144,_ports[p_transpose].integer);
  // 10 bytes _ports[(145-154) are the name of the patch
  // Controlle_ports[rs (added at the end of the data[])
  onParam(155,_ports[p_pitch_bend_range].integer);
  onParam(156,_ports[p_pitch_bend_step].integer);
  onParam(157,_ports[p_mod_wheel_range].integer);
  onParam(158,_ports[p_mod_wheel_assign].integer);
  onParam(159,_ports[p_foot_ctrl_range].integer);
  onParam(160,_ports[p_foot_ctrl_assign].integer);
  onParam(161,_ports[p_breath_ctrl_range].integer);
  onParam(162,_ports[p_breath_ctrl_assign].integer);
  onParam(163,_ports[p_aftertouch_range].integer);
  onParam(164,_ports[p_aftertouch_assign].integer);
  onParam(165,_ports[p_master_tune].integer);
  onParam(166,_ports[p_op1_enable].integer);
  onParam(167,_ports[p_op2_enable].integer);
  onParam(168,_ports[p_op3_enable].integer);
  onParam(169,_ports[p_op4_enable].integer);
  onParam(170,_ports[p_op5_enable].integer);
  onParam(171,_ports[p_op6_enable].integer);
  onParam(172,_ports[p_number_of_voices].integer);
  if _param_change_counter>PARAM_CHANGE_LEVEL then begin
    panic();
    controllers.refresh();
  end;
end;


/// <summary>
///   override the run() method
/// </summary>
{@@@
procedure TDexed.run( sample_count : uint32);
var
  output           : single;
  num_this_time ,
  last_frame       : uint32;
  drop_next_events : Boolean;
//  ev: LV2_Atom_Event;

begin
    output := _ports[p_audio_out].default_value;
    last_frame := 0;
    num_this_time := 0;
    drop_next_events := false;
//@@@    Plugin.run(sample_count);
    inc(_k_rate_counter);

    if _k_rate_counter mod 16 = 0 then
      set_params(); // pre_process: copy actual voice params

    for (LV2_Atom_Event* ev = lv2_atom_sequence_begin (&seq^.body);
          not lv2_atom_sequence_is_end(&seq^.body, seq^.atom.size, ev);
         ev := lv2_atom_sequence_next (ev))
    begin
       num_this_time := ev^.time.frames - last_frame;
       // If it's midi, send it to the engine
       if ev^.body.type = m_midi_type then begin
         drop_next_events|=ProcessMidiMessage((uint8_t*) LV2_ATOM_BODY (&ev^.body),ev^.body.size);
         if drop_next_events=true then continue;
       end;
       // render audio from the last frame until the timestamp of this event
       GetSamples (num_this_time, outbuf_);
       // i is the index of the engine's buf, which always starts at 0 (i think)
       // j is the index of the plugin's float output buffer which will be the timestamp
       // of the last processed atom event.
       for (uint32_t i = 0, j = last_frame; i < num_this_time; PreInc(i), PreInc(j))
           output[j] := outbuf_[i];
       last_frame := ev^.time.frames;
    end;
    // render remaining samples if any left
    if last_frame < sample_count then begin
       // do the same thing as above except from last frame until the end of
       // the processing cycles last sample. at this point, all events have
       // already been handled.
       num_this_time := sample_count - last_frame;
       GetSamples (num_this_time, outbuf_);
       for (uint32_t i = 0, j = last_frame; i < num_this_time; PreInc(i), PreInc(j))
           output[j] := outbuf_[i];
    end;
    fx.process(output, sample_count);
end;
}

procedure TDexed.GetSamples( n_samples : uint32; buffer : psingle);
var
  note,
  i,j,k          : Integer;
  sumbuf         : array[0..(N)-1] of Single;
  lfovalue,
  lfodelay,
  val,
  clip_val       : integer;
  f              : Single;
  jmax           : {@@@ uint32} integer;
  op,
  op_carrier,
  op_amp,
  op_carrier_num,
  op_bit         : byte;
  parAr : TLFOParameters;
begin
  // play test signal:
  // for i := 0 to n_samples-1 do Buffer[i] := System.sin(440*2*pi*i/44100);

  if refreshVoice then begin
    for i := 0 to max_notes-1 do begin
      if voices[i].live  then
        voices[i].dx7_note.update_dx7(data, voices[i].midi_note, voices[i].velocity);
    end;
    Move(data[137],parAr.rate,SizeOf(parAr));
    lfo.reset(parAr);
    refreshVoice := false;
  end;
  // flush first events
  // @@@
  for i := 0 to n_samples-1 do
  begin
    buffer[i] := extra_buf_[i];
  end;
  // remaining buffer is still to be processed
  if extra_buf_size_ > n_samples then
  begin
    for j := 0 to extra_buf_size_ - n_samples - 1 do
      extra_buf_[j] := extra_buf_[j + n_samples];
    extra_buf_size_  := extra_buf_size_ - n_samples;
  end
  else
  begin
    setlength(audiobuf,n_samples);
    for k:=0 to n_samples-1 do
    begin
      i := i + N;
//      AlignedBuf<int32_t, N> audiobuf;
      for j := 0 to N-1 do
      begin
        audiobuf[j] := 0;
        sumbuf[j] := 0.0;
      end;
      lfovalue := lfo.getSample();
      lfodelay := lfo.getDelay();
      for note := 0 to MAX_ACTIVE_NOTES { max_notes}-1 do
      begin
        if voices[note].live then
        begin
          voices[note].dx7_note.compute(@audiobuf[0], lfovalue, lfodelay, &controllers);
          for j:=0 to N-1 do
          begin
            val := audiobuf[j];
            val := val  shr  4;
            clip_val := IfThen(val < -(1 shl 24) , $8000 , ifthen( val >= (1 shl 24) , $7fff , val shr 9));
            f := (clip_val shr 1) div $8000;
            f := EnsureRange(f,-1,1);
            sumbuf[j] := sumbuf[j] + f;
            audiobuf[j]:=0;
          end;
        end;
      end;
///      @@@
      jmax := n_samples - i;
      for j := 0 to N-1 do
      begin
        if j < jmax then
          buffer[i + j] := sumbuf[j]
        else
          extra_buf_[j - jmax] := sumbuf[j];
      end;
    end;
    extra_buf_size_ := i - n_samples;
// @@
  end;
  inc(_k_rate_counter);
  if (_k_rate_counter mod 32  = 0) and (not monoMode) then
  begin
    op_carrier := controllers.core.get_carrier_operators(data[134]);
    for i := 0 to max_notes-1 do
    begin
      if voices[i].live=true then
      begin
        op_amp := 0;
        op_carrier_num := 0;
        voices[i].dx7_note.peekVoiceStatus(voiceStatus);
        for op := 0 to 5 do
        begin
          op_bit := trunc(Power(2,op));
          if (op_carrier and op_bit) >0 then
          begin
            // this voice is a carrier!
            Inc(op_carrier_num);
            //TRACE('Voice[%2d] OP [%d] amp=%ld,amp_step=%d,pitch_step=%d',i,op,voiceStatus.amp[op],voiceStatus.ampStep[op],voiceStatus.pitchStep);
            if (voiceStatus.amp[op]<=1069) and (voiceStatus.ampStep[op]=4) then // this voice produces no audio output
              Inc(op_amp);
          end;
        end;
        if op_amp=op_carrier_num then
        begin
          // all carrier-operators are silent ^. disable the voice
          voices[i].live := false;
          voices[i].sustained := false;
          voices[i].keydown := false;
//          TRACE('Shutted down Voice[%2d]',i);
        end;
      end;
//    TRACE('Voice[%2d] live=%d keydown=%d',i,voices[i].live,voices[i].keydown);
    end;
  end;
end;


function TDexed.ProcessMidiMessage(buf: pbyte; buf_size: uint32): Boolean;
var
  cmd, ctrl, value, note: byte;
begin
  cmd := buf[0];
  case cmd and $F0 of
    $80:
      begin
        // TRACE('MIDI keyup event: %d',buf[1]);
        keyup(buf[1]);
        Exit((false))
      end;
    $90:
      begin
        // TRACE('MIDI keydown event: %d %d',buf[1],buf[2]);
        keydown(buf[1], buf[2]);
        Exit((false))
      end;
    $B0:
      begin
        ctrl  := buf[1];
        value := buf[2];
        case ctrl of
          1:
            begin
              // TRACE('MIDI modwheel event: %d %d',ctrl,value);
              controllers.modwheel_cc := value;
              controllers.refresh()
            end;
          2:
            begin
              // TRACE('MIDI breath event: %d %d',ctrl,value);
              controllers.breath_cc := value;
              controllers.refresh()
            end;
          4:
            begin
              // TRACE('MIDI footsw event: %d %d',ctrl,value);
              controllers.foot_cc := value;
              controllers.refresh()
            end;
          64:
            begin
              // TRACE('MIDI sustain event: %d %d',ctrl,value);
              sustain := value > 63;
              if not sustain then
              begin
                for note := 0 to max_notes - 1 do
                begin
                  if voices[note].sustained and not voices[note].keydown then
                  begin
                    voices[note].dx7_note.keyup();
                    voices[note].sustained := false
                  end;
                end; //
              end;
            end;

          120:
            begin
              // TRACE('MIDI all-sound-off: %d %d',ctrl,value);
              panic();
              Exit((true));
            end;
          123:
            begin // TRACE('MIDI all-notes-off: %d %d',ctrl,value);
              notes_off();
              Exit((true));
            end;
        end;
      end;
    $C0:
      begin
        // @@@            setCurrentProgram(buf[1]);
        // channel aftertouch
      end;
    $D0:
      begin
        // TRACE('MIDI aftertouch $d0 event: %d %d',buf[1]);
        controllers.aftertouch_cc := buf[1];
        controllers.refresh();
      end;
    // pitchbend
    $E0:
      begin
        // TRACE('MIDI pitchbend $e0 event: %d %d',buf[1],buf[2]);
        controllers.values_[kControllerPitch] := buf[1] or (buf[2] shl 7);
      end;
  else
    // TRACE('MIDI event unknown: cmd=%d, val1=%d, val2=%d',buf[0],buf[1],buf[2]);
  end;
  Result := (false);

end;


procedure TDexed.keydown( pitch, velo : byte);
var
  i,
  note,
  keydown_counter : byte;
begin
    if velo = 0  then
    begin
        keyup(pitch);
        Exit;
    end;
    pitch  := pitch + (data[144] - 24);
    note := currentNote;
    keydown_counter := 0;
    for i := 0 to max_notes-1 do
    begin
        if  not voices[note].keydown then
        begin
            currentNote := (note + 1) mod max_notes;
            voices[note].midi_note := pitch;
            voices[note].velocity := velo;
            voices[note].sustained := sustain;
            voices[note].keydown := true;
            voices[note].dx7_note.Create(data, pitch, velo);
            if data[136]<>0 then
              voices[note].dx7_note.oscSync();
            break;
        end
        else
          Inc(keydown_counter);
        note := (note + 1) mod max_notes;
    end;
    if keydown_counter=0 then lfo.KeyDown();
    if monoMode  then begin
        for i := 0 to max_notes-1do
        begin
            if voices[i].live  then begin
                // all keys are up, only transfer signal
                if  not  voices[i].keydown  then  begin
                    voices[i].live := false;
                    voices[note].dx7_note.transferSignal( voices[i].dx7_note);
                    break;
                end;
                if voices[i].midi_note < pitch  then begin
                    voices[i].live := false;
                    voices[note].dx7_note.transferState( voices[i].dx7_note);
                    break;
                end;
                Exit;
            end;
        end;
    end;
    voices[note].live := true;
end;


procedure TDexed.keyup( pitch : byte);
var
  i,
  note     : byte;
  highNote,
  target   : shortint;
begin
    pitch  := pitch + data[144] - 24;
    for note := 0 to max_notes-1 do
    begin
        if (voices[note].midi_note = pitch) and (voices[note].keydown) then
        begin
            voices[note].keydown := false;
            break;
        end;
    end;
    // note not found ?
    if note >= max_notes  then begin
//        TRACE('note-off not found???');
        Exit;
    end;
    if monoMode  then begin
        highNote := -1;
        target := 0;
        for  i := 0 to max_notes-1 do begin
            if (voices[i].keydown) and (voices[i].midi_note > highNote) then
            begin
                target := i;
                highNote := voices[i].midi_note;
            end;
        end;
        if highNote <> -1  then begin
            voices[note].live := false;
            voices[target].live := true;
            voices[target].dx7_note.transferState( voices[note].dx7_note);
        end;
    end;
    if sustain  then begin
        voices[note].sustained := true;
    end
    else begin
        voices[note].dx7_note.keyup();
    end;
end;


procedure TDexed.onParam( param_num : byte; param_val : Single);
var
  tune : integer;
  tmp : byte;
begin
  if param_val<>data_float[param_num] then
  begin
//    TRACE('Parameter %d change from %f to %f',param_num, data_float[param_num], param_val);
{$IFDEF DEBUG}
    tmp := data[param_num];
{$ENDIF}

    Inc(_param_change_counter);
    if (param_num=144) or (param_num=134) or (param_num=172) then
      panic();

    refreshVoice := true;
    data[param_num] := trunc(param_val);
    data_float[param_num] := param_val;
    case param_num of
      155: controllers.values_[kControllerPitchRange]:=data[param_num];
      156: controllers.values_[kControllerPitchStep]:=data[param_num];
      157: controllers.wheel.setRange  (data[param_num]);
      158: controllers.wheel.setTarget (data[param_num]);
      159: controllers.foot.setRange   (data[param_num]);
      160: controllers.foot.setTarget  (data[param_num]);
      161: controllers.breath.setRange (data[param_num]);
      162: controllers.breath.setTarget(data[param_num]);
      163: controllers.at.setRange     (data[param_num]);
      164: controllers.at.setTarget    (data[param_num]);
      165:
        begin
          tune := Trunc(param_val * $4000);
          controllers.masterTune := Trunc((tune shl 11)*(1/12));
        end;
      166..171:
        begin
        {@@@
          controllers.opSwitch := [(data[166] shl 5)=32,
                                   (data[167] shl 4)=16,
                                   (data[168] shl 3)=8,
                                   (data[169] shl 2)=4,
                                   (data[170] shl 1)=2,
                                   (data[171] shl 0)=1
                                  ];
}
//          controllers.opSwitch[0] := (data[166] shl 5)=32;
//          controllers.opSwitch[1] := (data[167] shl 4)=16;
//          controllers.opSwitch[2] := (data[168] shl 3)= 8;
//          controllers.opSwitch[3] := (data[169] shl 2)= 4;
//          controllers.opSwitch[4] := (data[170] shl 1)= 2;
//          controllers.opSwitch[5] := (data[171] shl 0)= 1;
        end;
      172: max_notes:=data[param_num];
    end;
  end;//    TRACE('Done: Parameter %d changed from %d to %d',param_num, tmp, data[param_num]);

end;

function TDexed.GetParameter(param_num: byte):Single;
begin
//  Result := _data_float[param_num];
end;


function TDexed.getEngineType:TDexedEngineResolution;
begin
    Result := engineType;
end;


procedure TDexed.setEngineType( tp : TDexedEngineResolution);
begin
//    TRACE('settings engine %d', tp);
    if (engineType=tp) and (controllers.core<>nil) then
      Exit;

    case tp of
      DEXED_ENGINE_MARKI:
        begin
//          TRACE('DEXED_ENGINE_MARKI:%d',DEXED_ENGINE_MARKI);
          controllers.core := engineMkI
        end;
      DEXED_ENGINE_OPL:
        begin
//          TRACE('DEXED_ENGINE_OPL:%d',DEXED_ENGINE_OPL);
          controllers.core := engineOpl
        end
      else
        begin
//          TRACE('DEXED_ENGINE_MODERN:%d',DEXED_ENGINE_MODERN);
          controllers.core := engineMsfa;
          tp := DEXED_ENGINE_MODERN
        end;
    end;
    engineType := tp;
    panic();
    controllers.refresh();
end;


function TDexed.isMonoMode:Boolean;
begin
    Result := monoMode;
end;


procedure TDexed.setMonoMode( mode : Boolean);
begin
    if monoMode=mode then Exit;
    monoMode := mode;
end;


procedure TDexed.panic;
var i:integer;
begin
  for i := 0 to MAX_ACTIVE_NOTES-1 do
  begin
    if voices[i].live = true then
    begin
      voices[i].keydown := false;
      voices[i].live := false;
      voices[i].sustained := false;
      voices[i].dx7_note.oscSync();
    end;
  end;
end;


procedure TDexed.notes_off;
var i:integer;
begin
  for i := 0 to MAX_ACTIVE_NOTES - 1 do
  begin
    if (voices[i].live=true) and (voices[i].keydown=true) then
    begin
      voices[i].keydown := false;
    end;
  end;
end;



{ DexedVoice }

procedure TDexedVoice.&on( key, velocity : byte);
begin
  m_key := key;
end;


procedure TDexedVoice.&off( velocity : byte);
begin
  m_key :=  255;
end;






end.
