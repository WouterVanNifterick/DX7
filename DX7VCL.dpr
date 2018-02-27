program DX7VCL;

uses
  Vcl.Forms,
  DX7.Forms.Main in 'DX7.Forms.Main.pas' {frmMain},
  DX7.Config in 'DX7.Config.pas',
  DX7.Envelope in 'DX7.Envelope.pas',
  DX7.LFO in 'DX7.LFO.pas',
  DX7.Op in 'DX7.Op.pas',
  DX7.Voice in 'DX7.Voice.pas',
  DX7.Synth in 'DX7.Synth.pas',
  DX7.SysEx in 'DX7.SysEx.pas',
  Midi in 'Midi.pas',
  superdate in 'C:\dev\lib\SuperObject\superdate.pas',
  SuperObject in 'C:\dev\lib\SuperObject\SuperObject.pas',
  supertimezone in 'C:\dev\lib\SuperObject\supertimezone.pas',
  supertypes in 'C:\dev\lib\SuperObject\supertypes.pas',
  superxmlparser in 'C:\dev\lib\SuperObject\superxmlparser.pas',
  WvN.Audio.Sample.Wave in 'C:\dev\lib\myown\WvN.Audio.Sample.Wave.pas',
  B200.Sysex in 'B200.Sysex.pas',
  DX7.Forms.Op in 'DX7.Forms.Op.pas' {Frame1: TFrame},
  FM.Oscillator in 'FM.Oscillator.pas',
  FS1R.Params in 'FS1R.Params.pas',
  Midi.CircBuf in 'C:\dev\lib\MidiIO\Midi.CircBuf.pas',
  Midi.KeyPatchArray in 'C:\dev\lib\MidiIO\Midi.KeyPatchArray.pas',
  Midi.MidiCallback in 'C:\dev\lib\MidiIO\Midi.MidiCallback.pas',
  Midi.MidiDefs in 'C:\dev\lib\MidiIO\Midi.MidiDefs.pas',
  Midi.MidiFile in 'C:\dev\lib\MidiIO\Midi.MidiFile.pas',
  Midi.MidiIn in 'C:\dev\lib\MidiIO\Midi.MidiIn.pas',
  Midi.MidiOut in 'C:\dev\lib\MidiIO\Midi.MidiOut.pas',
  Midi.MidiPortSelect in 'C:\dev\lib\MidiIO\Midi.MidiPortSelect.pas',
  Midi.MidiScope in 'C:\dev\lib\MidiIO\Midi.MidiScope.pas',
  Midi.MidiType in 'C:\dev\lib\MidiIO\Midi.MidiType.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
