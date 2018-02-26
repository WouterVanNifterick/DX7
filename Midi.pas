unit Midi;

interface

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



implementation

end.
