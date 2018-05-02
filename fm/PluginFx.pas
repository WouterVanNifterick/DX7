unit PluginFx;

interface


  function tptpc(var state:Single; inp, cutoff : Single):single;inline;

  function tptlpupw(var state:Single; inp, cutoff, srInv : Single):single;inline;
  /// <summary>
  ///   static float linsc(float param,const float min,const float max) {
  ///   return (param) * (max - min) + min;
  ///   }
  /// </summary>
  function logsc(param : Single; const min, max:Single; rolloff : Single=19):Single;

var
  dc : Single = 1e-18;

type
TPluginFx = class
  s1,
  s2,
  s3,
  s4,
  sampleRate,
  sampleRateInv,
  d,
  c,
  R24,
  rcor24,
  rcor24Inv,
  bright,
  mm,
  mmt           : Single;
  mmch          : integer;
  rCutoff,
  rReso,
  rGain,
  pReso,
  pCutoff,
  pGain         : Single;
  bandPassSw    : Boolean;
  rcor,
  rcorInv       : Single;
  R             : integer;
  dc_id,
  dc_od,
  dc_r,
  uiCutoff,
  uiReso,
  uiGain        : Single;
  constructor Create;
  procedure init( sr : integer);
  function NR24( sample, g, lpc : Single):Single;inline;
  function NR( sample, g : Single):Single;inline;
  procedure process(work : TArray<Single>; sampleSize : integer);
end;


implementation

uses Math;


function tptpc(var state:Single; inp, cutoff : Single):single;inline;
var
  v, res : Double;
begin
  v      := (inp - state) * cutoff / (1 + cutoff);
  res    := v + state;
  state  := res + v;
  Result := res;
end;


function tptlpupw(var state:Single; inp, cutoff, srInv : Single):single;inline;
var
  v, res : Double;
begin
  cutoff := (cutoff * srInv)*pi;
  v      := (inp - state) * cutoff / (1 + cutoff);
  res    := v + state;
  state  := res + v;
  Result := res;
end;


/// <summary>
///   static float linsc(float param,const float min,const float max) {
///   return (param) * (max - min) + min;
///   }
/// </summary>
function logsc(param : Single; const min, max:Single; rolloff : Single=19):Single;
begin
  Result := ((exp(param * Log2(rolloff+1)) - 1.0) / (rolloff)) * (max-min) + min;
end;



{ PluginFx }

constructor TPluginFx.Create;
begin
    uiCutoff := 1;
    uiReso   := 0;
    uiGain   := 1;
end;


procedure TPluginFx.init( sr : integer);
var
  rcrate : Single;
begin
    mm            := 0;
    s1            := 0;
    s2 := 0;
    s3 := 0;
    s4 := 0;
    c := 0;
    d := 0;
    R24           := 0;
    mmch          := trunc(mm * 3);
    mmt           := mm*3-mmch;
    sampleRate    := sr;
    sampleRateInv := 1/sampleRate;
    rcrate        := sqrt((44000/sampleRate));
    rcor24        := (970.0 / 44000)*rcrate;
    rcor24Inv     := 1 / rcor24;
    bright        := tan((sampleRate*0.5-10) * pi * sampleRateInv);
    R             := 1;
  rcor            := (480.0 / 44000)*rcrate;
    rcorInv       := 1 / rcor;
    bandPassSw    := false;
    pCutoff       := -1;
    pReso         := -1;
    dc_r          := 1.0-(126.0/sr);
    dc_id         := 0;
    dc_od         := 0;
end;


function TPluginFx.NR24( sample, g, lpc : Single):Single;
var
  ml, S, G_, y : Single;
begin
    ml     := 1 / (1+g);
    S      := (lpc*(lpc*(lpc*s1 + s2) + s3) +s4)*ml;
    G_      := lpc*lpc*lpc*lpc;
    y      := (sample - R24 * S) / (1 + R24*G_);
    Result := y + 1e-8;
end;


function TPluginFx.NR( sample, g : Single):Single;
var
  y : Single;
begin
    y      := ((sample- R * s1*2 - g*s1  - s2)/(1+ g*(2*R + g))) + dc;
    Result := y;
end;


procedure TPluginFx.process( work : TArray<Single>; sampleSize : integer);
var
  t_fd       : Single;
  i          : integer;
  cutoffNorm, 
  g, 
  lpc        : Single;
  s, 
  y0         : Single;
  v, 
  res        : Double;
  y1, 
  y2, 
  y3, 
  y4, 
  mc         : Single;
begin
    // very basic DC filter
    t_fd    := work[0];
    work[0] := work[0] - dc_id + dc_r * dc_od;
    dc_id   := t_fd;
    for i := 1 to sampleSize-1 do begin 
        t_fd := work[i];
        work[i] := work[i] - dc_id + dc_r * work[i-1];
        dc_id := t_fd;
    end; 
    dc_od := work[sampleSize-1];
    if uiGain <> 1  then begin 
        for i := 0 to sampleSize-1 do 
            work[i]  := work[i]  * uiGain;
    end; 
    // don't apply the LPF if the cutoff is to maximum
    if  uiCutoff = 1  then Exit;
    if (uiCutoff <> pCutoff) or (uiReso <> pReso) then begin
        rReso := (0.991-logsc(1-uiReso,0,0.991));
        R24 := 3.5 * rReso;
        cutoffNorm := logsc(uiCutoff,60,19000);
        rCutoff := tan(cutoffNorm * sampleRateInv * PI);
        pCutoff := uiCutoff;
        pReso := uiReso;
        R := 1 - trunc(rReso); //@@@
    end; 
    // THIS IS MY FAVORITE 4POLE OBXd filter
    // maybe smooth this value
    g   := rCutoff;
    lpc := g / (1 + g);
    for i := 0 to sampleSize-1 do
    begin
        s := work[i];
        s := s - 0.45*tptlpupw(c,s,15,sampleRateInv);
        s := tptpc(d,s,bright);
        y0 := NR24(s,g,lpc);
        //first low pass in cascade
        v := (y0 - s1) * lpc;
        res := v + s1;
        s1 := res + v;
        //damping
        s1 := arctan(s1*rcor24)*rcor24Inv;
        y1 := res;
        y2 := tptpc(s2,y1,g);
        y3 := tptpc(s3,y2,g);
        y4 := tptpc(s4,y3,g);
        mc := 0.0;
        case mmch of
          0: mc := ((1 - mmt) * y4 + (mmt) * y3);
          1: mc := ((1 - mmt) * y3 + (mmt) * y2);
          2: mc := ((1 - mmt) * y2 + (mmt) * y1);
          3: mc := y1;
        end; // case
        //half volume comp
        work[i] := mc * (1 + R24 * 0.45);
    end;
end;




end.
