uses crt;

begin
  repeat
    writeln(port[$60])
  until port[$60]=1;
  clrscr
end.
