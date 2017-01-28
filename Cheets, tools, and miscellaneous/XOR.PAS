program xornums;

uses crt,win,dos;

var
  numc,total,power,count,numdigit,x,y:integer;
  ch:char;
  data:array[1..4] of integer;

function raise16 (power:integer) : integer;

var
  sum:integer;
  count:integer;

begin
  sum:=1;
  for count:=1 to power do
    sum:=sum*16;
  raise16:=sum
end;

procedure writehex (w:integer);

const
  hexchars:array[0..$f] of char = '0123456789ABCDEF';

begin
  write(hexchars[hi(w) shr 4]);
  write(hexchars[hi(w) and $f]);
  write(hexchars[lo(w) shr 4]);
  write(hexchars[lo(w) and $f])
end;

begin
  clrscr;
  x:=wherex;
  y:=wherey;
  numdigit:=0;
  ch:=#0;
  for count:=1 to 4 do
    data[count]:=0;
  while (numdigit < 4) and (ch <> #13) do
    begin
      ch:=readkey;
      if ch=#0
        then ch:=readkey;
      if upcase(ch) in  ['A'..'F','0'..'9'] then
        begin
          ch:=upcase(ch);
          write(ch);
          inc(numdigit);
          case ch of
            'A'..'F' : data[numdigit]:=(ord(ch)-ord('A')+10);
            '0'..'9' : data[numdigit]:=(ord(ch)-ord('0'))
          end
        end
    end;
  writeln;
  writeln;
  total:=0;
  numc:=0;
  count:=3;
  if numdigit > 0 then
    begin
      repeat
        power:=numdigit-numc;
        if numdigit > 3
          then total:=total+(data[numdigit-count]*raise16(power-1))
          else total:=total+(data[count-numdigit]*raise16(power-1));
        dec(count);
        inc(numc)
      until (count=-1) and (numdigit-count > -1);
      writehex(total);
      writeln(' ',total)
    end
end.