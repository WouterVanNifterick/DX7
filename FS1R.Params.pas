unit FS1R.Params;

interface

uses
  SysUtils,
  System.Math,
  System.StrUtils,
  Generics.Collections,
  Generics.Defaults,
  Midi,
  WvN.Math.Bits;

  {$SCOPEDENUMS ON}

type

  TMidiWord=0..127;
  TSysexVal=0..127;
  T0_99=0..99;
  TMidiNote=0..127;

  /// <summary>
  /// sine     The operator will generate a sine wave which can be used for additive or FM synthesis.
  /// all 1    Broad band — including all harmonics.
  /// all 2    Narrow band — including all harmonics.
  /// odd 1    Broad band — odd harmonics only.
  /// odd 2    Narrow band — odd harmonics only.
  /// res1     Resonant broad band.
  /// res 1    Resonant narrow band.
  /// frmt The operator will function as a formant for formant-shaping synthesis.
  /// </summary>
  TOscSpectralForm=(sine, all1, all2, odd1, odd2, res1, res2, frmt);

  TCurve=(NegLin=0,NegExp, PosExp, Poslin);
const
  Notes:Array[0..11] of string=('C-','C#','D-','D#','E-','F-','F#','G-','G#','A-','A#','B-');
  Curves:array[TCurve] of string=('-Lin','-exp','+exp','+lin');

type
  TReserved=0..0;

  TLFODelay =(Onset,Ramp,Complete);

  TCategory=(
    NoAssign=0,
    Piano,
    ChromaticPercussion,
    Organ,
    Guitar,
    Bass,
    StringsOrchestral,
    Ensemble,
    Brass,
    Reed,
    Pipe,
    SynthLead,
    SynthPad,
    SynthSoundEffects,
    Ethnic,
    Percussive,
    SoundEffects,
    Drums,
    SynthComping,
    Vocal,
    Combination,
    MaterialWave,
    Sequence=$16);

  TBreakPoint=(
    A1,AS1,B1,C1,CS1,D1,DS1,E1,F1,FS1,G1,GS1,
    A2,AS2,B2,C2,CS2,D2,DS2,E2,F2,FS2,G2,GS2,
    A3,AS3,B3,C3,CS3,D3,DS3,E3,F3,FS3,G3,GS3,
    A4,AS4,B4,C4,CS4,D4,DS4,E4,F4,FS4,G4,GS4,
    A5,AS5,B5,C5,CS5,D5,DS5,E5,F5,FS5,G5,GS5,
    A6,AS6,B6,C6,CS6,D6,DS6,E6,F6,FS6,G6,GS6,
    A7,AS7,B7,C7,CS7,D7,DS7,E7,F7,FS7,G7,GS7,
    A8,AS8,B8,C8
  );


  // From Yamaha Montage data list page 155:
const

// 39.70 ┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼───────█
// 38.71 |         |         |         |         |         |         |         |         |         |         |         |         |      ▄█
// 37.72 ┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼──────██
// 36.72 |         |         |         |         |         |         |         |         |         |         |         |         |      ██
// 35.73 ┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────▄██
// 34.74 |         |         |         |         |         |         |         |         |         |         |         |         |     ███
// 33.75 ┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼────▄███
// 32.75 |         |         |         |         |         |         |         |         |         |         |         |         |   ▄████
// 31.76 ┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼───█████
// 30.77 |         |         |         |         |         |         |         |         |         |         |         |         |  ██████
// 29.78 ┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─▄██████
// 28.78 |         |         |         |         |         |         |         |         |         |         |         |         | ███████
// 27.79 ┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼████████
// 26.80 |         |         |         |         |         |         |         |         |         |         |         |         █████████
// 25.81 ┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼────────▄█████████
// 24.81 |         |         |         |         |         |         |         |         |         |         |         |        ██████████
// 23.82 ┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼───────███████████
// 22.83 |         |         |         |         |         |         |         |         |         |         |         |      ████████████
// 21.84 ┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────▄████████████
// 20.84 |         |         |         |         |         |         |         |         |         |         |         |     █████████████
// 19.85 ┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼────██████████████
// 18.86 |         |         |         |         |         |         |         |         |         |         |         |   ▄██████████████
// 17.87 ┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼──▄███████████████
// 16.87 |         |         |         |         |         |         |         |         |         |         |         |▄█████████████████
// 15.88 ┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────▄██████████████████
// 14.89 |         |         |         |         |         |         |         |         |         |         |       ▄████████████████████
// 13.90 ┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼──────▄█████████████████████
// 12.90 |         |         |         |         |         |         |         |         |         |         |    ▄███████████████████████
// 11.91 ┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼───▄████████████████████████
// 10.92 |         |         |         |         |         |         |         |         |         |         | ▄██████████████████████████
//  9.93 ┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────▄████████████████████████████
//  8.93 |         |         |         |         |         |         |         |         |         |      ▄▄██████████████████████████████
//  7.94 ┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼───▄▄█████████████████████████████████
//  6.95 |         |         |         |         |         |         |         |         |         |▄▄████████████████████████████████████
//  5.96 ┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼──────▄▄▄███████████████████████████████████████
//  4.96 |         |         |         |         |         |         |         |         | ▄▄█████████████████████████████████████████████
//  3.97 ┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼───▄▄▄▄▄██████████████████████████████████████████████████
//  2.98 |         |         |         |         |         |         ▄▄▄▄▄▄▄▄█████████████████████████████████████████████████████████████
//  1.99 ┼─────────┼─────────┼─────────┼─────▄▄▄▄▄▄▄▄▄▄▄▄█████████████████████████████████████████████████████████████████████████████████
//  0.99 |         |  ▄▄▄▄▄▄▄▄▄▄▄▄████████████████████████████████████████████████████████████████████████████████████████████████████████
//     0 ┼████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████
//      ─┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────
//       0         10        20        30        40        50        60        70        80        90        100       110       120

  LFOFrequencies:array[0..127] of single=(
    0.00,0.04,0.08,0.13,0.17,0.21,0.25,0.29,0.34,0.38,0.42,0.46,0.51,0.55,0.59,
    0.63,0.67,0.72,0.76,0.80,0.84,0.88,0.93,0.97,1.01,1.05,1.09,1.14,1.18,1.22,
    1.26,1.30,1.35,1.39,1.43,1.47,1.51,1.56,1.60,1.64,1.68,1.72,1.77,1.81,1.85,
    1.89,1.94,1.98,2.02,2.06,2.10,2.15,2.19,2.23,2.27,2.31,2.36,2.40,2.44,2.48,
    2.52,2.57,2.61,2.65,2.69,2.78,2.86,2.94,3.03,3.11,3.20,3.28,3.37,3.45,3.53,
    3.62,3.70,3.87,4.04,4.21,4.37,4.54,4.71,4.88,5.05,5.22,5.38,5.55,5.72,6.06,
    6.39,6.73,7.07,7.40,7.74,8.08,8.41,8.75,9.08,9.42,9.76,10.1,10.8,11.4,12.1,
    12.8,13.5,14.1,14.8,15.5,16.2,16.8,17.5,18.2,19.5,20.9,22.2,23.6,24.9,26.2,
    27.6,28.9,30.3,31.6,33.0,34.3,37.0,39.7);

  ModulationDelayOffset:array[0..127] of single=(
    0.0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0,1.1,1.2,1.3,1.4,1.5,1.6,1.7,1.8,
    1.9,2.0,2.1,2.2,2.3,2.4,2.5,2.6,2.7,2.8,2.9,3.0,3.1,3.2,3.3,3.4,3.5,3.6,3.7,
    3.8,3.9,4.0,4.1,4.2,4.3,4.4,4.5,4.6,4.7,4.8,4.9,5.0,5.1,5.2,5.3,5.4,5.5,5.6,
    5.7,5.8,5.9,6.0,6.1,6.2,6.3,6.4,6.5,6.6,6.7,6.8,6.9,7.0,7.1,7.2,7.3,7.4,7.5,
    7.6,7.7,7.8,7.9,8.0,8.1,8.2,8.3,8.4,8.5,8.6,8.7,8.8,8.9,9.0,9.1,9.2,9.3,9.4,
    9.5,9.6,9.7,9.8,9.9,10.0,11.1,12.2,13.3,14.4,15.5,17.1,18.6,20.2,21.8,23.3,
    24.9,26.5,28.0,29.6,31.2,32.8,34.3,35.9,37.5,39.0,40.6,42.2,43.7,45.3,46.9,
    48.4,50.0
  );

type
// 80 bytes
TPerformanceCommonSysex =
Record
  Name            : Array[1..12] of $20..$7F;
  Reserved        : TMidiWord;
  Category        : { $00..$16 } TCategory;
  Reserved2       : TSysexVal;
  PerfVol         : TSysexVal; // 10 performance volume
  PerfPan         : TSysexVal; // 11 performance pan (L63~0~R63)
  PerfNoteShift	  : $00..$30; // 12 performance note shift (-24~0~+24)
  Reserved3       : TSysexVal;     // 13
  IndOut          : $00..$02; // 14 individual out (0: off, 1: pre ins, 2: post ins)
  FSeq:record
    FSeqPart        : $00..$04; // 15 FSEQ PART (0: off, 1~4: part)
    FSeqBank        : $00..$01; // 16 FSEQ bank 0: int, 1: pre
    FSeqNum         : $00..$59; // 17 FSEQ number int (0-5) , pre (0-89)
    FSeqSpeedRatio  : TMidiWord;// 18 FSEQ Speed Ratio (10.0~500.0) / MIDI Clock (0-4) MIDI Clock: 0: 1/4, 1: 1/2, 2: 1/1, 3: 2/1, 4: 4/1
    FSeqStart       : TMidiWord;// 1a FSEQ start step offset (hi byte)
    FSeqLoopStart   : TMidiWord;// 1c FSEQ start step of loop point (hi byte)
    FSeqLoopEnd     : TMidiWord;// 1e FSEQ end step of loop point (hi byte)
    FSeqLoopMode    : (loopOneWay,loopRound); // 20 FSEQ loop mode (0: one way, 1: round)
    FSeqPlayMode    : (Scratch=1,FSeq=2); // 21 FSEQ play mode (1: scratch, 2: fseq)
    FSeqVelSensTempo: $00..$07; // 22 FSEQ velocity sensitivity for tempo
    FSeqPitchMode   : $00..$01; // 23 FSEQ formant pitch mode
    FSeqKeyOnTrigger: (First,All); // 243FSEQ key on trigger (0: first, 1: all)
    Reserved4       : byte;     // 25
    FseqDelay       : $00..$63; // FSEQ formant seqence delay
    FSeqLelSens     : $00..$7F; // FSEQ level velocity sensitivity (-64~+63)
  end;
  ContrPartSW     : array[0..7] of $00..$0F;  // 28 controller part switch [----pppp]
  ContrSrcSw      : array[0..7] of TMidiWord; // 30 controller source switch (bitmap-high)
  ContrDest       : array[0..7] of $00..$2F;  // 40 controller destination
  ContrDepth      : array[0..7] of $00..$7F;  // 48 controller depth (-64~+63)
End;

// 112 bytes
TPerformanceEffectSysex =
Record
  RevParams1:array[0..7] of TMidiWord; // 00 50 Reverb parameter (See "Effect Parameter List.")
  RevParams2:array[0..7] of $0..$7F;   // 00 60 Reverb parameter (See "Effect Parameter List.")
  VarParams :array[0..15] of TMidiWord; // 00 68 Variation parameter (See "Effect Parameter List.")
  InsParams :array[0..15] of TMidiWord; // 01 08 Insertion parameter (See "Effect Parameter List.")

  RevType    : $00..$10;  // 01 28 Reverb type (See "Effect Type List.")
  RevPan     : $01..$7F;  // 01 29 Reverb pan L63...C...R63 (1..64..127)
  RevRet     : $00..$7F;  // 01 2A Reverb return
  VarType    : $00..$1C;  // 01 2B Variation type (See "Effect Type List.")
  VarPan     : $01..$7F;  // 01 2C Variation pan L63...C...R63 (1..64..127)
  VarRet     : $00..$7F;  // 01 2D Variation return
  VarToRev   : $00..$7F;  // 01 2E Send Variation to Reverb
  InsType    : $00..$28;  // 01 2F Insertion type (See "Effect Type List.")
  InsPan     : $01..$7F;  // 01 30 Insertion pan L63...C...R63 (1..64..127)
  InsToRev   : $00..$7F;  // 01 31 Send insertion to Reverb
  InsToVar   : $00..$7F;  // 01 32 Send insertion to Variation
  InsLev     : $00..$7F;  // 01 33 Insertion level
  EqLowGain  : $34..$4C;  // 01 34 EQ low gain -12~+12 [dB]
  EqLowFreq  : $04..$28;  // 01 35 EQ low frequency 32~2000 [Hz]
  EqLowQ     : $01..$78;  // 01 36 EQ low Q 0.1~12.0
  EqLowShape : $00..$01;  // 01 37 EQ low shape 00: shelving, 01: peaking
  EqMidGain  : $34..$4C;  // 01 38 EQ mid gain -12~+12 [dB]
  EqMidFreq  : $0E..$36;  // 01 39 EQ mid frequency 100~10.0 [kHz]
  EqMidQ     : $01..$78;  // 01 3A EQ mid Q 0.1~12.0
  EqHighGain : $34..$4C;  // 01 3B EQ high gain -12~+12 [dB]
  EqHighFreq : $1C..$3A;  // 01 3C EQ high frequency 0.5~16.0 [kHz]
  EqHighQ    : $01..$78;  // 01 3D EQ high Q 0.1-12.0
  EqHighShape: { $00..$01} (Shelving, Peaking);  // 01 3E EQ high shape 00: shelving, 01: peaking
  Reserved   : TReserved;  // 01 3F reserved
End;

// 52 bytes
TBankNum=(Off,Int,PrA,PrB,PrC,PrD,PrE,PrF,PrG,PrH,PrI,PrJ,PrK);
TChanMax=(A1,A2,A3,A4,A5,A6,A7,A8,A9,A10,A11,A12,A13,A14,A15,A16,Off);
TRcvChan=(A1,A2,A3,A4,A5,A6,A7,A8,A9,A10,A11,A12,A13,A14,A15,A16,prm,Off);
TMonoPoly=(Mono,Poly);
TMonoPriority=(last, top, bottom, first);
TFilterSW=(off,&on);


TPerformancePartSysex =
packed record
  NoteReserve   : $00..$20; // 00 NOTE RESERVE 0~32
  BankNum       : { $00..$0C }TBankNum; // 01 BANK NUMBER off, Int, PrA~PrK
  ProgramNum    : $00..$7F; // 02 PROGRAM NUMBER 0~127
  RcvChanMax    : { $00..$16 } TChanMax; // 03 Rcv CHANNEL MAX A1~A16, off
  RcvChan       : { $00..$7F}  TRcvChan; // 04 Rcv CHANNEL A1~A16, pfm, off
  MonoPoly      : { $00..$01 } TMonoPoly; // 05 MONO/POLY MODE 0:MONO,1:POLY
  MonoPrio      : { $00..$03 } TMonoPriority; // 06 MONO PRIORITY 0: last, 1: top, 2: bottom, 3: first
  FilterSW      : { $00..$01 } TFilterSW; // 07 FilterSw 0: off, 1: on
  NoteShift     : $00..$30; // 08 NOTE SHIFT -24~+24 [semitones]
  Detune        : $00..$7F; // 09 DETUNE -64~+63
  VcdUvcdBal    : $00..$7F; // 0A VOICED/UNVOICED BALANCE -64~+63
  Volume        : $00..$7F; // 0B VOLUME 0~127
  VelSensDpt    : $00..$7F; // 0C VELOCITY SENSE DEPTH 0~127
  VelSensOfst   : $00..$7F; // 0D VELOCITY SENSE OFFSET 0~127
  Ran           : $00..$7F; // 0E PAN Rnd, L63...C...R63 (0: random, 1~64 -127)
  NoteLimLo     : $00..$7F; // 0F NOTE LIMIT LOW C-2~G8
  NoteLimHi     : $00..$7F; // 10 NOTE LIMIT HIGH C-2~G8
  DryLevel      : $00..$7F; // 11 DRY LEVEL 0~127
  VarSend       : $00..$7F; // 12 VARIATION SEND 0~127
  RevSend       : $00..$7F; // 13 REVERB SEND 0~127
  InsSW         : $00..$01; // 14 INSERTION SW off/on
  LFORate       : $00..$7F; // 15 LFO1 RATE -64~+63
  LFOPModDpt    : $00..$7F; // 16 LFO1 PITCH MOD DEPTH -64~+63
  LFODelay      : $00..$7F; // 17 LFO1 DELAY -64~+63
  FiltCutoff    : $00..$7F; // 18 FILTER CUTOFF FREQ -64~+63
  FiltRes       : $00..$7F; // 19 FILTER RESONANCE -64~+63
  EGAttackTime  : $00..$7F; // 1A EG ATTACK TIME -64~+63
  EGDecayTime   : $00..$7F; // 1B EG DECAY TIME -64~+63
  EGReleaseTime : $00..$7F; // 1C EG RELEASE TIME -64~+63
  Formant       : $00..$7F; // 1D FORMANT -64~+63
  FM            : $00..$7F; // 1E FM -64~+63
  FilterEGDpt   : $00..$7F; // 1F FILTER EG DEPTH -64~+63
  PitchEGIniLev : $00..$7F; // 20 PITCH EG INITIAL LEVEL -64~+63
  PitchEGAtt    : $00..$7F; // 21 PITCH EG ATTACK TIME -64~+63
  PitchEGRelLev : $00..$7F; // 22 PITCH EG RELEASE LEVEL -64~+63
  PitchEGRelTim : $00..$7F; // 23 PITCH EG RELEASE TIME -64~+63
  PortaSwMode   : $00..$03; // 24 PORTAMENTO SWITCH/MODE. bit0: off/on. bit1: 0: fingerd, 1: fulltime
  PortaTime     : $00..$7F; // 25 PORTAMENTO TIME 0~127
  PBRangeHi     : $10..$58; // 26 PITCH BEND RANGE HIGH -48~+24
  PBRangeLo     : $10..$58; // 27 PITCH BEND RANGE LOW -48~+24
  PanScaling    : $00..$64; // 28 PAN SCALING 0~100
  PanLFODpt     : $00..$63; // 29 PAN LFO DEPTH 0~99
  VelLimitLo    : $01..$7F; // 2A VELOCITY LIMIT LOW 1~127
  VelLimitHi    : $01..$7F; // 2B VELOCITY LIMIT HIGH 1~127
  ExprLow       : $00..$7F; // 2C EXPRESSION LOW LIMIT 0~127
  SustainRcv    : $00..$01; // 2D SUSTAIN Rcv SW off/on
  LFO2Rate      : $00..$7F; // 2E LFO2 RATE -64~+63
  LFO2ModDpt    : $00..$7F; // 2F LFO2 MOD DEPTH -64~+63
  Reserved      : packed array[0..3] of TReserved; // 30 Reserved
end;

TLevels=packed array[0..3] of $00..$64;
TRates =packed array[0..3] of $00..$63;
TFilterType=(LPF24, LPF18, LPF12, HPF, BPF, BEF);

TEnvelope=packed record
    Levels:TLevels;
    Rates :TRates;
end;

TLFOWaveForm=(Triangle,SawDown,SawUp,Square,Sine,SampleHold);
TLFOPhase=(Phase0=0,Phase90=1,Phase180=2,Phase270=3);
TLFOKeySync=(off,&on);



TVoiceCommonSysex = packed record
  Name      : Array[1 .. 10] of ansichar; // 00 NAME 0
  Reserved  : Array[0 .. 3] of TReserved; // 0A reserved

  Category  : TCategory;               // 0E CATEGORY
  Reserved2 : TReserved;                 // 0F reserved
  LFO1:record
    WaveForm : TLFOWaveForm;                 // 10 COMMON LFO1 - waveform
    /// <summary>Sets the speed of the LFO. “0” is the slowest Speed setting, A setting of “99” produces the fastest LFO variation.</summary>
    Speed : $00..$63;                 // 11 COMMON LFO1 - speed
    /// <summary>
    /// Delay between when a key is pressed and modulation kicks in
    /// </summary>
    /// <remarks>
    /// Sets the delay time between the beginning of a note and the beginning of LFO operation. The minimum setting “0”
    /// results in no delay, while a setting of “99” produces the longest delay before the LFO begins operation.
    /// </remarks>
    Delay : $00..$63;                 // 12 COMMON LFO1 - delay

    /// <summary>
    /// Determines whether the LFO runs continuously (off), or is triggered by notes played (on) so that modulation always
    /// begins from the same point in the LFO waveform when a note is played.
    /// </summary>
    Sync      : $00..$01;                 // 13 COMMON LFO1 - key sync
    Reserved3 : TReserved;             // 14 reserved
    /// <summary>
    /// Pitch Modulation Depth
    /// Sets the maximum amount of pitch modulation that can be applied to the current voice. A “0” setting produces no
    /// modulation while a setting of “99” produces maximum modulation. Pitch modulation produces a periodic pitch
    /// variation, thereby creating a vibrato effect.
    /// No effect will be produced if EDIT [VOICE] mode OPERATOR/Sns/Pitch Mod parameter (page 69) is set to “0”.
    /// </summary>
    PMD   : $00..$63;                 // 15 COMMON LFO1 - pitch modulation depth
    /// <summary>
    /// Amplitude Modulation Depth
    ///
    /// Sets the maximum amount of amplitude modulation that can be applied to the current voice. A “0” setting produces
    /// no modulation while a setting of “99” produces maximum modulation. Amplitude modulation produces a periodic
    /// variation in the volume of the sound, thus creating a tremolo effect.
    /// No effect will be produced if EDIT [VOICE] mode OPERATOR/Sns/Amp Mod parameter (page 70) is set to “0”.
    /// </summary>
    AMD   : $00..$63;                 // 16 COMMON LFO1 - amplitude modulation depth
    /// <summary>
    /// Frequency Modulation Depth
    /// Sets the maximum amount of frequency modulation that can be applied to the current voice. A “0” setting produces
    /// no modulation while a setting of “99” produces maximum modulation. Frequency modulation produces a periodic
    /// variation in the frequency, thus creating a vibrato-like effect which is slightly different from simple pitch modulation.
    /// No effect will be produced if EDIT [VOICE] mode OPERATOR/Sns/Freq Mod parameter (page 70) is set to “0”.
    ///
    /// </summary>
    FMD       : $00..$63;                 // 17 COMMON LFO1 - frequency modulation depth
  end;

  LFO2:record
    LFO2Wave  : TLFOWaveForm;             // 18 COMMON LFO2 - waveform
    LFO2Speed : $00..$7F;                 // 19 COMMON LFO2 - speed
    Reserved4 : TReserved; // 1A reserved
    Reserved5 : TReserved; // 1A reserved
    /// <summary>
    /// Phase
    /// Determines at which point in the LFO waveform the LFO will begin operation. The values correspond to phase
    /// angles in degrees. The illustration below shows how the various phase angles correspond to points on the LFO
    /// waveform (a sine wave is used for clarity).
    /// </summary>
    LFO2Phase : { $00..$03 }TLFOPhase;  // 1C COMMON LFO2 - phase (0: 0, 1: 90, 2: 180, 3: 270)
    LFO2Sync  : { $00..$01 }Boolean;    // 1D COMMON LFO2 - key sync
  end;

  /// <summary>
  /// Transposes the pitch of the current voice down or up in semitone steps over a ±2 octave range.
  /// </summary>
  /// <remarks>
  /// “0” corresponds to standard pitch.
  /// Each increment corresponds to a semitone.
  /// A setting of “-12”, for example, transposes the pitch down one octave
  /// </remarks>
  [default(24)]
  NoteShift : $00..$30; // 0..48            // 1E COMMON Note shift (-24-0-+24)

  PitchEG:packed record
//    PitchEGL1 : $00..$64;                 // 1F COMMON Pitch EG - level 0
//    PitchEGL2 : $00..$64;                 // 20 COMMON Pitch EG - level 1
//    PitchEGL3 : $00..$64;                 // 21 COMMON Pitch EG - level 2
//    PitchEGL4 : $00..$64;                 // 22 COMMON Pitch EG - level 4
//    PitchEGT1 : $00..$63;                 // 23 COMMON Pitch EG - time 1
//    PitchEGT2 : $00..$63;                 // 24 COMMON Pitch EG - time 2
//    PitchEGT3 : $00..$63;                 // 25 COMMON Pitch EG - time 3
//    PitchEGT4 : $00..$63;                 // 26 COMMON Pitch EG - time 4
    Envelope    : TEnvelope;
    PitchEGVS : $00..$07;               // 27 COMMON Pitch EG - velocity sensitivity
  end;

  FSeqVcOpH : $00..$01;                 // 28 COMMON Fseq voiced op (8) switch -high
  FSeqVcOpL : $00..$7F;                 // 29 COMMON Fseq voiced op (1-7) switch -low

  FSeqUvOpH : $00..$01;                 // 2A COMMON Fseq unvoiced op (8) switch -high
  FSeqUvOpL : $00..$7F;                 // 2B COMMON Fseq unvoiced op (1-7) switch -low


 /// <summary>
 /// Selects the algorithm to be used for the current voice from among the 88
 /// variations available (see the algorithmsheet). A graphic representation of
 /// the selected algorithm appears at the bottom of the display.
 /// Also, the operator towhich feedback can be applied in the selected
 /// algorithm is indicated at the bottom of the display by "FBOP"followed by
 /// the number of the operator. An indication such as "FB3-5" in the same
 /// location means that feedback isapplied from the output of operator 5 to
 /// the input of operator 3. "FB—" means that there is no feedback in
 /// thecurrent algorithm.
 /// </summary>
  Algorithm : $00..$57;                 // 2C COMMON Algorithm preset number

  /// <summary>
  /// Voiced opX carrier level correction
  /// </summary>
  VcdOpCarC : packed array[0..7] of $00..$0F;  // 2D COMMON
  Reserved5 : packed Array[0..5] of TReserved;  // 35 reserved
  PitchEGR  : { $00..$03 } (EG_8va,EG_2va,EG_1va,EG_1_2va);  // 3B COMMON Pitch EG - range (8va, 2va, 1va, 1/2va) ---- Pitch EG Range (8oct, 4oct, 1oct, 1/2oct)
  PitchEGTS : $00..$07;                 // 3C COMMON Pitch EG - time scaling depth

  /// <summary>
  /// Sets the amount of feedback applied to the feedback operator in the
  /// currently selected algorithm. Higher valuesapply a greater amount of
  /// feedback.
  /// </summary>
  /// <remarks>
  /// The operator to which feedback can be applied in the selected
  /// algorithm isindicated at the bottom of the display by "FBOP" followed by
  /// the number of the operator. An indication such as"FB3-5" in the same
  /// location means that feedback is applied from the output of operator 5 to
  /// the input of operator 3."FB—" means that there is no feedback in the
  /// current algorithm
  /// </remarks>
  FeedBack  : $00..$07;                 // 3D COMMON Voiced feedback level
  PitchEGL  : $00..$64;                 // 3E COMMON Pitch EG - level 3
  Reserved6 : TReserved;                // 3F reserved
  FCDest    : packed array[0..4] of $00..$7F;  // 40 COMMON Formant Control Destination 1
                                               //    dest (off,out,freq,width) /V/N/OP (1~8)
                                               //    [--ddvooo]
  FCDepth   : packed array[0..4] of $00..$7F;  // 45 COMMON Formant Control Depth 1 (-64~+63)
  FmDest    : packed array[0..4] of $00..$7F;  // 4A 00-03/00-01/00-07 COMMON FM Control Destination 1
                                               //    dest (off,out,freq,width) /V/N/OP (1~8)
                                               //    [--ddvooo]
  FmDepth   : packed array[0..4] of $00..$7F;  // 4F 00-7F COMMON FM Control Depth 1 (-64~+63)
  Filter    :
  packed record
    &Type   : TFilterType;              // 54 COMMON Filter Type (LPF24, LPF18, LPF12, HPF, BPF, BEF)
    Res    : $00..$74;                 // 55 COMMON Filter Resonance (-16~+100)
    ResVel : $00..$0E;                 // 56 COMMON Filter Resonance Vel Sens (-7~+7)
    Cutoff : $00..$7F;                 // 57 COMMON Filter Cutoff Frequency
    EGVel  : $00..$0E;                 // 58 COMMON Filter EG Depth Vel Sens (-7~+7)
    LFO1Dp : $00..$63;                 // 59 COMMON Filter Cutoff Frequency LFO1 Depth
    LFO2Dp : $00..$63;                 // 5A COMMON Filter Cutoff Frequency LFO2 Depth
    KeyScl : $00..$7F;                 // 5B COMMON Filter Cutoff Frq. Key Scale Dpt (-64~+63)
    KeySp  : $00..$7F;                 // 5C COMMON Filter Cutoff Frequency Key Scale Point
    InGain : $00..$18;                 // 5D COMMON Filter Input Gain (-12~+12)
    Reserved7 : packed array[0..5] of TReserved;  // 5E reserved
    EGDpt  : $00..$7F;                 // 64 COMMON Filter EG - depth (-64~+63)
//    FltEGL1   : $00..$64;                 // 65 COMMON Filter EG - level4
//    FltEGL2   : $00..$64;                 // 66 COMMON Filter EG - level1
//    FltEGL3   : $00..$64;                 // 67 COMMON Filter EG - level2
//    FltEGL4   : $00..$64;                 // 68 COMMON Filter EG - level3
//    FltEGT1   : $00..$63;                 // 69 COMMON Filter EG - time1
//    FltEGT2   : $00..$63;                 // 6A COMMON Filter EG - time2
//    FltEGT3   : $00..$63;                 // 6B COMMON Filter EG - time3
//    FltEGT4   : $00..$63;                 // 6C COMMON Filter EG - time4
    Envelope  : TEnvelope;
    Reserved8 : TReserved;                // 6D reserved
    FltEGAtTm : $00..$7F;                 // 6E 00-07 /00-07 COMMON Filter EG - attack time vel/time scale
    Reserved9 : TReserved;                // 6F reserved
  end;
end;

TEnvelopeGenerator=packed record
{$REGION 'envelope'}
//  Level1    : $00..$63;                 // 0C VOICED EG - level1
//  Level2    : $00..$63;                 // 0D VOICED EG - level2
//  Level3    : $00..$63;                 // 0E VOICED EG - level3
//  Level4    : $00..$63;                 // 0F VOICED EG - level4
//  Time1     : $00..$63;                 // 10 VOICED EG - time1
//  Time2     : $00..$63;                 // 11 VOICED EG - time2
//  Time3     : $00..$63;                 // 12 VOICED EG - time3
//  Time4     : $00..$63;                 // 13 VOICED EG - time4
{$ENDREGION}
  Envelope  : TEnvelope;

  /// <summary>
  /// The Hold Time parameter determines the length of time between the beginning
  /// of the envelope and the point at which the envelope begins to move towards
  /// the Level1 level at the Time1 rate, as shown below.
  /// </summary>
  HoldTime  : 0..99;      // 14 VOICED EG - hold time
  TimeScale : $00..$07;   // 15 VOICED EG - time scaling
end;


/// <summary>
/// These four parameters determine the shape of the frequency envelope generator for the selected operator. The
/// envelope starts at the initial level (“InitLevel”) at key-on, and then approaches the attack level (“AttackLevel”) at a
/// speed determined by the “Attack Time” parameter. Then the envelope approaches the normal pitch (0) again at a
/// speed determined by the setting of the “Decay Time” parameter.
/// </summary>
TFreqEG=packed record
  /// <summary>-50 .. 50</summary>
  IniV  : $00..$64;  // 08 VOICED oscillator frequency EG - initial value
  /// <summary>-50 .. 50</summary>
  AttV  : $00..$64;  // 09 VOICED oscillator frequency EG - attack value

  AttT  : $00..$63;  // 0A VOICED oscillator frequency EG - attack time
  DecT  : $00..$63;  // 0B VOICED oscillator frequency EG - decay time
end;


TOscTranspose=$00..$30;

/// <summary>
/// Specifies the frequency mode for the currently selected operator.
/// The “fixed” setting causes the operator to remain at a fixed frequency
/// regardless of the note played.
/// When set to “ratio,” the operator frequency will depend on the note played,
/// pitch control, and other parameters which affect pitch.
/// </summary>
TOscModeVoiced=(Ratio,Fixed);

const
  COscModeVoicedStr : array[TOscModeVoiced] of string=('Ratio','Fixed');

type
/// <summary>
/// When “normal” is selected the operator frequency is determined by the
/// F.Coarse and Freq Fine parameters, below.
/// When the “linkFO” (link to fundamental pitch) mode is selected, the voiced operator pitch is available.
/// When the “linkFF” (link to formant pitch    ) mode is selected, the voiced formant pitch is used.
/// This latter mode can only be selected when the 03: Form parameter is set to “frmt”.
/// </summary>
TOscModeUnVoiced=(Normal,LinkF0,LinkFF);

TFSeqTrack=(Tr1,Tr2,Tr3,Tr4,Tr5,Tr6,Tr7,Tr8);

TSkirt=0..7;

PVoiceVoicedSysex = ^TVoiceVoicedSysex;

TVoiceVoiced = record
  type
    TOsc =
    record
      KeySync     : boolean      ;
      Transpose   : TOscTranspose;

      /// <remarks>
      /// When “Freq Mode” is set to “Ratio”: 0 – 31
      /// When “Freq Mode” is set to “Fixed”: 0 – 21
      /// </remarks>
      FreqCoarse  : 0..31;                 // 01 VOICED oscillator frequency - coarse

      /// <remarks>
      /// When “Freq Mode” is set to “Ratio”: 0 – 99
      /// When “Freq Mode” is set to “Fixed”: 0 – 127
      /// </remarks>
      FreqFine    : 0..127;                 // 02 VOICED oscillator frequency - fine

      FrNoteSc    : 0..$63;                 // 03 VOICED oscillator frequency - note scaling

      BWBiasSense :byte             ;

      SpectralForm:TOscSpectralForm ;

      OscMode     :TOscModeVoiced ;
      /// <summary>
      /// This parameter is effective except when the “sine” spectral form
      /// (see “Form” parameter, above) is selected.
      /// It sets the spread of the “skirt” at the bottom of the formant or
      /// harmonics curve. Higher values produce a wider skirt.
      /// </summary>
      /// <remarks>
      /// Determines the spread of the “skirt” at the bottom of the formant
      /// harmonics curve. Higher values produce a wider skirt and smaller
      /// values produce a narrower skirt. This is not available when “Spectral”
      /// is set to “Sine.”
      /// </remarks>
      Skirt    : TSkirt;

      /// <summary>
      /// Specifies the Fseq “track” which will control the currently selected operator.
      /// Each Fseq has 8 tracks, each of which controls a single operator.
      /// Normally each operator is controlled by the correspondingly numbered
      /// Fseq track: i.e.
      ///    track 1 controls operator 1,
      ///    track 2 controls operator 2,
      ///    and so on through track 8 and operator 8.
      /// Changing the
      /// Fseq track-to-operator assignments can, however, produce some
      /// interesting variations. Please note that the Fseq Tr assignments apply
      /// to both the voiced and unvoiced operators.
      /// </summary>
      FSeqTrack        : TFSeqTrack;

      FrRatio          : $00..$63;                 // 06 VOICED oscillator freq. ratio of band spectrum
      FrDetune         : $00..$1E;                 // 07 VOICED oscillator detune
      FrEG             : TFreqEG;
    end;

  var
  Osc         : TOsc;
  EG          : TEnvelopeGenerator;       // 0C .. 15

  /// <summary>
  /// KbdLevelScaling contains all the keyboard level scaling parameters for a DX7 voice.
  /// Keyboard level scaling lets you change the output level of an operator based on the key that is pressed.
  /// Each operator can be programmed to have any of 4 curves on either side of an adjustable breakpoint.
  /// The scaling can be used to make the tone and/or volume change as you move to different octaves.
  /// </summary>
  LevelScaling:
  record
    TotalLvl  : T0_99;                    // 16 VOICED level scaling - total level

    /// <summary>
    /// Breakpoint is the break point in the level-scaling curve.
    /// 0 corresponds to 1 1/3 octaves below the lowest note on the keyboard (A-1),
    /// and 99 corresponds to 2 octaves above the highest note on the keybard.
    /// </summary>
    BreakPoint: { $00..$63 }TBreakPoint;  // 17 VOICED level scaling - break point (A-1~C8)
    /// <summary>LeftDpt controls the curve depth on the left side of the breakpoint.</summary>
    LeftDpt   : T0_99;                    // 18 VOICED level scaling - left depth
    /// <summary>RightDpt controls the curve depth on the right side of the breakpoint.</summary>
    RightDpt  : T0_99;                    // 19 VOICED level scaling - right depth

    LeftCurve : TCurve;                   // 1A VOICED level scaling - left  curve(0:-lin, 1:-exp, 2:+exp, 3:+lin)
    RightCurve: TCurve;                   // 1B VOICED level scaling - right curve(0:-lin, 1:-exp, 2:+exp, 3:+lin)
  end;
  Reserved    : array[0..2] of TReserved;  // 1C reserved

  Sensitivity : packed record
    FreqBiasSense: byte;
    PitchModSense: byte;


    FreqModSense : byte;
    FreqVelSense : byte;

    /// <summary>
    /// 0..7
    /// </summary>
    AmpModSense  : 0..7;

    /// <summary>
    /// -7 .. 7
    /// </summary>
    AmpVelSense  : 0..7;

    /// <summary>
    /// -7 .. 7
    /// </summary>
    EGBiasSense : 0..$E;                 // 22 VOICED - EG bias sense (-7~7)
  end;

//  LiveData         : TLiveData;

  property Volume:T0_99 read LevelScaling.TotalLvl write LevelScaling.TotalLvl;
  constructor Create(Sysex:PVoiceVoicedSysex);
end;

// 35 bytes
TVoiceVoicedSysex =
packed record
  KeySynTransp     : $00..$F7;                 // 00 VOICED oscillator key sync/transpose [-stttttt] (00-01/00-30)
  FrCoarse         : $00..$1F;                 // 01 VOICED oscillator frequency - coarse
  FrFine           : $00..$7F;                 // 02 VOICED oscillator frequency - fine
  FrNoteSc         : $00..$63;                 // 03 VOICED oscillator frequency - note scaling
  FrBiasSp         : $00..$7F;                 // 04 VOICED oscillator / bw bias sense (-7~7) /spectral form [-llllfff] (00-0E/00-07 )
  FrModeSkirtTrack : $00..$7F;                 // 05 VOICED oscillator mode/spectral skirt/Operator fseq track number [-msssnnn] (00-01/00-07/00-07)
  FrRatio          : $00..$63;                 // 06 VOICED oscillator freq. ratio of band spectrum
  FrDetune         : $00..$1E;                 // 07 VOICED oscillator detune
  FrEG             : TFreqEG;
  EG          : TEnvelopeGenerator;       // 0C .. 15
  LevelScaling:
  record
    TotalLvl  : $00..$63;                 // 16 VOICED level scaling - total level
    BreakPoint: { $00..$63 }TBreakPoint;  // 17 VOICED level scaling - break point (A-1~C8)
    LeftDpt   : $00..$63;                 // 18 VOICED level scaling - left depth
    RightDpt  : $00..$63;                 // 19 VOICED level scaling - right depth
    LeftCurve : TCurve;                   // 1A VOICED level scaling - left  curve(0:-lin, 1:-exp, 2:+exp, 3:+lin)
    RightCurve: TCurve;                   // 1B VOICED level scaling - right curve(0:-lin, 1:-exp, 2:+exp, 3:+lin)
  end;
  Reserved    : array[0..2] of TReserved; // 1C reserved
  FrBias_PMS  : $00..$7F;                 // 1F VOICED - freq bias sense/ pitch mod sense     fbs : (-7~7) [-bbbbmmm] (00-0E/00-07)
  FrModS_FVS  : $00..$7F;                 // 20 VOICED - freq mod sense / freq velocity sense fvs : (-7~7) [-fffvvvv] (00-07/00-0E)
  AmpModSense_AmpVelSense : $00..$7F;     // 21 VOICED - amp mod sense  / amp velocity sense   vs : (-7~7) [-aaavvvv] (00-07/00-0E)
  EGBiasSense : $00..$7F;                 // 22 VOICED - EG bias sense (-7~7)
end;

// Voice Unvoiced Parameter (Byte Count : 27 bytes / op ) (00-0E)
// 27 bytes
TVoiceUnvoicedSysex =
record
  FrmPTrans   : $00..$30; // 23 UNVOICED formant pitch - transpose
  FrmPMode    : $00..$7F; // 24 UNVOICED formant pitch - mode /coarse [-mmccccc] (00-02/00-15)
  FrmPFine    : $00..$7F; // 25 UNVOICED formant pitch - fine
  FrmPNoteSC  : $00..$63; // 26 UNVOICED formant pitch - note scaling
  FrmSShBW    : $00..$63; // 27 UNVOICED formant shape - band width
  FrmSShBias  : $00..$0E; // 28 UNVOICED formant shape - bw bias sense (-7~7)
  FrmRFrmR    : $00..$7F; // 29 UNVOICED formant resonance / formant skirt /nskt [--rrrsss] (00-07/00-07)
  FreqEG      : TFreqEG;
{
  FreqEGInitV : $00..$64; // 2A UNVOICED frequency EG - initial value
  FreqEGAttV  : $00..$64; // 2B UNVOICED frequency EG - attack value
  FreqEGAttT  : $00..$63; // 2C UNVOICED frequency EG - attack time
  FreqEGDecT  : $00..$63; // 2D UNVOICED frequency EG - decay time
  }
  Level       : $00..$63; // 2E UNVOICED level
  LevelKS     : $00..$0E; // 2F UNVOICED level - key scaling
  EG          : TEnvelopeGenerator; // 30 .. 39 UNVOICED
  FreqBias    : $00..$0E; // 3A UNVOICED - freq bias sense nfbs : (-7~7) [----bbbb]
  FreqMod     : $00..$7F; // 3B UNVOICED - freq mod sense/freq velocity sense nfvs : (-7~7) [-fffvvvv] (00-07/00-0E)
  AmpMod      : $00..$7F; // 3C UNVOICED - amp mod sense/amp velocity sense nvs : (-7~7) [-aaavvvv] (00-07/00-0E)
  EGBiasSense : $00..$0E; // 3D UNVOICED - EG bias sense (-7~7)
end;

// Voice Unvoiced Parameter (Byte Count : 27 bytes / op ) (00-0E)
// 27 bytes
TVoiceUnvoiced =
record
  FrmPTrans   : TOscTranspose { $00..$30}; // 23 UNVOICED formant pitch - transpose
  FrmPitchMode  : $00..$02; // 24 UNVOICED formant pitch - mode /coarse [-mmccccc] (00-02/00-15)
  FrmPitchCoarse: $00..$15; // 24 UNVOICED formant pitch - mode /coarse [-mmccccc] (00-02/00-15)
  FrmPFine    : $00..$7F; // 25 UNVOICED formant pitch - fine
  FrmPNoteSC  : $00..$63; // 26 UNVOICED formant pitch - note scaling
  FrmSShBW    : $00..$63; // 27 UNVOICED formant shape - band width
  FrmSShBias  : $00..$0E; // 28 UNVOICED formant shape - bw bias sense (-7~7)
  FrmRFrmResonance: $00..$7F; // 29 UNVOICED formant resonance / formant skirt /nskt [--rrrsss] (00-07/00-07)
  FrmRFrmSkirt    : $00..$7F; // 29 UNVOICED formant resonance / formant skirt /nskt [--rrrsss] (00-07/00-07)
  FrmRFrmRNskt    : $00..$7F; // 29 UNVOICED formant resonance / formant skirt /nskt [--rrrsss] (00-07/00-07)
  FreqEG      : TFreqEG;
//  FreqEGInitV : $00..$64; // 2A UNVOICED frequency EG - initial value
//  FreqEGAttV  : $00..$64; // 2B UNVOICED frequency EG - attack value
//  FreqEGAttT  : $00..$63; // 2C UNVOICED frequency EG - attack time
//  FreqEGDecT  : $00..$63; // 2D UNVOICED frequency EG - decay time
  Level       : $00..$63; // 2E UNVOICED level
  LevelKS     : $00..$0E; // 2F UNVOICED level - key scaling
  EG          : TEnvelopeGenerator; // 30 .. 39 UNVOICED
  FreqBias    : $00..$0E; // 3A UNVOICED - freq bias sense nfbs : (-7~7) [----bbbb]
  FreqModSense: $00..$07; // 3B UNVOICED - freq mod sense/freq velocity sense nfvs : (-7~7) [-fffvvvv] (00-07/00-0E)
  FreqVelSense: $00..$0E; // 3B UNVOICED - freq mod sense/freq velocity sense nfvs : (-7~7) [-fffvvvv] (00-07/00-0E)
  AmpModSense : $00..$07; // 3C UNVOICED - amp mod sense/amp velocity sense nvs : (-7~7) [-aaavvvv] (00-07/00-0E)
  AmpVelSense : $00..$0E; // 3C UNVOICED - amp mod sense/amp velocity sense nvs : (-7~7) [-aaavvvv] (00-07/00-0E)
  EGBiasSense : $00..$0E; // 3D UNVOICED - EG bias sense (-7~7)

//  LiveData         : TLiveData;

end;

TSysexHeader =
record
  Status   , { $F0 }
  VendorID , { $43 }
  DeviceID , { $00 }
  ModelID   : byte { $00 };
  ByteCount : TMidiWord;
  AddressHi,
  AddressMid,
  AddressLo : 0..127;
end;

// 208 bytes
TPerformanceSysex =
record
  Header   : TSysexHeader;
  Common   : TPerformanceCommonSysex;
  Effect   : TPerformanceEffectSysex;
  Part     : array[0..3] of TPerformancePartSysex;
  Footer   : Record Checksum, Close:0..127 end;
end;

TFS1ROperatorSysex = packed record
  Voiced   : TVoiceVoicedSysex;
  UnVoiced : TVoiceUnvoicedSysex;
end;

TFS1ROperator = packed record
//  Idx:integer;
  Voiced   : TVoiceVoiced;
  UnVoiced : TVoiceUnvoiced;
end;


// 608 bytes
PVoiceParamsSysex=^TVoiceParamsSysex;
TVoiceParamsSysex =
  packed record
    Header    : TSysexHeader;
    Common    : TVoiceCommonSysex;
    Operators : packed array[0..7] of TFS1ROperatorSysex;
    Footer    : packed record
                  Checksum,
                  Close:0..127
                end;
end;

PVoiceParams=^TVoiceParams;
TVoiceParams =
  record
    Common    : TVoiceCommonSysex;
    Operators : packed array[0..7] of TFS1ROperator;

    FileName:string;
    BankName:string;
    IndexInBank : integer;
    afterTouchEnabled:boolean;
    controllerModVal:double;
    fbRatio:double;
    procedure SetBankName(const b:string);
    function GetOpsCount:integer;
    function ToString:string;
  end;

TParamsBank=class(TList<TVoiceParams>)
  procedure SortByPatchName;
  procedure SortByBankName;
  procedure SortByAlgorithm;
  procedure SortByOpsCount;
end;


function CheckSum(var ar:array of byte):byte;
Function ReadPerformanceFromFile(FileName:String):TPerformanceSysex;
Function ReadVoiceFromFile(FileName:String):TVoiceParamsSysex;
procedure WriteVoiceToFile(Voice:TVoiceParamsSysex; FileName:String);


implementation

function TVoiceParams.GetOpsCount;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(Operators) do
  begin
    if Operators[I].Voiced.Volume > 0 then
      Inc(Result);
    if Operators[I].UnVoiced.Level > 0 then
      Inc(Result);
  end;

end;

procedure TParamsBank.SortByOpsCount;
begin
  self.Sort(TComparer<TVoiceParams>.Construct(
    function(const l,r:TVoiceParams):Integer
    begin
      Result := CompareValue( l.GetOpsCount, r.GetOpsCount )
    end
  ))
end;

procedure TParamsBank.SortByBankName;
begin
  self.Sort(TComparer<TVoiceParams>.Construct(
    function(const l,r:TVoiceParams):Integer
    begin
      Result := CompareText( l.BankName, r.BankName )
    end
  ))
end;

procedure TParamsBank.SortByPatchName;
begin
  self.Sort(TComparer<TVoiceParams>.Construct(
    function(const l,r:TVoiceParams):Integer
    begin
      Result := CompareText( string(l.Common.Name), string(r.Common.Name) )
    end
  ))
end;

procedure TParamsBank.SortByAlgorithm;
begin
  self.Sort(TComparer<TVoiceParams>.Construct(
    function(const l,r:TVoiceParams):Integer
    begin
      Result := CompareValue( l.Common.Algorithm, r.Common.Algorithm )
    end
  ))
end;


procedure TVoiceParams.SetBankName(const b: string);
begin
  BankName := b
end;

function CheckSum(var ar:array of byte):byte;
var
  A : array of byte;
  i: word;
  Size:Integer;
  Sum:longword;
begin
  Size := SizeOf(A);
  SetLength(A,Size);

  Move(ar[0],A[0],Size);
  A[Size-2]:=  0;
  A[Size-1]:=  $F7;

  Sum := 0;

  for i := 4 to Size-3 do
    Sum := (Sum + A[i])and $7F;

  Result := $80-sum;
  A[Size-2]:=$80-sum;

  A[Size-1]:=$F7;
  Move(A[0],Ar[0],Size);

end;



Function ReadPerformanceFromFile(FileName:String):TPerformanceSysex;
var
  F : File of Byte;
begin
//  if DetectFileType(FileName)= FS1RPerformance then
  begin
    AssignFile(F,FileName);
    Reset(F);
    BlockRead(F,Result,SizeOf(TPerformanceSysex));
    CloseFile(F);
  end;
end;

Function ReadVoiceFromFile(FileName:String):TVoiceParamsSysex;
var
  F : File of Byte;
begin
//  if DetectFileType(FileName)= FS1RVoice then
  begin
    AssignFile(F,FileName);
    Reset(F);
    BlockRead(F,Result,SizeOf(TVoiceParamsSysex));
    CloseFile(F);
  end;
end;

procedure WriteVoiceToFile(Voice:TVoiceParamsSysex; FileName:String);
var
  F : File of Byte;
  A : Array of Byte;
begin
  SetLength(A,619);
  Move(Voice,A[0],619);
  Voice.Footer.Checksum := CheckSum(A);
  AssignFile(F,FileName);
  ReWrite(F);
  BlockWrite(F,Voice,SizeOf(TVoiceParamsSysex));
  CloseFile(F);
end;

constructor TVoiceVoiced.Create(Sysex:PVoiceVoicedSysex);
begin
  Osc.KeySync      := boolean((Sysex.KeySynTransp shr 6) and 1);                 // 00 VOICED oscillator key sync/transpose [-stttttt] (00-01/00-30)
  Osc.Transpose    := sysex.KeySynTransp and $3F;
  Osc.FreqCoarse   := Sysex.FrCoarse;
  osc.FreqFine     := Sysex.FrFine;
  osc.FrNoteSc     := Sysex.FrNoteSc;
  Osc.BWBiasSense  := Wvn.Math.Bits.GetValue(Osc.BWBiasSense, 3, 4); // 0..0E
  Osc.SpectralForm := TOscSpectralForm( Wvn.Math.Bits.GetValue(Osc.BWBiasSense, 0, 3) ); // 0..7


  // VOICED oscillator mode/spectral skirt/Operator fseq track number [-msssnnn] (00-01/00-07/00-07)
  Osc.OscMode      := TOscModeVoiced( wvn.Math.Bits.GetValue( sysex.frModeSkirtTrack,6,1));
  Osc.Skirt        := wvn.Math.Bits.GetValue( sysex.FrModeSkirtTrack,3,3);
  Osc.FSeqTrack    := TFSeqTrack( wvn.Math.Bits.GetValue( sysex.FrModeSkirtTrack,0,3));

  osc.FrRatio := sysex.FrRatio;
  Osc.FrDetune := sysex.FrDetune;

  Osc.FrEG := sysex.FrEG;

  Self.EG := sysex.EG;
  Self.LevelScaling.TotalLvl := sysex.LevelScaling.TotalLvl;
  Self.LevelScaling.BreakPoint := sysex.LevelScaling.BreakPoint;
  Self.LevelScaling.LeftDpt := sysex.LevelScaling.LeftDpt;
  Self.LevelScaling.RightDpt := sysex.LevelScaling.RightDpt;
  Self.LevelScaling.LeftCurve := sysex.LevelScaling.LeftCurve;
  Self.LevelScaling.RightCurve := sysex.LevelScaling.RightCurve;

//  Self.FreqBiasSense := sysex.

  EG          := Default(TEnvelopeGenerator);       // 0C .. 15
  EG.Envelope.Levels[0] := 99;
  EG.Envelope.Levels[1] := 99;
  EG.Envelope.Levels[2] := 99;
  EG.Envelope.Levels[3] := 99;
  EG.Envelope.Rates[0] := 99;
  EG.Envelope.Rates[1] := 99;
  EG.Envelope.Rates[2] := 00;
  EG.Envelope.Rates[3] := 99;



  LevelScaling.TotalLvl  := $63;             // 16 VOICED level scaling - total level
  LevelScaling.BreakPoint:= TBreakPoint.C4;  // 17 VOICED level scaling - break point (A-1~C8)
  LevelScaling.LeftDpt   := $63;             // 18 VOICED level scaling - left depth
  LevelScaling.RightDpt  := $63;             // 19 VOICED level scaling - right depth
  LevelScaling.LeftCurve := TCurve.NegLin;  // 1A VOICED level scaling - left  curve(0:-lin, 1:-exp, 2:+exp, 3:+lin)
  LevelScaling.RightCurve:= TCurve.Poslin;  // 1B VOICED level scaling - right curve(0:-lin, 1:-exp, 2:+exp, 3:+lin)


//  Reserved    := array[0..2] of TReserved; // 1C reserved
//  FrBias_PMS  := $00..$7F;                 // 1F VOICED - freq bias sense/ pitch mod sense     fbs : (-7~7) [-bbbbmmm] (00-0E/00-07)
//  FrModS_FVS  := $00..$7F;                 // 20 VOICED - freq mod sense / freq velocity sense fvs : (-7~7) [-fffvvvv] (00-07/00-0E)
//  AmpModSense_AmpVelSense : $00..$7F;     // 21 VOICED - amp mod sense  / amp velocity sense   vs : (-7~7) [-aaavvvv] (00-07/00-0E)
  Sensitivity.EGBiasSense := 7;                 // 22 VOICED - EG bias sense (-7~7)

//  Self.Osc.KeySync := Sysex.KeySynTransp
end;


function TVoiceParams.ToString;
var
  sb:TStringBuilder;
  o,i:integer;
  op:^TFS1ROperator;
  f:ShortString;
begin
  sb := TStringBuilder.Create;
  sb.Append('Name       : '); sb.Append(string(Common.Name).Trim);  sb.AppendLine;
  sb.Append('Alg        : '); sb.Append(1+Common.Algorithm);  sb.AppendLine;
  sb.Append('Transpose  : '); sb.Append(Common.NoteShift );  sb.AppendLine;
//  sb.Append('Aftertouch : '); sb.Append(ifthen(Common. ,'On','Off')); sb.AppendLine;
  sb.Append('FeedbackLvl: '); sb.Append(Common.FeedBack); sb.AppendLine;


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
    op := @Operators[o];
//    op.UpdateFreq;

    sb.AppendFormat('%d: ',[6-o]);
//    sb.AppendFormat('[%s] ',[ifthen(op.enabled,'x',' ')]);

    sb.Append(COscModeVoicedStr[op.Voiced.Osc.OscMode]+' ');

//    case op.oscMode of
//      Coarse: str(op.freqRatio:7:2,f);
//      Fixed : str(op.freqFixed:7:2,f);
//    end;
    sb.Append(f); sb.append(' ');

    sb.AppendFormat('%s%d ',[

      ifthen(op.Voiced.Osc.FrDetune -7 < 0,'-',
      ifthen(op.Voiced.Osc.FrDetune     =0,' ','+')),

      abs(op.Voiced.Osc.FrDetune)]);


     for I := 0 to 3 do
     begin
       sb.AppendFormat('%0.02d ',[ op.Voiced.EG.Envelope.Rates[i] ]);
       sb.AppendFormat('%0.02d ',[ op.Voiced.EG.Envelope.Levels[i] ]);
     end;


     sb.AppendFormat('%0.02d ',[ op.Voiced.Volume ]);
//   sb.AppendFormat('%g ',[ op.outputLevel ]);
     sb.AppendFormat('%d ',[ op.Voiced.Sensitivity.AmpVelSense ]);
     sb.AppendFormat('%d ',[ op.Voiced.Sensitivity.FreqModSense ]);

     sb.AppendFormat('%s%d ',[Notes[ord(op.Voiced.LevelScaling.BreakPoint) mod 12] , ord(op.Voiced.LevelScaling.BreakPoint) div 12  ]);
     sb.AppendFormat('%0.02d ',[ op.Voiced.LevelScaling.LeftDpt ]);
     sb.AppendFormat('%0.02d ',[ op.Voiced.LevelScaling.RightDpt ]);
//     sb.AppendFormat('%s ',[ Curves[op.Voiced.LevelScaling.LeftCurve] ]);
//     sb.AppendFormat('%s ',[ Curves[op.Voiced.LevelScaling.RightCurve] ]);
//     sb.AppendFormat('%d ',[ op.keyScaleRate ]);


     sb.Append(sLineBreak)
  end;


  sb.Append('                ');
  for I := 0 to 3 do
  begin
    sb.AppendFormat('%0.02d ',[
      self.Common.PitchEG.Envelope.Rates[i],
      self.Common.PitchEG.Envelope.Levels[I]
      ]);
  end;
  sb.Append(sLineBreak);

  Result := sb.ToString;
end;



end.
