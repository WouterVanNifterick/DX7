unit SynthUnit;

interface

uses
  controllers,
  dx7note,
  lfo,
  ringbuffer,
  Windows,
  System.SysUtils,
  synth,
  freqlut,
  sin,
  exp2,
  fm_core,
//  EngineMkI,
  pitchenv,
  patch
  // , aligned_buf
    ;

type
  PInt16 = ^System.int16;

  TActiveNote = record
    midi_note: integer;
    keydown, sustained, live: Boolean;
    dx7_note: TDx7Note;
  end;

  TSynthUnit = class
  const
    max_active_notes = 16;

  private
  var
    FRingBuffer        : PRingBuffer;
    FActiveNote        : array [0 .. max_active_notes - 1] of TActiveNote;
    FCurrentNote       : integer;
    FInputBuffer       : array [0 .. 8191] of byte;
    FInputBufferIndex  : integer;
    FPatchBankData     : TPatchBankData;
    FCurrentPatchIndex : integer;
    FUnpackedPatch     : TPatchData;
    FLFO               : TLfo;
    FControllers       : TControllers;
//    FFilterControl     : array [0 .. 2] of integer;
    FSustain           : Boolean;
    FExtraBuf          : array [0 .. N - 1] of int16;
    FExtraBufSize      : integer;
  public
    procedure Init(sample_rate: Double);

    constructor Create(ring_buffer: PRingBuffer; sample_rate: Double);
    procedure GetSamples(n_samples: integer; aBuffer: array of int16);
    procedure TransferInput;
    procedure ConsumeInput(n_input_bytes: integer);
    function AllocateNote: integer;
    procedure ProgramChange(p: integer);
    procedure SetController(controller, value: integer);
    function ProcessMidiMessage(buf: pbyte; buf_size: integer): integer;

    procedure onPatch(const aPatch: TArray<byte>);
    procedure onParam(id: uint32; value: byte);
  end;

var
  program_number: integer;
  name          : array [0 .. 10] of byte;

  const
  epiano: TBulkData = (
    {    ┌───────────[EG]─────────────┐   ┌─────[KLS]──────┐                                             }
    {    L1  L2  L3  L4  R1  R2  R3  R4  BP  LD  RD  LC  RC KRS MSA KVS LVL  OM  C    F DET                }
    {op6}95, 29, 20, 50, 99, 95, 00, 00, 41, 00, 19, 00,115, 24, 79, 02, 00,
         95, 20, 20, 50, 99, 95, 00, 00, 00, 00, 00, 00, 03, 00, 99, 02, 00,
         95, 29, 20, 50, 99, 95, 00, 00, 00, 00, 00, 00, 59, 24, 89, 02, 00,
         95, 20, 20, 50, 99, 95, 00, 00, 00, 00, 00, 00, 59, 08, 99, 02, 00,
         95, 50, 35, 78, 99, 75, 00, 00, 00, 00, 00, 00, 59, 28, 58, 28, 00,
    {    ┌───────[Pitch EG]───────────┐             ┌───────[LFO]───────┐                           }
    {    L1  L2  L3  L4  R1  R2  R3  R4 ALG FB SN SPD DLY PMD AMD SNC WAV PMS TRP                   }
         96, 25, 25, 67, 99, 75, 00, 00, 00, 00, 00, 00, 83, 08, 99, 02, 00, 94, 67, 95,
         60, 50, 50, 50, 50, 04, 06, 34, 33, 00, 00, 56, 024,

    {    ┌─────────────────────────────────────[Name]────────────────────────────────────────────┐  }
    {        69       46       80       73       65       78       79       32       49       32    }
         ord('E'),ord('.'),ord('P'),ord('I'),ord('A'),ord('N'),ord('O'),ord(' '),ord('1'),ord(' ')  );

implementation

uses System.Math;

{ SynthUnit }

procedure TSynthUnit.Init(sample_rate: Double);
var LFOParams:TLFOParameters;
begin
  TFreqlut.Init(sample_rate);
  move(Self.FUnpackedPatch[137], LFOParams.rate, sizeof(LFOParams));
  FLFO := lfo.TLFO.Create(sample_rate, LFOParams );
  TPitchEnv.Create(sample_rate);
end;

/// <summary>
/// Transfer as many bytes as possible from ring buffer to input buffer.
/// Note that this implementation has a fair amount of copying - we'd probably
/// do it a bit differently if it were bulk data, but in this case we're
/// optimizing for simplicity of implementation.
/// </summary>
procedure TSynthUnit.TransferInput;
var
  bytes_available: size_t;
  bytes_to_read  : integer;
begin
  bytes_available := FRingBuffer.BytesAvailable();
  bytes_to_read   := min(bytes_available, sizeof(FInputBuffer) - FInputBufferIndex);
  if bytes_to_read > 0 then
  begin
    FRingBuffer.Read(bytes_to_read, @FInputBuffer[FInputBufferIndex]);
    FInputBufferIndex := FInputBufferIndex + bytes_to_read;
  end;
end;

procedure TSynthUnit.ConsumeInput(n_input_bytes: integer);
begin
  if n_input_bytes < FInputBufferIndex then
    move(FInputBuffer[0], FInputBuffer[n_input_bytes], FInputBufferIndex - n_input_bytes);

  FInputBufferIndex := FInputBufferIndex - n_input_bytes;
end;

constructor TSynthUnit.Create(ring_buffer: PRingBuffer; sample_rate: Double);
var note:integer; Patch:TPatchData;
begin
  Self.FRingBuffer := ring_buffer;
  Init(sample_rate);

  Move(epiano[0], FPatchBankData[0], length(epiano));
  UnpackPatch(epiano,Patch);

  for note := 0 to high(FActiveNote) do
  begin
    FActiveNote[note].dx7_note := TDx7Note.Create(Patch,60,0);
    FActiveNote[note].keydown := false;
    FActiveNote[note].sustained := false;
    FActiveNote[note].live := false;
  end;
  FInputBufferIndex := 0;
  ProgramChange(0);
  FCurrentNote := 0;
  // JJK filter_control_[0] = 258847126;
  // filter_control_[1] = 0;
  // filter_control_[2] = 0; *)
  FControllers := TControllers.Create(TFmMod.Create, TFmCore.Create);
  FControllers.values_[kControllerPitch] := $2000;
  FSustain                               := false;
  FExtraBufSize                          := 0;
end;




function TSynthUnit.AllocateNote: integer;
var
  NoteIndex, i: integer;
begin
  NoteIndex  := FCurrentNote;
  for i := 0 to High(FActiveNote) do
  begin
    if not FActiveNote[NoteIndex].keydown then
    begin
      FCurrentNote := (NoteIndex + 1) mod max_active_notes;
      Exit(NoteIndex);
    end;
    NoteIndex := (NoteIndex + 1) mod max_active_notes;
  end;
  Result := -1;
end;

procedure TSynthUnit.ProgramChange(p: integer);
var
  patch    : TBulkData;
  LfoParams: TLFOParameters;
begin
  FCurrentPatchIndex := p;
  move(FPatchBankData[128 * FCurrentPatchIndex], patch, 128);
  UnpackPatch(patch, FUnpackedPatch);
  move(FUnpackedPatch[137], LfoParams, SizeOf(LfoParams));
  FLFO.reset(LfoParams);
end;

procedure TSynthUnit.SetController(controller, value: integer);
begin
  FControllers.values_[controller] := value;
end;

procedure WriteLog(s:string);
begin
  OutputDebugString(PChar(s));
end;

function TSynthUnit.ProcessMidiMessage(buf: pbyte; buf_size: integer): integer;
var
  cmd, cmd_type : byte;
  note_ix, controller, value, program_number: integer;
  name : array [0 .. 10] of byte;
  nameStr:string;
begin
  cmd      := buf[0];
  cmd_type := cmd and $F0;
  WriteLog(Format('got %d midi: $%02x $%02x $%02x', [buf_size, buf[0], buf[1], buf[2]]));
  // LOGI();
  case cmd_type of
    $80:
      if buf[2] = 0 then
      begin
        if buf_size >= 3 then
        begin
          // note off
          for note_ix := 0 to high(FActiveNote) do
          begin
            if (FActiveNote[note_ix].midi_note = buf[1]) and FActiveNote[note_ix].keydown then
            begin

              if FSustain then FActiveNote[note_ix].sustained := true
                          else FActiveNote[note_ix].dx7_note.keyup();

              FActiveNote[note_ix].keydown := false;
            end;
          end;
          Exit(3);
        end;
        Exit(0);
      end;
    $90:
      begin
        if buf_size >= 3 then
        begin
          // note on
          note_ix := AllocateNote();
          if note_ix >= 0 then
          begin
            FLFO.KeyDown(); // TODO: should only do this if # keys down was 0
            FActiveNote[note_ix].midi_note := buf[1];
            FActiveNote[note_ix].keydown   := true;
            FActiveNote[note_ix].sustained := FSustain;
            FActiveNote[note_ix].live      := true;
            FActiveNote[note_ix].dx7_note.Create(FUnpackedPatch, buf[1], buf[2]);
          end;
          Exit(3);
        end;
        Exit(0);
      end;
    $B0:
      begin
        if buf_size >= 3 then
        begin
          // controller
          // TODO: move more logic into SetController
          controller := buf[1];
          value      := buf[2];
          (* JJK if (controller = 1) {
            filter_control_[0] := 142365917 + value * 917175;
            } else if (controller = 2) {
            filter_control_[1] := value * 528416;
            } else if (controller = 3) {
            filter_control_[2] := value * 528416;
            } else *)
          if controller = 64 then
          begin
            FSustain := value <> 0;
            if not FSustain then
              for note_ix := 0 to high(FActiveNote) do
                if FActiveNote[note_ix].sustained and not FActiveNote[note_ix].keydown then
                begin
                  FActiveNote[note_ix].dx7_note.keyup();
                  FActiveNote[note_ix].sustained := false;
                end;
          end;
          Exit(3);
        end;
        Exit(0);
      end;

    $C0:
      begin
        if buf_size >= 2 then
        begin
          // program change
          program_number := buf[1];
          ProgramChange(min(program_number, 31));
          move(FUnpackedPatch[145], name[0], 10);
          name[10] := 0;
{$IFDEF DEBUG}
          NameStr:= String(PAnsiChar(@name[0]));
          WriteLog(Format('Loaded patch %d: %s', [FCurrentPatchIndex, NameStr]));
{$ENDIF}
          Exit(2);
        end;
        Exit(0);
      end;
    $E0:
      begin
        // pitch bend
        SetController(kControllerPitch, buf[1] or (buf[2] shl 7));
        Exit(3);
      end;
    $F0:
      begin
        // sysex
        if (buf_size >= 6) and (buf[1] = $43) and (buf[2] = $00) and (buf[3] = $09) and (buf[4] = $20) and (buf[5] = $00) then
        begin
          if buf_size >= 4104 then
          begin
            // TODO: check checksum?
            move(buf[6], FPatchBankData[0], 4096);
            ProgramChange(FCurrentPatchIndex);
            Exit(4104);
          end;
          Exit(0);
        end;
      end;
  end;
  // TODO: more robust handling
{$IFDEF VERBOSE}
  // std.cout shl 'Unknown message ' shl std.hex shl (int)cmd shl ', skipping "  shl  std.dec  shl  buf_size  shl  " bytes' shl std.endl;
{$ENDIF}
  Result := buf_size;
end;

procedure TSynthUnit.GetSamples(n_samples: integer; aBuffer: array of int16);
var
  input_offset                                                                        : size_t;
  note, bytes_consumed, bytes_available, i, j, lfovalue, lfodelay, jmax, val, clip_val: integer;
  bufs                                                                                : PInteger;
  audiobuf, audiobuf2                                                                 : TArray<int32>;
begin
  TransferInput();

  input_offset := 0;
  while input_offset < FInputBufferIndex do
  begin
    bytes_available := FInputBufferIndex - input_offset;
    bytes_consumed  := ProcessMidiMessage(@FInputBuffer[input_offset], bytes_available);
    if bytes_consumed = 0 then
      break;
    input_offset := input_offset + bytes_consumed;
  end;

  ConsumeInput(input_offset);
  i := 0;
  while (i < n_samples) and (i < FExtraBufSize) do
  begin
    aBuffer[i] := FExtraBuf[i];
    inc(i);
  end;

  if FExtraBufSize > n_samples then
  begin
    for j := 0 to FExtraBufSize - n_samples - 1 do
    begin
      FExtraBuf[j] := FExtraBuf[j + n_samples];
    end;
    FExtraBufSize := FExtraBufSize - n_samples;
    Exit;
  end;

  i := 0;
  while i < n_samples do
  begin

    setlength(audiobuf, N);
    setlength(audiobuf2, N);

    for j         := 0 to N - 1 do
      audiobuf[j] := 0;

    lfovalue := FLFO.getSample();
    lfodelay := FLFO.getDelay();
    for note := 0 to High(FActiveNote) do
      if FActiveNote[note].live then
        FActiveNote[note].dx7_note.compute(@audiobuf[0], lfovalue, lfodelay, FControllers);

    // bufs := @audiobuf[0];
    (* JJK int32_t *bufs2[] = { audiobuf2.get() };
      filter_.process(bufs, filter_control_, filter_control_, bufs2); *)
    jmax  := n_samples - i;
    for j := 0 to N - 1 do
    begin
      // JJK int32_t val = audiobuf2.get()[j]  shr  4;
      val := audiobuf[j] shr 4;
      // @@@WvNverify!!
      clip_val := ifthen(val < -(1 shl 24), $8000, ifthen(val >= (1 shl 24), $7FFF, val shr 9));
      // TODO: maybe some dithering?
      if j < jmax then
      begin
        aBuffer[i + j] := clip_val;
      end
      else
      begin
        FExtraBuf[j - jmax] := clip_val;
      end;
    end;
    inc(i, N);
  end;
  FExtraBufSize := i - n_samples;
end;

procedure TSynthUnit.onPatch(const aPatch: TArray<byte>);
var
  bulk   : TBulkData;
  LfoData: TLFOParameters;
begin
  if Length(aPatch) = 128 then
  begin
    move(aPatch[0], bulk, 128);
    UnpackPatch(bulk, FUnpackedPatch)
  end
  else if Length(aPatch) = 145 then
  begin
    move(aPatch[0], FUnpackedPatch[0], Length(aPatch));
    FUnpackedPatch[155] := $3F;
  end;
  move(FUnpackedPatch[137], LfoData.rate, 6);
  FLFO.reset(LfoData);
end;

procedure TSynthUnit.onParam(id: uint32; value: byte);
begin
  FUnpackedPatch[id] := value;
end;

end.
