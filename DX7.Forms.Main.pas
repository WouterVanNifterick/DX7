unit DX7.Forms.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Math,
  System.IOUtils,
  DX7.Config,
  DX7.Voice,
  DX7.SysEx,
  DX7.Op,
  FS1R.Params,
  Generics.Collections,
  Generics.Defaults,
  DX7.Synth, Vcl.ExtCtrls,

  DAV_Classes, DAV_AudioData, DAV_AsioHost, DAV_Types,

  System.SyncObjs,

  TypInfo,
  clipbrd,

  System.Actions, Vcl.ActnList,
  Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnMan, DAV_GuiAudioDataDisplay,
  DX7.Forms.Op, Vcl.ComCtrls, Types, Vcl.WinXCtrls, DAV_GuiBaseControl,
  DAV_GuiMidiKeys, DAV_DspComponents,
  Midi.MidiPortSelect, Midi.MidiType, Midi.MidiIn, Vcl.AppEvnts;

type
  TfrmMain = class(TForm)
    GuiTimer: TTimer;
    ASIOHost: TAsioHost;
    ADC: TAudioDataCollection32;
    ActionManager1: TActionManager;
    actPlay: TAction;
    actStop: TAction;
    actPause: TAction;
    Panel1: TPanel;
    AdTimeDomain: TGuiAudioDataDisplay;
    DriverCombo: TComboBox;
    SearchBox1: TSearchBox;
    ListView1: TListView;
    Panel2: TPanel;
    GridPanel1: TGridPanel;
    Frame11: TFrame1;
    Frame12: TFrame1;
    Frame13: TFrame1;
    Frame14: TFrame1;
    Frame15: TFrame1;
    Frame16: TFrame1;
    GuiMidiKeys1: TGuiMidiKeys;
    Memo1: TMemo;
    Panel3: TPanel;
    Algorithm: TScrollBar;
    lblAlgorithm: TLabel;
    Splitter1: TSplitter;
    PatchName: TEdit;
    lblFeedback: TLabel;
    Feedback: TScrollBar;
    MidiInput1: TMidiInput;
    MidiPortSelect1: TMidiPortSelect;
    stat1: TStatusBar;
    ApplicationEvents1: TApplicationEvents;
    procedure LoadParams(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure DriverComboChange(Sender: TObject);
    procedure actPlayExecute(Sender: TObject);
    procedure ASIOHostBufferSwitch32(Sender: TObject; const InBuffer, OutBuffer: TDAVArrayOfSingleFixedArray);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure GuiTimerTimer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure LoadAllPatches(Sender: TObject);
    procedure ListView1Data(Sender: TObject; Item: TListItem);
    procedure ListView1SelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure SearchBox1Change(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure GuiMidiKeys1NoteOff(Sender: TObject; KeyNr: Byte);
    procedure GuiMidiKeys1MouseDownOnMidiKey(Sender: TObject; KeyNr: Byte;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure AlgorithmChange(Sender: TObject);
    procedure MidiInput1MidiInput(Sender: TObject);
    procedure MidiPortSelect1Change(Sender: TObject);
    procedure ApplicationEvents1Hint(Sender: TObject);
    procedure ListView1ColumnClick(Sender: TObject; Column: TListColumn);
    //procedure Panel3Click(Sender: TObject);
  private
    /// <summary>
    /// Convert keyboard input to note number, for keyboard playing
    /// </summary>
    function KeyToNote(key: Word): Integer;
    procedure UpdateFilter;
    procedure SynthToGui;
    procedure LoadBanksOfType(AMask: string);
  public
    Synth : TDX7Synth;
    Octave : integer;
    KeyPressed:array[0..255] of boolean;
    AllPatches:TParamsBank;
    VisiblePatches:TParamsBank;
    FCriticalSection : TCriticalSection;
    OpFrames:array[1..OPERATOR_COUNT] of TFrame1;
    procedure RenderToArray(Samples:TArray<Single>);

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}


procedure TfrmMain.actPlayExecute(Sender: TObject);
begin
 ASIOHost.Active  := True;
 GuiTimer.Enabled := True;
end;


procedure TfrmMain.ASIOHostBufferSwitch32(Sender: TObject; const InBuffer,
  OutBuffer: TDAVArrayOfSingleFixedArray);
var
  Channel: Integer;
  Sample : Integer;
  Samples: TArray<Single>;
const
  delayMilliseconds = 50;                              // half a second
  delaySamples      = Round(delayMilliseconds * 44.1); // assumes 44100 Hz sample rate
  decay             = 0.5;
begin
  FCriticalSection.Enter;
  try
    SetLength(Samples, ASIOHost.BufferSize);
    RenderToArray(Samples);

    for Sample := 0 to ASIOHost.BufferSize - 1 do
    begin
      for Channel := 0 to ASIOHost.OutputChannelCount - 1 do
      begin
        OutBuffer[Channel, Sample] := Samples[Sample];
        // OutBuffer[Channel, Sample] := 0;
      end;
    end;

//    //
//     for Sample := 0 to ASIOHost.BufferSize - delaySamples - 1 do
//     begin
//     for Channel := 0 to ASIOHost.OutputChannelCount - 1 do
//     begin
//     OutBuffer[Channel,Sample + delaySamples] := OutBuffer[Channel,Sample + delaySamples] + (OutBuffer[Channel,Sample] * decay);
//     end;
//     end;
//    //

    // update waveform
    {
    ADC.ChannelCount := Min(2, ASIOHost.OutputChannelCount);
    ADC.SampleFrames := Max(256, ASIOHost.BufferSize);
    for Channel      := 0 to ADC.ChannelCount - 1 do
      Move(OutBuffer[Channel, 0], ADC[Channel].ChannelDataPointer^[0], ADC.SampleFrames * SizeOf(Single));
}
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TfrmMain.LoadParams(Sender: TObject);
begin

{
See: http://www.mattmontag.com/projects/speech/rosenberg.m

Description: this function accepts fundamental frequency of the glottal signal
             and the sampling frequency in hertz as input and returns one
             period of the rosenberg pulse at the specified frequency.

Parameters:  DutyCycle : duty cycle of the pulse, from 0 to 1.
               GlotDur : the duration of the glottal opening as a fraction of
                         the total pulse, from 0 to 1.
                    F0 : the fundamental pitch frequency, in Hz
                    SR : is the Sample frequency, as samples per second
}
{
function rosenberg(DutyCycle,GlotDur,FP:double;SR:integer):TWaveformSamplesSingle;
var T:Double;
L1,L2,n,pulselength:integer;
begin
  Assert(InRange(DutyCycle,0,1));
  Assert(InRange(GlotDur,0,1));
  Assert(InRange(FP,1,SR div 2));
  Assert(InRange(SR,4000,96000));

  T:= 1/FP; // period in seconds
  pulselength:=floor(T*SR);    // length of one period of pulse
  // select N1 and N2 for duty cycle
  L2:=floor(pulselength*GlotDur);
  L1:=floor(DutyCycle*L2);

  Assert(L2-L1<>0);

  Setlength(Result,PulseLength);
  // calculate pulse samples
  for n:=1 to L1-1 do
    Result[n] := 0.5*(1-cos(pi*(n-1)/L1));
  for n:=L1 to L2-1 do
    Result[n] := cos(pi*(n-L1)/(L2-L1)/2);
end;
}
end;

procedure TfrmMain.MidiInput1MidiInput(Sender: TObject);
var mev:TMyMidiEvent; ev:dx7.Synth.TMidiEvent;
begin
  mev := MidiInput1.GetMidiEvent;
  if mev=nil then
    Exit;

  try
    if Synth=nil then
      Exit;

    setlength(ev.data,3);
    ev.data[0] := mev.MidiMessage;
    ev.data[1] := mev.Data1;
    ev.data[2] := mev.Data2;
    ev.receivedTime := now;
    Synth.processMidiEvent(ev);
  finally
    mev.Free;
  end;
end;

procedure TfrmMain.MidiPortSelect1Change(Sender: TObject);
begin
  MidiInput1.DeviceID := MidiPortSelect1.ItemIndex;
  MidiInput1.OpenAndStart;

end;

{
procedure TfrmMain.Panel3Click(Sender: TObject);
var p:TVoiceParams; v:TVoiceParamsSysex; op:integer;
begin
  v := ReadVoiceFromFile('c:\project\fs1r\Patches\CYBER_3.syx');

  p.name              := v.Common.Name;
  p.IndexInBank       := 0;
  p.algorithm         := v.Common.Algorithm;
  p.feedback          := v.Common.FeedBack;
  p.lfo.Speed         := v.Common.LFO1.Speed;
  p.lfo.Delay         := v.Common.LFO1.Delay;
  p.lfo.PitchModDepth := v.Common.LFO1.PMD;
  p.lfo.AmpModDepth   := v.Common.LFO1.AMD;
  p.lfo.PitchModSens  := v.Common.LFO1.FMD;
  p.lfo.Sync          := v.Common.LFO1.Sync<>0;
  p.lfo.Waveform      := DX7.Params.TLFOWaveForm(v.Common.LFO1.WaveForm);
  p.transpose         := v.Common.NoteShift;
  p.pitchEnvelope.Rates[0]  := v.Common.PitchEG.Envelope.Rates[0];
  p.pitchEnvelope.Rates[1]  := v.Common.PitchEG.Envelope.Rates[1];
  p.pitchEnvelope.Rates[2]  := v.Common.PitchEG.Envelope.Rates[2];
  p.pitchEnvelope.Rates[3]  := v.Common.PitchEG.Envelope.Rates[3];
  p.pitchEnvelope.Levels[0] := v.Common.PitchEG.Envelope.Levels[0];
  p.pitchEnvelope.Levels[1] := v.Common.PitchEG.Envelope.Levels[1];
  p.pitchEnvelope.Levels[2] := v.Common.PitchEG.Envelope.Levels[2];
  p.pitchEnvelope.Levels[3] := v.Common.PitchEG.Envelope.Levels[3];
  for op := 0 to OPERATOR_COUNT-1 do
  begin
    p.operators[op].idx     := op;
    p.operators[op].enabled := v.Operators[op].Voiced.LevelScaling.TotalLvl>0;
    p.operators[op].envelope.Levels[0] := v.Operators[op].Voiced.EG.Envelope.Levels[0];
    p.operators[op].envelope.Levels[1] := v.Operators[op].Voiced.EG.Envelope.Levels[1];
    p.operators[op].envelope.Levels[2] := v.Operators[op].Voiced.EG.Envelope.Levels[2];
    p.operators[op].envelope.Levels[3] := v.Operators[op].Voiced.EG.Envelope.Levels[3];
    p.operators[op].envelope.Rates [0] := v.Operators[op].Voiced.EG.Envelope.Rates[0];
    p.operators[op].envelope.Rates [1] := v.Operators[op].Voiced.EG.Envelope.Rates[1];
    p.operators[op].envelope.Rates [2] := v.Operators[op].Voiced.EG.Envelope.Rates[2];
    p.operators[op].envelope.Rates [3] := v.Operators[op].Voiced.EG.Envelope.Rates[3];
//    p.operators[op].detune  := v.Operators[op].Voiced. Osc.FrDetune;
//    p.operators[op].velocitySens := v.Op[op].Voiced.AmpMod; // ??
    p.operators[op].lfoAmpModSens     := v.Operators[op].Voiced.AmpModSense_AmpVelSense; // div $;
    p.operators[op].volume            := v.Operators[op].Voiced.LevelScaling.TotalLvl;
//    p.operators[op].oscMode           := TOscFreqMode(v.Operators[op].Voiced.FrModS_FVS);
    p.operators[op].freqCoarse        := v.Operators[op].Voiced.FrCoarse;
    p.operators[op].freqFine          := v.Operators[op].Voiced.FrFine;

    p.operators[op].keyScale.Breakpoint := Ord(v.Operators[op].Voiced.LevelScaling.BreakPoint);
    p.operators[op].keyScale.LeftDpt    := v.Operators[op].Voiced.LevelScaling.LeftDpt;
    p.operators[op].keyScale.RightDpt   := v.Operators[op].Voiced.LevelScaling.RightDpt;
    p.operators[op].keyScale.LeftCurve  := v.Operators[op].Voiced.LevelScaling.LeftCurve;
    p.operators[op].keyScale.RightCurve := v.Operators[op].Voiced.LevelScaling.RightCurve;
    p.operators[op].keyScale.Rate       := v.Operators[op].Voiced.LevelScaling.TotalLvl; // ???

  end;
//  Synth.params := p; @@@
  Synth.allNotesOff;

  SynthToGui;

end;
}

procedure TfrmMain.Button2Click(Sender: TObject);
begin
{  MidiFile1.ReadFile;
  MidiFile1.OnMidiEvent := procedure (ev:TMidiEvent)
    begin
      FCriticalSection.Enter;
      case ev.Event of
        $80..$8f:
          Synth.noteOff(ev.Data1);
        $90..$9f:
          Synth.noteOn(ev.Data1,ev.Data2);
      end;
      FCriticalSection.Leave;
    end;
  MidiFile1.StartPlaying;
}
end;

procedure TfrmMain.LoadAllPatches(Sender: TObject);
var
  p:TVoiceParams;
begin
  AllPatches := TParamsBank.Create;
  VisiblePatches := TParamsBank.Create;
  LoadBanksOfType('*.syx');
  LoadBanksOfType('*.dx7');
  UpdateFilter;
end;

procedure TfrmMain.AlgorithmChange(Sender: TObject);
begin
  Synth.params.Common.Algorithm := Algorithm.Position;
  lblAlgorithm.Caption := 'Algorithm: '+ IntToStr(Synth.params.Common.Algorithm+1);

  Synth.params.Common.FeedBack := Feedback.Position;
  lblFeedback.Caption := 'Feedback: '+ IntToStr(Synth.params.Common.FeedBack);
end;

procedure TfrmMain.ApplicationEvents1Hint(Sender: TObject);
begin
  stat1.Panels[0].Text := Application.Hint;
end;

procedure TfrmMain.SearchBox1Change(Sender: TObject);
begin
  UpdateFilter;
end;

procedure TfrmMain.UpdateFilter;
var i,j:integer;s:string;
begin
  s := SearchBox1.Text;
  s := s.Trim.ToLower;
  VisiblePatches.Count := 0;
  for I := 0 to AllPatches.Count-1 do
    if (S='') or string(AllPatches[I].Common.Name).ToLower.Contains(S) then
    begin
      VisiblePatches.Add(AllPatches[I]);
    end;

  VisiblePatches.SortByPatchName;

  ListView1.Items.Count := VisiblePatches.Count;
  ListView1.Refresh;



end;

procedure TfrmMain.RenderToArray(Samples:TArray<single>);
var
  i           : integer;
  LSample:double;
begin
  if not Assigned(Synth) then
    exit;

  for i := 0 to high(Samples) do
  begin
{
    case i of
          0: Synth.noteOn(60, 90);
       5000: Synth.noteOn(60 + 3, 90);
      10000: Synth.noteOn(60 + 7, 90);
      60100: begin
               Synth.noteOff(60);
               Synth.noteOff(60 + 3);
               Synth.noteOff(60 + 7);
             end;
     end;

    if i>28000 then
      Synth.pitchBend((i-28000)/high(Samples));
}
    LSample := Synth.render;

    Samples[i] := LSample*2 {ensureRange(r[0],-1,1)};
  end;
end;

procedure TfrmMain.LoadBanksOfType(AMask: string);
var
  files: TStringDynArray;
  f: string;
  pb: TParamsBank;
  i: Integer;
begin
  files := TDirectory.GetFiles('c:\Users\Wouter\Documents\Embarcadero\Studio\Projects\DX7\Patches\', AMask, TSearchOption.soAllDirectories);
  for f in files do
  begin
    pb := TParamsBank.Create;
    try
      TSysexDX7.loadBank(f, pb);
      for I := 0 to pb.Count - 1 do
      //      if pb[I].OpsUsed > 0 then @@@
      begin
        pb[i].SetBankName(ChangeFileExt(ExtractFileName(f), ''));
        AllPatches.Add(pb[I]);
      end;
    finally
      pb.Free;
    end;
  end;
end;

procedure TfrmMain.SynthToGui;
var
  f: TFrame1;
begin
  Algorithm.Position  := Synth.params.Common.Algorithm;
  PatchName.Text      := Synth.params.Common.Name;
  Feedback.Position   := Synth.params.Common.FeedBack;
  for f in TArray<TFrame1>.Create(Frame11, Frame12, Frame13, Frame14, Frame15, Frame16) do
    f.ParamsToGui(Synth.params.Operators[f.Tag - 1].Voiced);
end;

function TfrmMain.KeyToNote(Key: Word):integer;
begin
  case key of
    90:  Result := 48;
    83:  Result := 49;
    88:  Result := 50;
    68:  Result := 51;
    67:  Result := 52;
    86:  Result := 53;
    71:  Result := 54;
    66:  Result := 55;
    72:  Result := 56;
    78:  Result := 57;
    74:  Result := 58;
    77:  Result := 59;
    188: Result := 60;
    76:  Result := 61;
    190: Result := 62;
    186: Result := 63;
    191: Result := 64;
    81:  Result := 60;
    50:  Result := 61;
    87:  Result := 62;
    51:  Result := 63;
    69:  Result := 64;
    82:  Result := 65;
    53:  Result := 66;
    84:  Result := 67;
    54:  Result := 68;
    89:  Result := 69;
    55:  Result := 70;
    85:  Result := 71;
    73:  Result := 72;
    57:  Result := 73;
    79:  Result := 74;
    48:  Result := 75;
    80:  Result := 76;
    219: Result := 77;
    187: Result := 78;
    221: Result := 79;
  else
    Result := 0;
  end;
end;

procedure TfrmMain.ListView1ColumnClick(Sender: TObject;
  Column: TListColumn);
begin
  case Column.Index of
    0: ;
    1: VisiblePatches.SortByBankName;
    2: VisiblePatches.SortByPatchName;
    3: VisiblePatches.SortByAlgorithm;
    4: VisiblePatches.SortByOpsCount;
  end;
  ListView1.Refresh;
end;

procedure TfrmMain.ListView1Data(Sender: TObject; Item: TListItem);
begin
  if Item.Index>=VisiblePatches.Count then
    Exit;

  FCriticalSection.Enter;


  with VisiblePatches[Item.Index] do
  begin
    Item.Caption := Item.Index.ToString;
    Item.SubItems.Add( BankName );
    Item.SubItems.Add( Common.Name );
    Item.SubItems.Add( IntToStr(Common.Algorithm+1) );
    Item.SubItems.Add( IntToStr(GetOpsCount) );
  end;

  FCriticalSection.Release;
end;

procedure TfrmMain.ListView1SelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
var
  Params:TVoiceParams;
begin
  if Item = nil then
    Exit;

  if Item.index<0 then
    Exit;

  Params := VisiblePatches[Item.Index];
//  Memo1.Lines.Text := Params.CSV;

  if not Assigned(Synth) then
    Synth := TDX7Synth.Create(Params)
  else
    Synth.params := Params;

  SynthToGui;
end;

procedure TfrmMain.DriverComboChange(Sender: TObject);
begin
 DriverCombo.ItemIndex := DriverCombo.Items.IndexOf(DriverCombo.Text);
 if DriverCombo.ItemIndex >= 0 then
  begin
   ASIOHost.DriverIndex := DriverCombo.ItemIndex;
   ASIOHost.Active  := True;
   GuiTimer.Enabled := True;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  I: Integer;
begin
//  DirectoryListBox1.Directory := 'c:\Users\Wouter\Documents\Embarcadero\Studio\Projects\DX7\Patches\AJay';
  Octave := 1;

  FCriticalSection := TCriticalSection.Create;

  DriverCombo.Items := ASIOHost.DriverList;
  if DriverCombo.Items.Count = 0 then
    try
      raise Exception.Create('No ASIO Driver present! Application Terminated!');
    except
      Application.Terminate;
    end;

  LoadAllPatches(Sender);

  DriverCombo.ItemIndex := 0;
  DriverCombo.OnChange(nil);

  OpFrames[1] := Frame11;
  OpFrames[2] := Frame12;
  OpFrames[3] := Frame13;
  OpFrames[4] := Frame14;
  OpFrames[5] := Frame15;
  OpFrames[6] := Frame16;

  for I := Low(OpFrames) to High(OpFrames) do
  begin
    if OpFrames[I]=nil then
      Continue;

    OpFrames[I].Tag := I;
    OpFrames[I].lblCaption.Caption := Format('Op %d',[I]);
  end;
end;





procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  ASIOHost.Active := False;

  if Assigned(Synth) then
    Synth.Free;
end;

procedure TfrmMain.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var r,note:integer;
begin
  if KeyPressed[key] then
    Exit;

  if Synth=nil then
    Exit;

  Note := KeyToNote(Key);
  if note < 1 then
    exit;

  Note := Note + Octave * 12;


  r := Random(40)-20;
  Synth.noteOn(Note,60+r);

  GuiMidiKeys1.SetKeyPressed( Note, True );
  KeyPressed[key]  := True;
end;

procedure TfrmMain.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var note:integer;
begin
  if Synth=nil then Exit;

  // Slash    (/) for octave down
  // Asterisk (*) for octave up
  case key of
    111:
      begin
        dec(Octave);
        Exit;
      end;
    106:
      begin
        inc(Octave);
        Exit;
      end;
  end;

  Note := KeyToNote(Key);
  if note < 1 then
  begin
    exit;
  end;

  Note := Note + Octave*12;

  GuiMidiKeys1.ReleaseKey( Note, False );
  Synth.noteOff(Note);
  KeyPressed[key]  := False;
end;

procedure TfrmMain.GuiMidiKeys1MouseDownOnMidiKey(Sender: TObject; KeyNr: Byte;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  vel:byte;
begin
  if Synth=nil then Exit;

  vel := trunc(127*y/GuiMidiKeys1.Height);
  Synth.noteOn(KeyNr,vel);
end;

procedure TfrmMain.GuiMidiKeys1NoteOff(Sender: TObject; KeyNr: Byte);
begin
  if Synth=nil then Exit;

  Synth.noteOff(KeyNr);
end;

var InTimer:Boolean;
procedure TfrmMain.GuiTimerTimer(Sender: TObject);
var i,v:integer; o:double;
begin

  if synth=nil then
    Exit;
  Synth.Lock.Acquire;

  if InTimer then
    Exit;

  InTimer := True;
  GuiTimer.Enabled := False;
  try

    AdTimeDomain.Refresh;
    if Synth=nil then
      Exit;

    if synth.VoiceCount=0 then
      Exit;

    v := Synth.VoiceCount-1;
    for I := 1 to Length(OpFrames) do
      if OpFrames[I]<>nil then
      begin
        o := Synth.EnvOutput[I-1];
        if InRange(o,0,1) then
        begin
          OpFrames[I].ProgressBar1.Position := round(o * OpFrames[I].ProgressBar1.Max);
          OpFrames[I].PaintBox1Paint(nil);
        end;
      end;
      Caption := Synth.VoiceCount.ToString;
  finally
    GuiTimer.Enabled := True;
    InTimer := False;
    Synth.Lock.Release;
  end;
end;

end.
