program Variant19;

uses
SysUtils;

var
x_start, x_end, x, h, eps: real;
q, a_k, sum: real;
k: int64;
f: TextFile;
i, p, j: integer;

begin
write('введите начало диапазона 0.5: ');
readln(x_start);
write('введите конец диапазона 6.0: ');
readln(x_end);

Assign(f, 'result.txt');
Rewrite(f);

writeln('|   x    |   eps   |       f(x)       |  iter (n)       |');
writeln(f, '|   x    |   eps   |       f(x)       |  iter (n)       |');

//10 точек 9 интервалов
h := (x_end - x_start) / 10;
x := x_start;
=
for i := 0 to 10 do
begin
    q := (x - 1) / x;

//цикл по точностям от 10^-1 до 10^-6
for p := 1 to 6 do
begin
//считаю 10^-p
    eps := 1;
for j := 1 to p do eps := eps / 10;

sum := 0;
a_k := q; 
k := 1;

//накопление суммы пока член ряда больше точности
while Abs(a_k) >= eps do
begin
    sum := sum + a_k;

//рекуррентная формула для следующего члена
a_k := a_k * (k / (k + 1)) * q;
k := k + 1;
end;

WriteLn('| ', x:6:2, ' | 1e-', p, '   | ', sum:16:8, ' | ', k:15, ' |');
WriteLn(f, '| ', x:6:2, ' | 1e-', p, '   | ', sum:16:8, ' | ', k:15, ' |');
end;

//переход к следующему значению x
x := x + h;
end;
close(f);
ReadLn;
end.