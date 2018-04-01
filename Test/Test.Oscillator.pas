unit Test.Oscillator;

interface

uses
  WvN.Console,
  System.TypInfo,
  System.diagnostics,
  FM.Oscillator,
  System.SysUtils,
  DUnitX.TestFramework;

type

  [TestFixture]
  TOscillatorTest = class(TObject)

  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    // Sample Methods
    // Simple single Test
    [Test]
    // phase 0
    [TestCase('phase 0/sinus'     ,'sinus'     +',0,0'  )]
    [TestCase('phase 0/opl2_w1'   ,'opl2_w1'   +',0,0'  )]
    [TestCase('phase 0/opl2_w2'   ,'opl2_w2'   +',0,0'  )]
    [TestCase('phase 0/opl2_w3'   ,'opl2_w3'   +',0,0'  )]
    [TestCase('phase 0/opl2_w4'   ,'opl2_w4'   +',0,0'  )]
    [TestCase('phase 0/op4_w1'    ,'op4_w1'    +',0,0'  )]
    [TestCase('phase 0/op4_w2'    ,'op4_w2'    +',0,0'  )]
    [TestCase('phase 0/op4_w3'    ,'op4_w3'    +',0,0'  )]
    [TestCase('phase 0/op4_w4'    ,'op4_w4'    +',0,0'  )]
    [TestCase('phase 0/op4_w5'    ,'op4_w5'    +',0,0'  )]
    [TestCase('phase 0/op4_w6'    ,'op4_w6'    +',0,0'  )]
    [TestCase('phase 0/op4_w7'    ,'op4_w7'    +',0,0'  )]
    [TestCase('phase 0/op4_w8'    ,'op4_w8'    +',0,0'  )]
    [TestCase('phase 0/saw_up'    ,'saw_up'    +',0,-1'  )]
    [TestCase('phase 0/saw_down'  ,'saw_down'  +',0,1'  )]
    [TestCase('phase 0/square'    ,'square'    +',0,1'  )]
    [TestCase('phase 0/triangle'  ,'triangle'  +',0,-1'  )]
    [TestCase('phase 0/whitenoise','whitenoise'+',0,0,1')]

    // phase pi
    [TestCase('phase half pi/sinus'     ,'sinus'     +',1.57079632679,1')]
    [TestCase('phase half pi/opl2_w1'   ,'opl2_w1'   +',1.57079632679,1')]
    [TestCase('phase half pi/opl2_w2'   ,'opl2_w2'   +',1.57079632679,1')]
    [TestCase('phase half pi/opl2_w3'   ,'opl2_w3'   +',1.57079632679,1')]
//    [TestCase('phase half pi/opl2_w4'   ,'opl2_w4'   +',1.57079632679,0')]
    [TestCase('phase half pi/op4_w1'    ,'op4_w1'    +',1.57079632679,1')]
    [TestCase('phase half pi/op4_w2'    ,'op4_w2'    +',1.57079632679,1')]
    [TestCase('phase half pi/op4_w3'    ,'op4_w3'    +',1.57079632679,1')]
    [TestCase('phase half pi/op4_w4'    ,'op4_w4'    +',1.57079632679,1')]
    [TestCase('phase half pi/op4_w5'    ,'op4_w5'    +',1.57079632679,0')]
    [TestCase('phase half pi/op4_w6'    ,'op4_w6'    +',1.57079632679,0')]
    [TestCase('phase half pi/op4_w7'    ,'op4_w7'    +',1.57079632679,0')]
    [TestCase('phase half pi/op4_w8'    ,'op4_w8'    +',1.57079632679,0')]
    [TestCase('phase half pi/saw_up'    ,'saw_up'    +',1.57079632679,-0.5')]
    [TestCase('phase half pi/saw_down'  ,'saw_down'  +',1.57079632679,0.5')]
    [TestCase('phase half pi/triangle'  ,'triangle'  +',1.57079632679,0')]
    [TestCase('phase half pi/whitenoise','whitenoise'+',1.57079632679,0,1')]

    // phase pi
    [TestCase('phase pi/sinus'     ,'sinus'     +',3.14159265359,0'  )]
    [TestCase('phase pi/opl2_w1'   ,'opl2_w1'   +',3.14159265359,0'  )]
    [TestCase('phase pi/opl2_w2'   ,'opl2_w2'   +',3.14159265359,0'  )]
    [TestCase('phase pi/opl2_w3'   ,'opl2_w3'   +',3.14159265359,0'  )]
    [TestCase('phase pi/opl2_w4'   ,'opl2_w4'   +',3.14159265359,0'  )]
    [TestCase('phase pi/op4_w1'    ,'op4_w1'    +',3.14159265359,0'  )]
    [TestCase('phase pi/op4_w2'    ,'op4_w2'    +',3.14159265359,0'  )]
    [TestCase('phase pi/op4_w3'    ,'op4_w3'    +',3.14159265359,0'  )]
    [TestCase('phase pi/op4_w4'    ,'op4_w4'    +',3.14159265359,0'  )]
    [TestCase('phase pi/op4_w5'    ,'op4_w5'    +',3.14159265359,0'  )]
    [TestCase('phase pi/op4_w6'    ,'op4_w6'    +',3.14159265359,0'  )]
    [TestCase('phase pi/op4_w7'    ,'op4_w7'    +',3.14159265359,0'  )]
    [TestCase('phase pi/op4_w8'    ,'op4_w8'    +',3.14159265359,0'  )]
    [TestCase('phase pi/saw_up'    ,'saw_up'    +',3.14159265359,0')]
    [TestCase('phase pi/saw_down'  ,'saw_down'  +',3.14159265359,0')]
    // not very useful to measure square halfwave the wavelength
//    [TestCase('phase pi/square'    ,'square'    +',3.14159265359,0,1.1')]
    [TestCase('phase pi/triangle'  ,'triangle'  +',3.14159265359,1')]
    [TestCase('phase pi/whitenoise','whitenoise'+',3.14159265359,0,1')]

    procedure TestIfWaveShapeIsCorrect(aWaveForm:TWaveForm;aPhase:Double;aExpected:Double;aRange:Double=0);

    [test]
    procedure TestPerformanceFunc;

//    [test]
    procedure TestPerformanceCase;
  end;

implementation

procedure TOscillatorTest.Setup;
begin
end;

procedure TOscillatorTest.TearDown;
begin
end;


procedure TOscillatorTest.TestIfWaveShapeIsCorrect(aWaveForm:TWaveForm;aPhase,aExpected,aRange:Double);
var
  i:Integer;
  u,v,v2:double;
  h,w,
  y:Integer;
begin
  Console.BufferWidth := 120;
  Console.WindowWidth := 120;
  if arange=0 then
    aRange := 0.000001;

  v := GetOsc(AWaveForm, aPhase);
{
  Console.Clear;
  h := 24;
  w := 75;

  Console.GotoXY(0,0);
  Console.GotoXY(0,0);
  Console.Write(GetEnumName(System.TypeInfo(TWaveForm),Ord(aWaveForm)));

  if aRange<>0 then
    WriteC(Format(' phase:%d%%, expected range:%g .. %g, value:%g',[round(100*aPhase/(2*pi)), aExpected-aRange,aExpected+aRange,v]))
  else
    WriteC(Format(' phase:%d%%, expected:%g, value:%g',[round(100*aPhase/(2*pi)), aExpected,v]));

  for i := 0 to w do
  begin
    u := GetOsc(aWaveForm, 2*pi*i/w);
    y := trunc( (0.5*u/2)*h*1.8);
    Console.GotoXY(i,trunc(h/2 - y));
    Console.Write('#');

  end;
  Console.ReadLine;
}
  if aRange = 0 then
    Assert.AreEqual<double>(v, aExpected)
  else
    Assert.IsTrue(abs(v - aExpected) < aRange, Format('phase:%d%%, expected range:%g .. %g, value:%g',[round(100*aPhase/(2*pi)), aExpected-aRange,aExpected+aRange,v]));

  v2 := WaveFunctions[aWaveForm](aPhase);

  if aRange = 0 then
    Assert.AreEqual<double>(v2, aExpected)
  else
    Assert.IsTrue(abs(v2 - aExpected) < aRange, Format('phase:%d%%, expected range:%g .. %g, value:%g',[round(100*aPhase/(2*pi)), aExpected-aRange,aExpected+aRange,v2]));

end;

procedure TOscillatorTest.TestPerformanceCase;
var i:Integer;
  w:TWaveForm;
  v:Double;
  sw:TStopwatch;

const c=65535*2;
begin
  sw := TStopwatch.StartNew;
  for w := low(twaveform) to high(TWaveform) do
    for i := 0 to c do
    begin
      v := GetOsc(w, 2*pi*i/c);
    end;
  Assert.IsTrue(sw.ElapsedMilliseconds<300);
end;

procedure TOscillatorTest.TestPerformanceFunc;
var i:Integer;
  w:TWaveForm;
  v:Double;
  sw:TStopwatch;
const c=65535*4;
begin
  sw := TStopwatch.StartNew;
  for w := low(twaveform) to high(TWaveform) do
    for i := 0 to c do
    begin
      v := WaveFunctions[w](2*pi*i/c);
    end;

  Assert.IsTrue(sw.ElapsedMilliseconds<300);
end;

initialization
  TDUnitX.RegisterTestFixture(TOscillatorTest);
end.
