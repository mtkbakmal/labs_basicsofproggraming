program Students;

{ Лабораторная работа № 6. Информационные таблицы.
  Консольная программа: читает 4 файла-таблицы (по 2 на каждое направление),
  выполняет задания II.1 - II.4 и записывает результаты в файлы.

  ФОРМАТ ВХОДНЫХ ФАЙЛОВ (UTF-8 или Windows-1251):
    строка 1:  Направление 02.03.02
    строка 2:  заголовок столбцов:
                 "Фамилия  Страна  Место регистрации"   - таблица мест регистрации
                 "Фамилия  Направление  Год рождения"   - таблица годов рождения
    далее по одной записи в строке. Поля разделяются знаком табуляции или ';'.
    Если таких разделителей нет, поля разделяются пробелами (тогда в таблице мест
    регистрации название места может состоять из нескольких слов, а в таблице
    годов рождения - код направления из одного слова).
  Какой файл какая таблица, определяется по заголовку, порядок файлов не важен. }

{$mode objfpc}{$H+}

uses
  {$IFDEF WINDOWS}Windows,{$ENDIF}
  SysUtils, Classes, DateUtils;

type
  TStrArray = array of string;
  TIntArray = array of Integer;

  { строка таблицы мест регистрации }
  TPlaceRow = record
    Surname, Country, Place, Dir: string;
  end;

  { строка таблицы годов рождения }
  TYearRow = record
    Surname, Dir: string;
    Year: Integer;
  end;

var
  Places: array of TPlaceRow;   // все студенты: фамилия, страна, место регистрации
  Years: array of TYearRow;     // все студенты: фамилия, направление, год рождения
  DirList: TStrArray;           // найденные направления подготовки
  OutDir: string;               // папка для файлов с результатами
  CurrentYear: Integer;

{ ======================= II.1. Косвенное упорядочение ======================= }

procedure MergeIdx(const Keys: array of string; var Idx, Tmp: array of Integer;
  lo, mid, hi: Integer);
var
  i, j, k: Integer;
begin
  i := lo; j := mid + 1; k := lo;
  while (i <= mid) and (j <= hi) do
  begin
    if CompareStr(Keys[Idx[i]], Keys[Idx[j]]) <= 0 then
    begin
      Tmp[k] := Idx[i]; Inc(i);
    end
    else
    begin
      Tmp[k] := Idx[j]; Inc(j);
    end;
    Inc(k);
  end;
  while i <= mid do begin Tmp[k] := Idx[i]; Inc(i); Inc(k); end;
  while j <= hi do begin Tmp[k] := Idx[j]; Inc(j); Inc(k); end;
  for k := lo to hi do Idx[k] := Tmp[k];
end;

procedure SortIdxRec(const Keys: array of string; var Idx, Tmp: array of Integer;
  lo, hi: Integer);
var
  mid: Integer;
begin
  if lo >= hi then Exit;
  mid := (lo + hi) div 2;
  SortIdxRec(Keys, Idx, Tmp, lo, mid);
  SortIdxRec(Keys, Idx, Tmp, mid + 1, hi);
  MergeIdx(Keys, Idx, Tmp, lo, mid, hi);
end;

{ Косвенное упорядочение массива строк Keys по возрастанию.
  Сам массив Keys не изменяется; в Idx записываются номера элементов Keys
  в порядке возрастания: Keys[Idx[0]] <= Keys[Idx[1]] <= ...
  Метод слияния (устойчивый). Трудоёмкость O(n log n) сравнений, доп. память O(n);
  время не зависит от размера записей, так как переставляются только индексы. }
procedure SortIndirect(const Keys: array of string; var Idx: array of Integer);
var
  i: Integer;
  Tmp: TIntArray;
begin
  for i := 0 to High(Idx) do Idx[i] := i;
  SetLength(Tmp, Length(Idx));
  SortIdxRec(Keys, Idx, Tmp, 0, High(Idx));
  SetLength(Tmp, 0);
end;

{ Двоичный поиск ключа в массиве Keys, упорядоченном косвенно индексами Idx.
  Возвращает номер элемента Keys или -1. Трудоёмкость O(log n). }
function FindByKey(const Keys: array of string; const Idx: array of Integer;
  const Key: string): Integer;
var
  lo, hi, mid, c: Integer;
begin
  Result := -1;
  lo := 0;
  hi := High(Idx);
  while lo <= hi do
  begin
    mid := (lo + hi) div 2;
    c := CompareStr(Keys[Idx[mid]], Key);
    if c = 0 then
    begin
      Result := Idx[mid];
      Exit;
    end
    else if c < 0 then lo := mid + 1
    else hi := mid - 1;
  end;
end;

{ ============================ Ввод таблиц ============================ }

function IsValidUtf8(const S: string): Boolean;
var
  i, n, k: Integer;
  c: Byte;
begin
  Result := True;
  i := 1;
  n := Length(S);
  while i <= n do
  begin
    c := Byte(S[i]);
    if c < $80 then k := 0
    else if (c and $E0) = $C0 then k := 1
    else if (c and $F0) = $E0 then k := 2
    else if (c and $F8) = $F0 then k := 3
    else Exit(False);
    if i + k > n then Exit(False);
    while k > 0 do
    begin
      Inc(i);
      if (Byte(S[i]) and $C0) <> $80 then Exit(False);
      Dec(k);
    end;
    Inc(i);
  end;
end;

function Cp1251ToUtf8(const S: string): string;
var
  i: Integer;
  b: Byte;
  cp: Integer;
begin
  Result := '';
  for i := 1 to Length(S) do
  begin
    b := Byte(S[i]);
    if b < $80 then Result := Result + Char(b)
    else
    begin
      cp := -1;
      if b >= $C0 then cp := $410 + (b - $C0)
      else if b = $A8 then cp := $401
      else if b = $B8 then cp := $451;
      if cp > 0 then
        Result := Result + Char($C0 or (cp shr 6)) + Char($80 or (cp and $3F))
      else if b = $B9 then
        Result := Result + #$E2#$84#$96      // №
      else
        Result := Result + '?';
    end;
  end;
end;

{ Читает файл целиком, приводит к UTF-8 и делит на строки }
function ReadLines(const FileName: string; out Lines: TStrArray): Boolean;
var
  fs: TFileStream;
  s: string;
  i, start, cnt: Integer;
begin
  Result := False;
  SetLength(Lines, 0);
  if not FileExists(FileName) then Exit;
  fs := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(s, fs.Size);
    if fs.Size > 0 then fs.ReadBuffer(s[1], fs.Size);
  finally
    fs.Free;
  end;
  if (Length(s) >= 3) and (s[1] = #$EF) and (s[2] = #$BB) and (s[3] = #$BF) then
    Delete(s, 1, 3);                       // BOM
  if not IsValidUtf8(s) then s := Cp1251ToUtf8(s);
  cnt := 0;
  start := 1;
  for i := 1 to Length(s) + 1 do
    if (i > Length(s)) or (s[i] = #10) then
    begin
      SetLength(Lines, cnt + 1);
      Lines[cnt] := Trim(Copy(s, start, i - start));   // Trim убирает и #13
      Inc(cnt);
      start := i + 1;
    end;
  Result := True;
end;

{ Делит строку по разделителю sep, поля обрезаются от пробелов }
procedure SplitBy(const S: string; sep: Char; out F: TStrArray);
var
  i, start, cnt: Integer;
begin
  SetLength(F, 0);
  cnt := 0;
  start := 1;
  for i := 1 to Length(S) + 1 do
    if (i > Length(S)) or (S[i] = sep) then
    begin
      SetLength(F, cnt + 1);
      F[cnt] := Trim(Copy(S, start, i - start));
      Inc(cnt);
      start := i + 1;
    end;
end;

{ Делит строку на слова, разделённые пробелами/табуляциями }
procedure SplitWords(const S: string; out F: TStrArray);
var
  i, cnt: Integer;
  cur: string;
begin
  SetLength(F, 0);
  cnt := 0;
  cur := '';
  for i := 1 to Length(S) + 1 do
    if (i > Length(S)) or (S[i] in [' ', #9]) then
    begin
      if cur <> '' then
      begin
        SetLength(F, cnt + 1);
        F[cnt] := cur;
        Inc(cnt);
        cur := '';
      end;
    end
    else cur := cur + S[i];
end;

function JoinWords(const F: TStrArray; from, upto: Integer): string;
var
  i: Integer;
begin
  Result := '';
  for i := from to upto do
  begin
    if Result <> '' then Result := Result + ' ';
    Result := Result + F[i];
  end;
end;

procedure AddDir(const D: string);
var
  i: Integer;
begin
  if D = '' then Exit;
  for i := 0 to High(DirList) do
    if DirList[i] = D then Exit;
  SetLength(DirList, Length(DirList) + 1);
  DirList[High(DirList)] := D;
end;

{ Загрузка одной таблицы. Тип таблицы определяется по заголовку. }
function LoadTable(const FileName: string; out Msg: string): Boolean;
var
  L: TStrArray;
  F: TStrArray;
  i, first, nPlace, nYear, bad: Integer;
  hdrDir, head, line: string;
  isPlace: Boolean;
begin
  Result := False;
  if not ReadLines(FileName, L) then
  begin
    Msg := 'файл не найден: ' + FileName;
    Exit;
  end;
  // первые две непустые строки - заголовки
  first := 0;
  while (first <= High(L)) and (L[first] = '') do Inc(first);
  if (first + 1 > High(L)) or (Pos('Направление', L[first]) <> 1) then
  begin
    Msg := 'неверный формат (нет строки "Направление ...") в файле ' + FileName;
    Exit;
  end;
  hdrDir := L[first];
  Delete(hdrDir, 1, Length('Направление'));
  hdrDir := Trim(StringReplace(StringReplace(hdrDir, #9, ' ', [rfReplaceAll]),
    ';', ' ', [rfReplaceAll]));
  head := L[first + 1];
  if Pos('Страна', head) > 0 then isPlace := True
  else if Pos('Год', head) > 0 then isPlace := False
  else
  begin
    Msg := 'не распознан заголовок столбцов в файле ' + FileName;
    Exit;
  end;
  AddDir(hdrDir);
  nPlace := 0; nYear := 0; bad := 0;
  for i := first + 2 to High(L) do
  begin
    line := L[i];
    if line = '' then Continue;
    if Pos(#9, line) > 0 then SplitBy(line, #9, F)
    else if Pos(';', line) > 0 then SplitBy(line, ';', F)
    else SplitWords(line, F);
    if isPlace then
    begin
      if (Pos(#9, line) = 0) and (Pos(';', line) = 0) and (Length(F) > 3) then
      begin
        // разделители - пробелы: фамилия, страна, остальное - место
        F[2] := JoinWords(F, 2, High(F));
        SetLength(F, 3);
      end;
      if Length(F) < 3 then begin Inc(bad); Continue; end;
      SetLength(Places, Length(Places) + 1);
      with Places[High(Places)] do
      begin
        Surname := F[0]; Country := F[1]; Place := F[2]; Dir := hdrDir;
      end;
      Inc(nPlace);
    end
    else
    begin
      if (Pos(#9, line) = 0) and (Pos(';', line) = 0) and (Length(F) > 3) then
      begin
        // разделители - пробелы: фамилия, направление (слова), год - последнее слово
        F[1] := JoinWords(F, 1, High(F) - 1);
        F[2] := F[High(F)];
        SetLength(F, 3);
      end;
      if Length(F) < 3 then begin Inc(bad); Continue; end;
      SetLength(Years, Length(Years) + 1);
      with Years[High(Years)] do
      begin
        Surname := F[0];
        if F[1] <> '' then Dir := F[1] else Dir := hdrDir;
        Year := StrToIntDef(F[2], 0);
        if Year = 0 then Inc(bad);
      end;
      AddDir(Years[High(Years)].Dir);
      Inc(nYear);
    end;
  end;
  Msg := FileName + ': направление ' + hdrDir + ', ';
  if isPlace then Msg := Msg + 'таблица мест регистрации, строк ' + IntToStr(nPlace)
  else Msg := Msg + 'таблица годов рождения, строк ' + IntToStr(nYear);
  if bad > 0 then Msg := Msg + ' (пропущено/с ошибкой: ' + IntToStr(bad) + ')';
  Result := True;
end;

{ ============================ Вывод в файл ============================ }

procedure WriteResult(const FileName, Text: string);
var
  fs: TFileStream;
  bom: string;
begin
  fs := TFileStream.Create(FileName, fmCreate);
  try
    bom := #$EF#$BB#$BF;                   // чтобы Блокнот распознал UTF-8
    fs.WriteBuffer(bom[1], 3);
    if Length(Text) > 0 then fs.WriteBuffer(Text[1], Length(Text));
  finally
    fs.Free;
  end;
end;

{ ============================== Задания ============================== }

function IsRussia(const Country: string): Boolean;
begin
  Result := (Country = 'Россия') or (Country = 'РОССИЯ') or (Country = 'россия') or
    (Country = 'РФ') or (Country = 'рф') or (Country = 'Российская Федерация');
end;

{ II.2. Субъекты РФ, из которых прибыли студенты всех (обоих) направлений.
  Трудоёмкость: косвенное упорядочение O(n log n) + один проход O(n·d), d = 2,
  итого O(n log n). }
function SubjectsOfBothDirections: string;
var
  keys, dirs: TStrArray;
  idx: TIntArray;
  n, i, j, k, seen, found: Integer;
  groupDirs: TStrArray;
  ok: Boolean;
begin
  Result := '';
  n := 0;
  SetLength(keys, Length(Places));
  SetLength(dirs, Length(Places));
  for i := 0 to High(Places) do
    if IsRussia(Places[i].Country) then
    begin
      keys[n] := Places[i].Place;
      dirs[n] := Places[i].Dir;
      Inc(n);
    end;
  SetLength(keys, n);
  SetLength(dirs, n);
  SetLength(idx, n);
  SortIndirect(keys, idx);
  found := 0;
  i := 0;
  while i < n do
  begin
    j := i;
    SetLength(groupDirs, 0);
    while (j < n) and (keys[idx[j]] = keys[idx[i]]) do
    begin
      ok := True;                          // новое ли направление в этой группе
      for k := 0 to High(groupDirs) do
        if groupDirs[k] = dirs[idx[j]] then ok := False;
      if ok then
      begin
        SetLength(groupDirs, Length(groupDirs) + 1);
        groupDirs[High(groupDirs)] := dirs[idx[j]];
      end;
      Inc(j);
    end;
    seen := Length(groupDirs);
    if seen = Length(DirList) then
    begin
      Result := Result + keys[idx[i]] + #13#10;
      Inc(found);
    end;
    i := j;
  end;
  Result := 'Субъекты РФ, из которых прибыли студенты всех направлений (' +
    IntToStr(Length(DirList)) + '): ' + IntToStr(found) + #13#10 + Result +
    #13#10 + 'Трудоёмкость: косвенная сортировка O(n log n) + проход O(n), итого O(n log n).' + #13#10;
end;

{ II.3. Таблица со всеми сведениями о студентах из зарубежных стран.
  Трудоёмкость: сортировка таблицы годов O(m log m), сортировка зарубежных
  студентов O(k log k), k поисков O(log m) каждый: O((m + k) log m). }
function ForeignTable: string;
var
  yKeys, fKeys: TStrArray;
  yIdx, fIdx: TIntArray;
  fRows: TIntArray;
  i, k, p, y: Integer;
  yearTxt, dirTxt: string;
begin
  SetLength(yKeys, Length(Years));
  for i := 0 to High(Years) do yKeys[i] := Years[i].Surname;
  SetLength(yIdx, Length(Years));
  SortIndirect(yKeys, yIdx);
  k := 0;
  SetLength(fRows, Length(Places));
  SetLength(fKeys, Length(Places));
  for i := 0 to High(Places) do
    if not IsRussia(Places[i].Country) then
    begin
      fRows[k] := i;
      fKeys[k] := Places[i].Surname;
      Inc(k);
    end;
  SetLength(fRows, k);
  SetLength(fKeys, k);
  SetLength(fIdx, k);
  SortIndirect(fKeys, fIdx);
  Result := 'Фамилия'#9'Направление'#9'Страна'#9'Место регистрации'#9'Год рождения'#13#10;
  for i := 0 to k - 1 do
  begin
    with Places[fRows[fIdx[i]]] do
    begin
      p := FindByKey(yKeys, yIdx, Surname);
      if p >= 0 then
      begin
        y := Years[p].Year;
        yearTxt := IntToStr(y);
        dirTxt := Years[p].Dir;
      end
      else
      begin
        yearTxt := '?';
        dirTxt := Dir;
      end;
      Result := Result + Surname + #9 + dirTxt + #9 + Country + #9 + Place + #9 +
        yearTxt + #13#10;
    end;
  end;
  Result := Result + #13#10 + 'Зарубежных студентов: ' + IntToStr(k) + #13#10 +
    'Трудоёмкость: O((m + k) log m), где m - число строк таблицы годов рождения, ' +
    'k - число зарубежных студентов.' + #13#10;
end;

{ II.4. Страны и субъекты РФ, из которых приехал ровно один студент,
  и возрастной диапазон этих студентов.
  Трудоёмкость: сортировка O(n log n) + проход O(n) + поиски O(s log m). }
function SingleStudents: string;
var
  pKeys, yKeys: TStrArray;
  pIdx, yIdx: TIntArray;
  i, j, p, cnt, y: Integer;
  minY, maxY: Integer;
  body: string;
begin
  SetLength(yKeys, Length(Years));
  for i := 0 to High(Years) do yKeys[i] := Years[i].Surname;
  SetLength(yIdx, Length(Years));
  SortIndirect(yKeys, yIdx);
  SetLength(pKeys, Length(Places));
  for i := 0 to High(Places) do pKeys[i] := Places[i].Place;
  SetLength(pIdx, Length(Places));
  SortIndirect(pKeys, pIdx);
  body := '';
  cnt := 0;
  minY := 0;
  maxY := 0;
  i := 0;
  while i < Length(Places) do
  begin
    j := i;
    while (j < Length(Places)) and (pKeys[pIdx[j]] = pKeys[pIdx[i]]) do Inc(j);
    if j - i = 1 then
    begin
      with Places[pIdx[i]] do
      begin
        p := FindByKey(yKeys, yIdx, Surname);
        if p >= 0 then y := Years[p].Year else y := 0;
        body := body + Place + #9 + Surname + #9 + Dir + #9;
        if y > 0 then
        begin
          body := body + IntToStr(y) + #9 + IntToStr(CurrentYear - y);
          if (cnt = 0) or (y < minY) then minY := y;
          if (cnt = 0) or (y > maxY) then maxY := y;
          Inc(cnt);
        end
        else body := body + '?'#9'?';
        body := body + #13#10;
      end;
    end;
    i := j;
  end;
  Result := 'Место регистрации'#9'Фамилия'#9'Направление'#9'Год рождения'#9'Возраст'#13#10 + body + #13#10;
  if cnt = 0 then
    Result := Result + 'Нет студентов, приехавших из места, где учится только один.' + #13#10
  else
    Result := Result + 'Возрастной диапазон: от ' + IntToStr(CurrentYear - maxY) +
      ' до ' + IntToStr(CurrentYear - minY) + ' лет (годы рождения ' + IntToStr(minY) +
      ' - ' + IntToStr(maxY) + '; возраст на ' + IntToStr(CurrentYear) + ' год)' + #13#10;
  Result := Result + 'Трудоёмкость: O(n log n), n - число студентов.' + #13#10;
end;

{ ================================ main ================================ }

var
  files: array[1..4] of string;
  k: Integer;
  msg, res: string;
  loaded: Integer;

begin
  SetMultiByteConversionCodePage(CP_UTF8);
  SetMultiByteRTLFileSystemCodePage(CP_UTF8);
  {$IFDEF WINDOWS}
  SetConsoleOutputCP(CP_UTF8);
  {$ENDIF}
  SetTextCodePage(Output, CP_UTF8);

  CurrentYear := YearOf(Date);

  if ParamCount >= 4 then
    for k := 1 to 4 do files[k] := ParamStr(k)
  else
  begin
    WriteLn('Введите имена 4 файлов с таблицами (пустая строка - table<N>.txt):');
    for k := 1 to 4 do
    begin
      Write('Файл ', k, ': ');
      ReadLn(files[k]);
      files[k] := Trim(files[k]);
      if files[k] = '' then files[k] := 'table' + IntToStr(k) + '.txt';
    end;
  end;

  loaded := 0;
  for k := 1 to 4 do
    if LoadTable(files[k], msg) then
    begin
      WriteLn('Прочитано: ', msg);
      Inc(loaded);
    end
    else WriteLn('ОШИБКА: ', msg);

  if (Length(Places) = 0) or (Length(Years) = 0) then
  begin
    WriteLn('Не хватает данных: нужны таблицы мест регистрации и годов рождения.');
    ReadLn;
    Halt(1);
  end;

  OutDir := ExtractFilePath(ExpandFileName(files[1]));

  res := SubjectsOfBothDirections;
  WriteResult(OutDir + 'result_subjects.txt', res);
  WriteLn; WriteLn('--- II.2 (result_subjects.txt) ---'); Write(res);

  res := ForeignTable;
  WriteResult(OutDir + 'result_foreign.txt', res);
  WriteLn; WriteLn('--- II.3 (result_foreign.txt) ---'); Write(res);

  res := SingleStudents;
  WriteResult(OutDir + 'result_single.txt', res);
  WriteLn; WriteLn('--- II.4 (result_single.txt) ---'); Write(res);

  { освобождаем память после вывода результатов }
  SetLength(Places, 0);
  SetLength(Years, 0);
  SetLength(DirList, 0);

  WriteLn;
  WriteLn('Результаты записаны в папку: ', OutDir);
  WriteLn('Нажмите Enter...');
  ReadLn;
end.
