program quarterdeckregister;

uses crt,dos,win;

const
  up=72;
  down=80;
  left=75;
  right=77;

type
  infotype=array [1..120] of char;
  stringtype=array [1..30] of char;

var
  newinfo:infotype;
  count:integer;
  exit,found:boolean;
  infile,outfile:string;
  oldcb:pointer;
  display:word;
  orgx,orgy,border,bordercolor,titlecolor:byte;
  buffers:buffertype;

procedure opening;

var
  key:char;

begin
  repeat
    setmenu(12,6,70,20,bordercolor,titlecolor,1,'Quarterdeck Activate - V1.0',true,true);
    setcursoroffon(true);
    setmenu(1,25,80,25,bordercolor,titlecolor,1,'',false,false);
    gotoxy(1,25);
    write(' Strike a key...',' ':3);
    write('Use ',chr(27),' ',chr(26),' Title color = ',titlecolor,' ':8);
    write('Use ',chr(24),' ',chr(25),' Border color = ',bordercolor);
    gotoxy(13,8);
    write(' ':5,'Programming by ');
    textcolor(lightgreen);
    write('Code Breaker');
    textcolor(white);
    write('.');
    gotoxy(13,10);
    write(' ':5,'Greetings to : ');
    gotoxy(13,11);
    textcolor(lightblue);
    write(' ':10,'The Rocketeer ');
    gotoxy(13,12);
    textcolor(lightred);
    write(' ':10,'The Silicon Soldier');
    gotoxy(13,13);
    textcolor(yellow);
    write(' ':10,'Flip Boy');
    gotoxy(13,15);
    textcolor(lightcyan);
    write(' ':5,'This program let you activate the installation ');
    gotoxy(13,16);
    write(' ':5,'program such as ''INSTALL.EXE'' so you could use');
    gotoxy(13,17);
    write(' ':5,'Qemm (Quarterdeck extended memory), Desqview or');
    gotoxy(13,18);
    write(' ':5,'any softwares from Quarterdeck.');
    key:=readkey;
    if key=#0
      then key:=readkey;
    case ord(key) of
      up : if bordercolor<255
             then inc(bordercolor)
             else bordercolor:=0;
      down : if bordercolor>0
               then dec(bordercolor)
               else bordercolor:=255;
      right : if titlecolor<128
                then inc(titlecolor)
                else titlecolor:=0;
      left : if titlecolor>0
               then dec(titlecolor)
               else titlecolor:=127
    end
  until not (ord(key) in [left,right,up,down])
  
end;

procedure userexit(character:char);

begin
  setcursoroffon(true);
  if character=#27 then
    begin
      window(1,1,80,25);
      movescreento(1,1,80,25,display,toscreen,buffers[2]);
      delay(200);
      movescreento(1,1,80,25,display,toscreen,buffers[1]);
      gotoxy(orgx,orgy-1);
      textcolor(lightgray);
      textbackground(black);
      setcursoroffon(false);
      halt
    end
end;

procedure getyesno (whichone:integer);

var
  x,y:integer;
  ch:char;

begin
  x:=wherex;
  y:=wherey;
  textbackground(black);
  if whichone=1
    then write('Y')
    else write('N');
  gotoxy(x,y);
  x:=wherex;
  y:=wherey;
  repeat
    ch:=readkey;
    if ch in ['Y','y','N','n',#13,#27] then
      begin
	write(ch);
	if (whichone=1) then
	  begin
	    if ch in ['Y','y',#13,#27]
	      then exit:=false
	      else exit:=true
	  end
      end
    else
      begin
        sound(100);
        delay(100);
        nosound;
        gotoxy(x,y)
      end
  until ch in ['Y','y','N','n',#13,#27];
  userexit(ch);
  textattr:=bordercolor;
  textcolor(white)
end;

procedure registeranother;

begin
  textcolor(white);
  setcursoroffon(false);
  writeln;
  write(' ':5,'Activate another file [Y/n] ==> ');
  getyesno(1)
end;

procedure writeHexWord(var where:text; w:word);

const
  hexChars : array [0..$F] of Char ='0123456789ABCDEF';

begin
  write(where,hexchars[lo(w) shr 4],hexchars[lo(w) and $F])
end;

procedure searchwrite;

var
  f,outf:file; ch:char;
  ct,x,y,numblocks,c,numwritten,numread,count:integer;
  pos:longint;
  numchar:integer;
  buf:array [1..120] of char;
  found:boolean;

begin
  clrscr;
  textcolor(red+blink);
  writeln;
  writeln(' ':5,'Please wait...Activating...');
  writeln;
  textcolor(lightgray);
  assign(f,infile);
  rename(f,outfile);
  reset(f,1);
  assign(outf,infile);
  rewrite(outf,1);
  numread:=0;
  numwritten:=0;
  found:=false;
  setcursoroffon(true);
  textcolor(lightgreen);
  numblocks:=filesize(f) div 120;
  writeln(' ':5,'Number of blocks to search = ',numblocks);
  write(' ':5,'Number of blocks searched = ');
  x:=wherex;
  y:=wherey;
  gotoxy(x,y);
  c:=1;
  repeat
    blockread(f,buf,sizeof(buf),numread);
    gotoxy(x,y);
    clreol;
    textcolor(lightgreen);
    write(c);
    inc(c);
    textcolor(lightcyan);
    writeln;
    writeln;
    write(' ':5);
    for count:=1 to 120 do
      begin
	writehexword(output,ord(buf[count]));
	if count mod 20 = 0 then
	  begin
	    writeln;
	    write(' ':5)
	  end
	else write(' ');
	if buf[count]=chr($ff) then
	if buf[count+1]=chr($ff) then
	if buf[count+2]=chr(0) then
	if buf[count+3]=chr($ff) then
	  begin
	    pos:=filepos(f);
	    pos:=pos-120+count+1;
	    blockwrite(outf,buf,numread,numwritten);
	    seek(f,pos); seek(outf,pos);
	    blockread(f,buf,sizeof(buf),numread);
	    newinfo[1]:=chr(1);
	    for ct:=2 to 120 do
	      newinfo[ct]:=buf[ct];
	    blockwrite(outf,newinfo,numread,numwritten);
	    found:=true;
	    repeat
	      blockread(f,buf,sizeof(buf),numread);
              gotoxy(x,y);
	      clreol;
	      textcolor(lightgreen);
	      write(c);
	      inc(c);
	      textcolor(lightcyan);
	      writeln;
	      writeln;
	      write(' ':5);
	      for ct:=1 to 120 do
                begin
		  writehexword(output,ord(buf[ct]));
		  if ct mod 20 = 0 then
		    begin
		      writeln;
		      write(' ':5)
		    end
		  else write(' ')
	      end;
	      blockwrite(outf,buf,numread,numwritten)
	    until (numread=0) or (numwritten <> numread)
	  end
      end;
    if not found
      then blockwrite(outf,buf,numread,numwritten);
  until (numread=0) or (numwritten <> numread);
  gotoxy(x,y);
  textcolor(lightgreen);
  writeln(numblocks);
  textcolor(lightcyan);
  writeln;
  delline; delline; delline;
  delline; delline; delline;
  if found
    then writeln(' ':5,'Activation process was successful.')
    else writeln(' ':5,'Activation bytes were not found.');
  close(f);
  close(outf);
  erase(f)
end;

procedure register;

var
  c:integer; outf:file;

begin
  setmenu(38,11,43,13,bordercolor,titlecolor,1,'',true,false);
  setmenu(32,9,49,15,bordercolor,titlecolor,1,'',true,false);
  setmenu(26,7,55,17,bordercolor,titlecolor,1,'',true,false);
  setmenu(20,5,61,19,bordercolor,titlecolor,1,'',true,false);
  setmenu(14,3,67,21,bordercolor,titlecolor,1,'',true,false);
  setmenu(1,1,80,25,bordercolor,titlecolor,1,'Get filename and register',true,true);
  window(2,2,79,24);
  repeat
    clrscr;
    writeln;
    write(' ':5,'Please enter file to be registered ==> ');
    setcursoroffon(false);
    readln(infile);
    setcursoroffon(true);
    writeln;
    if fsearch(infile,getenv('path'))<>'' then
      begin
	count:=0;
	found:=false;
	while (count<=length(infile)) and not found do
	  begin
	    inc(count);
	    if infile[count]='.'
	      then found:=true
	  end;
	outfile:=infile;
	if found
	  then c:=count
	  else c:=length(infile);
	outfile[c+1]:='b';
	outfile[c+2]:='a';
	outfile[c+3]:='k';
	if fsearch(outfile,getenv('path'))<>'' then
	  begin
	    assign(outf,outfile);
	    erase(outf)
	  end;
	writeln;
	searchwrite
      end
    else
      begin
        sound(100);
        delay(100);
        nosound;
        writeln(' ':5,'File not found. Abort activation process.')
      end;
    registeranother
  until exit
end;

procedure newcb; interrupt;

begin
end;

procedure driver;

begin
  orgx:=wherex;
  orgy:=wherey;
  border:=1;
  bordercolor:=59;
  titlecolor:=15;
  display:=detectmode;
  movescreento(1,1,80,25,display,tomemory,buffers[1]);
  getintvec($1b,oldcb);
  setintvec($1b,@newcb);
  opening;
  movescreento(1,1,80,25,display,tomemory,buffers[2]);
  register;
  setintvec($1b,oldcb);
  userexit(#27)
end;

begin
  driver
end.


  
