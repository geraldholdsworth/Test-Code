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
//Translated from the 6502 code as used in Repton 3 Redux
//Thank you to Matthew Atkinson for the source code
//See also: https://github.com/dmsc/zx02
var
 A      : Word=0;
 X      : Byte=0;
 bitr   : Word=$80;
 C      : Byte=0;
 inptr  : Cardinal=0;
 outptr : Cardinal=0;
 //Arithmetic shift left C<-A<-0
 procedure ASL;
 begin
  bitr:=bitr<<1;
  C   :=bitr div $100;
  bitr:=bitr mod $100;
 end;
 //Rotate left one bit C<-A<-C
 procedure ROL;
 begin
  A:=(A<<1)OR C;
  C:=A div $100;
  A:=A mod $100;
 end;
 //Get the next byte from the compressed stream, and update the pointer
 function GetByte: Boolean;
 begin
  if inptr<Length(compressed)then
  begin
   A:=compressed[inptr]mod$100;               //Ensure it is 8 bits
   inc(inptr);
   Result:=True;
  end
  else
  begin
   A:=$FF00;                                  //>$FF Indicates error condition
   Result:=False;
  end;
 end;
 //Put a byte into the next location in the decompressed stream
 procedure SaveByte(b: Word);
 begin
  if outptr>=Length(Result)then SetLength(Result,outptr+1);
  Result[outptr]:=b mod$100;                  //b should not be more than $FF
  inc(outptr);
 end;
 //Get an encoded elias number
 function GetElias: Boolean;
 var
  Lfirst: Boolean=True;
 begin
  X     :=1;
  Lfirst:=True;
  repeat
   if not Lfirst then
   begin
    A:=X mod$100;
    ASL;
    ROL;
    X:=A;
   end;
   Lfirst:=False;
   ASL;
   if bitr=0 then
    if GetByte then
    begin
     ROL;
     bitr:=A;
    end;
  until(C=0)or(A>$FF);
  Result:=A<$100;                             //Error state
 end;
//Function body starts here
var
 action : String='decode_literal';
 Y      : Byte=0;
 offset : Cardinal=0;
 pointer: Cardinal=0;
begin
 //Initialise
 A   :=0;  //Accumulator
 X   :=0;  //X register
 Y   :=0;  //Y register
 C   :=0;  //C flag (carry)
 bitr:=$80;
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
 repeat
  //No compression - just copy from src to dest
  if action='decode_literal' then
  begin
   if not GetElias then exit(nil);            //Error
   while X<>0 do
   begin
    if not GetByte then exit(nil);            //Error
    SaveByte(A);
    dec(X);
   end;
   ASL;
   if C=1 then action:='get_new_offset'
   else
   begin
    if not GetElias then exit(nil);           //Error
    action:='copybytes';
   end;
  end;
  //Copy a series of bytes N number of times
  if action='copybytes' then
  begin
   pointer:=(outptr-offset-(1-C));
   while X<>0 do
   begin
    if pointer>=Length(Result) then exit(nil);//Error
    SaveByte(Result[pointer]);
    inc(pointer);
    dec(X);
   end;
   ASL;
   if C=0 then action:='decode_literal' else action:='get_new_offset';
  end;
  //Get new offset
  if action='get_new_offset' then
  begin
   offset:=(offset mod $100)OR Y<<8;
   if not GetByte then exit(nil);             //Error
   A:=A mod $100;
   C:=A AND 1;
   A:=A>>1;
   if C=1 then
   begin
    if A=$7F then exit;//Reached the end of the compressed data
    offset:=(offset mod $100)OR A<<8;
    if not GetByte then exit(nil);            //Error
   end;
   offset:=(offset AND $FF00)OR A;
   if not GetElias then exit(nil);            //Error
   inc(X);
   X:=X mod $100;
   if C=0 then action:='copybytes' else action:='';
  end;
 until action='';
 if A<>$7F then SetLength(Result,0);          //Error
end;

//Main program +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
var
 decompressed: TByteArray=();
 compressed  : TByteArray=();
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
 if outputfile='' then outputfile:=ExtractFilePath(filename)+'-decompressed';
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
   except //File error has occurred.
    on E:Exception do WriteLn(#13#10#$1B'[91m'#$1B'[1mError: '+E.Message
                             +#$1B'[0m');
   end;
   //Decompress the data
   decompressed:=ZX02Decompress(compressed,startofdata);
   //Display the result
   if Length(decompressed)<Length(compressed) then //Was it a success?
    WriteLn(#13#10#$1B'[91m'#$1B'[1m'
           +'Decompression failed. Likely reason: not a valid ZX02 file.'
           +#$1B'[0m') //No
   else
   begin //Yes
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
    except //File error has occurred.
     on E:Exception do WriteLn(#13#10#$1B'[91m'#$1B'[1mError: '+E.Message
                              +#$1B'[0m');
    end;
   end; //Errors due to wrong input
  end else WriteLn(#13#10#$1B'[91m'#$1B'[1mFile "'+filename+'" does not exist.'
                  +#$1B'[0m')
 else WriteLn(#13#10#$1B'[93m'#$1B'[1m'
             +'Syntax: <input file>[<output file>[<start>]]'+#$1B'[0m');
end.
