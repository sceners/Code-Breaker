program sprite;

{$s-}

uses crt,dos;

const
  charseg=$0f000;
  charofs=$0fa6e;
  altw=#17;
  altr=#19;
  alty=#21;
  alto=#24;
  alts=#31;
  altd=#32;
  altx=#45;
  altc=#46;
  home=#71;
  up=#72;
  pgup=#73;
  left=#75;
  right=#77;
  endk=#79;
  down=#80;
  pgdn=#81;
  charlength=8;
  numchars=256;

type
  onechar=array[1..charlength] of byte;
  filetype=packed array[1..12] of char;
  charsettype=array[1..numchars] of onechar;
  colortype=array[1..8] of byte;
  boxtype=array[0..110,189..199] of byte;
  saveimagetype=record
    bx,by,ex,ey:integer;
    image:array[0..319,0..199] of byte;
  end;

var
  oldcint,oldcint2:pointer;
  colorstr:colortype;
  image:saveimagetype;

procedure setcolor (newcolor,newred,newgreen,newblue:byte);

begin
  port[$3c8]:=newcolor;
  port[$3c9]:=newred;
  port[$3c9]:=newgreen;
  port[$3c9]:=newblue
end;

procedure setmode (mode:byte);

begin
  asm
    mov ah,0
    mov al,mode
    int 10h
  end
end;

procedure putpixel (x,y:integer; color:byte);

begin
  mem[$0a000:320*y+x]:=color
end;

function getpixel (x,y:integer) : byte;

begin
  getpixel:=mem[$0a000:320*y+x]
end;

procedure switch (var first,second:integer);

var
  temp:integer;

begin
  temp:=first;
  first:=second;
  second:=temp
end;

procedure line (x1,y1,x2,y2:integer; color:byte);

var
  lgdelta,shdelta,lgstep,shstep,cycle,pointaddr:integer;

begin
  lgdelta:=x2-x1;
  shdelta:=y2-y1;
  if lgdelta<0 then
    begin
      lgdelta:=-lgdelta;
      lgstep:=-1
    end
  else lgstep:=1;
  if shdelta<0 then
    begin
      shdelta:=-shdelta;
      shstep:=-1
    end
  else shstep:=1;
  if lgdelta > shdelta then
    begin
      cycle:=lgdelta shr 1;
      while x1 <> x2 do
        begin
          putpixel(x1,y1,color);
          inc(x1,lgstep);
          inc(cycle,shdelta);
          if cycle > lgdelta then
            begin
              inc(y1,shstep);
              dec(cycle,lgdelta)
            end
        end
    end
  else
    begin
      cycle:=shdelta shr 1;
      switch(lgdelta,shdelta);
      switch(lgstep,shstep);
      while y1 <> y2 do
        begin
          putpixel(x1,y1,color);
          inc(y1,lgstep);
          inc(cycle,shdelta);
          if cycle > lgdelta then
            begin
              inc(x1,shstep);
              dec(cycle,lgdelta);
            end
        end
    end
end;

procedure blink (x,y:integer; color:byte; special:boolean);

begin
  randomize;
  repeat
    putpixel(x,y,random(255))
  until keypressed or special;
  putpixel(x,y,color)
end;

procedure blinkxy (x,y:integer; drawmode:boolean; color,status:byte);

begin
  blink(x,y,getpixel(x,y),false);
  if drawmode and ((x>0) or (x<319)) and ((y>0) or (y<199))
     and not (status in [1,2]) then
    begin
      blink(x,y,color,false);
      image.image[x,y]:=color
    end
end;

function readkey : byte;

label setkeyp,exit;

var
  keyp:byte;

begin
  repeat
    asm
      mov ah,1
      int 16h
      mov [keyp],1
      je  setkeyp
      jmp exit
setkeyp:
      mov [keyp],0
exit:
    end;
  until keyp=1;
  readkey:=keyp
end;

procedure getkey (x,y:integer; color:byte; var status:byte; drawmode:boolean; var key:char);

var
  regs:registers;
  keyp:byte;

begin
  repeat
    blinkxy(x,y,drawmode,color,status)
  until readkey=1;
  status:=mem[$40:$17] and $f;
  regs.ah:=0;
  intr($16,regs);
  if regs.al=0
    then key:=chr(regs.ah)
    else key:=chr(regs.al)
end;

procedure getchars (var charset:charsettype);

var
  numcounter,bytecounter,memcounter:integer;

begin
  memcounter:=0;
  for numcounter:=1 to numchars do
    for bytecounter:=1 to charlength do
      begin
        charset[numcounter][bytecounter]:=mem[charseg:charofs+memcounter];
        inc(memcounter)
      end
end;

procedure drawstr (xpos,ypos,size:integer; color:colortype; str:string;
                   charset:charsettype);

var
  temppos,mempos:word;
  xsize,ysize,count,xcount,ycount:integer;
  letter:onechar;

begin
  mempos:=(ypos-1)*320+(xpos-1);
  for count:=1 to length(str) do
    begin
      letter:=charset[ord(str[count])+1];
      for ycount:=1 to 8 do
        for xcount:=1 to 8 do
          if letter[ycount] and ($80 shr (xcount-1)) <> 0 then
            begin
              temppos:=mempos+(ycount-1)*320*size+(count-1)*8*size+(xcount-1)*size;
              for xsize:=1 to size do
                for ysize:=1 to size do
                  mem[$0a000:temppos+(xsize-1)+(ysize-1)*320]:=color[ycount]
            end
    end
end;

procedure init (var xrate,yrate,color,bkcolor:byte; var drawmode:boolean;
                var colorstr:colortype; var x,y:integer);

begin
  drawmode:=false;
  xrate:=1;
  yrate:=1;
  y:=0;
  x:=0;
  colorstr[1]:=26;
  colorstr[2]:=25;
  colorstr[3]:=24;
  colorstr[4]:=23;
  colorstr[5]:=22;
  colorstr[6]:=21;
  colorstr[7]:=20;
  colorstr[8]:=19;
  color:=0;
  bkcolor:=0
end;

procedure movement (var x,y:integer; key:char);

begin
  case key of
    left : if x>0
             then dec(x);
    right : if x<319
              then inc(x);
    up : if y>0
           then dec(y);
    down : if y<199
             then inc(y);
    pgdn : if y<199 then
             if x<319 then
               begin
                 y:=y+1;
                 x:=x+1
               end;
    home : if y>0 then
             if x>0 then
               begin
                 y:=y-1;
                 x:=x-1
               end;
    pgup : if y>0 then
             if x<319 then
               begin
                 y:=y-1;
                 x:=x+1
               end;
    endk : if y<199 then
             if x>0 then
               begin
                 y:=y+1;
                 x:=x-1
               end;
  end
end;

procedure mapfile (var filename:text);

var
  count,color:byte;
  bx,by,xc,yc,endx,endy:integer;

begin
  reset(filename);
  readln(filename,bx,by,endx,endy);
  count:=0;
  for yc:=by to endy do
    for xc:=bx to endx do
      begin
        if count<19
          then read(filename,color)
          else readln(filename,color);
	if color<>0
	  then putpixel(xc,yc,color);
        if count<19
          then count:=count+1
          else count:=0
      end;
  close(filename)
end;

procedure drawstatus (drawmode:boolean);

var
  filename:text;

begin
  if drawmode
    then assign(filename,'draw.but')
    else assign(filename,'move.but');
  mapfile(filename);
  assign(filename,'color.but');
  mapfile(filename)
end;

procedure showstatus (var show:boolean; var boxarea:boxtype; color:byte;
                      drawmode:boolean);

var
  bx,by:integer;

begin
  show:=not show;
  if show then
    for by:=189 to 199 do
      for bx:=0 to 110 do
        boxarea[bx,by]:=getpixel(bx,by);
  for by:=192 to 196 do
    line(95,by,108,by,color);
  drawstatus(drawmode);
  if not show then
    for by:=189 to 199 do
      for bx:=0 to 110 do
        putpixel(bx,by,boxarea[bx,by])
end;

procedure savetofile;

var
  imagefile:file;
  x,y:integer;

begin
  for x:=0 to 319 do
    for y:=0 to 199 do
      image.image[x,y]:=0;
  assign(imagefile,'image.img');
  rewrite(imagefile,1);
  image.bx:=0;
  image.by:=0;
  image.ex:=319;
  image.ey:=199;
  blockwrite(imagefile,image,sizeof(image));
  close(imagefile)
end;

procedure openfile;

var
  imagefile:file;
  x,y:integer;

begin
  assign(imagefile,'image.img');
  reset(imagefile,1);
  blockread(imagefile,image.bx,1);
  blockread(imagefile,image.by,1);
  blockread(imagefile,image.ex,1);
  blockread(imagefile,image.ey,1);
  blockread(imagefile,image.image,64000);
  for x:=image.bx to image.ex do
    for y:=image.by to image.ey do
      putpixel(x,y,image.image[x,y]);
  close(imagefile)
end;

procedure shiftkeys (var x,y:integer; xrate,yrate:byte; key:char);

begin
  case key of
    '9' : if (x < 319) and (y > 0) then
            begin
              x:=x+xrate;
              y:=y-yrate
            end;
    '3' : if (x < 319) and (y < 199) then
            begin
              x:=x+xrate;
              y:=y+yrate
            end;
    '1' : if (x > 0) and (y < 199) then
            begin
              x:=x-xrate;
              y:=y+yrate
            end;
    '7' : if (x > 0) and (y > 0) then
            begin
              x:=x-xrate;
              y:=y-yrate
            end;
    '6' : if x < 319
            then x:=x+xrate
            else x:=319;
    '4' : if x > 0
            then x:=x-xrate
            else x:=0;
    '8' : if y > 0
            then y:=y-yrate
            else y:=0;
    '2' : if y < 199
            then y:=y+yrate
            else y:=199
  end
end;

procedure checkcorrectxy (var x,y:integer);

begin
  if x > 319
      then x:=319;
    if x < 0
      then x:=0;
    if y > 199
      then y:=199;
    if y < 0
      then y:=0
end;

procedure driver;

var
  regs:registers;
  charset:charsettype;
  tkey,key:char;
  dummy,show,done,drawmode:boolean;
  color,bkcolor,xrate,yrate:byte;
  bx,by,x,y:integer;
  tstatus,count,status:byte;
  filename:text;
  boxarea:boxtype;

begin
  setmode($13);
  done:=false;
  show:=false;
  init(xrate,yrate,color,bkcolor,drawmode,colorstr,x,y);
  getchars(charset);
  xrate:=5;
  yrate:=5;
  repeat
    getkey(x,y,color,status,drawmode,key);
    if status in [0,8] then
      begin
        case key of
          altd : begin
                   drawmode:=not drawmode;
                 end;
          altc : begin
                   inc(color); {changecolor}
                 end;
          altr : begin
                   repeat
                     repeat until readkey=1;
                     regs.ah:=0;
                     intr($16,regs);
                     if regs.al=0
                       then tkey:=chr(regs.ah)
                       else tkey:=chr(regs.al);
                     case tkey of
                       up : if yrate < 50
                              then yrate:=yrate+5
                              else yrate:=0;
                       down : if yrate > 5
                              then yrate:=yrate-5
                              else yrate:=50;
                       left : if xrate > 5
                              then xrate:=xrate-5
                              else xrate:=50;
                       right : if xrate < 50
                              then xrate:=xrate+5
                              else xrate:=0;
                       alty : yrate:=5;
                       altx : xrate:=5
                     end
                   until tkey=#13
                 end;
          left,right,up,down,home,pgup,endk,pgdn : movement(x,y,key);
        end
      end
    else
      case status of
        1,2 : shiftkeys(x,y,xrate,yrate,key)
      end;
    checkcorrectxy(x,y)
  until key=#45;
  setmode(3)
end;

begin
  driver
end.


