unit DX7.Forms.Op;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Menus, Vcl.ComCtrls, FS1R.Params;

const
  Cols: array[0..3] of TColor = ($99CC99, $CC9999, $99AACC, $CC88CC);

type
  TFrame1 = class(TFrame)
    GridPanel1: TGridPanel;
    EG_R1: TScrollBar;
    EG_L1: TScrollBar;
    EG_R2: TScrollBar;
    EG_L2: TScrollBar;
    EG_R3: TScrollBar;
    EG_L3: TScrollBar;
    EG_R4: TScrollBar;
    lblRates: TLabel;
    Panel1: TPanel;
    FreqCoarse: TScrollBar;
    FreqFine: TScrollBar;
    cbOscMode: TCheckBox;
    Volume: TScrollBar;
    lblLevels: TLabel;
    EG_L4: TScrollBar;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    lblCaption: TLabel;
    PaintBox1: TPaintBox;
    PopupMenu1: TPopupMenu;
    miPoints: TMenuItem;
    miSimulation: TMenuItem;
    ProgressBar1: TProgressBar;
    procedure GuiChanged(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject);
    procedure miSimulationClick(Sender: TObject);
    procedure EG_R1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FUpdating:Boolean;
    FEnvBitmapBuffer:TBitmap;
    FEnvBitmap:TBitmap;
    procedure PaintRealEnvOutput(c: TCanvas);
    procedure PaintEnvelopePoints(AA: Shortint; aCanvas: TCanvas);
    procedure UpdateHints;
  public
    maxT:integer;
    function GuiToParams:TVoiceParams;
    procedure ParamsToGui(const Op:TVoiceVoiced);
    procedure PaintEnvelope;
  end;

implementation

{$R *.dfm}

uses Math, DX7.Forms.Main, GraphUtil, DX7.Envelope;

procedure TFrame1.EG_R1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_DELETE: TScrollbar(Sender).Position := TScrollbar(Sender).Tag;
  end;
end;

procedure TFrame1.GuiChanged(Sender: TObject);
begin
  if FUpdating then
    Exit;

  frmMain.Synth.params.Operators[Tag-1] := GuiToParams.Operators[Tag-1];
//  frmMain.Memo1.Text := frmMain.Synth.params.CSV; @@@
  PaintEnvelope;
  PaintBox1.Repaint;
  UpdateHints;
  frmMain.stat1.Panels[0].Text := TControl(Sender).Hint;
end;



function TFrame1.GuiToParams: TVoiceParams;
  function RateScaling(v:integer):byte;
  const curve=4;
  begin
    Result := Round((power(1+v/10,curve)/power(100,curve))*99);
  end;
begin
  if FUpdating then
    Exit;

  Result := frmMain.Synth.params;

  if cbOscMode.Checked then
    Result.Operators[Tag-1].Voiced.Osc.OscMode := TOscModeVoiced.Fixed
  else
    Result.Operators[Tag-1].Voiced.Osc.OscMode := TOscModeVoiced.Ratio;

  Result.Operators[Tag-1].Voiced.EG.Envelope.Rates[0]  := EG_R1.Position;
  Result.Operators[Tag-1].Voiced.EG.Envelope.Rates[1]  := EG_R2.Position;
  Result.Operators[Tag-1].Voiced.EG.Envelope.Rates[2]  := EG_R3.Position;
  Result.Operators[Tag-1].Voiced.EG.Envelope.Rates[3]  := EG_R4.Position;
  Result.Operators[Tag-1].Voiced.EG.Envelope.Levels[0] := EG_L1.Position;
  Result.Operators[Tag-1].Voiced.EG.Envelope.Levels[1] := EG_L2.Position;
  Result.Operators[Tag-1].Voiced.EG.Envelope.Levels[2] := EG_L3.Position;
  Result.Operators[Tag-1].Voiced.EG.Envelope.Levels[3] := EG_L4.Position;

  Result.Operators[Tag-1].Voiced.Volume         := Volume.Position;
  Result.Operators[Tag-1].Voiced.Osc.FreqFine   := FreqFine.Position;
  Result.Operators[Tag-1].Voiced.Osc.FreqCoarse := FreqCoarse.Position;
  // Result.freqRatio  := FreqRatio.

end;


procedure TFrame1.miSimulationClick(Sender: TObject);
begin
  PaintEnvelope;
  PaintBox1.Repaint;
end;

procedure TFrame1.PaintBox1Paint(Sender: TObject);
begin
  PaintBox1.Canvas.Draw(0,0, FEnvBitmap);
end;


/// <summary>
/// Paint a Yamaha style 4-stage envelope.
/// It's not like an ADSR, but some rather strange
/// </summary>

procedure TFrame1.PaintEnvelope;
var c:TCanvas;
  p:TPoint;
  dc: HDC;
const
  AA=8;
begin

  if FEnvBitmapBuffer=nil then
    FEnvBitmapBuffer := TBitmap.Create;

  FEnvBitmapBuffer.SetSize( PaintBox1.ClientWidth * AA, PaintBox1.ClientHeight * AA );
  c := FEnvBitmapBuffer.Canvas;

  c.Brush.Color := clBtnFace;
  c.FillRect(c.ClipRect);


  if miSimulation.Checked then
    PaintRealEnvOutput(c);
  if miPoints.Checked then
    PaintEnvelopePoints(AA, c);

  if FEnvBitmap=nil then
    FEnvBitmap := TBitmap.Create;

  FEnvBitmap.SetSize(PaintBox1.ClientRect.Width, PaintBox1.ClientRect.Height);

  dc:=FEnvBitmap.Canvas.Handle;
  GetBrushOrgEx(dc,p);
  SetStretchBltMode(dc,HALFTONE);
  StretchBlt(dc      ,0,0, FEnvBitmap      .Width, FEnvBitmap      .Height,
             c.Handle,0,0, FEnvBitmapBuffer.Width, FEnvBitmapBuffer.Height,
             FEnvBitmap.Canvas.CopyMode);
end;

procedure TFrame1.UpdateHints;
begin
  EG_R1.Hint := Format('Op%d:%s %d = %d', [Tag, 'EG Rate', 1, EG_R1.Position]);
  EG_R2.Hint := Format('Op%d:%s %d = %d', [Tag, 'EG Rate', 2, EG_R2.Position]);
  EG_R3.Hint := Format('Op%d:%s %d = %d', [Tag, 'EG Rate', 3, EG_R3.Position]);
  EG_R4.Hint := Format('Op%d:%s %d = %d', [Tag, 'EG Rate', 4, EG_R4.Position]);
  EG_L1.Hint := Format('Op%d:%s %d = %d', [Tag, 'EG Level', 1, EG_L1.Position]);
  EG_L2.Hint := Format('Op%d:%s %d = %d', [Tag, 'EG Level', 2, EG_L2.Position]);
  EG_L3.Hint := Format('Op%d:%s %d = %d', [Tag, 'EG Level', 3, EG_L3.Position]);
  EG_L4.Hint := Format('Op%d:%s %d = %d', [Tag, 'EG Level', 4, EG_L4.Position]);
end;

/// <summary>
///   Paint envelope's real output, using a real envelope.
///   Note that this is just an example. The real envelope's output is
///   depending on the note that's being played
/// </summary>
procedure TFrame1.PaintRealEnvOutput(c: TCanvas);
var
  e: TEnvelopeDX7;
  a: TArray<double>;
  stages: TArray<integer>;
  I: Integer;
  J: Integer;
  h: Integer;
  mv: Double;
begin
  h := c.ClipRect.Height;
  e := TEnvelopeDX7.Create(Tag - 1, @frmMain.Synth.params);
  e.qr := e.qr * 100;
  //  c.Pen.Color := $CC9999;
  c.MoveTo(0, round(h - h * e.Render));
  setlength(a, FEnvBitmapBuffer.Width);
  setlength(stages, FEnvBitmapBuffer.Width);
  for I := 0 to FEnvBitmapBuffer.Width - 1 do
  begin
    if (I / FEnvBitmapBuffer.Width) > 0.7 then
      e.noteOff;
    stages[I] := e.state;
    a[I] := e.Render;
    for j := 0 to 400 do
      e.Render;
  end;
  mv := 1 / MaxValue(a);
  for I := 0 to FEnvBitmapBuffer.Width - 1 do
  begin
    c.Pen.Color := cols[stages[i]];
    c.MoveTo(I, h);
    c.LineTo(I, round(h - h * a[i] * mv));
  end;
end;



/// <summary>
///   Points envelope points
/// </summary>
/// <para>
/// AA:ShortInt
///    Sets AntiAliasing level.
///    Setting this to 1 means no Anti-aliasing
///    Setting this to 2 means that an image of double size will be painted, and
///      scaled down to 1/2 the size, to create smooth lines.
///    This is needed because with GDI it's kind of crappy to draw anti-aliased
///    lines and polygons. It would be overkill to include Graphics32 or GDI+
///    for this.
/// </para>
procedure TFrame1.PaintEnvelopePoints(AA: Shortint; aCanvas: TCanvas);
type
  TEnvelopePoints = array[0..8] of TPoint;

  procedure DrawTimeBars(aMaxT:integer);
  var n:integer;
  begin
    aCanvas.Pen.Color := $666666;
    aMaxT := min(aMaxT, aCanvas.ClipRect.Width*10);
    for n := 1 to aMaxT div 200 do
    begin
      aCanvas.MoveTo( round(n * 200 * aCanvas.ClipRect.Width / aMaxT), 0 );
      aCanvas.LineTo( round(n * 200 * aCanvas.ClipRect.Width / aMaxT), aCanvas.ClipRect.Height-1);
    end;
    // horizontal line:
    // aCanvas.MoveTo( 0, aCanvas.ClipRect.Height div 2 );
    // aCanvas.LineTo( aCanvas.ClipRect.Width-1 , aCanvas.ClipRect.Height div 2 );
  end;

  procedure NormalizeX(var Points:TEnvelopePoints; aMaxT:integer);
  var n:integer;
  begin
    for n := 0 to high(points) do
      points[n].X := round(points[n].X * (aCanvas.ClipRect.Width / aMaxT));
  end;

  procedure DrawPoints(const Points:TEnvelopePoints);
  var n:integer;  r: TRect; p:TPoint;
  begin
    // draw point rectagles
    for n := 1 to 4 do
    begin
      p := Points[n];

      r.Width := AA * 3+1;
      r.Height := AA * 3+1;
      r.SetLocation(P.X - AA-1, P.Y - AA-1);

      aCanvas.Brush.Color := clBlack;
      aCanvas.FillRect(r);
    end;
  end;

  {
  procedure DrawLines(const Points:TEnvelopePoints);
  var p:TPoint;
  begin
    aCanvas.MoveTo(Points[0].X, Points[0].Y);
    for p in Points do
    begin
      aCanvas.Pen.Color := clBlack;
      aCanvas.LineTo(P.X,P.Y);
    end;
  end;
  }

var
  p: TPoint;
  N,M: Double;
  w,h:integer;
  I:Integer;
  pol:array of TPoint;
  Points: TEnvelopePoints;
const
  e=0.0001;
begin
  //  PaintRealEnvOutput(c, h);
  w := aCanvas.ClipRect.Width;
  h := aCanvas.ClipRect.Height;

  N := 0;
  Points[0].X := 0;
  Points[0].Y := Round(h - h * EG_L4.Position / EG_L4.Max);


  N := N +   EG_R1.Max / (EG_R1.Position+e)-1; m := EG_L1.Position / EG_L1.Max; m := outputLUT[trunc(m*4095)]*0.333; Points[1].X := Round(w * N * 0.2);  Points[1].Y := Round(h - h * m);
  N := N +   EG_R2.Max / (EG_R2.Position+e)-1; m := EG_L2.Position / EG_L2.Max; m := outputLUT[trunc(m*4095)]*0.333; Points[2].X := Round(w * N * 0.2);  Points[2].Y := Round(h - h * m);
  N := N +   EG_R3.Max / (EG_R3.Position+e)-1; m := EG_L3.Position / EG_L3.Max; m := outputLUT[trunc(m*4095)]*0.333; Points[3].X := Round(w * N * 0.2);  Points[3].Y := Round(h - h * m);
  N := N + 1                                 ; m := EG_L3.Position / EG_L3.Max; m := outputLUT[trunc(m*4095)]*0.333; Points[4].X := Round(w * N * 0.2);  Points[4].Y := Round(h - h * m); // sustain
  N := N +   EG_R4.Max / (EG_R4.Position+e)-1; m := EG_L4.Position / EG_L4.Max; m := outputLUT[trunc(m*4095)]*0.333; Points[5].X := Round(w * N * 0.2);  Points[5].Y := Round(h - h * m); // release

  Points[6].X := Round(w * N * 0.2);
  Points[6].Y := Round(h);

  Points[7].X := Points[0].X;
  Points[7].Y := Round(h);



  // maximum time
  MaxT := Points[6].X;

  // normalize X, to make the envelope fit the image
  NormalizeX(Points,MaxT);

  DrawTimeBars(MaxT);

  // draw colored filled polygons
  for I := 0 to 3 do
  begin
    pol := [];

    // start with the first point, at the bottom of the image:
    p := Points[I+0];
    p.Y := h;
    pol := pol + [p];

    pol := pol + [Points[I+0]];
    pol := pol + [Points[I+1]];
    pol := pol + [Points[I+2]];

    // we also add a point at the bottom for the last point:
    p := Points[I+2];
    p.Y := h;
    pol := pol + [p];

    // set color based on envelope stage
    aCanvas.Brush.Color := cols[I];

    aCanvas.Polygon(pol);
  end;

  DrawPoints(Points);
end;

procedure TFrame1.ParamsToGui(const Op: TVoiceVoiced);
begin
  FUpdating := True;

  cbOscMode.Checked   := Op.Osc.OscMode =  TOscModeVoiced.Fixed;
  EG_R1.Position      := Op.EG.Envelope.Rates[0];
  EG_R2.Position      := Op.EG.envelope.Rates[1];
  EG_R3.Position      := Op.EG.envelope.Rates[2];
  EG_R4.Position      := Op.EG.envelope.Rates[3];
  EG_L1.Position      := Op.EG.envelope.Levels[0];
  EG_L2.Position      := Op.EG.envelope.Levels[1];
  EG_L3.Position      := Op.EG.envelope.Levels[2];
  EG_L4.Position      := Op.EG.envelope.Levels[3];
  Volume.Position     := Op.Volume;
  FreqFine.Position   := Op.Osc.FreqFine;
  FreqCoarse.Position := Op.Osc.FreqCoarse;
  // Result.freqRatio  := FreqRatio.

  FUpdating := False;
  PaintEnvelope;
  PaintBox1.Repaint;
end;

end.
