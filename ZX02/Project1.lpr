program Project1;

{$mode objfpc}{$H+}

uses
 {$IFDEF UNIX}
 cthreads,
 {$ENDIF}
 Classes,
  SysUtils
 { you can add units after this };

type
  TByteArray = array of Byte;

function ZX02Decompress(compressed: TByteArray;start: Cardinal=0): TByteArray;
//Translated from the 6502 code as used in Repton 3 : Redux
//Thank you to Matthew Atkinson for the source code
//See also: https://github.com/dmsc/zx02
var
 A           : Word=0;  //We could just use Byte, but we need 9 bits
 X           : Word=0;
 Y           : Word=0;
 bitr        : Word=$80;
 C           : Byte=0;
 inptr       : Cardinal=0;
 outptr      : Cardinal=0;
 offset      : Cardinal=0;
 pointer     : Cardinal=0;
 //Arithmetic shift left C<-b<-0
 procedure ASL(var b: Word);
 begin
  b:=b<<1;
  C:=b div $100;
  b:=b mod $100;
 end;
 //Logical shift right 0->b->C
 procedure LSR(var b: Word);
 begin
  b:=b mod $100;
  C:=b AND 1;
  b:=b>>1;
 end;
 //Rotate left one bit C<-b<-C
 procedure ROL(var b: Word);
 begin
  b:=(b<<1)OR C;
  C:=b div $100;
  b:=b mod $100;
 end;
 //Get the next byte from the compressed stream
 function get_byte: Word;
 begin
  Result:=$FF00;
  if inptr<Length(compressed) then
  begin
   Result:=compressed[inptr];
   inc(inptr);
  end;
 end;
 //Put a byte into the next location in the decompressed stream
 procedure save_byte(b: Word);
 begin
  if outptr>=Length(Result) then SetLength(Result,outptr+1);
  Result[outptr]:=b mod $100;
  inc(outptr);
 end;
 //Get an encoded elias number
 function get_elias: Boolean;
 label
   elias_start, elias_get, elias_skip1;
 begin
   Result:=True;
   X     :=1;
   goto elias_start;

  elias_get:
   A:=X;
   ASL(bitr);
   ROL(A);
   X:=A;

  elias_start:
   ASL(bitr);
   if bitr<>0 then goto elias_skip1;
   A   :=get_byte;
   if A>$FF then
   begin
    Result:=False;
    exit;
   end;
   ROL(A);
   bitr:=A;

  elias_skip1:
   if C=1 then goto elias_get;
 end;
label
  decode_literal, dzx0s_new_offset, dzx0s_copy;
//Function body starts here
begin
 A     :=0;    //Accumulator
 X     :=0;    //X register
 Y     :=0;    //Y register
 C     :=0;    //C flag (carry)
 bitr  :=$80;
 //A starting position other than zero has been specified.
 if start>0 then //Copy the uncompressed data across first
 begin
  //Set our output container
  SetLength(Result,start);
  //Copy the data across
  for inptr:=0 to start-1 do Result[inptr]:=compressed[inptr];
  //Set the starting points
  inptr :=start;
  outptr:=start;
 end
 else
 begin //Otherwise, just set them to zero
  inptr :=$0;
  outptr:=$0;
 end;
 //Start the decompression
 decode_literal:
  if not get_elias then exit;
  while X<>0 do
  begin
   A:=get_byte;
   if A>$FF then exit;
   save_byte(A);
   dec(X);
  end;
  ASL(bitr);
  if C=1 then goto dzx0s_new_offset;
  if not get_elias then exit;

 dzx0s_copy:
  A:=outptr-offset-(1-C);
  if C<0 then C:=0 else C:=1;
  pointer:=A;
  while X<>0 do
  begin
   if pointer<Length(Result) then A:=Result[pointer] else exit;
   inc(pointer);
   save_byte(A);
   dec(X);
  end;
  ASL(bitr);
  if C=0 then goto decode_literal;

 dzx0s_new_offset:
  offset:=(offset mod $100)OR Y<<8;
  A:=get_byte;
  if A>$FF then exit;
  LSR(A);
  if C=1 then
  begin
   if A=$7F then exit;
   offset:=(offset mod $100)OR A<<8;
   A:=get_byte;
   if A>$FF then exit;
  end;
  offset:=(offset AND $FF00)OR A;
  if not get_elias then exit;
  inc(X);
  X:=X mod $100;
  if C=0 then goto dzx0s_copy;
end;

var
 decompressed: array of Byte=();
 compressed  : array of Byte=();
 F           : TFileStream=nil;
 filename    : String='';
 outputfile  : String='';
 startofdata : Cardinal=0;

begin
 //Get the file specified
 filename  :=ParamStr(1);
 //And the optional output file
 outputfile:=ParamStr(2);
 //Starting point
 startofdata:=StrToIntDef('$'+ParamStr(3),0);
 //If no output file specified, then make our own
 if outputfile='' then outputfile:=ExtractFilePath(filename)+'output';
 //If no input file, can't do any decompression
 if filename<>'' then
  //Needs to exist too
  if FileExists(filename) then
  begin
   //Load the compressed file in
   try
    F:=TFileStream.Create(filename,fmOpenRead or fmShareDenyNone);
    SetLength(compressed,F.Size);
    F.Read(compressed[0],F.Size);
    F.Free;
   except
    on E:Exception do WriteLn(#13#10#$1B'[91m'#$1B'[1mError: '+E.Message
                             +#$1B'[0m');
   end;
   //Decompress the data
   decompressed:=ZX02Decompress(compressed,startofdata);
   //Was it a success?
   if Length(decompressed)<Length(compressed) then
    WriteLn(#13#10#$1B'[91m'#$1B'[1m'
           +'Decompression failed. Likely reason: not a valid ZX02 file.'
           +#$1B'[0m')
   else
   begin
    //Display the output
    WriteLn(#13#10#$1B'[92m'#$1B'[1mDecompression success.'+#$1B'[0m');
    WriteLn(#$1B'[1mCompressed length  :'
           +#$1B'[93m 0x'+IntToHex(Length(compressed)  ,4)+#$1B'[0m');
    WriteLn(#$1B'[1mDecompressed length:'
           +#$1B'[93m 0x'+IntToHex(Length(decompressed),4)+#$1B'[0m');
    //Save the output to a file
    try
     F:=TFileStream.Create(outputfile,fmCreate or fmShareDenyNone);
     F.Write(decompressed[0],Length(decompressed));
     F.Free;
    except
     on E:Exception do WriteLn(#13#10#$1B'[91m'#$1B'[1mError: '+E.Message
                              +#$1B'[0m');
    end;
   end;
  end else WriteLn(#13#10#$1B'[91m'#$1B'[1mFile "'+filename+'" does not exist.'
                  +#$1B'[0m')
 else WriteLn(#13#10#$1B'[93m'#$1B'[1m'
             +'Syntax: <input file>[<output file>[<start>]]'+#$1B'[0m');
end.
