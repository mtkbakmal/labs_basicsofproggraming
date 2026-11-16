{Переменные}
program Laba;
var
x, y, z, d, p: integer;
cenx, ceny, rad, coordx, coordy: integer;
vector: real;

a: array[1..100] of integer;
n, i, maxPos, minPos: integer;


{1. Даны 2 целых числа. Вычислите их произведение.}
begin
writeln('Введите первое число: ');
read(x);
writeln('Введите второе число: ');
read(y);
z := x * y;

writeln('Произведение: ', z);

{2. Даны 3 числа. Выведите числа в порядке возрастания.}
for p := 1 to 1 do
begin
writeln('Введите первое число для сортировки: ');
read(x);
writeln('Введите второе число для сортировки: ');
read(y);
writeln('Введите третье число для сортировки: ');
read(z);

if x > y then begin d := x; x := y; y := d; end;
if x > z then begin d := x; x := z; z := d; end;
if y > z then begin d := y; y := z; z := d; end;

writeln('Числа в порядке возрастания: ', x, ' ', y, ' ', z);
end;
{3. Даны координаты центра и радиус круга. Определите, лежит ли точка с заданными координатами внутри круга (все значения вещественные).}
begin
for p := 1 to 1 do
begin
writeln('Введите координату x круга: ');
read(cenx);
writeln('Введите координату y круга: ');
read(ceny);
writeln('Введите радиус окружности: ');
read(rad);

writeln('Задайте первую точку координату x: ');
readln(coordx);
writeln('Задайте вторую точку координату y: ');
readln(coordy);

vector := (coordx - cenx) * (coordx - cenx) + (coordy - ceny) * (coordy - ceny);

if vector < (rad * rad) then begin writeln('Точка внутри круга'); end;
if vector = (rad * rad) then begin writeln('Точка на круге'); end;
if vector > (rad * rad) then begin writeln('Точка вне круга'); end;
end;
{4. Без деления найдите целую часть частного и остаток от деления двух заданных целых чисел.}
writeln('Введите делимое число: ');
readln(x);
writeln('Введите делитель числа: ');
readln(y);
d := 0;

while x >= y do
begin
d := d + 1;
x := x - y;
end;
writeln('Целая часть частного: ', d, ' Остаток от деления: ', x);

end;


{5. Поменяйте местами последний максимальный и первый минимальный элемент массива и выведите весь массив.}
begin
writeln('Введите количество элементов массива: ');
readln(n);

writeln('Введите элементы массива:');

for i := 1 to n do
    read(a[i]);

maxPos := 1;

for i := 1 to n do
    if a[i] >= a[maxPos] then
        maxPos := i;

minPos := 1;

for i := 2 to n do
    if a[i] < a[minPos] then
        minPos := i;

d := a[maxPos];
a[maxPos] := a[minPos];
a[minPos] := d;

writeln('Массив после замены:');

for i := 1 to n do
    write(a[i], ' ');

end;
end.