unit B200.Sysex;

interface

type
  TVCEDOscParams =
  record
    AttackRate    {AR} : 1 .. 31;  //  0   1 - 31
    Decay1Rate    {D1R}: 0 .. 31;  //  1   0 - 31
    Decay2Rate    {D2R}: 0 .. 31;  //  2   0 - 31
    ReleaseRate   {RR }: 1 .. 15;  //  3
    Decay1Level   {D1L}: 0 .. 15;  //  4
    KbScalingLev  {LS }: 0 .. 99;  //  5
    KbScalingRate1{RS }: 0 ..  3;  //  6    OP.4
    EgBiasSens    {EBS}: 0 ..  7;  //  7
    KbScalingRate2{AME}: 0 ..  1;  //  8
    KeyVelocity   {KVS}: 0 ..  7;  //  9
    OutputLevel   {OL} : 0 .. 99;  // 10
    OscFreq       {CRS}: 0 .. 63;  // 11
    Detune        {DET}: 0 ..  6;  // 12    (center = 3)
  end;

{
   F = 3;
   data size = 128*32 = 4096 ($1000)
   data format = 7 bit binary
   total bulk size = 4096 + 8 = 4104;
}
  TVCED =
  record
    Osc               : packed array[1..4] of tVCEDOscParams; // 0,13,26,39
    Algorithm         : 0 .. 7;  // 52   0 -  7
    FeedbackLevel     : 0 .. 7;  // 53   0 -  7
    LFOSpeed     {LFS}: 0 ..99;  // 54   0 - 99
    LFODelay     {LFD}: 0 ..99;  // 55   0 - 99
    PitchModDepth{PMD}: 0 ..99;  // 56   0 - 99
    AmpModDepth  {AMD}: 0 ..99;  // 57   0 - 99
    LFOSync      {SY} : 0 .. 1;  // 58   0 -  1
    LFOWave      {LFW}: 0 .. 3;  // 59   0 -  3
    PitchModSens {PMS}: 0 .. 7;  // 60   0 -  7
    AmpModSens   {AMS}: 0 .. 3;  // 61   0 -  3
    Transpose         : 0 ..48;  // 62   0 - 48  (center = 24)
    PolyMode     {MO} : 0 .. 1;  // 63   0 -  1  (0=Mono, 1=Poly)
    PBRange           : 0 ..12;  // 64   0 - 12
    PortaMode         : 0 .. 1;  // 65   0 -  1
    PortaTime         : 0 ..99;  // 66   0 - 99                  DX11 ONLY
    FootVolume        : 0 ..99;  // 67   0 - 99
    SustainFootSW{SU} : 0 .. 1;  // 68   0 -  1                  DX11 ONLY
    PortFootSW   {PO} : 0 .. 1;  // 69   0 -  1                  DX11 ONLY
    ChorusSW     {CH} : 0 .. 1;  // 70   0 -  1                  DX11 ONLY
    ModWhlPitchModRng : 0 ..99;  // 71   0 - 99
    ModWhlAmpModRng   : 0 ..99;  // 72   0 - 99
    BreathPitchModRng : 0 ..99;  // 73   0 - 99
    BreathAmpModRng   : 0 ..99;  // 74   0 - 99
    BreathPitchBiasRng: 0 ..100; // 75   0 - 100 (center = 50)
    BreathEGBiasRng   : 0 ..99;  // 76   0 - 99
    VoiceName         : array[0..9] of ansichar; // 77  32 - 127
    PitchEGRate  {PR} : array[1..3] of 0 ..99;   // 87   0 .. 99                  DX11 ONLY
    PitchEGLevel {PL} : array[1..3] of 0 ..99;   // 90   0 .. 99  (center = 50)   DX11 ONLY
    OpMask            : 0..127;  // 0 = all off, $0F = all on, etc
  end;



implementation

end.
