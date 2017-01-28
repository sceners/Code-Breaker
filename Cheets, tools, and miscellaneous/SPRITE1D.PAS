program sprite;

{$s-}

uses crt,dos;

const
  vgaseg=$0a000;
  charseg=$0f000;
  charofs=$0fa6e;
  alty=#21;
  alti=#23;
  alto=#24;
  altp=#25;
  alta=#30;
  alts=#31;
  altd=#32;
  alte=#18;
  altr=#19;
  altf=#33;
  altl=#38;
  altk=#37;
  altz=#44;
  altx=#45;
  altc=#46;
  altv=#47;
  altb=#48;
  altn=#49;
  altm=#50;
  f1=#59;
  f2=#60;
  f3=#61;
  f4=#62;
  f5=#63;
  f6=#64;
  f7=#65;
  f8=#66;
  f9=#67;
  f10=#68;
  home=#71;
  up=#72;
  pgup=#73;
  left=#75;
  right=#77;
  endkey=#79;
  down=#80;
  pgdn=#81;
  charlength=8;
  numchars=256;

type
  onechar=array[1..charlength] of byte;
  filetype=packed array[1..12] of char;
  charsettype=array[1..numchars] of onechar;

var
  oldcint,oldcint2:pointer;

procedure setmsgcolor(var br,bg,bb,wr,wg,wb:byte);

begin
  port[$3c7]:=1;
  br:=port[$3c9];
  bg:=port[$3c9];
  bb:=port[$3c9];
  port[$3c8]:=1;
  port[$3c9]:=0;
  port[$3c9]:=0;
  port[$3c9]:=42;
  port[$3c7]:=100;
  wr:=port[$3c9];
  wg:=port[$3c9];
  wb:=port[$3c9];
  port[$3c8]:=100;
  port[$3c9]:=45;
  port[$3c9]:=63;
  port[$3c9]:=63
end;

procedure restoremsgcolor(br,bg,bb,wr,wg,wb:byte);

begin
  port[$3c8]:=1;
  port[$3c9]:=br;
  port[$3c9]:=bg;
  port[$3c9]:=bb;
  port[$3c8]:=100;
  port[$3c9]:=wr;
  port[$3c9]:=wg;
  port[$3c9]:=wb
end;

procedure getchars(var charset:charsettype);

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

procedure drawstr (xpos,ypos,size:integer; color:byte; str:string;
                   charset:charsettype);

var
  temppos,mempos:word;
  xsize,ysize,count,xcount,ycount:integer;
  letter:onechar;

begin
  mempos:=(ypos-1)*320+(xpos-1);
  for count := 1 to length(str) do
    begin
      letter := charset[ord(str[count])+1];
      for ycount := 1 to 8 do
        for xcount := 1 to 8 do
          if letter[ycount] and ($80 shr (xcount-1)) <> 0 then
            begin
              temppos := mempos+(ycount-1)*320*size+(count-1)*8*size
                         +(xcount-1)*size;
              for xsize := 1 to size do
                for ysize := 1 to size do
		  mem[vgaseg:temppos+(xsize-1)+(ysize-1)*320] := color
            end
    end
end;

procedure putpixel(x,y,color:integer);

begin
  mem[vgaseg:320*y+x]:=color
end;

function getpixel (x,y:integer) : byte;

var
  c:byte;

begin
  asm
    mov ah,0dh
    mov cx,[x]
    mov dx,[y]
    int 10h
    mov [c],al
  end;
  getpixel:=c
end;

procedure switch (var first,second:integer);

var
  temp:integer;

begin
  temp := first;
  first := second;
  second := temp
end;

procedure line (x1,y1,x2,y2,color:integer);

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

function changecolorto (color:byte; charset:charsettype; msg:string) : byte;

type
  saveareatype=array[0..125,0..7] of byte;

var
  ch:char; yc,xc,xt,yt:integer;
  savearea:saveareatype;
  br,bg,bb,wr,wg,wb,strc,count:byte;
  newcolor:array[1..3] of char;

begin
  setmsgcolor(br,bg,bb,wr,wg,wb);
  for yc:=0 to 7 do
    for xc:=0 to 125 do
      savearea[xc,yc]:=getpixel(xc,yc);
  for yc:=0 to 7 do
    line(0,yc,125,yc,1);
  drawstr(1,1,1,100,msg,charset);
  xt:=95;
  yt:=1;
  count:=0;
  repeat
    repeat
      drawstr(xt,yt,1,random(255),'_',charset)
    until keypressed;
    ch:=readkey;
    if ch=#0
      then ch:=readkey
      else
        begin
	  if upcase(ch) in ['0'..'9'] then
	    begin
	      drawstr(xt,yt,1,1,'_',charset);
	      if (ch<>'.') and not (xt<95) then
		begin
		  drawstr(xt,yt,1,100,upcase(ch),charset);
		  count:=count+1
		end;
	      newcolor[count]:=upcase(ch);
	      xt:=xt+8
	    end
          else
	    if (ch=#8) and (count>0) and (xt>0) then
	      begin
		drawstr(xt,yt,1,1,'_',charset);
		xt:=xt-8;
		drawstr(xt,yt,1,1,newcolor[count],charset);
		newcolor[count]:=' ';
		count:=count-1
              end
        end
  until (ch=#27) or ((count<>0) and (count>2));
  for yc:=0 to 7 do
    for xc:=0 to 125 do
       putpixel(xc,yc,savearea[xc,yc]);
  restoremsgcolor(br,bg,bb,wr,wg,wb);
  if ch=#27
    then changecolorto:=color
    else changecolorto:=((ord(newcolor[1])-$30)*100)+
			((ord(newcolor[2])-$30)*10)+(ord(newcolor[3])-$30)
end;

procedure getname(var filename:filetype; charset:charsettype; st:string;
                      var abort:boolean);

type
  saveareatype=array[0..319,0..7] of byte;

var
  x,y:integer; ch:char;
  savearea:saveareatype;
  wb,wg,wr,br,bg,bb,wc,bc,strc,count,color:byte;

begin
  setmsgcolor(br,bg,bb,wr,wg,wb);
  abort:=false;
  for y:=0 to 7 do
    for x:=0 to 319 do
      savearea[x,y]:=getpixel(x,y);
  for y:=0 to 7 do
    line(0,y,319,y,1);
  drawstr(1,1,1,100,st,charset);
  drawstr(110,1,1,100,'        .   ',charset);
  for count:=1 to 12 do
    filename[count]:=' ';
  x:=110;
  y:=1;
  count:=0;
  repeat
    repeat
      drawstr(x,y,1,random(255),'_',charset)
    until keypressed;
    ch:=readkey;
    if ch=#0
      then ch:=readkey
      else
        begin
          if upcase(ch) in [#32,'A'..'Z','0'..'9','.'] then
            begin
	      drawstr(x,y,1,1,'_',charset);
	      if (ch<>'.') and not (x<110) then
		begin
		  drawstr(x,y,1,100,upcase(ch),charset);
		  count:=count+1
		end;
              if count=9
                then count:=count+1;
              if (ch<>'.') and not (x<110)
                then filename[count]:=upcase(ch)
                else
                  begin
                    count:=8;
                    x:=166
                  end;
              if x=166
                then x:=x+16
                else x:=x+8
            end
          else
            if (ch=#8) and (count>0) and (x>110) then
              begin
		drawstr(x,y,1,1,'_',charset);
		if x=182
		  then x:=x-16
		  else x:=x-8;
		drawstr(x,y,1,1,filename[count],charset);
		filename[count]:=' ';
                count:=count-1
              end
        end
  until (ch=#27) or (((count<>0) and (ch=#13)) or (count>11));
  if ch=#27
    then abort:=true;
  filename[9]:='.';
  for y:=0 to 7 do
    for x:=0 to 319 do
      putpixel(x,y,savearea[x,y]);
  restoremsgcolor(br,bg,bb,wr,wg,wb)
end;

procedure overwrite(var filename:filetype; charset:charsettype;
		    var ow,abort:boolean; st,st2:string; s:pathstr);

type
  saveareatype=array[0..319,0..7] of byte;

var
  savearea:saveareatype;
  ch:char;
  x,y:integer;

begin
  if s<>'' then
    begin
      for y:=0 to 7 do
	for x:=0 to 319 do
	  savearea[x,y]:=getpixel(x,y);
      for y:=0 to 7 do
	line(0,y,319,y,1);
      drawstr(1,1,1,100,st,charset);
      repeat
	repeat
	  drawstr(250,1,1,random(255),'[Y]',charset)
	until keypressed;
	ch:=readkey;
	if ch=#0
	  then ch:=readkey;
      until upcase(ch) in ['Y','N',#13];
      for y:=0 to 7 do
	for x:=0 to 319 do
	  putpixel(x,y,savearea[x,y]);
      if upcase(ch)='N' then
	repeat
	  getname(filename,charset,st2,abort);
	  s:=fsearch(filename,getenv('path'));
	  if s<>''
	    then overwrite(filename,charset,ow,abort,st,st2,s);
	until (s='') or abort or ow
      else ow:=true
    end
  else ow:=true
end;

procedure saveimage(x,y,x2,y2:integer; charset:charsettype);

var
  abort,ow:boolean;
  bx,by,endx,endy,xc,yc,count:integer;
  image:text;
  filename:filetype;
  ch:char;
  s:pathstr;

begin
  by:=y;
  bx:=x;
  endx:=x2;
  endy:=y2;
  {$i-}
  getname(filename,charset,'Pic filename ',abort);
  s:=fsearch(filename,getenv('path'));
  overwrite(filename,charset,ow,abort,'Picture file exists. Overwrite? '
	    ,'Pic filename ',s);
  if not abort or ow then
    begin
      assign(image,filename);
      rewrite(image);
      count:=0;
      writeln(image,x,' ',y,' ',x2,' ',y2);
      for yc:=by to endy do
        for xc:=bx to endx do
           begin
             if count<19
               then write(image,getpixel(xc,yc),' ')
               else writeln(image,getpixel(xc,yc));
             if count<19
               then count:=count+1
               else count:=0
           end;
      close(image);
      filename[10]:='p';
      filename[11]:='a';
      filename[12]:='l';
      overwrite(filename,charset,ow,abort,'Palette file exists. Overwrite? ',
		'Pal filename ',s);
      if not abort or ow then
        begin
          assign(image,filename);
          rewrite(image);
          for count:=0 to 255 do
            begin
              port[$3c7]:=count;
              writeln(image,count,' ',port[$3c9],' ',port[$3c9],' ',port[$3c9])
            end;
          close(image)
        end
   end
end;

procedure restorepic(charset:charsettype; change:boolean);

var
  abort:boolean;
  color,count,bx,by,endx,endy,x,y:integer;
  image:text;
  filename:filetype;
  s:pathstr;

begin
  {$i-}
  abort:=false;
  if (paramcount>0) and not change
    then assign(image,paramstr(1))
    else
      begin
	repeat
	  getname(filename,charset,'Pic file name ',abort);
	  s:=fsearch(filename,getenv('path'))
	until (s<>'') or abort;
	assign(image,filename)
      end;
  count:=0;
  if not abort then
    begin
      reset(image);
      readln(image,bx,by,endx,endy);
      for y:=by to endy do
        for x:=bx to endx do
          begin
            if count<19
              then read(image,color)
              else readln(image,color);
	    if color<>0
	      then putpixel(x,y,color);
            if count<19
              then count:=count+1
              else count:=0
          end;
      close(image)
    end
end;

procedure restorenewpalette(charset:charsettype; change:boolean);

var
  abort:boolean;
  temp,c1,c2,c3:integer;
  image:text;
  s:pathstr;
  filename:filetype;

begin
  {$i-}
  abort:=false;
  if (paramcount>1) and not change
    then assign(image,paramstr(2))
    else
      begin
	repeat
	  getname(filename,charset,'Pal file name ',abort);
	  s:=fsearch(filename,getenv('path'))
	until (s<>'') or abort;
	assign(image,filename)
      end;
  if not abort then
    begin
      reset(image);
      while not eof(image) do
        begin
          readln(image,temp,c1,c2,c3);
          port[$3c8]:=temp;
          port[$3c9]:=c1;
          port[$3c9]:=c2;
          port[$3c9]:=c3
      end;
      close(image)
    end
end;

procedure restoreimage(charset:charsettype; change:boolean);

begin
  restorenewpalette(charset,change);
  restorepic(charset,change)
end;

procedure movexy(var x,y:integer; charset:charsettype);

label gotoxy,exit,mode,sy,sx,ya;

type
  saveareatype=array[0..115,0..7] of byte;

var
  nx,ny,xt,yt,xc,yc:integer; ch:char;
  savearea:saveareatype;
  br,bg,bb,wr,wg,wb,strc,count,color:byte;
  abortx,aborty:boolean;
  ycoord,xcoord:array[1..3] of char;

begin
  abortx:=false;
  aborty:=false;
  setmsgcolor(br,bg,bb,wr,wg,wb);
  for yc:=0 to 7 do
    for xc:=0 to 115 do
      savearea[xc,yc]:=getpixel(xc,yc);
  for yc:=0 to 7 do
    line(0,yc,115,yc,1);
  drawstr(1,1,1,100,'X = ',charset);
  drawstr(60,1,1,100,'Y = ',charset);
  xt:=30;
  yt:=1;
  count:=0;
  repeat
    repeat
      drawstr(xt,yt,1,random(255),'_',charset)
    until keypressed;
    ch:=readkey;
    if ch=#0
      then ch:=readkey
      else
        begin
	  if upcase(ch) in ['0'..'9'] then
	    begin
	      drawstr(xt,yt,1,1,'_',charset);
	      if (ch<>'.') and not (xt<30) then
		begin
		  drawstr(xt,yt,1,100,upcase(ch),charset);
		  count:=count+1
		end;
	      xcoord[count]:=upcase(ch);
	      xt:=xt+8
	    end
          else
	    if (ch=#8) and (count>0) and (xt>0) then
	      begin
		drawstr(xt,yt,1,1,'_',charset);
		xt:=xt-8;
		drawstr(xt,yt,1,1,xcoord[count],charset);
		xcoord[count]:=' ';
		count:=count-1
              end
        end
  until (ch=#27) or ((count<>0) and (count>2));
  if ch=#27
    then abortx:=true;
  xt:=90;
  yt:=1;
  count:=0;
  repeat
    repeat
      drawstr(xt,yt,1,random(255),'_',charset)
    until keypressed;
    ch:=readkey;
    if ch=#0
      then ch:=readkey
      else
	begin
	  if upcase(ch) in ['0'..'9'] then
	    begin
	      drawstr(xt,yt,1,1,'_',charset);
	      if (ch<>'.') and not (xt<90) then
		begin
		  drawstr(xt,yt,1,100,upcase(ch),charset);
		  count:=count+1
		end;
	      ycoord[count]:=upcase(ch);
	      xt:=xt+8
	    end
          else
	    if (ch=#8) and (count>0) and (xt>0) then
	      begin
		drawstr(xt,yt,1,1,'_',charset);
		xt:=xt-8;
		drawstr(xt,yt,1,1,ycoord[count],charset);
		ycoord[count]:=' ';
		count:=count-1
              end
        end
  until (ch=#27) or ((count<>0) and (count>2));
  if ch=#27
    then aborty:=true;
  for yc:=0 to 7 do
    for xc:=0 to 115 do
      putpixel(xc,yc,savearea[xc,yc]);
  if not abortx
    then nx:=(ord(xcoord[1])-$30)*100+(ord(xcoord[2])-$30)*10+
	    (ord(xcoord[3])-$30);
  if not aborty
    then ny:=(ord(ycoord[1])-$30)*100+(ord(ycoord[2])-$30)*10+
	    (ord(ycoord[3])-$30);
   asm
     mov ah,02
     cmp word ptr [nx],0
     jl  sx
     cmp word ptr [nx],319
     jge sx
     mov cx,word ptr [nx]
     jmp ya
   sx:
     mov ax,word ptr [x]
     mov [nx],ax
   ya:
     cmp word ptr [ny],0
     jl  sy
     cmp word ptr [ny],200
     jge sy
     mov dx,word ptr [ny]
 mode:
     int 10h
     jmp exit
 sy:
     mov ax,word ptr [y]
     mov [ny],ax
     jmp mode
 exit:
  end;
  x:=nx;
  y:=ny;
  restoremsgcolor(br,bg,bb,wr,wg,wb)
end;

procedure rectangle(x1,y1,x2,y2,color:integer);

begin
  line(x1,y1,x2,y1,color);
  line(x1,y1,x1,y2,color);
  line(x2,y1,x2,y2,color);
  line(x1,y2,x2,y2,color);
  putpixel(x2,y2,color)
end;

procedure drawbar(color:byte);

var
  y:integer;

begin
  rectangle(0,150,40,170,100);
  for y:=152 to 168 do
    line(2,y,39,y,color)
end;

procedure changecolor(var color:byte; charset:charsettype);

type
  saveareatype=array[0..31,179..187] of integer;

var
  ch:char;
  savearea:saveareatype;
  s:string[3];
  rc,bc,gc:string[2];
  yc,xc:integer;

begin
  repeat
    for yc:=179 to 187 do
      for xc:=0 to 31 do
	savearea[xc,yc]:=getpixel(xc,yc);
    str(color, s);
    port[$3c7]:=color;
    str(port[$3c9],rc);
    str(port[$3c9],gc);
    str(port[$3c9],bc);
    drawstr(1,180,1,100,s,charset);
    delay(300);
    ch:=readkey;
    if ch=#0 then
      begin
        ch:=readkey;
        case ch of
          left:if color > 0
                 then dec(color)
                 else color:=255;
          right:if color < 255
                  then inc(color)
		  else color:=0
	end
      end;
    drawbar(color);
    for yc:=179 to 187 do
      for xc:=0 to 31 do
	putpixel(xc,yc,savearea[xc,yc])
  until ch in [#13,#27]
end;

procedure colorchange(var color:byte; charset:charsettype);

type
  colorareatype=array [0..40,150..170] of integer;

var
  colorarea:colorareatype;

procedure savecolorarea(var colorarea:colorareatype);

var
  x,y:integer;

begin
  for x:=0 to 40 do
    for y:=150 to 170 do
      colorarea[x,y]:=getpixel(x,y)
end;

procedure restorecolorarea(colorarea:colorareatype);

var
  x,y:integer;

begin
  for x:=0 to 40 do
    for y:=150 to 170 do
      putpixel(x,y,colorarea[x,y])
end;

begin
  savecolorarea(colorarea);
  drawbar(color);
  changecolor(color,charset);
  restorecolorarea(colorarea)
end;

procedure restorepalette;

const
  pal:array[0..255,1..3] of byte =
    ((0,0,0),(0,0,42),(0,42,0),(0,42,42),(42,0,0),(42,0,42),(42,21,0),
     (42,42,42),(21,21,21),(21,21,63),(21,63,21),(21,63,63),(63,21,21),
     (63,21,63),(63,63,21),(63,63,63),(0,0,0),(5,5,5),(8,8,8),(11,11,11),
     (14,14,14),(17,17,17),(20,20,20),(24,24,24),(28,28,28),(32,32,32),
     (36,36,36),(40,40,40),(45,45,45),(50,50,50),(56,56,56),(63,63,63),
     (0,0,63),(16,0,63),(31,0,63),(47,0,63),(63,0,63),(63,0,47),(63,0,31),
     (63,0,16),(63,0,0),(63,16,0),(63,31,0),(63,47,0),(63,63,0),(47,63,0),
     (31,63,0),(16,63,0),(0,63,0),(0,63,16),(0,63,31),(0,63,47),(0,63,63),
     (0,47,63),(0,31,63),(0,16,63),(31,31,63),(39,31,63),(47,31,63),
     (55,31,63),(63,31,63),(63,31,55),(63,31,47),(63,31,39),(63,31,31),
     (63,39,31),(63,47,31),(63,55,31),(63,63,31),(55,63,31),(47,63,31),
     (39,63,31),(31,63,31),(31,63,39),(31,63,47),(31,63,55),(31,63,63),
     (31,55,63),(31,47,63),(31,39,63),(45,45,63),(49,45,63),(54,45,63),
     (58,45,63),(63,45,63),(63,45,58),(63,45,54),(63,45,49),(63,45,45),
     (63,49,45),(63,54,45),(63,58,45),(63,63,45),(58,63,45),(54,63,45),
     (49,63,45),(45,63,45),(45,63,49),(45,63,54),(45,63,58),(45,63,63),
     (45,58,63),(45,54,63),(45,49,63),(0,0,28),(7,0,28),(14,0,28),(21,0,28),
     (28,0,28),(28,0,21),(28,0,14),(28,0,7),(28,0,0),(28,7,0),(28,14,0),
     (28,21,0),(28,28,0),(21,28,0),(14,28,0),(7,28,0),(0,28,0),(0,28,7),
     (0,28,14),(0,28,21),(0,28,28),(0,21,28),(0,14,28),(0,7,28),(14,14,28),
     (17,14,28),(21,14,28),(24,14,28),(28,14,28),(28,14,24),(28,14,21),
     (28,14,17),(28,14,14),(28,17,14),(28,21,14),(28,24,14),(28,28,14),
     (24,28,14),(21,28,14),(17,28,14),(14,28,14),(14,28,17),(14,28,21),
     (14,28,24),(14,28,28),(14,24,28),(14,21,28),(14,17,28),(20,20,28),
     (22,20,28),(24,20,28),(26,20,28),(28,20,28),(28,20,26),(28,20,24),
     (28,20,22),(28,20,20),(28,22,20),(28,24,20),(28,26,20),(28,28,20),
     (26,28,20),(24,28,20),(22,28,20),(20,28,20),(20,28,22),(20,28,24),
     (20,28,26),(20,28,28),(20,26,28),(20,24,28),(20,22,28),(0,0,16),
     (4,0,16),(8,0,16),(12,0,16),(16,0,16),(16,0,12),(16,0,8),(16,0,4),
     (16,0,0),(16,4,0),(16,8,0),(16,12,0),(16,16,0),(12,16,0),(8,16,0),
     (4,16,0),(0,16,0),(0,16,4),(0,16,8),(0,16,12),(0,16,16),(0,12,16),
     (0,8,16),(0,4,16),(8,8,16),(10,8,16),(12,8,16),(14,8,16),(16,8,16),
     (16,8,14),(16,8,12),(16,8,10),(16,8,8),(16,10,8),(16,12,8),(16,14,8),
     (16,16,8),(14,16,8),(12,16,8),(10,16,8),(8,16,8),(8,16,10),(8,16,12),
     (8,16,14),(8,16,16),(8,14,16),(8,12,16),(8,10,16),(11,11,16),(12,11,16),
     (13,11,16),(15,11,16),(16,11,16),(16,11,15),(16,11,13),(16,11,12),
     (16,11,11),(16,12,11),(16,13,11),(16,15,11),(16,16,11),(15,16,11),
     (13,16,11),(12,16,11),(11,16,11),(11,16,12),(11,16,13),(11,16,15),
     (11,16,16),(11,15,16),(11,13,16),(11,12,16),(0,0,0),(0,0,0),(0,0,0),
     (0,0,0),(0,0,0),(0,0,0),(0,0,0),(0,0,0));

var
  count:byte;

begin
  for count:=0 to 255 do
    begin
      port[$3c8]:=count;
      port[$3c9]:=pal[count][1];
      port[$3c9]:=pal[count][2];
      port[$3c9]:=pal[count][3]
    end
end;

procedure setcolor(newcolor,newred,newgreen,newblue:byte);

begin
  port[$3c8]:=newcolor;
  port[$3c9]:=newred;
  port[$3c9]:=newgreen;
  port[$3c9]:=newblue
end;

procedure setmode(mode:byte);

begin
  asm
    mov ah,0
    mov al,mode
    int 10h
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
     and not (status in [1,2])
     then blink(x,y,color,false)
end;

function readkey2 : byte;

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
  readkey2:=keyp
end;

procedure getkey (x,y:integer; color:byte; var status:byte; drawmode:boolean; var key:char);

var
  regs:registers;
  keyp:byte;

begin
  repeat
    blinkxy(x,y,drawmode,color,status)
  until readkey2=1;
  status:=mem[$40:$17] and $f;
  regs.ah:=0;
  intr($16,regs);
  if regs.al=0
    then key:=chr(regs.ah)
    else key:=chr(regs.al)
end;

procedure changepalcolor (color:byte; var red,green,blue:byte; charset:charsettype);

type
  saveareatype=array[0..319,0..7] of byte;

var
  nx,ny,xt,yt,xc,yc:integer; ch:char;
  savearea:saveareatype;
  bt,rt,gt,br,bg,bb,wr,wg,wb,strc,count:byte;
  abortr,abortg,abortb:boolean;
  bluepal,greenpal,redpal:array[1..2] of char;
  cs:string;

begin
  abortr:=false;
  abortg:=false;
  abortb:=false;
  port[$3c7]:=color;
  red:=port[$3c9];
  green:=port[$3c9];
  blue:=port[$3c9];
  str(color,cs);
  setmsgcolor(br,bg,bb,wr,wg,wb);
  for yc:=0 to 7 do
    for xc:=0 to 319 do
      savearea[xc,yc]:=getpixel(xc,yc);
  for yc:=0 to 7 do
    line(0,yc,319,yc,1);
  drawstr(1,1,1,100,'Color = '+cs,charset);
  drawstr(110,1,1,100,'R = ',charset);
  drawstr(170,1,1,100,'G = ',charset);
  drawstr(230,1,1,100,'B = ',charset);
  xt:=140;
  yt:=1;
  count:=0;
  repeat
    repeat
      drawstr(xt,yt,1,random(255),'_',charset)
    until keypressed;
    ch:=readkey;
    if ch=#0
      then ch:=readkey
      else
        begin
	  if upcase(ch) in ['0'..'9'] then
	    begin
	      drawstr(xt,yt,1,1,'_',charset);
	      if (ch<>'.') and not (xt<140) then
		begin
		  drawstr(xt,yt,1,100,upcase(ch),charset);
		  count:=count+1
		end;
	      redpal[count]:=upcase(ch);
	      xt:=xt+8
	    end
          else
	    if (ch=#8) and (count>0) and (xt>0) then
	      begin
		drawstr(xt,yt,1,1,'_',charset);
		xt:=xt-8;
		drawstr(xt,yt,1,1,redpal[count],charset);
		redpal[count]:=' ';
		count:=count-1
              end
        end
  until (ch=#27) or ((count<>0) and (count>1));
  if ch=#27
    then abortr:=true;
  xt:=200;
  yt:=1;
  count:=0;
  repeat
    repeat
      drawstr(xt,yt,1,random(255),'_',charset)
    until keypressed;
    ch:=readkey;
    if ch=#0
      then ch:=readkey
      else
	begin
	  if upcase(ch) in ['0'..'9'] then
	    begin
	      drawstr(xt,yt,1,1,'_',charset);
	      if (ch<>'.') and not (xt<185) then
		begin
		  drawstr(xt,yt,1,100,upcase(ch),charset);
		  count:=count+1
		end;
	      greenpal[count]:=upcase(ch);
	      xt:=xt+8
	    end
          else
	    if (ch=#8) and (count>0) and (xt>0) then
	      begin
		drawstr(xt,yt,1,1,'_',charset);
		xt:=xt-8;
		drawstr(xt,yt,1,1,greenpal[count],charset);
		greenpal[count]:=' ';
		count:=count-1
              end
        end
  until (ch=#27) or ((count<>0) and (count>1));
  if ch=#27
    then abortg:=true;
  xt:=260;
  yt:=1;
  count:=0;
  repeat
    repeat
      drawstr(xt,yt,1,random(255),'_',charset)
    until keypressed;
    ch:=readkey;
    if ch=#0
      then ch:=readkey
      else
	begin
	  if upcase(ch) in ['0'..'9'] then
	    begin
	      drawstr(xt,yt,1,1,'_',charset);
	      if (ch<>'.') and not (xt<240) then
		begin
		  drawstr(xt,yt,1,100,upcase(ch),charset);
		  count:=count+1
		end;
	      bluepal[count]:=upcase(ch);
	      xt:=xt+8
	    end
          else
	    if (ch=#8) and (count>0) and (xt>0) then
	      begin
		drawstr(xt,yt,1,1,'_',charset);
		xt:=xt-8;
		drawstr(xt,yt,1,1,bluepal[count],charset);
		bluepal[count]:=' ';
		count:=count-1
              end
        end
  until (ch=#27) or ((count<>0) and (count>1));
  if ch=#27
    then abortb:=true;
  for yc:=0 to 7 do
    for xc:=0 to 319 do
      putpixel(xc,yc,savearea[xc,yc]);
  if not abortr
    then rt:=(ord(redpal[1])-$30)*10+(ord(redpal[2])-$30)
    else rt:=red;
  if not abortg
    then gt:=(ord(greenpal[1])-$30)*10+(ord(greenpal[2])-$30)
    else gt:=green;
  if not abortb
    then bt:=(ord(bluepal[1])-$30)*10+(ord(bluepal[2])-$30)
    else bt:=blue;
  if not ((bt>63) or (rt>63) or (gt>63) or (rt<0) or (bt<0) or (gt<0)) then
    begin
      blue:=bt;
      red:=rt;
      green:=gt
    end;
  restoremsgcolor(br,bg,bb,wr,wg,wb)
end;

procedure showcolor(x,y:integer; charset:charsettype; c:byte; show:boolean);

type
  saveareatype=array[0..319,179..187] of byte;

var
  ch:char;
  savearea:saveareatype;
  s:string[3];
  r,b,g:string[2];
  br,bg,bb,wr,wg,wb,color:byte;
  xc,yc:integer;

begin
  setmsgcolor(br,bg,bb,wr,wg,wb);
  for yc:=179 to 187 do
    for xc:=0 to 319 do
      savearea[xc,yc]:=getpixel(xc,yc);
  if show
    then color:=getpixel(x,y)
    else color:=c;
  if not show
    then restoremsgcolor(br,bg,bb,wr,wg,wb);
  str(color, s);
  port[$3c7]:=color;
  str(port[$3c9], r);
  str(port[$3c9], g);
  str(port[$3c9], b);
  drawstr(1,180,1,100,'Color = '+s+'   R = '+r+'   G = '+g+'   B = '+b,charset);
  delay(400);
  for yc:=179 to 187 do
    for xc:=0 to 319 do
      putpixel(xc,yc,savearea[xc,yc]);
  restoremsgcolor(br,bg,bb,wr,wg,wb)
end;

procedure changepal(var color:byte; charset:charsettype);

type
  colorareatype=array [0..40,150..170] of integer;
  saveareatype=array[0..190,179..187] of byte;

var
  colorarea:colorareatype;
  savearea:saveareatype;
  ch:char; x,y:integer;
  red,blue,green:byte;
  c,r,g,b:string;

begin
  for x:=0 to 40 do
    for y:=150 to 170 do
      colorarea[x,y]:=getpixel(x,y);
  drawbar(color);
  port[$3c7]:=color;
  red:=port[$3c9];
  green:=port[$3c9];
  blue:=port[$3c9];
  repeat
    str(color, c);
    port[$3c7]:=color;
    str(port[$3c9], r);
    str(port[$3c9], g);
    str(port[$3c9], b);
    for y:=179 to 187 do
      for x:=0 to 190 do
	savearea[x,y]:=getpixel(x,y);
    drawstr(1,180,1,100,c+' R = '+r+' G = '+g+' B = '+b,charset);
    ch:=readkey;
    if ch=#0 then
      begin
	ch:=readkey;
	case ch of
	  f1:begin
	       for y:=179 to 187 do
		 for x:=0 to 190 do
		   putpixel(x,y,savearea[x,y]);
	       colorchange(color,charset)
	     end;
	  f2:if red<63
		 then inc(red)
		 else red:=0;
	  f3:if red>0
		 then dec(red)
		 else red:=63;
	  f4:if green<63
		 then inc(green)
		 else green:=0;
	  f5:if green>0
		 then dec(green)
		 else green:=63;
	  f6:if blue<63
		 then inc(blue)
		 else blue:=0;
	  f7:if blue>0
		 then dec(blue)
		 else blue:=63;
	  f8:color:=changecolorto(color,charset,'New color = ');
	  f9:changepalcolor(color,red,green,blue,charset);
	  f10:restorepalette;
	  altc:restorenewpalette(charset,true)
	end;
	drawbar(color)
      end;
    for y:=179 to 187 do
      for x:=0 to 190 do
	putpixel(x,y,savearea[x,y]);
    if ch in [f2,f3,f4,f5,f6,f7,f9]
      then setcolor(color,red,green,blue)
  until ch in [#13,#27];
  for y:=179 to 187 do
    for x:=0 to 190 do
      putpixel(x,y,savearea[x,y]);
  for x:=0 to 40 do
    for y:=150 to 170 do
      putpixel(x,y,colorarea[x,y])
end;

procedure clearscreen (charset:charsettype; var bkcolor:byte);

type
  saveareatype=array[0..90,0..7] of byte;

var
  ch:char;
  savearea:saveareatype;
  xt,yt,br,bg,bb,wr,wg,wb,strc,count:byte;
  abortx,aborty:boolean;
  xc:array[1..3] of char;
  x,y:integer;
  color:byte;

begin
  setmsgcolor(br,bg,bb,wr,wg,wb);
  for y:=0 to 7 do
    for x:=0 to 90 do
      savearea[x,y]:=getpixel(x,y);
  for y:=0 to 7 do
    line(0,y,90,y,1);
  drawstr(1,1,1,100,'Color = ',charset);
  xt:=65;
  yt:=1;
  count:=0;
  repeat
    repeat
      drawstr(xt,yt,1,random(255),'_',charset)
    until keypressed;
    ch:=readkey;
    if ch=#0
      then ch:=readkey
      else
        begin
	  if upcase(ch) in ['0'..'9'] then
	    begin
	      drawstr(xt,yt,1,1,'_',charset);
	      if (ch<>'.') and not (xt<60) then
		begin
		  drawstr(xt,yt,1,100,upcase(ch),charset);
		  count:=count+1
		end;
	      xc[count]:=upcase(ch);
	      xt:=xt+8
	    end
          else
	    if (ch=#8) and (count>0) and (xt>0) then
	      begin
		drawstr(xt,yt,1,1,'_',charset);
		xt:=xt-8;
		drawstr(xt,yt,1,1,xc[count],charset);
		xc[count]:=' ';
		count:=count-1
              end
        end
  until (ch=#27) or ((count<>0) and (count>2));
  if ch<>#27 then
    begin
      color:=(ord(xc[1])-$30)*100+(ord(xc[2])-$30)*10+(ord(xc[3])-$30);
      for y:=0 to 199 do
        line(0,y,320,y,color)
    end
  else
    for y:=0 to 7 do
      for x:=0 to 90 do
        putpixel(x,y,savearea[x,y]);
  restoremsgcolor(br,bg,bb,wr,wg,wb);
  bkcolor:=color
end;

procedure movement (var x,y:integer; ch:char; charset:charsettype);

begin
  case ch of
    pgup:if (y<319) and (y>0) then
           begin
             x:=x+1;
             y:=y-1
           end;
    endkey:if (x>0) and (y<199) then
             begin
               x:=x-1;
               y:=y+1
             end;
    pgdn:if (x<319) and (y<199) then
           begin
             x:=x+1;
             y:=y+1
           end;
    up:if y>0
         then y:=y-1
         else y:=199;
    down:if y<199
           then y:=y+1
           else y:=0;
    left:if x>0
           then x:=x-1
           else x:=319;
    right:if x<319
            then x:=x+1
            else x:=0;
    home:if (x>0) and (y>0) then
           begin
             x:=x-1;
             y:=y-1
	   end;
    alta:showcolor(x,y,charset,1,true)
  end
end;

procedure changerate(var xrate,yrate:byte; ch:char);

begin
  case ch of
    altv:if xrate<20
           then xrate:=xrate+1
           else xrate:=1;
    altb:if xrate>1
           then xrate:=xrate-1
           else xrate:=20;
    altn:if yrate<20
           then yrate:=yrate+1
           else yrate:=1;
    altm:if yrate>1
           then yrate:=yrate-1
           else yrate:=20
  end
end;

procedure markandsave(var color:byte; charset:charsettype);

type
  xtype=array[0..319] of byte;
  ytype=array[0..199] of byte;

var
  ch:char;
  xarea,xarea2:xtype;
  yarea,yarea2:ytype;
  count,tempc,cx,cy,cx2,cy2:integer;
  br,bg,bb,wr,wg,wb:byte;

procedure restorerec(xarea,xarea2:xtype;yarea,yarea2:ytype;
                     cx,cx2,cy,cy2:integer);

var
  count:integer;

begin
  for count:=cx to cx2 do
    putpixel(count,cy,xarea[count]);
  for count:=cy to cy2 do
    putpixel(cx,count,yarea[count]);
  for count:=cy to cy2 do
    putpixel(cx2,count,yarea2[count]);
  for count:=cx to cx2 do
    putpixel(count,cy2,xarea2[count])
end;

procedure restorerec1(xarea,xarea2:xtype;yarea,yarea2:ytype;
                      cx,cx2,cy,cy2:integer);

var
  count:integer;
  
begin
  for count:=cy to cy2 do
    putpixel(cx,count,yarea[count]);
  for count:=cy to cy2 do
    putpixel(cx2,count,yarea2[count]);
  for count:=cx to cx2 do
    putpixel(count,cy2,xarea2[count]);
  for count:=cx to cx2 do
    putpixel(count,cy,xarea[count])
end;

begin
  cx:=0;
  cy:=0;
  cy2:=199;
  cx2:=319;
  setmsgcolor(br,bg,bb,wr,wg,wb);
  repeat
    tempc:=getpixel(cx,cy);
    for count:=cx to cx2 do
      xarea[count]:=getpixel(count,cy);
    line(cx,cy,cx2,cy,color);
    for count:=cy to cy2 do
      yarea[count]:=getpixel(cx,count);
    line(cx,cy,cx,cy2,color);
    for count:=cy to cy2 do
      yarea2[count]:=getpixel(cx2,count);
    line(cx2,cy,cx2,cy2,color);
    for count:=cx to cx2 do
      xarea2[count]:=getpixel(count,cy2);
    line(cx,cy2,cx2,cy2,color);
    while not keypressed do;
    ch:=readkey;
    if ch=#0 then
      begin
        ch:=readkey;
        if ch in [f1,f2,f3,f4,f5,f6,f7,f8,f9,f10] then
          case ch of
            f1:begin
		 colorchange(color,charset);
                 restorerec(xarea,xarea2,yarea,yarea2,cx,cx2,cy,cy2);
                 putpixel(cx,cy,tempc);
                 ch:=f1
               end;
            f2:begin
                 restorerec1(xarea,xarea2,yarea,yarea2,cx,cx2,cy,cy2);
                 if (cy<cy2) and (cy<199)
                   then cy:=cy+1
               end;
            f3:begin
                 restorerec1(xarea,xarea2,yarea,yarea2,cx,cx2,cy,cy2);
                 if cy>0
                   then cy:=cy-1
               end;
            f4:begin
                 restorerec1(xarea,xarea2,yarea,yarea2,cx,cx2,cy,cy2);
                 if (cx<cx2) and (cx<319)
                   then cx:=cx+1
               end;
            f5:begin
                 restorerec1(xarea,xarea2,yarea,yarea2,cx,cx2,cy,cy2);
                 if cx>0
                   then cx:=cx-1
               end;
            f6:begin
                 restorerec(xarea,xarea2,yarea,yarea2,cx,cx2,cy,cy2);
                 putpixel(cx,cy,tempc);
                 if (cx2>0) and (cx2>cx)
                   then cx2:=cx2-1
               end;
            f7:begin
                 restorerec(xarea,xarea2,yarea,yarea2,cx,cx2,cy,cy2);
                 putpixel(cx,cy,tempc);
                 if cx2<319
                   then cx2:=cx2+1
               end;
            f8:begin
                 restorerec(xarea,xarea2,yarea,yarea2,cx,cx2,cy,cy2);
                 putpixel(cx,cy,tempc);
                 if cy2>cy
                   then cy2:=cy2-1
               end;
            f9:begin
                 restorerec1(xarea,xarea2,yarea,yarea2,cx,cx2,cy,cy2);
                 if cy2<199
                   then cy2:=cy2+1
               end;
            f10:begin
                  restorerec(xarea,xarea2,yarea,yarea2,cx,cx2,cy,cy2);
		  putpixel(cx,cy,tempc);
		  restoremsgcolor(br,bg,bb,wr,wg,wb);
                  saveimage(cx,cy,cx2,cy2,charset);
                  sound(100); delay(100); nosound
                end
          end
      end
  until not (ch in [f1,f2,f3,f4,f5,f6,f7,f8,f9,f10]);
  restorerec(xarea,xarea2,yarea,yarea2,cx,cx2,cy,cy2);
  restoremsgcolor(br,bg,bb,wr,wg,wb);
  putpixel(cx,cy,tempc)
end;

procedure writech(x,y:integer; xrate,yrate:byte; drawmode:boolean;
                  charset:charsettype; var color:byte);

var
  ch:char;
  status,chsize:byte;
  st:string;
  xs,ys,xf:integer;

begin
  drawmode:=false;
  chsize:=1;
  repeat
    getkey(x,y,color,status,drawmode,ch);
    if (status in [0,8]) and (ch in [f1,f2,f3,f4,f5,alta,pgup,endkey,pgdn,home,left,right,up,down]) then
      begin
        if ch=#0
          then ch:=readkey;
        case ch of
	  f1:colorchange(color,charset);
          f2:if chsize < 4
               then chsize:=chsize+1
               else chsize:=1;
          f3:if chsize > 1
               then chsize:=chsize-1
               else chsize:=4;
          f4:color:=0;
          f5:restorepic(charset,true);
	  alta,pgup,endkey,pgdn,home,left,right,up,down:movement(x,y,ch,charset)
        end
      end
    else
      if ord(ch) in [30..255] then
        begin
          st:=ch;
          xf:=307;
          xs:=7;
          ys:=8;
          case chsize of
            2:begin
                xf:=290;
                xs:=15;
                ys:=16
              end;
            3:begin
                xf:=280;
                xs:=22;
                ys:=22
              end;
            4:begin
                xf:=280;
                xs:=29;
                ys:=29
              end
          end;
          drawstr(x+1,y+1,chsize,color,st,charset);
          if x<xf
            then x:=x+xs
            else
              begin
                y:=y+ys;
                x:=0
              end
        end
  until ch in [#27,#13]
end;

procedure floodfill (x,y,oldc,newc:integer);

begin
  {$s+ 65536,0,0}
  if getpixel(x,y)=oldc then
    begin
      putpixel(x,y,newc);
      floodfill(x,y-1,oldc,newc);
      floodfill(x,y+1,oldc,newc);
      floodfill(x-1,y,oldc,newc);
      floodfill(x+1,y,oldc,newc)
    end
end;

procedure showxy(x,y:integer; charset:charsettype);

type
  saveareatype=array[0..125,189..197] of byte;

var
  savearea:saveareatype;
  s:string[4];
  br,bg,bb,wr,wg,wb,yc,xc:byte;

begin
  setmsgcolor(br,bg,bb,wr,wg,wb);
  for yc:=189 to 197 do
    for xc:=0 to 125 do
      savearea[xc,yc]:=getpixel(xc,yc);
  str(x, s);
  drawstr(1,190,1,100,'X = '+s,charset);
  str(y, s);
  drawstr(70,190,1,100,'Y = '+s,charset);
  delay(300);
  for yc:=189 to 197 do
    for xc:=0 to 125 do
      putpixel(xc,yc,savearea[xc,yc]);
  restoremsgcolor(br,bg,bb,wr,wg,wb);
end;

function floodfillmsg(charset:charsettype; st:string; color:byte) : byte;

type
  saveareatype=array[0..120,0..7] of byte;

var
  savearea:saveareatype;
  ch:char;
  wb,wg,wr,br,bg,bb,wc,bc:byte;
  y,x:integer;

begin
  setmsgcolor(br,bg,bb,wr,wg,wb);
  bc:=1;
  wc:=100;
  for y:=0 to 7 do
    for x:=0 to 90 do
      savearea[x,y]:=getpixel(x,y);
  for y:=0 to 7 do
    line(0,y,90,y,bc);
  color:=changecolorto(color,charset,st);
  for y:=0 to 7 do
    for x:=0 to 90 do
       putpixel(x,y,savearea[x,y]);
  floodfillmsg:=color;
  restoremsgcolor(br,bg,bb,wr,wg,wb)
end;

procedure lineto(x,y:integer; color:byte; charset:charsettype);

label gotoxy,exit,mode,sy,sx,ya;

type
  saveareatype=array[0..115,0..7] of byte;

var
  nx,ny,xt,yt,xc,yc:integer; ch:char;
  savearea:saveareatype;
  br,bg,bb,wr,wg,wb,strc,count:byte;
  abortx,aborty:boolean;
  ycoord,xcoord:array[1..3] of char;

begin
  abortx:=false;
  aborty:=false;
  setmsgcolor(br,bg,bb,wr,wg,wb);
  for yc:=0 to 7 do
    for xc:=0 to 115 do
      savearea[xc,yc]:=getpixel(xc,yc);
  for yc:=0 to 7 do
    line(0,yc,115,yc,1);
  drawstr(1,1,1,100,'X = ',charset);
  drawstr(60,1,1,100,'Y = ',charset);
  xt:=30;
  yt:=1;
  count:=0;
  repeat
    repeat
      drawstr(xt,yt,1,random(255),'_',charset)
    until keypressed;
    ch:=readkey;
    if ch=#0
      then ch:=readkey
      else
        begin
	  if upcase(ch) in ['0'..'9'] then
	    begin
	      drawstr(xt,yt,1,1,'_',charset);
	      if (ch<>'.') and not (xt<30) then
		begin
		  drawstr(xt,yt,1,100,upcase(ch),charset);
		  count:=count+1
		end;
	      xcoord[count]:=upcase(ch);
	      xt:=xt+8
	    end
          else
	    if (ch=#8) and (count>0) and (xt>0) then
	      begin
		drawstr(xt,yt,1,1,'_',charset);
		xt:=xt-8;
		drawstr(xt,yt,1,1,xcoord[count],charset);
		xcoord[count]:=' ';
		count:=count-1
              end
        end
  until (ch=#27) or ((count<>0) and (count>2));
  if ch=#27
    then abortx:=true;
  xt:=90;
  yt:=1;
  count:=0;
  repeat
    repeat
      drawstr(xt,yt,1,random(255),'_',charset)
    until keypressed;
    ch:=readkey;
    if ch=#0
      then ch:=readkey
      else
	begin
	  if upcase(ch) in ['0'..'9'] then
	    begin
	      drawstr(xt,yt,1,1,'_',charset);
	      if (ch<>'.') and not (xt<90) then
		begin
		  drawstr(xt,yt,1,100,upcase(ch),charset);
		  count:=count+1
		end;
	      ycoord[count]:=upcase(ch);
	      xt:=xt+8
	    end
          else
	    if (ch=#8) and (count>0) and (xt>0) then
	      begin
		drawstr(xt,yt,1,1,'_',charset);
		xt:=xt-8;
		drawstr(xt,yt,1,1,ycoord[count],charset);
		ycoord[count]:=' ';
		count:=count-1
              end
        end
  until (ch=#27) or ((count<>0) and (count>2));
  if ch=#27
    then aborty:=true;
  for yc:=0 to 7 do
    for xc:=0 to 115 do
      putpixel(xc,yc,savearea[xc,yc]);
  if not abortx
    then nx:=(ord(xcoord[1])-$30)*100+(ord(xcoord[2])-$30)*10+
	    (ord(xcoord[3])-$30)
    else nx:=x;
  if not aborty
    then ny:=(ord(ycoord[1])-$30)*100+(ord(ycoord[2])-$30)*10+
	    (ord(ycoord[3])-$30)
    else ny:=y;
  if not abortx or not aborty
    then line(x,y,nx,ny,color);
  restoremsgcolor(br,bg,bb,wr,wg,wb)
end;

procedure enlarge(startx,starty,sizex,sizey:integer; charset:charsettype);

var
  bx,by,endx,endy,count,a,p,xx,yy,x,y,cx,cy:integer;
  infile:text; color:byte; filename:filetype;
  abort:boolean;

begin
  p:=0;
  getname(filename,charset,'Pic file ',abort);
  if not abort then
    begin
      assign(infile,filename);
      reset(infile);
      readln(infile,bx,by,endx,endy);
      count:=0;
      for y:=by to endy do
	for x:=bx to endx do
	  begin
	    if count<19
	      then read(infile,color)
	      else readln(infile,color);
	    if count<19
	      then count:=count+1
	      else count:=0;
	    a:=y*320+x;
	    xx:=a mod 320 * sizex;
	    yy:=a div 320 * sizey;
	    for cx:=0 to sizex do
	      for cy:=0 to sizey do
		putpixel(startx+xx+cx,starty+yy+cy,color);
	  end;
      close(infile)
    end
end;

procedure edit (x,y:integer; xrate,yrate,color:byte; var bkcolor:byte;
                charset:charsettype);

const
  letters:array [$30..$7a,0..4,0..4] of byte =
   (((0,1,1,1,0),(1,0,0,1,1),(1,0,1,0,1),(1,1,0,0,1),(0,1,1,1,0)),
    ((0,0,1,0,0),(0,1,1,0,0),(0,0,1,0,0),(0,0,1,0,0),(0,0,1,0,0)),
    ((1,1,1,1,0),(0,0,0,0,1),(0,1,1,1,0),(1,0,0,0,0),(1,1,1,1,1)),
    ((1,1,1,1,0),(0,0,0,0,1),(0,1,1,1,0),(0,0,0,0,1),(1,1,1,1,0)),
    ((0,0,1,1,0),(0,1,0,1,0),(1,1,1,1,1),(0,0,0,1,0),(0,0,0,1,0)),
    ((1,1,1,1,0),(1,0,0,0,0),(1,1,1,1,0),(0,0,0,0,1),(1,1,1,1,0)),
    ((0,1,1,1,0),(1,0,0,0,0),(1,1,1,1,0),(1,0,0,0,1),(0,1,1,1,0)),
    ((1,1,1,1,1),(0,0,0,0,1),(0,0,0,1,0),(0,0,1,0,0),(0,0,1,0,0)),
    ((0,1,1,1,0),(1,0,0,0,1),(0,1,1,1,0),(1,0,0,0,1),(0,1,1,1,0)),
    ((0,1,1,1,0),(1,0,0,0,1),(0,1,1,1,1),(0,0,0,0,1),(0,1,1,1,0)),
    ((0,0,1,1,0),(0,0,1,1,0),(0,0,0,0,0),(0,0,1,1,0),(0,0,1,1,0)),
    ((0,0,1,1,0),(0,0,1,1,0),(0,0,0,0,0),(0,0,1,1,0),(0,1,1,0,0)),
    ((0,0,0,1,1),(0,0,1,1,0),(0,1,1,0,0),(0,0,1,1,0),(0,0,0,1,1)),
    ((0,0,0,0,0),(1,1,1,1,1),(0,0,0,0,0),(1,1,1,1,1),(0,0,0,0,0)),
    ((0,1,1,0,0),(0,0,1,1,0),(0,0,0,1,1),(0,0,1,1,0),(0,1,1,0,0)),
    ((0,0,1,1,0),(0,1,0,0,1),(0,0,0,1,0),(0,0,0,0,0),(0,0,0,1,0)),
    ((0,1,1,1,0),(1,0,0,0,1),(1,0,1,1,1),(1,0,0,0,0),(0,1,1,1,1)),
    ((0,1,1,1,0),(1,0,0,0,1),(1,1,1,1,1),(1,0,0,0,1),(1,0,0,0,1)),
    ((1,1,1,1,0),(1,0,0,0,1),(1,1,1,1,0),(1,0,0,0,1),(1,1,1,1,0)),
    ((0,1,1,1,1),(1,0,0,0,0),(1,0,0,0,0),(1,0,0,0,0),(0,1,1,1,1)),
    ((1,1,1,1,0),(1,0,0,0,1),(1,0,0,0,1),(1,0,0,0,1),(1,1,1,1,0)),
    ((1,1,1,1,1),(1,0,0,0,0),(1,1,1,1,0),(1,0,0,0,0),(1,1,1,1,1)),
    ((1,1,1,1,1),(1,0,0,0,0),(1,1,1,1,0),(1,0,0,0,0),(1,0,0,0,0)),
    ((0,1,1,1,1),(1,0,0,0,0),(1,0,0,1,1),(1,0,0,0,1),(0,1,1,1,1)),
    ((1,0,0,0,1),(1,0,0,0,1),(1,1,1,1,1),(1,0,0,0,1),(1,0,0,0,1)),
    ((0,1,1,1,0),(0,0,1,0,0),(0,0,1,0,0),(0,0,1,0,0),(0,1,1,1,0)),
    ((0,0,0,0,1),(0,0,0,0,1),(0,0,0,0,1),(1,0,0,0,1),(0,1,1,1,0)),
    ((0,1,0,0,1),(0,1,0,1,0),(0,1,1,0,0),(0,1,0,1,0),(0,1,0,0,1)),
    ((0,1,0,0,0),(0,1,0,0,0),(0,1,0,0,0),(0,1,0,0,0),(0,1,1,1,1)),
    ((1,0,0,0,1),(1,1,0,1,1),(1,0,1,0,1),(1,0,0,0,1),(1,0,0,0,1)),
    ((1,0,0,0,1),(1,1,0,0,1),(1,0,1,0,1),(1,0,0,1,1),(1,0,0,0,1)),
    ((0,1,1,1,0),(1,0,0,0,1),(1,0,0,0,1),(1,0,0,0,1),(0,1,1,1,0)),
    ((1,1,1,1,0),(1,0,0,0,1),(1,1,1,1,0),(1,0,0,0,0),(1,0,0,0,0)),
    ((0,1,1,1,0),(1,0,0,0,1),(1,0,1,0,1),(1,0,0,1,0),(0,1,1,0,1)),
    ((1,1,1,1,0),(1,0,0,0,1),(1,1,1,1,0),(1,0,1,0,0),(1,0,0,1,1)),
    ((0,1,1,1,1),(1,0,0,0,0),(0,1,1,1,0),(0,0,0,0,1),(1,1,1,1,0)),
    ((1,1,1,1,1),(0,0,1,0,0),(0,0,1,0,0),(0,0,1,0,0),(0,0,1,0,0)),
    ((1,0,0,0,1),(1,0,0,0,1),(1,0,0,0,1),(1,0,0,0,1),(0,1,1,1,1)),
    ((1,0,0,0,1),(1,0,0,0,1),(1,0,0,0,1),(0,1,0,1,0),(0,0,1,0,0)),
    ((1,0,0,0,1),(1,0,0,0,1),(1,0,1,0,1),(1,1,0,1,1),(1,0,0,0,1)),
    ((1,0,0,0,1),(0,1,0,1,0),(0,0,1,0,0),(0,1,0,1,0),(1,0,0,0,1)),
    ((1,0,0,0,1),(1,0,0,0,1),(0,1,0,1,0),(0,0,1,0,0),(0,0,1,0,0)),
    ((1,1,1,1,1),(0,0,0,1,0),(0,0,1,0,0),(0,1,0,0,0),(1,1,1,1,1)),
    ((1,1,1,0,0),(1,0,0,0,0),(1,0,0,0,0),(1,0,0,0,0),(1,1,1,0,0)),
    ((1,1,0,0,0),(0,1,1,0,0),(0,0,1,1,0),(0,0,0,1,1),(0,0,0,0,1)),
    ((0,0,1,1,1),(0,0,0,0,1),(0,0,0,0,1),(0,0,0,0,1),(0,0,1,1,1)),
    ((0,0,1,0,0),(0,1,0,1,0),(1,0,0,0,1),(0,0,0,0,0),(0,0,0,0,0)),
    ((0,0,0,0,0),(0,0,0,0,0),(0,0,0,0,0),(0,0,0,0,0),(1,1,1,1,1)),
    ((0,1,1,0,0),(0,1,1,0,0),(0,0,1,1,0),(0,0,0,0,0),(0,0,0,0,0)),
    ((0,1,1,1,0),(1,0,0,0,1),(1,1,1,1,1),(1,0,0,0,1),(1,0,0,0,1)),
    ((1,1,1,1,0),(1,0,0,0,1),(1,1,1,1,0),(1,0,0,0,1),(1,1,1,1,0)),
    ((0,1,1,1,1),(1,0,0,0,0),(1,0,0,0,0),(1,0,0,0,0),(0,1,1,1,1)),
    ((1,1,1,1,0),(1,0,0,0,1),(1,0,0,0,1),(1,0,0,0,1),(1,1,1,1,0)),
    ((1,1,1,1,1),(1,0,0,0,0),(1,1,1,1,0),(1,0,0,0,0),(1,1,1,1,1)),
    ((1,1,1,1,1),(1,0,0,0,0),(1,1,1,1,0),(1,0,0,0,0),(1,0,0,0,0)),
    ((0,1,1,1,1),(1,0,0,0,0),(1,0,0,1,1),(1,0,0,0,1),(0,1,1,1,1)),
    ((1,0,0,0,1),(1,0,0,0,1),(1,1,1,1,1),(1,0,0,0,1),(1,0,0,0,1)),
    ((0,1,1,1,0),(0,0,1,0,0),(0,0,1,0,0),(0,0,1,0,0),(0,1,1,1,0)),
    ((0,0,0,0,1),(0,0,0,0,1),(0,0,0,0,1),(1,0,0,0,1),(0,1,1,1,0)),
    ((0,1,0,0,1),(0,1,0,1,0),(0,1,1,0,0),(0,1,0,1,0),(0,1,0,0,1)),
    ((0,1,0,0,0),(0,1,0,0,0),(0,1,0,0,0),(0,1,0,0,0),(0,1,1,1,1)),
    ((1,0,0,0,1),(1,1,0,1,1),(1,0,1,0,1),(1,0,0,0,1),(1,0,0,0,1)),
    ((1,0,0,0,1),(1,1,0,0,1),(1,0,1,0,1),(1,0,0,1,1),(1,0,0,0,1)),
    ((0,1,1,1,0),(1,0,0,0,1),(1,0,0,0,1),(1,0,0,0,1),(0,1,1,1,0)),
    ((1,1,1,1,0),(1,0,0,0,1),(1,1,1,1,0),(1,0,0,0,0),(1,0,0,0,0)),
    ((0,1,1,1,0),(1,0,0,0,1),(1,0,1,0,1),(1,0,0,1,0),(0,1,1,0,1)),
    ((1,1,1,1,0),(1,0,0,0,1),(1,1,1,1,0),(1,0,1,0,0),(1,0,0,1,1)),
    ((0,1,1,1,1),(1,0,0,0,0),(0,1,1,1,0),(0,0,0,0,1),(1,1,1,1,0)),
    ((1,1,1,1,1),(0,0,1,0,0),(0,0,1,0,0),(0,0,1,0,0),(0,0,1,0,0)),
    ((1,0,0,0,1),(1,0,0,0,1),(1,0,0,0,1),(1,0,0,0,1),(0,1,1,1,1)),
    ((1,0,0,0,1),(1,0,0,0,1),(1,0,0,0,1),(0,1,0,1,0),(0,0,1,0,0)),
    ((1,0,0,0,1),(1,0,0,0,1),(1,0,1,0,1),(1,1,0,1,1),(1,0,0,0,1)),
    ((1,0,0,0,1),(0,1,0,1,0),(0,0,1,0,0),(0,1,0,1,0),(1,0,0,0,1)),
    ((1,0,0,0,1),(1,0,0,0,1),(0,1,0,1,0),(0,0,1,0,0),(0,0,1,0,0)),
    ((1,1,1,1,1),(0,0,0,1,0),(0,0,1,0,0),(0,1,0,0,0),(1,1,1,1,1)));

var
  ch:char;
  red,blue,green,xc,yc:byte;
  savearea:array[0..4,0..4] of byte;
  colors:array[0..4] of byte;

begin
  colors[0]:=26;
  colors[1]:=25;
  colors[2]:=24;
  colors[3]:=23;
  colors[4]:=22;
  repeat
    repeat
      for yc:=0 to 4 do
	for xc:=0 to 4 do
	  savearea[yc,xc]:=mem[vgaseg:320*(y+yc)+(x+xc)];
      for yc:=0 to 4 do
	for xc:=0 to 4 do
	  if (letters[ord('_'),yc,xc]<>0)
	    then mem[vgaseg:320*(y+yc)+(x+xc)]:=100;
      for yc:=0 to 4 do
	for xc:=0 to 4 do
	  mem[vgaseg:320*(y+yc)+(x+xc)]:=savearea[yc,xc];
    until keypressed;
    ch:=readkey;
    if ch=#0 then
      begin
	ch:=readkey;
	case ch of
	  alts:movexy(x,y,charset);
	  alta,pgup,endkey,pgdn,home,left,right,up,down:movement(x,y,ch,charset);
	  f1:colorchange(color,charset);
	  f2:begin
	       colors[0]:=changecolorto(26,charset,'Color #1 = ');
	       colors[1]:=changecolorto(25,charset,'Color #2 = ');
	       colors[2]:=changecolorto(24,charset,'Color #3 = ');
	       colors[3]:=changecolorto(23,charset,'Color #4 = ');
	       colors[4]:=changecolorto(22,charset,'Color #5 = ')
	     end;
	  f3:changepal(color,charset);
	  f4:restoreimage(charset,true);
	  f5:restorenewpalette(charset,true);
	  f6:restorepic(charset,true);
	  f7:restorepalette;
	  f8:clearscreen(charset,bkcolor);
	  f9:color:=changecolorto(0,charset,'New color = ');
	  f10:begin
		port[$3c7]:=color;
		red:=port[$3c9];
		green:=port[$3c9];
		blue:=port[$3c9];
		changepalcolor(color,red,green,blue,charset);
		setcolor(color,red,green,blue)
	      end
	end
      end
    else
      if ord(ch) in [$0d,$08,$20,$30..$7a] then
	begin
	  if ord(ch) in [$30..$7a]
	    then
	      for yc:=0 to 4 do
		for xc:=0 to 4 do
		  if (letters[ord(ch),yc,xc]<>0) and (y<198)
		    then mem[vgaseg:320*(y+yc)+(x+xc)]:=colors[yc];
	  if (ch=#8) and ((y>0) or (x>0)) then
	    begin
	      if x>0
		then x:=x-6
		else
		  begin
		    x:=312;
		    y:=y-6
		  end;
	      for yc:=0 to 4 do
		for xc:=0 to 4 do
		  if mem[vgaseg:320*(y+yc)+(x+xc)]<>0
		    then mem[vgaseg:320*(y+yc)+(x+xc)]:=bkcolor
	    end;
	  if ((x+6<318) and (y<198)) and not (ch in [#13,#8,#20])
	    then x:=x+6
	    else
	      if (ch<>#8) and (y<198) then
		begin
		  x:=0;
		  y:=y+6
		end
	end
  until ch=altx;
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

procedure moverate (var xrate,yrate:byte);

const
  alty=#21;
  altx=#45;

var
  regs:registers;
  tkey:char;

begin
  repeat
    repeat until readkey2=1;
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
  drawmode:boolean;
  ch:char;
  bkcolor,blue,green,red,oc,nc,xrate,yrate,color:byte;
  x,y:integer;
  status,al,ah:byte;
  charset:charsettype;
  regs:registers;

begin
  restorepalette;
  setmode($13);
  drawmode:=false;
  xrate:=1;
  yrate:=1;
  getchars(charset);
  y:=0;
  x:=0;
  color:=0;
  bkcolor:=0;
  xrate:=5;
  yrate:=5;
  restoreimage(charset,false);
  repeat
    getkey(x,y,color,status,drawmode,ch);
    if status in [0,8] then
      begin
	case ch of
	  f1:colorchange(color,charset);
	  f2:drawmode:=not(drawmode);
 	  f3:changepal(color,charset);
          f4:saveimage(0,0,319,199,charset);
	  f5:restorepic(charset,true);
	  f6:restorepalette;
	  f7:color:=changecolorto(color,charset,'New color = ');
	  f8:writech(x,y,xrate,yrate,drawmode,charset,color);
	  f9:clearscreen(charset,bkcolor);
	  f10:lineto(x,y,color,charset);
	  alte:enlarge(0,0,2,2,charset);
	  alto:showcolor(x,y,charset,color,false);
	  altr:edit(x,y,xrate,yrate,color,bkcolor,charset);
	  alts:movexy(x,y,charset);
	  altp:begin
		 port[$3c7]:=color;
		 red:=port[$3c9];
		 green:=port[$3c9];
		 blue:=port[$3c9];
		 changepalcolor(color,red,green,blue,charset);
		 setcolor(color,red,green,blue)
	       end;
	  altf:begin
		 oc:=floodfillmsg(charset,'Old color = ',color);
		 nc:=floodfillmsg(charset,'New color = ',color);
		 floodfill(x,y,oc,nc)
	       end;
	  altl:line(0,y,320,y,color);
          altk:line(x,0,x,200,color);
	  alti:showxy(x,y,charset);
	  altz:markandsave(color,charset);
	  altc:restorenewpalette(charset,true);
          alty:moverate(xrate,yrate);
	  alta,pgup,endkey,pgdn,home,left,right,up,down:movement(x,y,ch,charset)
	end
      end
    else
      case status of
        1,2 : shiftkeys(x,y,xrate,yrate,ch)
      end;
    checkcorrectxy(x,y)
  until ch=altx;
  setmode(3)
end;

begin
  driver
end.
