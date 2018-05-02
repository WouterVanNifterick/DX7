unit DX7.Synth;

interface

uses
  System.SyncObjs,
  Generics.Collections,
  DX7.Config,
  FS1R.Params,
  DX7.Voice;

type
  TMidiEvent = record
    data: array of byte;
    receivedTime: TDateTime;
  end;

  TDX7Synth = class
  private
    voices: TList<TDX7Voice>;
    sustainPedalDown: boolean;
    function GetVoiceCount: integer;
    function GetEnvOutput(index: integer): double;
  public
    Lock:TCriticalSection;
    params:TVoiceParams;
    constructor Create(const aParams:TVoiceParams);
    destructor Destroy; override;

    procedure processMidiEvent(ev: TMidiEvent);
    procedure controller(controlNumber, value: integer);
    procedure channelAftertouch(value: integer);
    procedure sustainPedal(down: boolean);
    procedure pitchBend(value:double);
    procedure noteOn(note, velocity: integer);
    procedure noteOff(note: integer);
    procedure allNotesOff;
    procedure panic;
    function getVoices(note:integer):TArray<integer>;
    function render: double;

    property EnvOutput[index:integer]:double read GetEnvOutput;
    property VoiceCount:integer read GetVoiceCount;


  end;

implementation

const
  PER_VOICE_LEVEL       = 0.125 / OPERATOR_COUNT; // nominal per-voice level borrowed from Hexter
  PITCH_BEND_RANGE      = 12;         // semitones (in each direction)

  MIDI_CC_MODULATION    = 1;
  MIDI_CC_SUSTAIN_PEDAL = 64;

  // TODO: Probably reduce responsibility to voice management; rename VoiceManager, MIDIChannel, etc.

constructor TDX7Synth.Create(const aParams:TVoiceParams);
begin
  Lock := TCriticalSection.Create;
  self.voices           := TList<TDX7Voice>.Create;
  self.sustainPedalDown := false;
  params                := aParams;
end;

destructor TDX7Synth.Destroy;
begin
  allNotesOff;
  inherited;
end;

function TDX7Synth.GetEnvOutput(index: integer): double;
begin
  if voices.Count=0 then
    Exit(0);

  Result := voices[0].operators[Index].Envelope.CurrentOutput;
end;

function TDX7Synth.GetVoiceCount: integer;
begin
  Lock.Acquire;
  Result := voices.Count;
  Lock.Release;
end;

function TDX7Synth.getVoices(note: integer): TArray<integer>;
var
  i    : integer;
begin
  Result := [];
  for i := 0 to voices.Count - 1 do
    if (voices[i].Note = note) {and voices[i].IsDown} then
      Result := Result + [i];
end;

procedure TDX7Synth.processMidiEvent(ev: TMidiEvent);
var
  cmd, channel, noteNumber, velocity: byte;
begin
  Lock.Acquire;
  try

    cmd        := ev.data[0] shr 4;
    channel    := ev.data[0] and $F;
    noteNumber := ev.data[1];
    velocity   := ev.data[2];
    // console.log( "" + ev.data[0] + " " + ev.data[1] + " " + ev.data[2])
    // console.log("midi: ch %d, cmd %d, note %d, vel %d", channel, cmd, noteNumber, velocity);

    // Ignore drum channel
    if (channel = 9) then
      exit;

    // with MIDI, note on with velocity zero is the same as note off
    case cmd of
      8: self.noteOff(noteNumber);
      9: begin
            if velocity = 0 then
              self.noteOff(noteNumber)
            else
              self.noteOn(noteNumber, {round(velocity / 99)} velocity);
             // changed 127 to 99 to incorporate "overdrive"
         end;
      // 10: self.polyphonicAftertouch(noteNumber, velocity/127);
      11: self.controller(noteNumber, round(velocity / 127));
      // 12: self.programChange(noteNumber);
      13: self.channelAftertouch(round(noteNumber / 127));
      14: self.pitchBend(round(((velocity * 128 + noteNumber) - 8192) / 8192));
    end;
  finally
    Lock.Release;
  end;
end;

procedure TDX7Synth.controller(controlNumber, value: integer);
var I: Integer;
begin
  // see http://www.midi.org/techspecs/midimessages.php#3

  case (controlNumber) of
    MIDI_CC_MODULATION:
      for I := 0 to Self.voices.Count-1 do
        self.voices[I].modulationWheel(value);
    MIDI_CC_SUSTAIN_PEDAL:
      self.sustainPedal(value > 0.5);
  end;
end;

procedure TDX7Synth.allNotesOff;
var
  i    : integer;
begin
  for i := 0 to voices.Count - 1 do
  begin

    if voices[i].IsDown then
    begin
      voices[i].IsDown := false;
      if not self.sustainPedalDown then
        voices[i].noteOff();
    end;
  end;
end;

procedure TDX7Synth.channelAftertouch(value: integer);
var I: Integer;
begin
  for I := 0 to voices.Count-1 do
    voices[I].channelAftertouch(value);
end;

procedure TDX7Synth.sustainPedal(down: boolean);
var  i: integer;
begin
  if down then
    self.sustainPedalDown := true
  else
  begin
    self.sustainPedalDown := false;
    for i := 0 to voices.Count-1 do
      if not self.voices[i].IsDown then
        self.voices[i].noteOff();
  end;
end;

procedure TDX7Synth.pitchBend(value: double);
var  i: integer;
begin
  for i := 0 to voices.Count - 1 do
  begin
    self.voices[i].SetPitchBend(value * PITCH_BEND_RANGE);
    self.voices[i].updatePitchBend();
  end;
end;

procedure TDX7Synth.noteOn(note, velocity: integer);
var
  Voice: TDX7Voice;
begin
  Lock.Acquire;

  try
    if self.voices.Count >= config.polyphony then
    begin
      // TODO: fade out removed voices
      // self.voices.shift(); // remove first
      Voices.Delete(0);
    end;
    Voice := TDX7Voice.Create(note, velocity, @params);
    voices.Add(Voice);
  finally
    Lock.Release;
  end;
end;

procedure TDX7Synth.noteOff(note: integer);
var
  i    : integer;
  Voice: TDX7Voice;
begin
  for i := 0 to voices.Count - 1 do
  begin
    Voice := voices[i];
    if (Voice.Note = note) and Voice.IsDown then
    begin
      Voice.IsDown := false;
      if not self.sustainPedalDown then
        Voice.noteOff();
     // if we know for sure that one note is only playing once, then we can break.
     // but we don't have guarantees, so let's make sure that we don't get "hanging" notes
     //      break;
    end;
  end;
end;

procedure TDX7Synth.panic();
var
  i: integer;
begin
  self.sustainPedalDown := false;
  for i := 0 to voices.Count - 1 do
  begin
    // if self.voices[i] then
    self.voices[i].noteOff();
  end;
  voices.Clear;
end;


var
  IsRendering:Boolean;

function TDX7Synth.render(): double;
var
  output : double;
  i      : integer;
begin
  if IsRendering then
    Exit;

  IsRendering := True;

  if self=nil then
    Exit(0);

  output := 0;
  for i := voices.Count - 1  downto 0 do
  begin
    if self.voices[i].isFinished then
      Voices.Delete(i)
    else
      output  := output + voices[i].render;
  end;
  Result := output * PER_VOICE_LEVEL;

  IsRendering := False;
end;

end.
