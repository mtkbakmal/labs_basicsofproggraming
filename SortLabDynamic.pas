program SortLab;

{$mode objfpc}{$H+}

uses
  SysUtils, DateUtils;

const
  MaxN   = 1000000; // размер эталонного массива
  MinVal = -999;
  MaxVal = 999;
  { наибольшее n для которого запускается каждая сортировка }
  LimSimple    = 1000;
  LimQuadratic = 100000;
  LimMerge     = 1000000;

type
  { динамический массив: размер задаётся во время работы (SetLength) }
  TIntArray = array of LongInt;
  { сортировка принимает ОТКРЫТЫЙ массив: подходит и статический, и динамический,
    и часть массива (Slice); длина определяется функциями Length/High }
  TSortProc = procedure(var A: array of LongInt);

var
  { динамические массивы: эталонный, рабочий и вспомогательный }
  Etalon, Work, Aux: TIntArray;

{ возвращает текущее время в секундах как дробное число }
function CommonUserTime: Double;
begin
  Result := Now * 24 * 60 * 60; // секунды
end;

{ простейшая сортировка; A - открытый массив, нумерация с 0 }
procedure SortSimple(var A: array of LongInt);
var
  i, z: LongInt;
begin
  i := 0;
  while i < High(A) do
    if A[i] <= A[i + 1] then
      Inc(i)
    else
    begin
      z := A[i]; A[i] := A[i + 1]; A[i + 1] := z;
      i := 0;
    end;
end;

{ сортировка вставками }
procedure SortInsertion(var A: array of LongInt);
var
  i, j, z: LongInt;
begin
  for i := 0 to High(A) - 1 do
  begin
    j := i;
    z := A[i + 1]; // элемент который вставляем
    while (j >= 0) and (A[j] > z) do
    begin
      A[j + 1] := A[j]; // сдвигаем вправо
      Dec(j);
    end;
    A[j + 1] := z; // ставим на место
  end;
end;

{ сливает две соседние части: X[a..c] и X[c+1..b] -> Y[a..b] }
procedure Merge(var X, Y: array of LongInt; a, c, b: LongInt);
var
  i1, i2, j: LongInt;
begin
  i1 := a; i2 := c + 1; j := a;
  while (i1 <= c) and (i2 <= b) do
  begin
    if X[i1] <= X[i2] then
    begin Y[j] := X[i1]; Inc(i1); end
    else
    begin Y[j] := X[i2]; Inc(i2); end;
    Inc(j);
  end;
  // дописываем остатки
  while i1 <= c do begin Y[j] := X[i1]; Inc(i1); Inc(j); end;
  while i2 <= b do begin Y[j] := X[i2]; Inc(i2); Inc(j); end;
end;

{ рекурсивная сортировка слиянием отрезка; Y это вспомогательный массив }
procedure MergeSortRec(var X, Y: array of LongInt; a, b: LongInt);
var
  c, i: LongInt;
begin
  if a < b then
  begin
    c := (a + b) div 2;
    MergeSortRec(X, Y, a, c);
    MergeSortRec(X, Y, c + 1, b);
    Merge(X, Y, a, c, b);
    for i := a to b do X[i] := Y[i];
  end;
end;

procedure SortMerge(var A: array of LongInt);
begin
  MergeSortRec(A, Aux, 0, High(A));
end;

{ проверяет что массив отсортирован и содержит те же значения что и исходный;
  оба параметра - открытые массивы одинаковой длины }
function Test(const Source, Sorted: array of LongInt): Boolean;
var
  i: LongInt;
  { статические массивы: границы известны заранее }
  CntS, CntR: array[MinVal..MaxVal] of LongInt;
begin
  Result := True;
  // проверяем что по возрастанию
  for i := 0 to High(Sorted) - 1 do
    if Sorted[i] > Sorted[i + 1] then
      Exit(False);
  // сравниваем количество каждого значения
  FillChar(CntS, SizeOf(CntS), 0);
  FillChar(CntR, SizeOf(CntR), 0);
  for i := 0 to High(Source) do
  begin
    Inc(CntS[Source[i]]);
    Inc(CntR[Sorted[i]]);
  end;
  for i := MinVal to MaxVal do
    if CntS[i] <> CntR[i] then
      Exit(False);
end;

{ вывод открытого массива в строку }
procedure PrintArray(const Title: string; const A: array of LongInt);
var
  i: LongInt;
begin
  Write(Title);
  for i := 0 to High(A) do
    Write(' ', A[i]);
  WriteLn;
end;

const
  NCount = 9;
  Sizes: array[1..NCount] of LongInt = (10, 100, 1000, 5000, 10000, 50000, 100000, 500000, 1000000);
  Names: array[1..3] of string = ('прост.', 'квадр.', 'слиян.');
  Limits: array[1..3] of LongInt = (LimSimple, LimQuadratic, LimMerge);

var
  Procs: array[1..3] of TSortProc;
  Table: array[1..3, 1..NCount] of Double; // -1 значит не измерялось
  Ok: array[1..3, 1..NCount] of Boolean;
  { статический массив для демонстрации сортировки малого массива }
  Demo: array[0..9] of LongInt = (7, -3, 12, 0, 5, -8, 5, 100, -999, 42);
  s, k, i, n, Reps: LongInt;
  t0, t1, MsTime: Double;

{ сколько раз повторить сортировку чтобы время было измеримым }
function Repetitions(n: LongInt): LongInt;
begin
  if n <= 100 then Result := 1000
  else if n <= 1000 then Result := 100
  else if n <= 10000 then Result := 10
  else Result := 1;
end;

begin
  Procs[1] := @SortSimple;
  Procs[2] := @SortInsertion;
  Procs[3] := @SortMerge;

  { выделяем память под динамические массивы }
  SetLength(Etalon, MaxN);
  SetLength(Work, MaxN);
  SetLength(Aux, MaxN);

  Randomize;
  for i := 0 to MaxN - 1 do
    Etalon[i] := MinVal + Random(MaxVal - MinVal + 1); // числа из [-999; 999]

  { демонстрация: тот же открытый параметр принимает статический массив }
  PrintArray('Статический массив до сортировки:   ', Demo);
  SortInsertion(Demo);
  PrintArray('Статический массив после сортировки:', Demo);
  WriteLn;

  Write('Пожалуйста, подождите...');

  // прогоняем каждую сортировку на разных размерах
  for s := 1 to 3 do
    for k := 1 to NCount do
    begin
      n := Sizes[k];
      Table[s, k] := -1;
      Ok[s, k] := True;
      if n > Limits[s] then Continue; // слишком большой размер для этой сортировки

      // повторяем несколько раз чтобы замерить маленькие времена точнее
      Reps := Repetitions(n);
      t0 := CommonUserTime;
      for i := 1 to Reps do
      begin
        Move(Etalon[0], Work[0], n * SizeOf(LongInt)); // копия первых n элементов
        Procs[s](Slice(Work, n));                      // сортируем первые n элементов
      end;
      t1 := CommonUserTime;

      // среднее время одного прогона, переводим в миллисекунды
      MsTime := ((t1 - t0) * 1000.0) / Reps;
      Table[s, k] := MsTime;
      Ok[s, k] := Test(Slice(Etalon, n), Slice(Work, n));
    end;

  WriteLn(' Готово!');
  WriteLn;
  WriteLn('миллисекунды:');
  WriteLn('Алг    | n=10   | n=100  | n=1k   | n=5k   | n=10k  | n=50k  | n=100k | n=500k | n=1M   |');
  WriteLn('-----------------------------------------------------------------------------------------');

  for s := 1 to 3 do
  begin
    // выводим название (выравнивание по левому краю в 6 символов + палочка)
    Write(Names[s]:6, ' |');

    for k := 1 to NCount do
    begin
      if Table[s, k] < 0 then
      begin
        // если не запускали (превышен лимит)
        Write('   -    |');
        Continue;
      end;

      if not Ok[s, k] then
      begin
        // если сортировка сломалась (не прошла проверку)
        Write('  ошибка  |');
        Continue;
      end;

      // форматируем время в зависимости от величины
      MsTime := Table[s, k];
      if MsTime < 0.001 then
        Write(Format('%7.4f |', [MsTime]))
      else if MsTime < 0.1 then
        Write(Format('%7.3f |', [MsTime]))
      else
        Write(Format('%7.1f |', [MsTime]));
    end;
    WriteLn;
  end;

  WriteLn('-----------------------------------------------------------------------------------------');
  WriteLn;

  { освобождаем память динамических массивов после вывода результатов }
  SetLength(Etalon, 0);
  SetLength(Work, 0);
  SetLength(Aux, 0);

  Writeln('Конец программы');
  ReadLn;
end.
