program FmSynthTest;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}{$STRONGLINKTYPES ON}
uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ENDIF }
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  Test.Oscillator in 'Test.Oscillator.pas',
  FM.Oscillator in '..\FM.Oscillator.pas',
  Test.MSFA.LFO in 'Test.MSFA.LFO.pas',
  FS1R.Params in '..\FS1R.Params.pas',
  synthunit in '..\fm\synthunit.pas',
  synth in '..\fm\synth.pas',
  sin in '..\fm\sin.pas',
  ringbuffer in '..\fm\ringbuffer.pas',
  PluginFx in '..\fm\PluginFx.pas',
  PluginData in '..\fm\PluginData.pas',
  pitchenv in '..\fm\pitchenv.pas',
  patch in '..\fm\patch.pas',
  lfo in '..\fm\lfo.pas',
  freqlut in '..\fm\freqlut.pas',
  fm_op_kernel in '..\fm\fm_op_kernel.pas',
  fm_core in '..\fm\fm_core.pas',
  exp2 in '..\fm\exp2.pas',
  env in '..\fm\env.pas',
  EngineOpl in '..\fm\EngineOpl.pas',
  EngineMkI in '..\fm\EngineMkI.pas',
  dx7note in '..\fm\dx7note.pas',
  dx7 in '..\fm\dx7.pas',
  dexed_ttl in '..\fm\dexed_ttl.pas',
  dexed in '..\fm\dexed.pas',
  controllers in '..\fm\controllers.pas',
  Test.FmOpKernel in 'Test.FmOpKernel.pas';

var
  runner : ITestRunner;
  results : IRunResults;
  logger : ITestLogger;
  nunitLogger : ITestLogger;
begin
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
  exit;
{$ENDIF}
  try
    //Check command line options, will exit if invalid
    TDUnitX.CheckCommandLine;
    //Create the test runner
    runner := TDUnitX.CreateRunner;
    //Tell the runner to use RTTI to find Fixtures
    runner.UseRTTI := True;
    //tell the runner how we will log things
    //Log to the console window
    logger := TDUnitXConsoleLogger.Create(true);
    runner.AddLogger(logger);
    //Generate an NUnit compatible XML File
    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);
    runner.FailsOnNoAsserts := False; //When true, Assertions must be made during tests;

    //Run tests
    results := runner.Execute;
    if not results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    //We don't want this happening when running under CI.
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
end.
