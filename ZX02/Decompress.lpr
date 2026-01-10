program Decompress;

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
 A      : Word=0;                             //Accumulator
 X      : Byte=0;                             //X register
 bitr   : Word=$80;                           //Elias seed
 C      : Byte=0;                             //Carry flag
 inptr  : Cardinal=0;                         //Input pointer
 outptr : Cardinal=0;                         //Output pointer
 //Arithmetic shift left C<-A<-0
 procedure ASL;
 begin
  bitr:=bitr<<1;                              //Shift left
  C   :=bitr div $100;                        //Get the carry bit
  bitr:=bitr mod $100;                        //Reduce to 8 bits
 end;
 //Rotate left one bit C<-A<-C
 procedure ROL;
 begin
  A:=(A<<1)OR C;                              //Shift left and add the carry
  C:=A div $100;                              //Get the new carry bit
  A:=A mod $100;                              //Reduce to 8 bits
 end;
 //Get the next byte from the compressed stream, and update the pointer
 function GetByte: Boolean;
 begin
  if inptr<Length(compressed)then             //Make sure it is within range
  begin
   A:=compressed[inptr]mod$100;               //Ensure it is 8 bits
   inc(inptr);                                //Move onto the next byte
   Result:=True;                              //Return a positive result
  end
  else
  begin
   A:=$FF00;                                  //>$FF Indicates error condition
   Result:=False;                             //So return a negative result
  end;
 end;
 //Put a byte into the next location in the decompressed stream
 procedure SaveByte(b: Word);
 begin
  if outptr>=Length(Result)then SetLength(Result,outptr+1);//Extend the output
  Result[outptr]:=b mod$100;                  //b should not be more than $FF
  inc(outptr);                                //Move on
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
  Result:=A<$100;                             //Error state if A>$FF
 end;
//Function body starts here
var
 action : String='decode_literal';
 Y      : Byte=0;
 offset : Cardinal=0;
 pointer: PtrUInt=0;
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
  case action of
   'decode_literal': //No compression - just copy from src to dest -------------
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
   'copybytes': //Copy a series of bytes N number of times ---------------------
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
   'get_new_offset': //Get new offset ------------------------------------------
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
  end;
 until action='';
 if A<>$7F then SetLength(Result,0);           //Error
end;

//Main program +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
var
 decompressed: TByteArray=();
 compressed  : TByteArray=();
 F           : TFileStream=nil;
 filename    : String='';
 outputfile  : String='';
 startofdata : Cardinal=0;
const
 crlf  = #13#10;
 red   = #$1B'[91m';
 green = #$1B'[92m';
 yellow= #$1B'[93m';
 bold  = #$1B'[1m';
 normal= #$1B'[0m';
begin
 //Get the file specified
 filename  :=ParamStr(1);
 //And the optional output file
 outputfile:=ParamStr(2);
 //Starting point
 startofdata:=StrToIntDef('$'+ParamStr(3),0);
 //If no output file specified, then make our own
 if outputfile='' then outputfile:=ExtractFilePath(filename)+'-decompressed';
 WriteLn(bold);
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
    on E:Exception do WriteLn(red+'Error: '+E.Message+normal);
   end;
   //Decompress the data
   decompressed:=ZX02Decompress(compressed,startofdata);
   //Display the result
   if Length(decompressed)<Length(compressed) then //Was it a success?
    WriteLn(red+'Decompression failed. Likely reason: not a valid ZX02 file.'
           +normal) //No
   else
   begin //Yes
    WriteLn(green+'Decompression success.'+normal);
    WriteLn(bold+'Compressed length  :'+yellow+' 0x'+IntToHex(Length(compressed)  ,4)+normal);
    WriteLn(bold+'Decompressed length:'+yellow+' 0x'+IntToHex(Length(decompressed),4)+normal);
    //Save the output to a file
    try
     F:=TFileStream.Create(outputfile,fmCreate or fmShareDenyNone);
     F.Write(decompressed[0],Length(decompressed));
     F.Free;
    except //File error has occurred.
     on E:Exception do WriteLn(red+'Error: '+E.Message+normal);
    end;
   end; //Errors due to wrong input
  end else WriteLn(red+'File "'+filename+'" does not exist.'+normal)
 else WriteLn(red+'Syntax: <input file>[<output file>[<start>]]'+normal);
end.
