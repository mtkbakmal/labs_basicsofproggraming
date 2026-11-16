program Fibonacci;

var n, i, errCode: integer;
t1, t2, sum: Int64;
tryStr: string;

begin
repeat
write('введите количество чисел фибоначчи: ');
readln(tryStr);
val(tryStr, n, errCode);

if errCode <> 0 then
writeln('введите число а не символ');

until (errCode = 0);

t1 := 0;
t2 := 1;
writeln(n, ' чисел фибоначчи:');

for i := 1 to n do
begin
write('"', t1, '" ');
sum := t1 + t2;
if sum < t2 then begin writeln('максимальное значение лля 64 бит'); break; end;
t1 := t2;
t2 := sum;
end;
end.