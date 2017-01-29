uses crt;

var
  x,y:longint;

procedure setmode (mode:byte);

begin
  asm
    mov ah,0
    mov al,[mode]
    int 10h
  end
end;

procedure setcolor (color,red,green,blue:byte);

begin
  port[$3c8]:=color;
  port[$3c9]:=red;
  port[$3c9]:=green;
  port[$3c9]:=blue
end;

procedure putpixel (x,y:integer; color:byte);

begin
  mem[$a000:320*y+x]:=color
end;

begin
  setmode($13);
  setcolor(1,100,100,100);
  x:=0;
  repeat
    if round(sin(x)) <> 0
      then y:=round(1/4)*10000*round(sin(x));
    inc(x);
    putpixel(x*3,y+100,random(255));
    if x=320
      then x:=0
  until keypressed;
  setmode(3)
end.