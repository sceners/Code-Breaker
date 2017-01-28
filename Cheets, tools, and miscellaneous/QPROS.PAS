Program QproSerial;

Uses Crt,Dos;

Var
  C,Count:LongInt;
  Key:Char;

Begin
  Write('Enter a number ');
  Readln(Count);
  Write('Your serial number is = DA247B');
  Writeln(10000001+11*Count:8)
End.
