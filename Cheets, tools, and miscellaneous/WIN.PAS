unit win;

interface

uses crt;

const
  bchars:array[1..5,1..7] of char = (('Õ','¸','À','Ù','Í','³','Ä'),
                                     ('Ú','¿','À','Ù','Ä','³','Ä'),
                                     ('Õ','¸','Ô','¾','Í','³','Í'),
                                     ('Ö','·','Ó','½','Ä','º','Ä'),
                                     ('É','»','È','¼','Í','º','Í'));
  colordisplay=$0b800;
  monodisplay=$0b000;
  toscreen=true;
  tomemory=false;

type
  buftype=array [1..4000] of byte;
  buffertype=array[1..6] of buftype;

procedure movescreento (x,y,x2,y2:byte; display:word; where:boolean;
                        var buff);
procedure setcursoroffon (off : boolean);
procedure scrollwin (topx,topy,bottomx,bottomy,color:byte);
procedure putchar (ch:char; x,y,color:byte);
procedure frame (x,y,x2,y2,bordercolor,titlecolor,border:byte; st:string;
                 puttitle:boolean);
procedure setmenu (topx,topy,bottomx,bottomy,bordercolor,titlecolor,
                   border:byte; title:string; framewin,puttitle:boolean);
function detectmode : word;

implementation

procedure movescreento (x,y,x2,y2:byte; display:word; where:boolean;
			var buff);

var
  upper,right,down,first,second,start:integer;
  buffer:array [1..4000] of byte absolute buff;

begin
  start:=1;
  upper:=(((2*x)-2)+((y-1)*160))-1;
  right:=((x2-x)+1)*2;
  down:=(y2-y)+1;
  for first:=1 to down do
    begin
      for second:=1 to right do
        begin
          if where=toscreen
            then mem[display:upper+second]:=buffer[start]
            else buffer[start]:=mem[display:upper+second];
          inc(start)
        end;
     upper:=upper+160       { advance to next line }
  end
end;

procedure setcursoroffon (off : boolean);

label on,exit;

begin
  asm
    mov ah,01
    mov bh,0
    cmp byte ptr [off],1
    jne on
    mov cx,4000
    jmp exit
  on:
    mov cx,1543
    mov dx,0
  exit:
    int 10h
  end
end;

procedure scrollwin (topx,topy,bottomx,bottomy,color:byte);

var
  numline:byte;

begin
  numline:=bottomy-topy+1;
  asm
    mov ah,6
    mov al,[numline]
    mov bh,[color]
    mov ch,[topy]
    mov cl,[topx]
    mov dh,[bottomy]
    mov dl,[bottomx]
    int 10h
  end
end;

procedure putchar (ch:char; x,y,color:byte);

var
  ordch:byte;

begin
  gotoxy(x,y);
  ordch:=ord(ch);
  asm
    mov ah,09
    mov al,ordch
    mov bh,0
    mov bl,[color]
    mov cx,1
    int 10h
  end
end;

procedure frame (x,y,x2,y2,bordercolor,titlecolor,border:byte; st:string;
                 puttitle:boolean);

const
  defaultcolor=white;

var
  xlength:integer;
  xc,yc:byte;

begin
  if not (border in [1..5])
    then border:=1;
  if x2>x then
    begin
      putchar(bchars[border][1],x,y,bordercolor);
      putchar(bchars[border][2],x2,y,bordercolor)
    end;
  if y2>y then
    begin
      putchar(bchars[border][3],x,y2,bordercolor);
      putchar(bchars[border][4],x2,y2,bordercolor)
    end;
  if x2-x>1 then
    for xc := x + 1 to x2 - 1 do
      begin
        putchar(bchars[border][5],xc,y,bordercolor);
        putchar(bchars[border][7],xc,y2,bordercolor)
      end;
  if y2-y>1 then
    for yc := y + 1 to y2 - 1 do
      begin
        putchar(bchars[border][6],x,yc,bordercolor);
        putchar(bchars[border][6],x2,yc,bordercolor)
      end;
  textattr:=bordercolor;
  xlength:=(x2 - x - length(st)) shr 1 + x;
  gotoxy(xlength,y);
  if ((x2-x) > xlength) and ((x2-x) > length(st)+5) then
    if puttitle then
      begin
        case border of
          1,3,5 : write('µ ',' ':length(st),' Æ');
          2,4 : write('´ ',' ':length(st),' Ã')
        end;
        textcolor(titlecolor);
        gotoxy(xlength+2,y);
        write(st)
      end;
  textcolor(defaultcolor)
end;

procedure setmenu (topx,topy,bottomx,bottomy,bordercolor,titlecolor,
                   border:byte; title:string; framewin,puttitle:boolean);

const
  off=true;
  on=false;

begin
  if (bottomy>80) or (bottomx<topx)
    then bottomx:=80;
  if (bottomy<topy) or (bottomy>25)
    then bottomy:=25;
  if (topx<1) or (topx>80)
    then topx:=1;
  if (topy<1) or (topy>25)
    then topy:=1;
  scrollwin(topx-1,topy-1,bottomx-1,bottomy-1,bordercolor);
  setcursoroffon(off);
  if framewin
    then frame(topx,topy,bottomx,bottomy,bordercolor,titlecolor,border,title,
               puttitle)
end;

function detectmode : word;

label color,exit;

var
  mode:word;

begin
  asm
    mov ah,0fh
    int 10h
    cmp al,7
    jne color
    mov word ptr [mode],monodisplay
    jmp exit
color:
    mov word ptr [mode],colordisplay
exit:
  end;
  detectmode:=mode
end;

end.

