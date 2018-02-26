unit DX7.Op;

interface

uses
  FS1R.Params,
  DX7.Config,
  DX7.Envelope,
  DX7.PitchEnv,
  DX7.LFO,
  FM.Oscillator;

type
  TLiveData=record
        pan               : Double;
        outputLevel       : Double;
        ampL, ampR        : Double;
        Ratio,
        freqRatio,
        freqFixed         : Double;
        enabled           : boolean;
  end;

  TOperator=record
  public
    Params:PVoiceParams;
    Index:TOperatorIndex;
    Phase:double;
    phaseStep:double;
    Val:double;
    Envelope:TEnvelopeDX7;
    OutputLevel:double;
    LFO:TLfoDX7;
    pitchEnvelope:TPitchEnvelopeDX7;
    WaveForm:TWaveform;
    LiveData:TLiveData;
    constructor Create(aIndex:TOperatorIndex;const aParams:PVoiceParams; aBaseFrequency:double;aRateScaling:integer);
    procedure updateFrequency(baseFrequency:double);
    function render(lMod:double):double;
    procedure noteOff;
    function isFinished:boolean;
  end;


implementation

uses Math;

const OUTPUT_LEVEL_TABLE:array[0..99] of double = (
	0.000000, 0.000337, 0.000476, 0.000674, 0.000952, 0.001235, 0.001602, 0.001905, 0.002265, 0.002694,
	0.003204, 0.003810, 0.004531, 0.005388, 0.006408, 0.007620, 0.008310, 0.009062, 0.010776, 0.011752,
	0.013975, 0.015240, 0.016619, 0.018123, 0.019764, 0.021552, 0.023503, 0.025630, 0.027950, 0.030480,
	0.033238, 0.036247, 0.039527, 0.043105, 0.047006, 0.051261, 0.055900, 0.060960, 0.066477, 0.072494,
	0.079055, 0.086210, 0.094012, 0.102521, 0.111800, 0.121919, 0.132954, 0.144987, 0.158110, 0.172420,
	0.188025, 0.205043, 0.223601, 0.243838, 0.265907, 0.289974, 0.316219, 0.344839, 0.376050, 0.410085,
	0.447201, 0.487676, 0.531815, 0.579948, 0.632438, 0.689679, 0.752100, 0.820171, 0.894403, 0.975353,
	1.063630, 1.159897, 1.264876, 1.379357, 1.504200, 1.640341, 1.788805, 1.950706, 2.127260, 2.319793,
	2.529752, 2.758714, 3.008399, 3.280683, 3.577610, 3.901411, 4.254519, 4.639586, 5.059505, 5.517429,
	6.016799, 6.561366, 7.155220, 7.802823, 8.509039, 9.279172, 10.11901, 11.03486, 12.03360, 13.12273
);

function mapOutputLevel(input:integer):double;
var idx :integer;
begin
	idx := EnsureRange(Input, 0, 99);
	Result := OUTPUT_LEVEL_TABLE[idx] * 1.27;
  Assert(Result>=0);
  Assert(Result<17);
end;

constructor TOperator.Create(aIndex:TOperatorIndex;const aParams:PVoiceParams; aBaseFrequency:double;aRateScaling:integer);
begin
  self.Index := aIndex;
  self.Params := aParams;
  self.WaveForm := TWaveForm.sinus;

	self.phase := 0;
	self.val := 0;
	self.envelope := TEnvelopeDX7.Create(Index,Params);
  self.LFO := TLFOdx7.Create(Index,params);
	// TODO: Pitch envelope
	self.pitchEnvelope := TPitchEnvelopeDX7.Create(Params);
	self.updateFrequency(aBaseFrequency);

  // Extended/non-standard parameters
  // Alternate panning: -25, 0, 25, -25, 0, 25
  LiveData.pan  := ((self.Index + 1) mod 3 - 1) * 25;
  LiveData.enabled     := True;
  LiveData.outputLevel := mapOutputLevel(aParams.Operators[self.Index].Voiced.LevelScaling.TotalLvl);

end;


procedure TOperator.updateFrequency(baseFrequency:double);
var frequency : double;
// http://www.chipple.net/dx7/fig09-4.gif
const OCTAVE_1024 = 1.0006771307; //exp(log(2)/1024);
begin
  if LiveData.freqRatio=0 then
    LiveData.freqRatio := 0.5;

  if Params.operators[Index].Voiced.Osc.OscMode = TOscModeVoiced.Fixed then
  	frequency := LiveData.freqFixed
  else
		frequency := baseFrequency * LiveData.freqRatio * power(OCTAVE_1024, Params.operators[Index].Voiced.Osc.FrDetune - 7); //@@@

	self.phaseStep := config.period * frequency / Config.sampleRate; // radians per sample
end;


function TOperator.render(lMod:double):double;
var p,o,env,l,a:double;

begin
  o   := GetOsc(WaveForm, self.Phase + lMod);
  env := envelope.render();
  l   := self.lfo.render();
  a   := lfo.renderAmp();
  p   := 1-self.pitchEnvelope.render()*0.0000001;
//  p   := 1;

	self.val := o * env * a;
//	self.phase := self.phase + (self.phaseStep * self.lfo.render());
  self.phase := self.phase + (self.phaseStep * l * p );
	if (self.phase >= config.period) then
		self.phase := self.phase - config.period;

	Result := self.val;
end;

procedure TOperator.noteOff;
begin
	self.envelope.noteOff();
end;

function TOperator.isFinished:boolean;
begin
	Result := self.envelope.isFinished();
end;

end.
