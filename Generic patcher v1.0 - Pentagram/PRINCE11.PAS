uses dos;

{$m $50a,0,0}

var
  oldtimer:pointer;
  work:boolean;
  num:byte;

procedure newtimer; interrupt;

var
  base:word;

begin
  base:=cseg;
  dec(num);
  if not work then
    if num=0 then
      while not work do
        begin
          if mem[base:$24e3] = $83 then
          if mem[base:$24e4] = $c4 then
          if mem[base:$24e5] = $0a then
            begin
              work:=true;
              mem[base:$24e6]:=$50;
              mem[base:$24e7]:=$b8;
              mem[base:$24e8]:=$10;
              mem[base:$24e9]:=$00;
              mem[base:$24ea]:=$a3;
              mem[base:$24eb]:=$58;
              mem[base:$24ec]:=$3d;
              mem[base:$24ed]:=$58;
              mem[base:$24ee]:=$90;
              mem[base:$24ef]:=$90
            end
          else
            asm
              int 0bbh
            end;
          inc(base)
        end
      else
        asm
          int 0bbh
        end
end;
  
begin
  num:=20;
  work:=false;
  getintvec($1c,oldtimer);
  setintvec($bb,oldtimer);
  setintvec($1c,@newtimer);
  exec('prince.exe ','');
  setintvec($1c,oldtimer);
  if doserror=2
    then writeln(#7,'''Prince.exe'' not found.');
  writeln;
  writeln('''Prince Of Persia'' V1.1 unprotected by Code Breaker.');
  write('Greetings to : The Rocketeer, Flip Boy and The Silicon Soldier.')
end.
