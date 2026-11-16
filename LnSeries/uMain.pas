unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type
  { TfrmMain }
  TfrmMain = class(TForm)
    lblA: TLabel;
    lblB: TLabel;
    edA: TEdit;
    edB: TEdit;
    btnCalc: TButton;
    memResult: TMemo;
    procedure btnCalcClick(Sender: TObject);
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

const
  N_POINTS = 10;                 // число равноотстоящих точек
  EPS: array[1..3] of Double = (1E-3, 1E-5, 1E-7); // границы точности
  X_MIN = 0.5;                   // область сходимости ряда
  X_MAX = 6.0;
  OUT_FILE = 'result.txt';

{ ln x = sum_{k=1}^{inf} (1/k) * q^k,  q = (x-1)/x
  Рекуррентное соотношение: f1 = q,  fk = f(k-1) * q * (k-1) / k
  Возвращает сумму, в n - число выполненных итераций (число слагаемых). }
function LnSeries(x, eps: Double; out n: Int64): Double;
var
  q, f, s, err: Double;
  k: Int64;
begin
  q := (x - 1) / x;
  f := q;
  s := q;
  k := 1;
  // оценка погрешности:
  //  x < 1 (q < 0): ряд знакочередующийся -> |первое отброшенное слагаемое|
  //  x >= 1 (q >= 0): слагаемые одного знака -> остаточный член <= f * q/(1-q) = f*(x-1)
  repeat
    if x < 1 then err := Abs(f) else err := f * (x - 1);
    if err < eps then Break;
    Inc(k);
    f := f * q * (k - 1) / k;
    s := s + f;
  until False;
  n := k;
  Result := s;
end;

function ParseFloat(const S: string; out V: Double): Boolean;
var
  fs: TFormatSettings;
begin
  fs := DefaultFormatSettings;
  fs.DecimalSeparator := '.';
  Result := TryStrToFloat(StringReplace(Trim(S), ',', '.', [rfReplaceAll]), V, fs);
end;

{ TfrmMain }

procedure TfrmMain.btnCalcClick(Sender: TObject);
var
  a, b, h, x, s: Double;
  i, j: Integer;
  n: Int64;
  line: string;
  fs: TFormatSettings;
  res: TStringList;
begin
  if not (ParseFloat(edA.Text, a) and ParseFloat(edB.Text, b)) then
  begin
    ShowMessage('Введите два числа: начало и конец диапазона.');
    Exit;
  end;
  if (a < X_MIN) or (b > X_MAX) or (a >= b) then
  begin
    ShowMessage(Format('Нужно: %.1f <= a < b <= %.1f', [X_MIN, X_MAX]));
    Exit;
  end;

  fs := DefaultFormatSettings;
  fs.DecimalSeparator := '.';
  res := TStringList.Create;
  try
    res.Add('Вычисление ln x рядом, диапазон [' + FloatToStr(a, fs) + '; ' +
      FloatToStr(b, fs) + '], ' + IntToStr(N_POINTS) + ' точек');
    res.Add('');
    line := '      x      ln x (станд.)';
    for j := Low(EPS) to High(EPS) do
      line := line + Format('  | eps=%g: сумма, итераций', [EPS[j]], fs);
    res.Add(line);

    h := (b - a) / (N_POINTS - 1);
    for i := 0 to N_POINTS - 1 do
    begin
      x := a + i * h;
      line := Format('%8.4f  %13.9f', [x, Ln(x)], fs);
      for j := Low(EPS) to High(EPS) do
      begin
        s := LnSeries(x, EPS[j], n);
        line := line + Format('  | %13.9f %9d', [s, n], fs);
      end;
      res.Add(line);
    end;

    memResult.Lines.Assign(res);
    res.SaveToFile(ExtractFilePath(ParamStr(0)) + OUT_FILE);
    memResult.Lines.Add('');
    memResult.Lines.Add('Результаты сохранены в файл: ' +
      ExtractFilePath(ParamStr(0)) + OUT_FILE);
  finally
    res.Free;
  end;
end;

end.
