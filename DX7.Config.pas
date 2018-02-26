unit DX7.Config;

interface

type
  TConfig=record
    sampleRate      : Integer;
    lfoRate         : Integer;
    lfoSamplePeriod : Integer;
    period          : Double;
    periodHalf      : Double;
    periodRecip     : Double;
  	polyphony       : Integer;
    msPerSecond     : double;
  end;

const
  OPERATOR_COUNT=6;

  DEFAULT_SAMPLE_RATE       = 44100;
  DEFAULT_LFO_RATE          = 441;
  DEFAULT_LFO_SAMPLE_PERIOD = DEFAULT_SAMPLE_RATE div DEFAULT_LFO_RATE;
  DEFAULT_HALF_PERIOD       = PI;
  DEFAULT_PERIOD            = PI * 2;
  DEFAULT_POLYPHONY         = 16;

  Config:TConfig=
  (
    sampleRate      : DEFAULT_SAMPLE_RATE;
    lfoRate         : DEFAULT_LFO_RATE;
    lfoSamplePeriod : DEFAULT_LFO_SAMPLE_PERIOD;
    period          : DEFAULT_PERIOD;
    periodHalf      : DEFAULT_HALF_PERIOD;
    periodRecip     : 1 / DEFAULT_PERIOD;
    polyphony       : DEFAULT_POLYPHONY;
    msPerSecond     : 1000 / DEFAULT_SAMPLE_RATE;
  );

type
  TOperatorIndex=0..pred(OPERATOR_COUNT);

implementation

end.
