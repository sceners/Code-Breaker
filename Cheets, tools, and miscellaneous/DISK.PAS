program diskorganizer;

{$s-}

uses crt,dos;

const
  numoptions=8;
  bchars:array[1..5,1..7] of char =
    (('Õ','¸','À','Ù','Í','³','Ä'),('Ú','¿','À','Ù','Ä','³','Ä'),
     ('Õ','¸','Ô','¾','Í','³','Í'),('Ö','·','Ó','½','Ä','º','Ä'),
     ('É','»','È','¼','Í','º','Í'));
  menu:array [1..numoptions] of string [47] =
   ( '[O]pen     -   Open and store a data file ',
     '[H]ilite   -   Change background and hilite ',
     '[C]lose    -   Close and save list to file ',
     '[A]dd      -   Add, remove or edit an item ',
     '[S]earch   -   Search for an item ',
     '[L]ist     -   List particular items ',
     '[P]rint    -   Print to file or printer ',
     '[Q]uit     -   Exit program ');

type
  balancefactor=(lh,rh,eh);
  buftype=array [1..4000] of byte;
  bufstype=array [1..5] of buftype;
  stringtype=packed array [1..45] of char;
  treetype = ^nodetype;
  nodetype = record
	       name:stringtype;
	       bf:balancefactor;
	       right,left,more:treetype
             end;

procedure cursoroffon (off : boolean);

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

function mode : word;

label color,exit;

var
  modenum:word;

begin
  asm
    mov ah,0fh
    int 10h
    cmp al,7
    jne color
    mov word ptr [modenum],0b000h
    jmp exit
color:
    mov word ptr [modenum],0b800h
exit:
  end;
  mode:=modenum
end;

procedure movescrto (x,y,x2,y2:byte; display:word; where:boolean; var buff);

const
  toscr=true;
  tomem=false;

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
          if where=toscr
            then mem[display:upper+second]:=buffer[start]
            else buffer[start]:=mem[display:upper+second];
          inc(start)
        end;
      upper:=upper+160       { advance to next line }
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

procedure frame (x,y,x2,y2,borderc,titlec,border:byte; st:string;
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
      putchar(bchars[border][1],x,y,borderc);
      putchar(bchars[border][2],x2,y,borderc)
    end;
  if y2>y then
    begin
      putchar(bchars[border][3],x,y2,borderc);
      putchar(bchars[border][4],x2,y2,borderc)
    end;
  if x2-x>1 then
    for xc := x + 1 to x2 - 1 do
      begin
        putchar(bchars[border][5],xc,y,borderc);
        putchar(bchars[border][7],xc,y2,borderc)
      end;
  if y2-y>1 then
    for yc := y + 1 to y2 - 1 do
      begin
        putchar(bchars[border][6],x,yc,borderc);
        putchar(bchars[border][6],x2,yc,borderc)
      end;
  textattr:=borderc;
  xlength:=(x2 - x - length(st)) shr 1 + x;
  gotoxy(xlength,y);
  if ((x2-x) > xlength) and ((x2-x) > length(st)+5) then
    if puttitle then
      begin
        case border of
          1,3,5 : write('µ ',' ':length(st),' Æ');
          2,4 : write('´ ',' ':length(st),' Ã')
        end;
        textcolor(titlec);
        gotoxy(xlength+2,y);
        write(st)
      end;
  textcolor(defaultcolor)
end;

procedure setmenu (topx,topy,bottomx,bottomy,borderc,titlec,
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
  scrollwin(topx-1,topy-1,bottomx-1,bottomy-1,borderc);
  cursoroffon(off);
  if framewin
    then frame(topx,topy,bottomx,bottomy,borderc,titlec,border,title,
               puttitle)
end;

procedure writexy (x,y,color,bkcolor:byte; st:string);

begin
  textattr:=bkcolor;
  textcolor(color);
  gotoxy(x,y);
  write(st)
end;

procedure displayinfo (var borderc,titlec,borders:byte);

const
  up=72;
  down=80;
  left=75;
  right=77;

var
  key:char;

begin
  repeat
    setmenu(14,5,67,19,borderc,titlec,borders,'Disks Organizer - V1.0',true,true);
    cursoroffon(true);
    setmenu(1,25,80,25,borderc,titlec,borders,'',false,false);
    writexy(1,25,white,borderc,'  Strike a key...  ');
    write('Use ',chr(27),' ',chr(26),' Title color = ',titlec,' ':8);
    write('Use ',chr(24),' ',chr(25),' Border color = ',borderc);
    writexy(15,7,white,borderc,'  Programming by ');
    writexy(wherex,wherey,lightgreen,borderc,'                   ');
    writexy(wherex,wherey,white,borderc,'.');
    writexy(15,9,white,borderc,'  Greetings to : ');
    writexy(wherex,wherey,lightred,borderc,'              ');
    writexy(15,10,lightmagenta,borderc,'                  ');
    writexy(15,11,yellow,borderc,'                  ');
    writexy(15,13,white,borderc,'  This program is for personal use in organizing');
    writexy(15,14,white,borderc,'  disks containing different softwares. Hopefully');
    writexy(15,15,white,borderc,'  this program will help you organize your disks.');
    writexy(15,16,white,borderc,'  You will be to enter, search, modify and print');
    writexy(15,17,white,borderc,'  you own data files. Should have wrote this a ');
    writexy(15,18,white,borderc,'  long time ago.');
    key:=readkey;
    if key=#0
      then key:=readkey;
    case ord(key) of
      up : if borderc < 255
             then inc(borderc)
             else borderc:=0;
      down : if borderc > 0
               then dec(borderc)
               else borderc:=255;
      right : if titlec < 128
                then inc(titlec)
                else titlec:=0;
      left : if titlec > 0
               then dec(titlec)
               else titlec:=127
    end
  until not (ord(key) in [left,right,up,down])
end;

procedure initdata (var display:word; var buffer:buftype; var orgx,orgy,
                    borders,borderc,titlec:byte);

const
  toscr=true;
  tomem=false;

begin
  orgx:=wherex;
  orgy:=wherey;
  display:=mode;
  borders:=1;
  borderc:=59;
  titlec:=15;
  movescrto(1,1,80,25,display,tomem,buffer)
end;

procedure userexit (buffer:buftype; orgx,orgy:byte; display:word);

const
  toscr=true;
  tomem=false;

begin
  movescrto(1,1,80,25,display,toscr,buffer);
  cursoroffon(false);
  gotoxy(orgx,orgy-1)
end;

procedure dobk (length,newc,oldc:byte);

var
  x,y,count:integer;

begin
  x:=wherex;
  y:=wherey;
  textbackground(newc);
  for count:=1 to length do
    write(' ');
  gotoxy(x,y);
  textbackground(oldc)
end;

procedure writeoptions (x,y,borderc,hilite,choice,display:byte);

var
  bkcolor,numlines:byte;

begin
  for numlines:=1 to numoptions do
    begin
      if choice=numlines
        then bkcolor:=hilite
        else bkcolor:=borderc;
      writexy(x,y,white,bkcolor,menu[numlines]);
      inc(y)
    end
end;

procedure displaymenu (display:word; borderc,titlec,borders,hilite:byte);

begin
  setmenu(1,1,80,25,25,titlec,borders,'',false,false);
  setmenu(12,5,70,18,borderc,titlec,borders,'Disks Organizer - V1.0',true,true);
  cursoroffon(true);
  setmenu(1,25,80,25,borderc,titlec,borders,'',false,false);
  writexy(1,25,white,borderc,'        Use '+chr(24)+' '+chr(25)+' '+chr(27));
  writexy(wherex,wherey,white,borderc,' '+chr(26)+' or press the corresponding ');
  writexy(wherex,wherey,white,borderc,'letter to select an option.');
  writeoptions(20,8,borderc,hilite,1,display)
end;

procedure displaymenu2 (display:word; borderc,titlec,borders,hilite,
                        choice:byte; hilitef:boolean);

begin
  if not hilitef then
    begin
      setmenu(12,5,70,18,borderc,titlec,borders,'Disks Organizer - V1.0',true,true);
      setmenu(2,23,79,23,borderc,titlec,borders,'',false,false);
      writexy(2,23,white,borderc,'       Use '+chr(26)+' '+chr(27)+' = ');
      writexy(wherex,wherey,white,borderc,'change hilite bar color.  Use ');
      writexy(wherex,wherey,white,borderc,chr(24)+' '+chr(25)+' = change border color');
      setmenu(2,24,79,24,borderc,titlec,borders,'',false,false);
      writexy(2,24,white,borderc,'       Press ENTER or ESC when done.')
    end;
  writeoptions(20,8,borderc,hilite,choice,display)
end;

procedure gethilite (var borderc,titlec,hilite:byte; borders,choice:byte;
                     display:word);

const
  toscr=true;
  tomem=false;
  up=72;
  down=80;
  left=75;
  right=77;

var
  key:char;
  hilitef,valid:boolean;

begin
  frame(1,1,80,25,25,titlec,borders,'Hilite bar change',true);
  displaymenu2(display,borderc,titlec,borders,hilite,choice,false);
  cursoroffon(true);
  valid:=true;
  repeat
    valid:=false;
    key:=readkey;
    if key=#0
      then key:=readkey;
    hilitef:=true;
    case ord(key) of
      up : begin
             if borderc < 255
               then inc(borderc)
               else borderc:=0;
               hilitef:=false;
               valid:=true
           end;
      down : begin
               if borderc > 0
                 then dec(borderc)
                 else borderc:=255;
               hilitef:=false;
               valid:=true
             end;
      right : begin
                if hilite < 128
                  then hilite:=hilite+16
                  else hilite:=0;
                valid:=true
              end;
      left : begin
               if hilite > 0
                 then hilite:=hilite-16
                 else hilite:=127;
               valid:=true
             end
    end;
    if valid
      then displaymenu2(display,borderc,titlec,borders,hilite,choice,hilitef)
  until key in [#13,#27];
  displaymenu(display,borderc,titlec,borders,hilite)
end;

procedure regularkey (var key:char; var choice:byte; var exit:boolean);

const
  esc=27;

begin
  case ord(key) of
    79,111 : choice:=1;
    72,104 : choice:=2;
     67,99 : choice:=3;
     65,97 : choice:=4;
    83,115 : choice:=5;
    76,108 : choice:=6;
    80,112 : choice:=7;
    81,113 : choice:=8;
    esc:exit:=true
  end;
  key:=chr($0d)
end;

procedure extendkey (key:char; var choice:byte; borderc,hilite:byte;
                     display:word);

const
  up=72;
  down=80;
  left=75;
  right=77;

begin
  key:=readkey;
  case ord(key) of
    right,down : begin
                   inc(choice);
                   if choice > 8
                   then choice:=1
                 end;
    left,up : begin
                dec(choice);
                if choice < 1
                  then choice:=8
              end
  end;
  writeoptions(20,8,borderc,hilite,choice,display)
end;

procedure getuserchoice (display:word; var choice:byte; var exit:boolean;
                         borderc,hilite:byte);

var
  key:char;

begin
  writeoptions(20,8,borderc,hilite,choice,display);
  exit:=false;
  repeat
    key:=readkey;
    if key=#0
      then extendkey(key,choice,borderc,hilite,display)
      else regularkey(key,choice,exit)
  until exit or (ord(key)=$0d)
end;

procedure douserchoice (display:word; var borderc:byte; choice,titlec,
                        borders:byte; var exit:boolean; var hilite:byte);

begin
  case choice of
    2 : gethilite(borderc,titlec,hilite,borders,choice,display);
    8 : exit:=true
  end
end;

procedure userroutine (display:word; borderc,titlec,borders:byte);

const
  toscr=true;
  tomem=false;

var
  buffer:buftype;
  exit:boolean;
  hilite,choice:byte;

begin
  exit:=false;
  hilite:=black;
  movescrto(1,1,80,25,display,tomem,buffer);
  displaymenu(display,borderc,titlec,borders,hilite);
  choice:=1;
  repeat
    getuserchoice(display,choice,exit,borderc,hilite);
    if not exit then
      douserchoice(display,borderc,choice,titlec,borders,exit,hilite)
  until exit;
  movescrto(1,1,80,25,display,toscr,buffer)
end;

procedure driver;

var
  orgx,orgy:byte;
  borders,borderc,titlec:byte;
  display:word;
  buffers:bufstype;

begin
  initdata(display,buffers[1],orgx,orgy,borders,borderc,titlec);
  displayinfo(borderc,titlec,borders);
  userroutine(display,borderc,titlec,borders);
  userexit(buffers[1],orgx,orgy,display)
end;

begin
  driver
end.
