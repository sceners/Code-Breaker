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
  orgx,orgy,count:integer;
  exit,found:boolean;
  infile,outfile:string;
  oldcb:pointer;
  buffers:buffertype;
  oldinfo,newinfo:infotype;
  oldserial,newserial,oldname,newname,oldcompany:stringtype;
  newcompany,oldcity,newcity:stringtype;
  x,y,x1,y1:integer;
  border,bordercolor,titlecolor,oldsum,newsum:byte;
  display:word;
  dummy,ch:char;

procedure opening;

var
  key:char;

begin
  repeat
    setmenu(12,6,70,19,bordercolor,titlecolor,border,'Quarterdeck Register - V1.0',true,true);
    setcursoroffon(true);
    setmenu(1,25,80,25,bordercolor,titlecolor,border,'',false,false);
    gotoxy(1,25);
    write(' Strike a key...',' ':3);
    write('Use ',chr(27),' ',chr(26),' Title color = ',titlecolor,' ':8);
    write('Use ',chr(24),' ',chr(25),' Border color = ',bordercolor);
    gotoxy(13,8);
    write(' ':5,'Programming by ');
    textcolor(lightgreen);
    write('Code Breaker & The Rocketeer');
    textcolor(white);
    write('.');
    gotoxy(13,9);
    write(' ':5,'Suggestions and great help from ');
    textcolor(lightmagenta);
    write('The Rocketeer');
    textcolor(white);
    write('.');
    gotoxy(13,10);
    write(' ':5,'Greetings to:');
    textcolor(lightred);
    write(' The Silicon Soldier');
    textcolor(white);
    write(' and ');
    textcolor(yellow);
    write('Flip Boy');
    textcolor(white);
    write('.');
    gotoxy(13,12);
    write(' ':5,'This program change the registeration informations ');
    gotoxy(13,13);
    write(' ':5,'of mostly any software from Quarterdeck such as ');
    gotoxy(13,14);
    write(' ':5,'Qemm (Quarterdeck extended memory) or Desqview ');
    gotoxy(13,15);
    write(' ':5,'(not yours) under your very own serial number,');
    gotoxy(13,16);
    write(' ':5,'name, company, and city-state. ');
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

procedure dobk (length:integer);

var
  x,y,count:integer;

begin
  x:=wherex;
  y:=wherey;
  textbackground(black);
  for count:=1 to length do
    write(' ');
  gotoxy(x,y);
  textbackground(lightcyan)
end;

procedure readinfo(var stringinfo:stringtype; maxlength:integer);

var
  ch:char;

begin
  dobk(maxlength);
  count:=0;
  textbackground(black);
  setcursoroffon(false);
  repeat
    repeat
      ch:=readkey;
      if ch=#0
        then
          begin
            sound(100);
            delay(100);
            nosound;
            ch:=readkey;
            ch:=#31
          end
    until(ch in [#32..#255,#13,#8,#27]);
    if(ch = #8) and(count > 0) then
      begin
        count:=count-1;
        if count = maxlength
	  then setcursoroffon(true)
	  else setcursoroffon(false);
        if maxlength=18
	  then stringinfo[count+1]:=chr($cf)
	  else stringinfo[count+1]:=chr($df);
	write(ch,' ',ch)
      end
    else
      if (ch<>#8) and (count < maxlength) and not (ch in [#13,#27]) then
        begin
          count:=count+1;
          if count = maxlength
	    then setcursoroffon(true)
	    else setcursoroffon(false);
	  stringinfo[count]:=chr(223-(ord(ch)-ord(' ')));
          write(ch)
        end
      else
        if not(ch in [#13,#27]) or((ch=#8) and(count=0)) then
          begin
            sound(100);
            delay(100);
            nosound
          end
  until(ch in [#13,#27]) and(count<maxlength+1);
  userexit(ch);
  if (maxlength=18) and (count<maxlength)
    then
      for count:=count to maxlength-1 do
        write('0');
  textattr:=bordercolor;
  textcolor(white)
end;

procedure initinfo;

var
  count:integer;

begin
  for count:=1 to 119 do
    begin
      newinfo[count]:=chr(0);
      oldinfo[count]:=chr(0)
    end
end;

procedure inittypes;

var
  count:integer;

begin
  for count:=1 to 18 do
    begin
      oldserial[count]:=chr($cf);
      newserial[count]:=chr($cf)
    end;
  for count:=1 to 30 do
    begin
      oldname[count]:=chr($df);
      newname[count]:=chr($df);
      oldcompany[count]:=chr($df);
      newcompany[count]:=chr($df)
    end;
  for count:=1 to 18 do
    begin
      oldcity[count]:=chr($df);
      newcity[count]:=chr($df)
    end
end;

procedure writemsg(msg,msg1:string);

begin
  write(' ':5,'Please enter ');
  textcolor(yellow);
  write(msg);
  textcolor(white);
  write(msg1);
  write(' ==> ')
end;

procedure displayinfo;

begin
  textcolor(lightcyan);
  writeln;
  write(' ':5,'This part will ask for old (registered) information to be');
  writeln(' search for');
  write(' ':5,'plus the new information that you wanted. ESC - Quit');
  writeln(' program');
  writeln;
  textcolor(lightgreen);
  writeln
end;

procedure getoldnewinfo;

begin
  setmenu(38,11,43,13,bordercolor,titlecolor,1,'',true,false);
  setmenu(32,9,49,15,bordercolor,titlecolor,1,'',true,false);
  setmenu(26,7,55,17,bordercolor,titlecolor,1,'',true,false);
  setmenu(20,5,61,19,bordercolor,titlecolor,1,'',true,false);
  setmenu(14,3,67,21,bordercolor,titlecolor,1,'',true,false);
  setmenu(1,1,80,25,bordercolor,titlecolor,border,'Get information & register',true,true);
  window(2,2,79,24);
  displayinfo;
  writeln(' ':5,'Enter the old (registered) information.');
  textcolor(white);
  writeln;
  writeln;
  writemsg('the first 3 numbers of the old',' serial number');
  readinfo(oldserial,3);
  clrscr;
  displayinfo;
  textcolor(lightmagenta);
  writeln(' ':5,'Now enter your own information.');
  textcolor(white);
  writeln;
  writeln;
  writemsg('new',' serial number');
  readinfo(newserial,18);
  writeln;
  writeln;
  writemsg('new',' name');
  readinfo(newname,30);
  writeln;
  writeln;
  writemsg('new',' company name');
  readinfo(newcompany,30);
  writeln;
  writeln;
  writemsg('new',' city name');
  readinfo(newcity,18);
  textcolor(white);
  writeln;
  writeln
end;

procedure merge;

var
  x,count:integer;

begin
  dummy:=newserial[1];
  oldsum:=0;
  newsum:=0;
  for count:=1 to 18 do
    begin
      oldinfo[count]:=oldserial[count];
      newinfo[count]:=newserial[count]
    end;
  x:=1;
  for count:=21 to 50 do
    begin
      oldinfo[count]:=oldname[x];
      newinfo[count]:=newname[x];
      inc(x)
    end;
  x:=1;
  for count:=53 to 82 do
    begin
      oldinfo[count]:=oldcompany[x];
      newinfo[count]:=newcompany[x];
      inc(x)
    end;
  x:=1;
  for count:=85 to 102 do
    begin
      oldinfo[count]:=oldcity[x];
      newinfo[count]:=newcity[x];
      inc(x)
    end;
  oldinfo[115]:=chr($ae);
  oldinfo[116]:=chr($b0);
  oldinfo[117]:=chr($ac);
  oldinfo[118]:=chr($a7);
  newinfo[115]:=chr($ae);
  newinfo[116]:=chr($b0);
  newinfo[117]:=chr($ac);
  newinfo[118]:=chr($a7);
  for x:=1 to 118 do
    begin
      newsum:=newsum+ord(newinfo[x]);
      oldsum:=oldsum+ord(oldinfo[x])
    end;
  newinfo[119]:=chr(newsum);
  oldinfo[119]:=chr(oldsum)
end;

procedure initall;

begin
  found:=false;
  inittypes;
  initinfo;
  getoldnewinfo;
  merge
end;

procedure getyesno(whichone:integer);

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
	else
	  if ch in ['Y','y'] then
	    begin
	      window(1,1,80,25);
	      initall
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

procedure changeinfo;

begin
  textcolor(white);
  setcursoroffon(false);
  writeln;
  writeln;
  write(' ':5,'Change current information [y/N] ==> ');
  getyesno(2)
end;

procedure registeranother;

begin
  textcolor(white);
  setcursoroffon(false);
  writeln;
  write(' ':5,'Register another file [Y/n] ==> ');
  getyesno(1)
end;

procedure writehexword (var where:text; w:word);

const
  hexchars : array [0..$f] of char ='0123456789ABCDEF';

begin
  write(where,hexchars[lo(w) shr 4],hexchars[lo(w) and $F])
end;

procedure searchwrite;

var
  f,outf:file; ch:char;
  x,y,numblocks,c,numwritten,numread,count:integer;
  pos:longint;
  numchar:integer;
  buf:array [1..120] of char;
  found:boolean;

begin
  clrscr;
  textcolor(red+blink);
  writeln;
  writeln(' ':5,'Please wait...Registering...');
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
	if buf[count]=oldinfo[1] then
	if buf[count+1]=oldinfo[2] then
	if buf[count+2]=oldinfo[3] then
	  begin
	    pos:=filepos(f);
	    pos:=pos-120+count-1;
	    blockwrite(outf,buf,numread,numwritten);
	    seek(f,pos); seek(outf,pos);
	    blockread(f,buf,sizeof(buf),numread);
            newinfo[120]:=buf[120];
	    blockwrite(outf,newinfo,numread,numwritten);
	    found:=true;
	    repeat
	      blockread(f,buf,sizeof(buf),numread);
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
    then writeln(' ':5,'Registeration was successful.')
    else writeln(' ':5,'Serial number was not found.');
  close(f);
  close(outf);
  erase(f)
end;

procedure register;

var
  c:integer; outf:file;

begin
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
        writeln(' ':5,'File not found. Abort registeration process.')
      end;
    registeranother;
    if not exit
      then changeinfo
  until exit;
  window(1,1,80,25)
end;

procedure newcb; interrupt;

begin
end;

procedure driver;

begin
  orgx:=wherex;
  orgy:=wherey;
  display:=detectmode;
  movescreento(1,1,80,25,display,tomemory,buffers[1]);
  getintvec($1b,oldcb);
  setintvec($1b,@newcb);
  border:=1;
  bordercolor:=59;
  titlecolor:=15;
  opening;
  movescreento(1,1,80,25,display,tomemory,buffers[2]);
  initall;
  register;
  setintvec($1b,oldcb);
  userexit(#27)
end;

begin
  driver
end.

