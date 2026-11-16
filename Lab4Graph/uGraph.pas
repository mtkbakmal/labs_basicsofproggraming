unit uGraph;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls, Math;

type
  { TfrmGraph }
  TfrmGraph = class(TForm)
    lblTitle: TLabel;
    pbGraph: TPaintBox;
    btnDraw: TButton;
    lblXMin: TLabel;
    edXMin: TEdit;
    lblXMax: TLabel;
    edXMax: TEdit;
    lblN: TLabel;
    cbN: TComboBox;
    chkPoints: TCheckBox;
    btnExit: TButton;
    procedure btnDrawClick(Sender: TObject);
    procedure btnExitClick(Sender: TObject);
    procedure chkPointsClick(Sender: TObject);
    procedure pbGraphPaint(Sender: TObject);
  end;

var
  frmGraph: TfrmGraph;

implementation

{$R *.lfm}

var
  // физическая система координат: область значений аргумента и функции
  xMin, xMax, yMin, yMax: Double;
  // экранная система координат: область окна, в которой рисуется график
  // (левый верхний угол (scrL, scrT), правый нижний угол (scrR, scrB))
  scrL, scrT, scrR, scrB: Integer;
  // вычисленные точки графика
  px, py: array of Double;
  ready: Boolean = False;

{ Функция, график которой строится (можно заменить на любую непрерывную) }
function F(x: Double): Double;
begin
  Result := Sin(x);
end;

{ Пересчёт физических координат в экранные (правила подобия, п. I.5) }
function ScreenX(x: Double): Integer;
begin
  Result := scrL + Round((x - xMin) * (scrR - scrL) / (xMax - xMin));
end;

function ScreenY(y: Double): Integer;
begin
  // экранная ось Y направлена вниз, поэтому отсчёт ведётся от нижней границы
  Result := scrB - Round((y - yMin) * (scrB - scrT) / (yMax - yMin));
end;

{ Шаг делений на оси: 2...8 делений на всю длину }
function TickStep(range: Double): Double;
var
  p: Double;
begin
  p := Power(10, Floor(Log10(range)));
  Result := p;
  if range / Result < 4 then
    Result := p / 2;
end;

function ParseFloat(const S: string; out V: Double): Boolean;
var
  fs: TFormatSettings;
begin
  fs := DefaultFormatSettings;
  fs.DecimalSeparator := '.';
  Result := TryStrToFloat(StringReplace(Trim(S), ',', '.', [rfReplaceAll]), V, fs);
end;

{ TfrmGraph }

procedure TfrmGraph.btnDrawClick(Sender: TObject);
var
  a, b, h, lo, hi: Double;
  n, i: Integer;
begin
  if not (ParseFloat(edXMin.Text, a) and ParseFloat(edXMax.Text, b)) then
  begin
    ShowMessage('Введите числа в поля «X минимальное» и «X максимальное».');
    Exit;
  end;
  if a >= b then
  begin
    ShowMessage('X минимальное должно быть меньше X максимального.');
    Exit;
  end;
  n := StrToIntDef(cbN.Text, 33);
  if n < 2 then n := 2;

  xMin := a;
  xMax := b;
  SetLength(px, n);
  SetLength(py, n);
  h := (b - a) / (n - 1);           // точки равноудалены друг от друга
  for i := 0 to n - 1 do
  begin
    px[i] := a + i * h;
    py[i] := F(px[i]);
  end;

  // область значений функции
  lo := py[0];
  hi := py[0];
  for i := 1 to n - 1 do
  begin
    if py[i] < lo then lo := py[i];
    if py[i] > hi then hi := py[i];
  end;
  if hi - lo < 1E-12 then
  begin
    lo := lo - 1;
    hi := hi + 1;
  end;
  yMin := lo - 0.05 * (hi - lo);    // небольшие поля сверху и снизу
  yMax := hi + 0.05 * (hi - lo);

  ready := True;
  pbGraph.Invalidate;
end;

procedure TfrmGraph.btnExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmGraph.chkPointsClick(Sender: TObject);
begin
  pbGraph.Invalidate;
end;

procedure TfrmGraph.pbGraphPaint(Sender: TObject);
var
  cv: TCanvas;
  i, sx, sy, axisX, axisY, i1, i2: Integer;
  step, v: Double;
  s: string;
begin
  cv := pbGraph.Canvas;
  cv.Brush.Style := bsSolid;
  cv.Brush.Color := clWhite;
  cv.Pen.Style := psSolid;
  cv.Pen.Width := 1;
  cv.Pen.Color := clGray;
  cv.Rectangle(0, 0, pbGraph.Width, pbGraph.Height);
  if not ready then Exit;

  scrL := 45;
  scrT := 15;
  scrR := pbGraph.Width - 20;
  scrB := pbGraph.Height - 25;

  // положение осей: через ноль, если он в области, иначе по краю
  if (xMin <= 0) and (xMax >= 0) then axisX := ScreenX(0) else axisX := scrL;
  if (yMin <= 0) and (yMax >= 0) then axisY := ScreenY(0) else axisY := scrB;

  cv.Pen.Color := clBlack;
  cv.Pen.Width := 2;
  cv.MoveTo(scrL, axisY);
  cv.LineTo(scrR, axisY);
  cv.MoveTo(axisX, scrB);
  cv.LineTo(axisX, scrT);

  cv.Pen.Width := 1;
  cv.Font.Size := 9;
  cv.Font.Color := clNavy;
  cv.Brush.Style := bsClear;

  // деления и подписи на оси X
  step := TickStep(xMax - xMin);
  i1 := Ceil(xMin / step);
  i2 := Floor(xMax / step);
  for i := i1 to i2 do
  begin
    v := i * step;
    sx := ScreenX(v);
    cv.MoveTo(sx, axisY - 4);
    cv.LineTo(sx, axisY + 5);
    s := Format('%g', [v]);
    cv.TextOut(sx - cv.TextWidth(s) div 2, axisY + 7, s);
  end;

  // деления и подписи на оси Y
  step := TickStep(yMax - yMin);
  i1 := Ceil(yMin / step);
  i2 := Floor(yMax / step);
  for i := i1 to i2 do
  begin
    if i = 0 then Continue;
    v := i * step;
    sy := ScreenY(v);
    cv.MoveTo(axisX - 4, sy);
    cv.LineTo(axisX + 5, sy);
    s := Format('%g', [v]);
    cv.TextOut(axisX - cv.TextWidth(s) - 7, sy - cv.TextHeight(s) div 2, s);
  end;

  // график
  cv.Pen.Color := clRed;
  cv.Pen.Width := 2;
  if chkPoints.Checked then
  begin
    cv.Brush.Style := bsSolid;
    cv.Brush.Color := clRed;
    for i := 0 to High(px) do
    begin
      sx := ScreenX(px[i]);
      sy := ScreenY(py[i]);
      cv.Ellipse(sx - 3, sy - 3, sx + 4, sy + 4);
    end;
  end
  else
  begin
    cv.MoveTo(ScreenX(px[0]), ScreenY(py[0]));
    for i := 1 to High(px) do
      cv.LineTo(ScreenX(px[i]), ScreenY(py[i]));
  end;
end;

end.
