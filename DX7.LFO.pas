﻿unit DX7.LFO;

interface

uses
  DX7.Config,
  FS1R.Params;

type
  TLFODelayAr=array[TLFODelay] of double;
  TLfoDX7=record
  strict private
    params:PVoiceParams;
    delayVal : double;
    Index:TOperatorIndex;
    phase :double;
    pitchVal :double;
    counter :integer;
    ampVal :double;
    ampValTarget :double;
    ampIncrement :double;
    delayState : tLFODelay;

    // Private static variables
    phaseStep:double;
    pitchModDepth:integer;
    ampModDepth:double;
    sampleHoldRandom:integer;
    delayTimes     :TLFODelayAr;
    delayIncrements:TLFODelayAr;
    delayVals      :TLFODelayAr{ = (0, 0, 1)};
    Initialized:boolean;
  public
    constructor Create(aIndex:TOperatorIndex; const aParams:PVoiceParams);
    procedure update;
    function render:double;
    function renderAmp : double;
  end;

implementation

uses Math, SysUtils, Windows;


const
//   Freq
//  7.17                                                                                                    ###########################
//  5.49╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌##╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌
//  3.81╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌#╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌
//  2.13╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌##╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌
//  0.44╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌#╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌
//  8.76╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌#╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌
//  7.08╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌##╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌
//  5.40╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌#┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌
//  3.71╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌#╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌
//  2.03╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌##╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌
//  0.35╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌#╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌
//  8.67╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌#╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌
//  6.98╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌##╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌
//  5.30╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌##╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌
//  3.62╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌##┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌
//  1.94╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌#╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌
//  0.25╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌##╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌
//  8.57╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌##╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌
//  6.89╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊##╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌
//  5.21╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌##╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌
//  3.52╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌##╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌
//  1.84╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌##╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌
//  0.16╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌#####╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌
//  8.48╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌###########┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌
//  6.79╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌###########╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌
//  5.11╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌###########╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌
//  3.43╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌##########╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌
//  1.75╌┊╌╌╌╌╌###########╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌
//  0.06╌######╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌
//     ╌━┻━━━━━━━━━┻━━━━━━━━━┻━━━━━━━━━┻━━━━━━━━━┻━━━━━━━━━┻━━━━━━━━━┻━━━━━━━━━┻━━━━━━━━━┻━━━━━━━━━┻━━━━━━━━━┻━━━━━━━━━┻━━━━━━━━━┻━━━━━━
//       0        10        20        30        40        50        60        70        80        90        100       110       120
//                                                                    Index
  LFO_FREQUENCY_TABLE:TArray<double> = [ // see https://github.com/smbolton/hexter/tree/master/src/dx7_voice.c#L1002
    0.062506,  0.124815,  0.311474,  0.435381,  0.619784,
    0.744396,  0.930495,  1.116390,  1.284220,  1.496880,
    1.567830,  1.738994,  1.910158,  2.081322,  2.252486,
    2.423650,  2.580668,  2.737686,  2.894704,  3.051722,
    3.208740,  3.366820,  3.524900,  3.682980,  3.841060,
    3.999140,  4.159420,  4.319700,  4.479980,  4.640260,
    4.800540,  4.953584,  5.106628,  5.259672,  5.412716,
    5.565760,  5.724918,  5.884076,  6.043234,  6.202392,
    6.361550,  6.520044,  6.678538,  6.837032,  6.995526,
    7.154020,  7.300500,  7.446980,  7.593460,  7.739940,
    7.886420,  8.020588,  8.154756,  8.288924,  8.423092,
    8.557260,  8.712624,  8.867988,  9.023352,  9.178716,
    9.334080,  9.669644, 10.005208, 10.340772, 10.676336,
    11.011900, 11.963680, 12.915460, 13.867240, 14.819020,
    15.770800, 16.640240, 17.509680, 18.379120, 19.248560,
    20.118000, 21.040700, 21.963400, 22.886100, 23.808800,
    24.731500, 25.759740, 26.787980, 27.816220, 28.844460,
    29.872700, 31.228200, 32.583700, 33.939200, 35.294700,
    36.650200, 37.812480, 38.974760, 40.137040, 41.299320,
    42.461600, 43.639800, 44.818000, 45.996200, 47.174400,
    47.174400, 47.174400, 47.174400, 47.174400, 47.174400,
    47.174400, 47.174400, 47.174400, 47.174400, 47.174400,
    47.174400, 47.174400, 47.174400, 47.174400, 47.174400,
    47.174400, 47.174400, 47.174400, 47.174400, 47.174400,
    47.174400, 47.174400, 47.174400, 47.174400, 47.174400,
    47.174400, 47.174400, 47.174400
  ];




//     Amp
//  0.53
//  0.52╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.50╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.48╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌#╌
//  0.47╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌#╌╌
//  0.45╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌#╌╌╌
//  0.43╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌#╌╌╌╌
//  0.42╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌#╌╌╌╌╌
//  0.40╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌#╌╌╌╌╌╌
//  0.38╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊#╌╌╌╌╌╌╌
//  0.37╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌#╌╌╌╌╌╌╌╌
//  0.35╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌#┊╌╌╌╌╌╌╌╌
//  0.33╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌#╌┊╌╌╌╌╌╌╌╌
//  0.32╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌#╌╌┊╌╌╌╌╌╌╌╌
//  0.30╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌#╌╌╌┊╌╌╌╌╌╌╌╌
//  0.28╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌##╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.27╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌#╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.25╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊##╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.23╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌##╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.22╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌#╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.20╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌##╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.18╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌##╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.17╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊###╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.15╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌##╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.13╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌###╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.12╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌####╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.10╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌###╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.08╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌#####╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.07╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌######╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.05╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌########╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.03╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌############┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.02╌┊╌╌#########################╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.00╌###╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//     ╌━┻━━━━━━━━━┻━━━━━━━━━┻━━━━━━━━━┻━━━━━━━━━┻━━━━━━━━━┻━━━━━━━━━┻━━━━━━━━━┻━━━━━━━━━┻━━━━━━━━━┻━━━━━━━━
//       0        10        20        30        40        50        60        70        80        90
//                                                      Index
  var LFO_AMP_MOD_TABLE:TArray<double> = [ // TODO: use lfo amp mod table
	0.00000, 0.00793, 0.00828, 0.00864, 0.00902, 0.00941, 0.00982, 0.01025, 0.01070, 0.01117,
	0.01166, 0.01217, 0.01271, 0.01327, 0.01385, 0.01445, 0.01509, 0.01575, 0.01644, 0.01716,
	0.01791, 0.01870, 0.01952, 0.02037, 0.02126, 0.02220, 0.02317, 0.02418, 0.02524, 0.02635,
	0.02751, 0.02871, 0.02997, 0.03128, 0.03266, 0.03409, 0.03558, 0.03714, 0.03877, 0.04047,
	0.04224, 0.04409, 0.04603, 0.04804, 0.05015, 0.05235, 0.05464, 0.05704, 0.05954, 0.06215,
	0.06487, 0.06772, 0.07068, 0.07378, 0.07702, 0.08039, 0.08392, 0.08759, 0.09143, 0.09544,
	0.09962, 0.10399, 0.10855, 0.11331, 0.11827, 0.12346, 0.12887, 0.13452, 0.14041, 0.14657,
	0.15299, 0.15970, 0.16670, 0.17401, 0.18163, 0.18960, 0.19791, 0.20658, 0.21564, 0.22509,
	0.23495, 0.24525, 0.25600, 0.26722, 0.27894, 0.29116, 0.30393, 0.31725, 0.33115, 0.34567,
	0.36082, 0.37664, 0.39315, 0.41038, 0.42837, 0.44714, 0.46674, 0.48720, 0.50856, 0.53283
];

//  Out
//  1.00                                                                     #
//  0.94╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌##┊╌╌╌╌╌╌╌╌
//  0.88╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌##╌┊╌╌╌╌╌╌╌╌
//  0.81╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌┊╌╌╌╌╌#╌╌╌┊╌╌╌╌╌╌╌╌
//  0.75╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌┊╌╌╌╌#╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.69╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌┊╌╌╌#╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.63╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌┊╌##╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.56╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌┊##╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.50╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌##╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.44╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌##╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.38╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌##╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.31╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌##╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.25╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌#######╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.19╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌#######╌╌╌╌╌┊╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.13╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌┊╌╌#####╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.06╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌################╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//  0.00╌################╌╌╌╌┊╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌╌┊╌╌╌╌╌╌╌╌
//     ╌━┻━━━━━━━━━┻━━━━━━━━━┻━━━━━━━━┻━━━━━━━━━┻━━━━━━━━━┻━━━━━━━━┻━━━━━━━━━┻━━━━━━━━
//       0         1         2        3         4         5        6         7
//                                           Index
// Wouter van Nifterick:
// these are now hard-coded values.
// Approximation formula: (Power(1.85;Index)-1)/((Power(1.85;MaxIndex))-1)

var LFO_PITCH_MOD_TABLE:array of double = [
	0.0000,
  0.0264,
  0.0534,
  0.0889,
  0.1612,
  0.2769,
  0.4967,
  1.0000
];


procedure AssertInRange(val,mn,mx:double;msg:string);
begin
  Assert(inrange(val,mn,mx),Format('%s out of range [%f..%f] : %f',[msg,mn,mx,val]));
end;

constructor TLfoDX7.Create(aIndex:TOperatorIndex; const aParams:PVoiceParams);
begin
  self.params:= aParams;
  self.Index := aIndex;
	self.phase := 0;
	self.pitchVal := 0;
	self.counter := 0;
	self.ampVal := 1;
	self.ampValTarget := 1;
	self.ampIncrement := 0;
	self.delayVal := 0;
	self.delayState := TLFODelay.Onset;

  self.sampleHoldRandom := 0;
  self.phaseStep :=0;
  self.pitchModDepth := 0;
  self.delayTimes[TLFODelay.Onset   ] := 0;
  self.delayTimes[TLFODelay.Ramp    ] := 0;
  self.delayTimes[TLFODelay.Complete] := 0;
  self.delayIncrements[TLFODelay.Onset   ] := 0;
  self.delayIncrements[TLFODelay.Ramp    ] := 0;
  self.delayIncrements[TLFODelay.Complete] := 0;
  self.delayVals[TLFODelay.Onset   ] := 0;
  self.delayVals[TLFODelay.Ramp    ] := 0;
  self.delayVals[TLFODelay.Complete] := 0;

  self.Initialized := True;
	update();
end;

function TLfoDX7.render:double;
var
  amp:double;
  ampSensDepth :double;
  Lphase : integer;
begin
  amp := 0;
  Assert(Initialized,'Not initialized');
  Assert(Params<>nil,'No params');
	if (counter mod config.lfoSamplePeriod) = 0 then
  begin
    Assert(Params<>nil,'Params is nill');
		case Params.Common.LFO1.Waveform of
			TLFOWaveForm.Triangle:  if self.phase < config.periodHalf then amp := 4     * self.phase * Config.periodRecip - 1
                                                                else amp := 3 - 4 * self.phase * config.periodRecip;
			TLFOWaveForm.SawDown:   		                                   amp := 1 - 2 * self.phase * config.periodRecip;
			TLFOWaveForm.SawUp:     		                                   amp := 2     * self.phase * config.periodRecip - 1;
			TLFOWaveForm.Square:    if self.phase < config.periodHalf then amp := -1
                                                                else amp := 1;
			TLFOWaveForm.Sine:       		                                   amp := sin(self.phase);
			TLFOWaveForm.SampleHold:		                                   amp := sampleHoldRandom;
		end;

		case self.delayState of
			TLFODelay.Onset,
			TLFODelay.Ramp:
        begin
				  self.delayVal := self.delayVal + delayIncrements[self.delayState];
   				if (self.counter / config.lfoSamplePeriod > delayTimes[self.delayState]) then
          begin
  					inc(self.delayState);
  					self.delayVal := delayVals[self.delayState];
  				end;
        end;
			TLFODelay.Complete:
		end;

//		if (self.counter mod 10000 = 0) and (self.Index = 0) then
//    OutputDebugString(PChar(Format('[%d] lfo amp value %f',[self.Index, self.ampVal]))) ;

    Assert(InRange(amp,-1,1));
    Assert(InRange(self.delayVal,0,1));
		amp := amp * self.delayVal;
    Assert(InRange(amp,-1,1));
    Assert(self.Params<>nil,'No params');
//    Assert(InRange(self.Params.Common.LFO1.PMD,low(LFO_PITCH_MOD_TABLE), High(LFO_PITCH_MOD_TABLE)),'Params.lfoPitchModSens out of range:'+IntToStr(Params.Common.LFO1.PMD));
    {needs to be pitch mod sense}

		pitchModDepth := trunc(1 + LFO_PITCH_MOD_TABLE[Params.Common.LFO1.PMD] * (Params.controllerModVal + Params.Common.LFO1.PMD / 99));

		self.pitchVal := power(pitchModDepth, amp);

		// TODO: Simplify ampValTarget calculation.
		// ampValTarget range := 0 to 1.
    // lfoAmpModSens range := -3 to 3.
    // ampModDepth range :=  0 to 1.
    // amp range := -1 to 1.
    ampSensDepth := abs(self.params.operators[Index].Voiced.Sensitivity.AmpModSense) * (1/3);

    AssertInRange(Index,0,OPERATOR_COUNT,'index' );
    AssertInRange(ampValTarget,0,1,'ampValTarget');
    AssertInRange(ampSensDepth,0,1,'ampSensDepth');
    AssertInRange(amp,-1,1,'amp');

    if self.params.operators[Index].Voiced.Sensitivity.AmpModSense > 0 then
      Lphase := 1
    else
      Lphase := -1;

		self.ampValTarget := 1 - ((ampModDepth   + Params.controllerModVal) * ampSensDepth * (amp * Lphase + 1) * 0.5);
		self.ampIncrement := (self.ampValTarget - self.ampVal) / Config.lfoSamplePeriod;
		self.phase := self.phase + phaseStep;
		if self.phase >= config.period then
    begin
      case Params.Common.LFO1.WaveForm of
        TLFOWaveForm.SampleHold :
          sampleHoldRandom := System.Round(1 - random * 2);
      end;

			self.phase := self.phase - config.period;
		end;
	end;
	inc(counter);
	Result := self.pitchVal;
end;

function TLfoDX7.renderAmp : double;
begin
	self.ampVal := self.ampVal + self.ampIncrement;
	Result := self.ampVal;
end;

procedure TLfoDX7.update;
var
  frequency: double;
begin
  Assert(Params<>nil);
  Assert(Params.Common.LFO1.Speed >= 0,inttostr(Params.Common.LFO1.Speed));

  frequency   := LFO_FREQUENCY_TABLE[Params.Common.LFO1.Speed];
  phaseStep   := Config.period * frequency / Config.lfoRate; // radians per sample
  ampModDepth := Params.Common.LFO1.AMD {lfo.AmpModDepth} * 0.01;

  // ignoring amp mod table for now. it seems shallow LFO_AMP_MOD_TABLE[params.lfoAmpModDepth];
  delayTimes     [TLFODelay.Onset] := (Config.lfoRate * 0.001753 * power(Params.Common.LFO1.Delay, 3.10454) + 169.344 - 168) / 1000;
  delayTimes     [TLFODelay.Ramp ] := (Config.lfoRate * 0.321877 * power(Params.Common.LFO1.Delay, 2.01163) + 494.201 - 168) / 1000;
  delayIncrements[TLFODelay.Ramp ] := 1 / (delayTimes[TLFODelay.Ramp] - delayTimes[TLFODelay.Onset]);
end;

end.