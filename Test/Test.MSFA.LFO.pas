unit Test.MSFA.LFO;

interface

uses
  WvN.Console,
  System.TypInfo,
  System.diagnostics,
  lfo,
  System.SysUtils,
  DUnitX.TestFramework;

type

  [TestFixture]
  LFOTest = class(TObject)
    [test]
    procedure TestLFOValue;
  end;

implementation

{ LFOTest }

procedure LFOTest.TestLFOValue;
var
  LFO:TLfo;
  Params:TLFOParameters;
begin
  Params.rate := 10;
  Params.delay := 0;
  Params.p1 := 0;
  Params.p2 := 1;


  LFO := TLfo.Create(44100, Params);
  LFO.keydown;


end;

initialization
  TDUnitX.RegisterTestFixture(LFOTest);
end.