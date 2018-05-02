unit Test.FmOpKernel;

interface

uses
  WvN.Console,
  System.TypInfo,
  System.diagnostics,
  fm_op_kernel,
  System.SysUtils,
  DUnitX.TestFramework;

type

  [TestFixture]
  TFmOpKernelTest = class(TObject)
    Kernel:TFmOpKernel;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    // Sample Methods
    // Simple single Test
    [Test]
    procedure TestCompute;
    [Test]
    procedure TestComputePure;
    [Test]
    procedure TestComputeFeedback;
  end;

implementation

{ TFmOpKernelTest }

procedure TFmOpKernelTest.Setup;
begin

end;

procedure TFmOpKernelTest.TearDown;
begin

end;

procedure TFmOpKernelTest.TestCompute;
var
  Input,
  Output:TArray<Single>;
  Phase:Integer;
  Freq:Integer;
  Gain1, Gain2:Integer;
  Add:Boolean;
begin
  SetLength(Input,256);
  SetLength(Output,256);
  Phase := 0;
  Freq := 220;
  Gain1:=100;
  Gain2:=100;
  Add := True;

  TFmOpKernel.compute(@Output[0],@Input[0],Phase,Freq,Gain1,Gain2,Add);

  Assert.AreEqual<Single>(0,Output[0]);
  Assert.IsTrue(Output[1]>0);
//  Assert.IsTrue(Output[10]>0);
//  Assert.IsTrue(Output[20]>0);
//  Assert.IsTrue(Output[30]>0);

  Phase := 1;

end;

procedure TFmOpKernelTest.TestComputeFeedback;
begin

end;

procedure TFmOpKernelTest.TestComputePure;
begin

end;

end.