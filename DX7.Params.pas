unit DX7.Params;

interface



type
  TLFOWaveForm  =(Triangle,SawDown,SawUp,Square,Sine,SampleHold);
  TLFODelay =(Onset,Ramp,Complete);

  TVelocitySens= 0..7;
  TSysexVal    = 0..127;
  T0_99        = 0..99;
//  T0_3         = 0..3;
  TDetune      =-7..7;
  TLevels      = Array[0..3] of T0_99;
  TRates       = Array[0..3] of T0_99;

  TEnvelopeParams=record
      Rates:TRates;
      Levels:TLevels;
  end;

  TOscFreqMode=(Coarse,Fixed);
const
  cOscFreqModeShortStr:array[TOscFreqMode]of string=('C','F');
  cOscFreqModeStr:array[TOscFreqMode]of string=('Coarse','Fixed');

  {
type

  PParams=^TDX7Params;
  TDX7Params=record
  type
    TOpParams=record
    public
      idx               : TSysexVal;
      enabled           : boolean;
      envelope          : TEnvelopeParams;
      /// <summary>
      /// Detune -7 .. 7
      /// </summary>
      detune            : TDetune;
      velocitySens      : TVelocitySens;
      lfoAmpModSens     : 0 .. 3;
      volume            : TSysexVal;
      oscMode           : TOscFreqMode;
      freqCoarse        : 0 .. 31;
      freqFine          : 0 .. 99;

      keyScale:record
        Breakpoint : T0_99;
        LeftDpt    : T0_99;
        RightDpt   : T0_99;
        LeftCurve  : TCurve;
        RightCurve : TCurve;
        Rate       : TSysexVal;
      end;

      pan               : Double;
      outputLevel       : Double;
      ampL, ampR        : Double;
//      freqRatio         : Double;
//      freqFixed         : Double;
//      procedure UpdateFreq;
    end;
  private
    function GetBankName:string;
    function GetOpsUsed:integer;
  public
    FileName:string;
    IndexInBank:integer;
    name:string;
    algorithm:TSysexVal;
    feedback:0..7;
    lfo:record
      Speed:0..99;
      Delay:0..99;
      PitchModDepth:0..99;
      AmpModDepth:0..99;
      PitchModSens:0..7;
      Sync: Boolean;
      Waveform: TLFOWaveForm;
    end;
		transpose: 0..48; // 12 = C2

    pitchEnvelope:TEnvelopeParams;

    aftertouchEnabled:boolean;

    operators:array[0..OPERATOR_COUNT-1] of TOpParams;

    controllerModVal:double;
    fbRatio:double;

 //   class function GetDefault:TParams;static;


    function GetCSV:string;
    property CSV:string read GetCSV;
    property BankName:String read GetBankName;
    property OpsUsed:Integer read GetOpsUsed;

  end;
}

implementation

uses Math, SysUtils, StrUtils;

(*
function TDX7Params.GetOpsUsed:integer;
var i:integer;
begin
  Result := 0;
  for I := Low(operators) to High(operators) do
    if operators[I].enabled and (Operators[I].volume>0) then
      Inc(Result);
end;

function TDX7Params.GetBankName:string;
begin
  Result := ChangeFileExt(ExtractFileName(FileName),'');
end;


function TDX7Params.GetCSV:string;
var sb:TStringBuilder; o,i:integer; op:^TOpParams;f:ShortString;
begin
  sb := TStringBuilder.Create;
  sb.Append('Name       : '); sb.Append(name            );  sb.AppendLine;
  sb.Append('Alg        : '); sb.Append(1+self.algorithm);  sb.AppendLine;
  sb.Append('Transpose  : '); sb.Append(self.transpose  );  sb.AppendLine;
  sb.Append('Aftertouch : '); sb.Append(ifthen(self.aftertouchEnabled,'On','Off')); sb.AppendLine;
  sb.Append('FeedbackLvl: '); sb.Append(self.feedback   ); sb.AppendLine;


  sb.AppendLine;

  sb.Append('Op Mode Freq  D ');
  // header
  for I := 0 to 3 do
  begin
    sb.Append(format('R%d L%d ',[i, i]));
  end;
  sb.Append('OL V A BP');
  sb.Append(sLineBreak);

  // osc
  for o := 5 downto 0 do
  begin
    op := @self.operators[o];
//    op.UpdateFreq;

    sb.AppendFormat('%d: ',[6-o]);
//    sb.AppendFormat('[%s] ',[ifthen(op.enabled,'x',' ')]);
    sb.Append(cOscFreqModeShortStr[op.oscMode]+' ');

//    case op.oscMode of
//      Coarse: str(op.freqRatio:7:2,f);
//      Fixed : str(op.freqFixed:7:2,f);
//    end;
    sb.Append(f); sb.append(' ');

    sb.AppendFormat('%s%d ',[ifthen(op.detune<0,'-',ifthen(op.detune=0,' ','+')), abs(op.detune)]);


     for I := 0 to 3 do
     begin
       sb.AppendFormat('%0.02d ',[ op.envelope.Rates [i] ]);
       sb.AppendFormat('%0.02d ',[ op.envelope.Levels[i] ]);
     end;


     sb.AppendFormat('%0.02d ',[ op.volume ]);
//   sb.AppendFormat('%g ',[ op.outputLevel ]);
     sb.AppendFormat('%d ',[ op.velocitySens ]);
     sb.AppendFormat('%d ',[ op.lfoAmpModSens ]);

     sb.AppendFormat('%s%d ',[Notes[(op.keyScale.Breakpoint mod 12)] , op.keyScale.Breakpoint div 12  ]);
     sb.AppendFormat('%0.02d ',[ op.keyScale.LeftDpt ]);
     sb.AppendFormat('%0.02d ',[ op.keyScale.RightDpt ]);
     sb.AppendFormat('%s ',[ Curves[op.keyScale.LeftCurve] ]);
     sb.AppendFormat('%s ',[ Curves[op.keyScale.RightCurve] ]);
//     sb.AppendFormat('%d ',[ op.keyScaleRate ]);


     sb.Append(sLineBreak)
  end;


  sb.Append('                ');
  for I := 0 to 3 do
  begin
    sb.AppendFormat('%0.02d ',[
      self.pitchEnvelope.Rates[i],
      self.pitchEnvelope.Levels[i]
      ]);
  end;
  sb.Append(sLineBreak);

  Result := sb.ToString;


end;



{
const defaultPreset:TParams =
  (

		name: 'Init';
		algorithm: 18;
		feedback: 7;
		lfoSpeed: 37;
		lfoDelay: 42;
		lfoPitchModDepth: 0;
		lfoAmpModDepth: 0;
		lfoPitchModSens: 4;
		lfoWaveform: TLFOMode.Sine;
		lfoSync: 0;

		pitchEnvelope: (
			rates: (0, 0, 0, 0);
			levels: (50, 50, 50, 50)
		);
		controllerModVal: 0;
		aftertouchEnabled: false;
		operators: (
			(idx:0;	enabled:true; envelope:(rates: (96,00,12,70); levels: (99,95,95,0)); detune:  1; velocitySens:0; lfoAmpModSens:0; volume:99; oscMode:0; freqCoarse: 2; freqFine:0;	pan:0;	outputLevel:13.12273; freqRatio :1; ampL:1; ampR:1),
			(idx:1;	enabled:true; envelope:(rates: (99,95,00,70); levels: (99,96,89,0)); detune: -1; velocitySens:0; lfoAmpModSens:0; volume:99; oscMode:0; freqCoarse: 0; freqFine:0;	pan:0;	outputLevel:13.12273; freqRatio :1; ampL:1; ampR:1),
			(idx:2;	enabled:true; envelope:(rates: (99,87,00,70); levels: (93,90,00,0)); detune:  0; velocitySens:0; lfoAmpModSens:0; volume:82; oscMode:0; freqCoarse: 1; freqFine:0;	pan:0;	outputLevel:3.008399; freqRatio :1; ampL:1; ampR:1),
			(idx:3;	enabled:true; envelope:(rates: (99,92,28,60); levels: (99,90,00,0)); detune:  2; velocitySens:0; lfoAmpModSens:0; volume:71; oscMode:0; freqCoarse: 2; freqFine:0;	pan:0;	outputLevel:1.159897; freqRatio :1; ampL:1; ampR:1),
			(idx:4;	enabled:true; envelope:(rates: (99,99,97,70); levels: (99,65,60,0)); detune: -2; velocitySens:0; lfoAmpModSens:0; volume:43; oscMode:0; freqCoarse: 3; freqFine:0;	pan:0;	outputLevel:0.102521; freqRatio :1; ampL:1; ampR:1),
      (idx:5;	enabled:true; envelope:(rates: (99,70,60,70); levels: (99,99,97,0)); detune:  0; velocitySens:0; lfoAmpModSens:0; volume:47; oscMode:0; freqCoarse:17; freqFine:0;	pan:0;	outputLevel:0.144987; freqRatio :1; ampL:1; ampR:1)
		)
	)
;
}

*)

end.
