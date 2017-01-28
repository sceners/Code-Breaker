uses crt,dos;

type
  dirname=record
    name:packed array[1..12] of char;
    size:byte
  end;
  dirnamestype=record
    names:array[1..100] of dirname;
    numdirs:integer
  end;

var
  dirinfo:searchrec;
  dirnames:dirnamestype;
  count,size:byte;
  drive:char;

procedure getdirs (var dirnames:dirnamestype);

begin
  dirnames.numdirs:=0;
  findfirst(drive+':\*',directory,dirinfo);
  while doserror=0 do
    begin
      inc(dirnames.numdirs);
      size:=0;
      while (dirinfo.name[size+1] <> ' ') and (size <=12) do
        begin
          inc(size);
          dirnames.names[dirnames.numdirs].name[size]:=dirinfo.name[size]
        end;
      dirnames.names[dirnames.numdirs].size:=size;
      findnext(dirinfo)
    end
end;

begin
  drive:='c';
  getdirs(dirnames);
  for size:=1 to dirnames.numdirs do
    begin
      for count:=1 to dirnames.names[size].size do
        write(dirnames.names[size].name[count]);
      writeln(' ':12-dirnames.names[size].size,dirnames.names[size].size)
    end
end.

