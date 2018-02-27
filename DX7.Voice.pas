unit DX7.Voice;

interface

uses
  SysUtils,
  Midi,
  DX7.Config,
  FS1R.Params,
  DX7.Op,
  DX7.PitchEnv;

type
  TDX7Voice=class
  strict private
    frequency:double;
    velocity:double;
    Params:PVoiceParams{PParams};
    aftertouch :integer;
    ModWheel :integer;
    PitchBend :double;
    LevelScaling:integer;
  public
    Note:integer;
    IsDown:boolean;
    operators:array[0..OPERATOR_COUNT-1] of TOperator;
    PitchEnv:TPitchEnvelopeDX7;

    procedure noteOff;

    procedure SetPitchBend(value:double);
    procedure updatePitchBend;

    procedure setOutputLevel(operatorIndex:TOperatorIndex; value:T0_99);

    procedure updateFrequency(operatorIndex:TOperatorIndex);
//    procedure updateFreq;

    procedure updateLFO;

    procedure modulationWheel(value:integer);
    procedure updateMod;

    function  render:double;
    function  isFinished:boolean;

    procedure setParams(const globalParams:{PParams}PVoiceParams);
    procedure setFeedback(value:integer);


    procedure channelAftertouch(value:integer);
    procedure setPan(operatorIndex:TOperatorIndex; value:integer);

    constructor Create(aNote:integer; aVelocity:integer;const aParams:PVoiceParams);
    class function frequencyFromNoteNumber(aNote:double):double;static;
    class function mapOutputLevel(input:integer):double;static;
  end;



implementation

uses Math;

var OUTPUT_LEVEL_TABLE:array[T0_99] of double = (
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
var OL_TO_MOD_TABLE :array[TSysexVal] of double = ( // TODO: use output level to modulation index table
	// 0 - 99
	0.000000, 0.000039, 0.000078, 0.000117, 0.000157, 0.000196, 0.000254, 0.000303, 0.000360, 0.000428,
	0.000509, 0.000606, 0.000721, 0.000857, 0.001019, 0.001212, 0.001322, 0.001442, 0.001715, 0.001870,
	0.002224, 0.002425, 0.002645, 0.002884, 0.003145, 0.003430, 0.003740, 0.004079, 0.004448, 0.004851,
	0.005290, 0.005768, 0.006290, 0.006860, 0.007481, 0.008158, 0.008896, 0.009702, 0.010580, 0.011537,
	0.012582, 0.013720, 0.014962, 0.016316, 0.017793, 0.019404, 0.021160, 0.023075, 0.025163, 0.027441,
	0.029925, 0.032633, 0.035587, 0.038808, 0.042320, 0.046150, 0.050327, 0.054882, 0.059850, 0.065267,
	0.071174, 0.077616, 0.084641, 0.092301, 0.100656, 0.109766, 0.119700, 0.130534, 0.142349, 0.155232,
	0.169282, 0.184603, 0.201311, 0.219532, 0.239401, 0.261068, 0.284697, 0.310464, 0.338564, 0.369207,
	0.402623, 0.439063, 0.478802, 0.522137, 0.569394, 0.620929, 0.677128, 0.738413, 0.805245, 0.878126,
	0.957603, 1.044270, 1.138790, 1.241860, 1.354260, 1.476830, 1.610490, 1.756250, 1.915210, 2.088550,
	// 100 - 127
	2.277580, 2.483720, 2.708510, 2.953650, 3.220980, 3.512500, 3.830410, 4.177100, 4.555150, 4.967430,
	5.417020, 5.907300, 6.441960, 7.025010, 7.660830, 8.354190, 9.110310, 9.934860, 10.83400, 11.81460,
	12.88390, 14.05000, 15.32170, 16.70840, 18.22060, 19.86970, 21.66810, 23.62920
);

type
  TOpRange=0..pred(OPERATOR_COUNT);
  TAlgorithm=record
    outputMix:TArray<TOpRange>;
    modulationMatrix:TArray<TArray<TOpRange>>;
  end;

const
  DX7_ALGORITHMS : array[0..31] of TAlgorithm = (
  //            1 2 3 4 5 6                       1        2    3        4      5    6      //
	( outputMix: [0,  2      ]; modulationMatrix: [[1    ], [ ], [3    ], [4  ], [5], [5]] ), //1
	( outputMix: [0,  2      ]; modulationMatrix: [[1    ], [1], [3    ], [4  ], [5], [ ]] ), //2
	( outputMix: [0,    3    ]; modulationMatrix: [[1    ], [2], [     ], [4  ], [5], [5]] ), //3
	( outputMix: [0,    3    ]; modulationMatrix: [[1    ], [2], [     ], [4  ], [5], [3]] ), //4
	( outputMix: [0,  2,  4  ]; modulationMatrix: [[1    ], [ ], [3    ], [   ], [5], [5]] ), //5
	( outputMix: [0,  2,  4  ]; modulationMatrix: [[1    ], [ ], [3    ], [   ], [5], [4]] ), //6
	( outputMix: [0,  2      ]; modulationMatrix: [[1    ], [ ], [3,4  ], [   ], [5], [5]] ), //7
	( outputMix: [0,  2      ]; modulationMatrix: [[1    ], [ ], [3,4  ], [3  ], [5], [ ]] ), //8
	( outputMix: [0,  2      ]; modulationMatrix: [[1    ], [1], [3,4  ], [   ], [5], [ ]] ), //9
	( outputMix: [0,    3    ]; modulationMatrix: [[1    ], [2], [2    ], [4,5], [ ], [ ]] ), //10
	( outputMix: [0,    3    ]; modulationMatrix: [[1    ], [2], [     ], [4,5], [ ], [5]] ), //11
	( outputMix: [0,  2      ]; modulationMatrix: [[1    ], [1], [3,4,5], [   ], [ ], [ ]] ), //12
	( outputMix: [0,  2      ]; modulationMatrix: [[1    ], [ ], [3,4,5], [   ], [ ], [5]] ), //13
	( outputMix: [0,  2      ]; modulationMatrix: [[1    ], [ ], [3    ], [4,5], [ ], [5]] ), //14
	( outputMix: [0,  2      ]; modulationMatrix: [[1    ], [1], [3    ], [4,5], [ ], [ ]] ), //15
	( outputMix: [0          ]; modulationMatrix: [[1,2,4], [ ], [3    ], [   ], [5], [5]] ), //16
	( outputMix: [0          ]; modulationMatrix: [[1,2,4], [1], [3    ], [   ], [5], [ ]] ), //17
	( outputMix: [0          ]; modulationMatrix: [[1,2,3], [ ], [2    ], [4  ], [5], [ ]] ), //18
	( outputMix: [0,3,    4  ]; modulationMatrix: [[1    ], [2], [     ], [5  ], [5], [5]] ), //19
	( outputMix: [0,1,  3    ]; modulationMatrix: [[2    ], [2], [2    ], [4,5], [ ], [ ]] ), //20
	( outputMix: [0,1,  3,4  ]; modulationMatrix: [[2    ], [2], [2    ], [5  ], [5], [ ]] ), //21
	( outputMix: [0,  2,3,4  ]; modulationMatrix: [[1    ], [ ], [5    ], [5  ], [5], [5]] ), //22
	( outputMix: [0,1,  3,4  ]; modulationMatrix: [[     ], [2], [     ], [5  ], [5], [5]] ), //23
	( outputMix: [0,1,2,3,4  ]; modulationMatrix: [[     ], [ ], [5    ], [5  ], [5], [5]] ), //24
	( outputMix: [0,1,2,3,4  ]; modulationMatrix: [[     ], [ ], [     ], [5  ], [5], [5]] ), //25
	( outputMix: [0,1,  3    ]; modulationMatrix: [[     ], [2], [     ], [4,5], [ ], [5]] ), //26
	( outputMix: [0,1,  3    ]; modulationMatrix: [[     ], [2], [2    ], [4,5], [ ], [ ]] ), //27
	( outputMix: [0,  2,    5]; modulationMatrix: [[1    ], [ ], [3    ], [4  ], [4], [ ]] ), //28
	( outputMix: [0,1,2,  4  ]; modulationMatrix: [[     ], [ ], [3    ], [   ], [5], [5]] ), //29
	( outputMix: [0,1,2,    5]; modulationMatrix: [[     ], [ ], [3    ], [4  ], [4], [ ]] ), //30
	( outputMix: [0,1,2,3,4  ]; modulationMatrix: [[     ], [ ], [     ], [   ], [5], [5]] ), //31
	( outputMix: [0,1,2,3,4,5]; modulationMatrix: [[     ], [ ], [     ], [   ], [ ], [5]] )  //32
);
{
  FS1R_ALGORITHMS : array[0..87] of TAlgorithm = (
  //            1 2 3 4 5 6 7 8                       1        2    3        4      5      6    7    8     //
	( outputMix: [1,2,3,4,5,6,7,8]; modulationMatrix: [[1    ], [ ], [     ], [   ], [   ], [ ], [ ], [ ]] ), //1
	( outputMix: [      4,5,6,7,8]; modulationMatrix: [[1    ], [1], [2    ], [3  ], [   ], [ ], [ ], [ ]] ), //2
	( outputMix: [      4,5,6,7,8]; modulationMatrix: [[1    ], [ ], [2,1  ], [3  ], [   ], [ ], [ ], [ ]] ), //3
	( outputMix: [      4,5,6,7,8]; modulationMatrix: [[     ], [ ], [2    ], [1,3], [   ], [ ], [ ], [ ]] ), //4
	( outputMix: [      4,5,6,7,8]; modulationMatrix: [[     ], [1], [     ], [2,3], [   ], [ ], [ ], [ ]] ), //5
	( outputMix: [  2,  4,5,6,7,8]; modulationMatrix: [[1    ], [1], [     ], [  3], [   ], [ ], [ ], [ ]] ), //6
	( outputMix: [  2,3,4,5,6,7,8]; modulationMatrix: [[1    ], [1], [1    ], [1  ], [   ], [ ], [ ], [ ]] ), //7
	( outputMix: [  2,3,4,5,6,7,8]; modulationMatrix: [[1    ], [1], [     ], [   ], [   ], [ ], [ ], [ ]] ), //8
	( outputMix: [1,2,      6,  8]; modulationMatrix: [[     ], [ ], [3    ], [3  ], [4  ], [5], [ ], [7]] ), //9
	( outputMix: [1,2,      6,  8]; modulationMatrix: [[     ], [ ], [3    ], [3  ], [4  ], [5], [7], [7]] ), //10
	( outputMix: [1,2,    5,    8]; modulationMatrix: [[     ], [ ], [3    ], [3  ], [4  ], [ ], [6], [7]] ), //11
	( outputMix: [1,2,    5,    8]; modulationMatrix: [[     ], [ ], [5    ], [3  ], [3,4], [5], [6], [7]] ), //12
);
}

const exp_scale_data: array[0..32] of byte = (
  0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 14, 16, 19, 23, 27, 33, 39, 47, 56, 66,
  80, 94, 110, 126, 142, 158, 174, 190, 206, 222, 238, 250
);

function ScaleCurve(group, depth:integer; curve:TCurve):integer;
var n_scale_data, raw_exp, scale:integer;
begin
  if (curve = TCurve.NegLin) or (curve = TCurve.Poslin) then
    // linear
    scale := (group * depth * 329) shr 12
   else
  begin
    // exponential
    n_scale_data := sizeof(exp_scale_data);
    raw_exp := exp_scale_data[min(group, n_scale_data - 1)];
    scale := (raw_exp * depth * 329) shr 15;
  end;

  if ord(curve) < 2 then
    scale := -scale;

  Result := scale;
end;



function ScaleLevel(midinote:TMidiNote; break_pt:TBreakPoint; left_depth, right_depth:byte; left_curve, right_curve:TCurve):integer;
var offset:integer;
begin
  offset := midinote - ord(break_pt) - 17;
  if (offset >= 0) then
    Result := ScaleCurve(offset div 3, right_depth, right_curve)
  else
    Result := ScaleCurve((-offset) div 3, left_depth, left_curve);
end;

const velocity_data:array[0..63] of byte = (
  0, 70, 86, 97, 106, 114, 121, 126, 132, 138, 142, 148, 152, 156, 160, 163,
  166, 170, 173, 174, 178, 181, 184, 186, 189, 190, 194, 196, 198, 200, 202,
  205, 206, 209, 211, 214, 216, 218, 220, 222, 224, 225, 227, 229, 230, 232,
  233, 235, 237, 238, 240, 241, 242, 243, 244, 246, 246, 248, 249, 250, 251,
  252, 253, 254
);


// See "velocity" section of notes. Returns velocity delta in microsteps.
function ScaleVelocity(velocity, sensitivity:integer):integer;
var clamped_vel,vel_value,scaled_vel:integer;
begin
  clamped_vel := max(0, min(127, velocity));
  vel_value   := velocity_data[clamped_vel shr 1] - 239;
  scaled_vel  := ((sensitivity * vel_value + 7) shr 3) shl 4;
  Result := scaled_vel;
end;


function ScaleRate(midinote:TMidiNote; sensitivity:byte):integer;
var x,qratedelta:integer;
begin
  x := min(31, max(0, midinote div 3 - 7));
  qratedelta := (sensitivity * x) shr 3;
{$ifdef SUPER_PRECISE}
  rem := x and 7;
  if (sensitivity = 3) and (rem = 3) then
    dec(qratedelta)
  else
    if (sensitivity = 7) and (rem > 0) and (rem < 4) then
    inc(qratedelta);
{$endif}
  Result := qratedelta;
end;

constructor TDX7Voice.Create(aNote:integer; aVelocity:integer; const aParams:PVoiceParams);
var
  I: TOperatorIndex;
  RateScaling:integer;
begin
	self.IsDown := true;
	self.Note := aNote;
	self.frequency := TDX7Voice.frequencyFromNoteNumber(self.Note);
	self.velocity := aVelocity/127;
  self.Params := aParams;
  self.PitchBend := 0;
  self.aftertouch := 0;
  for I := 0 to OPERATOR_COUNT-1 do
  begin
    LevelScaling := ScaleLevel(note,
      Params.operators[I].Voiced.LevelScaling.BreakPoint,
      Params.operators[I].Voiced.LevelScaling.LeftDpt,
      Params.operators[I].Voiced.LevelScaling.RightDpt,
      Params.operators[I].Voiced.LevelScaling.LeftCurve,
      Params.operators[I].Voiced.LevelScaling.RightCurve
    );

    RateScaling := ScaleRate(Note,  Params.operators[I].Voiced.EG.TimeScale);


		// Not sure about detune.
		// see https://github.com/smbolton/hexter/blob/621202b4f6ac45ee068a5d6586d3abe91db63eaf/src/dx7_voice.c#L789
		// https://github.com/asb2m10/dexed/blob/1eda313316411c873f8388f971157664827d1ac9/Source/msfa/dx7note.cc#L55
		// https://groups.yahoo.com/neo/groups/YamahaDX/conversations/messages/15919

    self.operators[i] := TOperator.Create(I, Params, self.frequency,RateScaling);

    updateFrequency(i);

		// TODO: DX7 accurate velocity sensitivity map
    Assert(operators[I].LiveData.outputLevel < 17);
		operators[i].OutputLevel :=(1 + (self.velocity - 1) * (Params.operators[I].Voiced.Sensitivity.AmpVelSense{ velocitySens} / 7)) * operators[I].LiveData.outputLevel;

//   	params.operators[operatorIndex].outputLevel := ;
    self.setPan(i,0);
	end;


//  outlevel += level_scaling;
//  outlevel = min(127, outlevel);

  PitchEnv := TPitchEnvelopeDX7.Create(Params);

  setFeedback(Params.Common.FeedBack);
  self.updateLFO;

	self.updatePitchBend();
end;

class function TDX7Voice.frequencyFromNoteNumber(aNote:double):double;
begin
	Result := 440 * power(2,(aNote-69)/12);
end;

procedure TDX7Voice.setParams(const globalParams:PVoiceParams);
begin
  self.Params := @globalParams;
  self.updateLFO;
end;


procedure TDX7Voice.setFeedback(value:integer);
begin
	self.params. fbRatio := Power(2, (value - 7)); // feedback of range 0 to 7
end;

procedure TDX7Voice.setOutputLevel(operatorIndex:TOperatorIndex; value:T0_99);
begin
	operators[operatorIndex].LiveData.outputLevel := self.mapOutputLevel(value);
end;

procedure TDX7Voice.updateFrequency(operatorIndex:TOperatorIndex);
begin
  case Params.Operators[operatorIndex].Voiced.Osc.OscMode of
    TOscmodeVoiced.Ratio:
      begin
        // freqCoarse of 0 is used for ratio of 0.5
        //    if op.freqCoarse=0 then
        //      op.freqCoarse := 0.5;
        operators[operatorIndex].LiveData.freqRatio := Params.Operators[operatorIndex].Voiced.Osc.FreqCoarse * (1 + Params.Operators[operatorIndex].Voiced.Osc.FreqFine / 100);
      end;
    TOscmodeVoiced.Fixed:
      operators[operatorIndex].LiveData.freqFixed := Power(10, Math.FMod(Params.Operators[operatorIndex].Voiced.Osc.FreqCoarse, 4)) * (1 + (Params.Operators[operatorIndex].Voiced.Osc.FreqFine / 99) * 8.772);
  else
    raise Exception.Create('Unsupported Osc mode set');
  end;


end;

procedure TDX7Voice.updateLFO;
var I: Integer;
begin
  for I := 0 to OPERATOR_COUNT-1 do
    self.operators[I].LFO.update;
end;

procedure TDX7Voice.setPan(operatorIndex:TOperatorIndex; value:integer);
begin
	operators[operatorIndex].LiveData.ampL := cos(PI / 2 * (value + 50) / 100);
	operators[operatorIndex].LiveData.ampR := sin(PI / 2 * (value + 50) / 100);
end;

class function TDX7Voice.mapOutputLevel(input:integer):double;
var idx :integer;
begin
	idx := EnsureRange(Input, Low(T0_99), High(T0_99));
	Result := OUTPUT_LEVEL_TABLE[idx] * 1.27;
  Assert(Result>=0);
  Assert(Result<17);
end;

procedure TDX7Voice.channelAftertouch(value:integer);
begin
	aftertouch := value;
	updateMod();
end;

procedure TDX7Voice.modulationWheel(value:integer);
begin
	ModWheel := value;
	updateMod();
end;

procedure TDX7Voice.updateMod;
var Laftertouch:integer;
begin
  if params.aftertouchEnabled then
    Laftertouch := aftertouch
   else
     Laftertouch := 0;
	params.controllerModVal := Math.min(1.27, Laftertouch + ModWheel); // Allow 27% overdrive
end;

procedure TDX7Voice.SetPitchBend(value:double);
begin
	self.PitchBend := value;
end;

function TDX7Voice.render:double;
var
  algorithmIdx: integer;
  modulationMatrix: TArray<TArray<TOpRange>>;
  outputMix: Tarray<TOpRange>;
  outputScaling: Extended;
  outputL, outputR: double;
  kmod:double;
  i,j,k:integer;
  Modulator:tOpRange;
  modOp:^TOperator;
  carrier: ^TOperator;
  carrierLevel: Double;
begin

	algorithmIdx := params.Common.Algorithm;
	modulationMatrix := DX7_ALGORITHMS[algorithmIdx].modulationMatrix;
	outputMix := DX7_ALGORITHMS[algorithmIdx].outputMix;
	outputScaling := 1 / length(outputMix);
	outputL := 0;
	outputR := 0;
  assert(params.fbRatio<100,'fb not <10 '+floattostr(params.fbRatio));
  assert(params.fbRatio>=0,'fb not >=0');

	for i:= OPERATOR_COUNT-1 downto 0 do
  begin
		kmod := 0;
		if operators[i].LiveData.enabled then
			for j:= 0 to length(modulationMatrix[i])-1 do begin
				modulator := modulationMatrix[i,j];
				if operators[modulator].LiveData.enabled then begin
					modOp := @self.operators[modulator];
					if modulator = i then
 						// Operator modulates itself; use feedback ratio
						// TODO: implement 2-sample feedback averaging (anti-hunting filter)
						// http://d.pr/i/1kuZ7/3h7jQN7w
						// https://code.google.com/p/music-synthesizer-for-android/wiki/Dx7Hardware
						// http://music.columbia.edu/pipermail/music-dsp/2006-June/065486.html
            kmod := kmod + (modOp.val * params.fbRatio)
					else
						kmod := kmod + (modOp.val * modOp.outputLevel);
				end;
		end;
		self.operators[i].render(kmod);
	end;

  for k:=0 to length(outputMix)-1 do
		if operators[outputMix[k]].LiveData.enabled then
    begin
			carrier       := @self.operators[outputMix[k]];
			carrierLevel  := carrier.val * carrier.outputLevel;
			outputL := outputL + carrierLevel * operators[carrier.Index].LiveData.ampL;
			outputR := outputR + carrierLevel * operators[carrier.Index].LiveData.ampR;
 		end;

	Result := outputL * outputScaling;
end;

procedure TDX7Voice.noteOff;
var i:integer;
begin
	self.IsDown := false;
	for i:=0 to OPERATOR_COUNT-1 do
		self.operators[i].noteOff();

  self.PitchEnv.noteOff;
end;

procedure TDX7Voice.updatePitchBend;
var frequency:double;i:integer;
begin
	frequency := TDX7Voice.frequencyFromNoteNumber(self.Note + self.PitchBend);
  for i := 0 to OPERATOR_COUNT-1 do
		self.operators[i].updateFrequency(frequency);
end;

function TDX7Voice.isFinished:boolean;
var outputMix:tArray<TOpRange>;i:integer;
begin
	outputMix := DX7_ALGORITHMS[params.Common.algorithm].outputMix;
	for i := 0 to high(outputMix) do
		if (not self.operators[outputMix[i]].isFinished()) then
      exit(False);

	Result := true;
end;



end.
