unit Dx7;

interface

uses
  System.SysUtils,
  synthunit,
  ringbuffer,
  freqlut,
  lfo,
  exp2,
  sin,
  pitchenv;

type
  TDx7 = class
  private
  var
    FRingBuffer: TRingbuffer;
    FSynthUnit : TSynthUnit;
    FOutBuf16  : TArray<int16>;
    FBufSize   : uint32;
  public
    constructor Create( bufsize, sr : integer);
    procedure resize(bufsize: uint32);
    procedure onMidi(status, data1, data2: byte);
    procedure onSysex(msg: TBytes);
    procedure onPatch(patch: TBytes);
    procedure onParam(idparam: uint32; value: Double);
    procedure onProcess(output:TArray<single>);
  end;

implementation

{ DX7 }

procedure TDx7.resize(bufsize: uint32);
begin
  FBufSize := bufsize;
  SetLength(FOutBuf16, FBufSize);
end;

constructor TDx7.Create(bufsize, sr: integer);
begin
  TFreqlut.init(sr);
//  LFO := TLFO.Create(sr);
  TPitchEnv.Create(sr);
  Resize(bufsize);
  FRingBuffer := Default(TRingBuffer);
  FSynthUnit  := TSynthUnit.Create(@FRingBuffer, sr);
end;

procedure TDx7.onMidi(status, data1, data2: byte);
var
  msg: array [0 .. 2] of byte;
begin
  msg[0] := status;
  msg[1] := data1;
  msg[2] := data2;

  FRingBuffer.Write(@msg[0], 3);
end;

procedure TDx7.onSysex(msg: TBytes);
begin
  if length(msg) = 4104 then
    FRingBuffer.Write(@msg[0], 4104);
end;

procedure TDx7.onPatch(patch: TBytes);
begin
  FSynthUnit.onPatch(patch);
end;

procedure TDx7.onParam(idparam: uint32; value: Double);
begin
  FSynthUnit.onParam(idparam, trunc(value));
end;

procedure TDx7.onProcess(output:TArray<single>);
const
  scaler = 0.00003051757813;
var
  i:integer;
begin
  // mono 16-bit signed ints
  FSynthUnit.GetSamples(FBufSize, FOutBuf16);

  for i:=0 to FBufSize-1 do
    output[i] := FOutBuf16[i] * scaler;
end;

end.
