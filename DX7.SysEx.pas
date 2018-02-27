unit DX7.SysEx;

interface

uses
  DX7.Config,
  DX7.Voice,
  Midi,
  FS1R.Params;

type
  TMidiByte=byte;
  TMidiBytes=TArray<TMidiByte>;
  TSysexDX7 = record
    class procedure loadBank(const aBankData: TMidiBytes; aBank:TParamsBank; aBankName:string);overload;static;
    class procedure loadBank(aFileName:string;Bank:TParamsBank);overload;static;
    class function extractPatchFromRom(const bankData: TMidiBytes; patchId: integer; var p:TVoiceParams): Boolean;static;
  private
  end;

implementation

uses Math, SysUtils, IoUtils;

  // Expects bankData to be a DX7 SYSEX Bulk Data for 32 Voices
class procedure TSysexDX7.loadBank(const aBankData: TArray<TMidiByte>; aBank:TParamsBank; aBankName:string);
var i:integer; p:TVoiceParams;
begin
  for i := 0 to (length(aBankData) div 128)-1 do
  begin
    if not extractPatchFromRom(aBankData, i, p) then
      Continue;

    p.BankName := aBankName;

    if p.Common.Algorithm > 32 then
      Exit;

    if string(p.Common.Name).Replace('-','').IsEmpty then
      Continue;

    if p.GetOpsCount = 0 then
      Continue;

    aBank.Add(p)
  end;
end;

class procedure TSysexDX7.loadBank(aFileName: string; Bank:TParamsBank);
begin
  TSysexDX7.loadBank( TFile.ReadAllBytes(aFileName) , Bank, ChangeFileExt(ExtractFileName(aFileName),''));
end;


// see http://homepages.abdn.ac.uk/mth192/pages/dx7/sysex-format.txt
// Section F: Data Structure: Bulk Dump Packed Format


class function TSysexDX7.extractPatchFromRom(const bankData: TMidiBytes; patchId: integer; var p:TVoiceParams): Boolean;
var
  i,j             : integer;
  dataStart       : integer;
  dataEnd         : integer;
  voiceData       : TArray<byte>;
  oscStart, oscEnd: integer;
  oscData         : TArray<byte>;
  op              : ^TFS1ROperator;
begin
  p := Default(TVoiceParams);
  dataStart := 128 * patchId {+ 6};
  if (Length(bankData) mod 128)<>0 then
    dataStart := dataStart + 6;

  dataEnd   := dataStart + 128;
  // voiceData := bankData.substring(dataStart, dataEnd);
  setlength(voiceData, dataEnd - dataStart);
  Move(bankData[dataStart], voiceData[0], dataEnd - dataStart);
  p.IndexInBank := PatchID;

//  setlength(Result.operators,OPERATOR_COUNT);
  for i := 0 to OPERATOR_COUNT - 1 do
    p.operators[i] := default(TFS1ROperator);

  for i := 5 downto 0 do
  begin
    oscStart := (5 - i) * 17;
    oscEnd   := oscStart + 17;
    setlength(oscData, oscEnd - oscStart);
    Move(voiceData[oscStart], oscData[0], oscEnd - oscStart);

    op := @p.operators[i];
    op^ := default(TFS1ROperator);
    for j := 0 to 3 do
    begin
      if not InRange(oscData[0+j], low(op.Voiced.EG.Envelope.Rates[j]), high(op.Voiced.EG.Envelope.Rates[j])) then
        Exit(False);
      if not InRange(oscData[4+j], low(op.Voiced.EG.Envelope.Levels[j]), high(op.Voiced.EG.Envelope.Levels[j])) then
        Exit(False);
    end;


    op.Voiced.EG.Envelope.Rates [0] := oscData[0];
    op.Voiced.EG.Envelope.Rates [1] := oscData[1];
    op.Voiced.EG.Envelope.Rates [2] := oscData[2];
    op.Voiced.EG.Envelope.Rates [3] := oscData[3];

    op.Voiced.EG.Envelope.Levels[0] := oscData[4];
    op.Voiced.EG.Envelope.Levels[1] := oscData[5];
    op.Voiced.EG.Envelope.Levels[2] := oscData[6];
    op.Voiced.EG.Envelope.Levels[3] := oscData[7];

    {$R-}
    op.Voiced.LevelScaling.Breakpoint := TBreakPoint(oscData[8]);
    op.Voiced.LevelScaling.LeftDpt    := oscData[9];
    op.Voiced.LevelScaling.RightDpt   := oscData[10];
    if not InRange(oscData[11] and 3, 0, 3) then
      Exit(False);
    op.Voiced.LevelScaling.LeftCurve  := TCurve( oscData[11] and 3 );

    if not InRange(oscData[11] shr 2 and 3, 0, 3) then
      Exit(False);
    op.Voiced.LevelScaling.RightCurve := TCurve( oscData[11] shr 2 );

    op.Voiced.EG.TimeScale := oscData[12] and 7; // rate?
    op.Voiced.Osc.FrDetune := (oscData[12] shr 3); // range 0 to 14

    op.Voiced.Sensitivity.AmpModSense {op.lfoAmpModSens}    := oscData[13] and 3;
    op.Voiced.Sensitivity.AmpVelSense {op.velocitySens}     := oscData[13] shr 2;
    op.Voiced.LevelScaling.TotalLvl {op.volume} := oscData[14];

    op.Voiced.Osc.OscMode            := TOscModeVoiced(oscData[15] and 1);
    op.Voiced.Osc.FreqCoarse         := oscData[15] shr 1;
    op.Voiced.Osc.freqFine           := oscData[16];
  end;

  p.Common.PitchEG.Envelope.Rates[0] := voiceData[102];
  p.Common.PitchEG.Envelope.Rates[1] := voiceData[103];
  p.Common.PitchEG.Envelope.Rates[2] := voiceData[104];
  p.Common.PitchEG.Envelope.Rates[3] := voiceData[105];

  p.Common.PitchEG.Envelope.Rates[0] := voiceData[106];
  p.Common.PitchEG.Envelope.Rates[1] := voiceData[107];
  p.Common.PitchEG.Envelope.Rates[2] := voiceData[108];
  p.Common.PitchEG.Envelope.Rates[3] := voiceData[109];

  p.Common.Algorithm                 := voiceData[110];
  p.Common.FeedBack                  := voiceData[111] and 7;
  if not InRange(voiceData[112], Low(p.Common.LFO1.Speed), High(p.Common.LFO1.Speed))  then
  begin
    Exit(False);
  end;

  p.Common.LFO1.Speed                := voiceData[112];
  p.Common.LFO1.Delay                := voiceData[113];
  p.Common.LFO1.PMD                  := voiceData[114];
  p.Common.LFO1.AMD                  := voiceData[115];

  p.Common.LFO1.Sync                 := voiceData[116] and 1;
  p.Common.LFO1.Waveform             := TLFOWaveForm( (voiceData[116] shr 1) and 7 );

  p.Common.LFO1.FMD {PitchModSens}   := voiceData[116] shr 4;

  p.Common.NoteShift {transpose}     := voiceData[117];
//  p.Common.Name                      := AnsiString(TEncoding.ASCII.GetString(voiceData, 118, 10));
  move(voicedata[118],p.Common.Name[low(p.Common.Name)],10);
  p.controllerModVal        := 0;
  p.aftertouchEnabled       := false;
  Result := True;

end;



end.
