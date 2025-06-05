unit Unit1;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

 { TForm1 }

 TForm1 = class(TForm)
  Button1: TButton;
  Button2: TButton;
  Memo1: TMemo;
  procedure Button1Click(Sender: TObject);
  procedure CombineZIP(files: array of String);
  procedure Button2Click(Sender: TObject);
 private

 public
  const
   Lfolder='/Users/geraldholdsworth/Library/Mobile Documents/com~apple~CloudDocs/'
          +'Programming/Lazarus/Old and Test Projects/ZIP Combiner/ZIP Tests';
 end;

var
 Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
begin
 Memo1.Lines.Clear;
 CombineZIP([LFolder+'/Test-empty.zip',LFolder+'/Test-archive 1.zip']);
 CombineZIP([LFolder+'/Output.zip'    ,LFolder+'/Test-archive 2.zip']);
end;

procedure TForm1.CombineZIP(files: array of String);
 //Finds the central library and returns the end of central library
 function FindCL(var EoCL: Integer;var buffer: array of Byte): Integer;
 var
  i: Integer=0;
 begin
  //Start with a default (i.e., not found)
  Result:=-1;
  EoCL:=-1;
  //Can't have a file smaller than 22 bytes
  if Length(buffer)<22 then exit;
  //Start here
  i:=Length(buffer)-3;
  //And work backwards until we find the EoCL marker
  repeat
    dec(i);
  until((buffer[i  ]=$50)
     and(buffer[i+1]=$4B)
     and(buffer[i+2]=$05)
     and(buffer[i+3]=$06))
     or (i=0);
  //Found OK?
  if (buffer[i  ]=$50)
  and(buffer[i+1]=$4B)
  and(buffer[i+2]=$05)
  and(buffer[i+3]=$06) then
  begin
   //Mark it
   EoCL:=i;
   //Retreive where the central library starts
   Result:=buffer[i+$10]
          +buffer[i+$11]<<8
          +buffer[i+$12]<<16
          +buffer[i+$13]<<24;
  end;
 end;
//Main method definitions
var
 input     : array[0..1] of TFileStream;
 output    : TFileStream;
 inbuffer  : array[0..1] of array of Byte;
 outbuffer : array of Byte;
 ptr       : Integer=0;    
 cnt       : Integer=0;
 fileptr   : Cardinal=0;
 CL        : array[0..1] of Integer;
 EoCL      : array[0..1] of Integer;
 temp      : Cardinal=0;
 numfiles  : Cardinal=0;
 CLsize    : Cardinal=0;
 filesize  : Cardinal=0;
 ok        : Boolean=True;
//Main method starts here
begin
 //Read in the files
 for ptr:=0 to 1 do
 begin
  Memo1.Lines.Add('Opening '+files[ptr]);
  input[ptr]:=TFileStream.Create(files[ptr],fmOpenRead OR fmShareDenyNone);
  input[ptr].Position:=0;
  SetLength(inbuffer[ptr],input[ptr].Size);
  input[ptr].Read(inbuffer[ptr][0],input[ptr].Size);
  input[ptr].Free;
  //Get the position of the central library for each
  CL[ptr]:=FindCL(EoCL[ptr],inbuffer[ptr]);
  ok:=(ok)AND(CL[ptr]<>-1)AND(EoCL[ptr]<>-1);
  Memo1.Lines.Add('File '+IntToStr(ptr+1)+' size                  : '+IntToHex(Length(inbuffer[ptr]),8));
  if CL[ptr]<>-1 then
   Memo1.Lines.Add('Central Library file '+IntToStr(ptr+1)+'       : '+IntToHex(CL[ptr],8));
  if EoCL[ptr]<>-1 then
  begin
   Memo1.Lines.Add('End of Central Library file '+IntToStr(ptr+1)+': '+IntToHex(EoCL[ptr],8));
   //Count the number of files stored
   inc(numfiles,inbuffer[ptr][EoCL[ptr]+$A]+inbuffer[ptr][EoCL[ptr]+$B]<<8);
  end;
 end;
 //Create the output file
 if ok then
 begin
  Memo1.Lines.Add('Total number of files        : '+IntToStr(numfiles));
  //This will be the eventual central library size
  CLsize:=(EoCL[0]-CL[0])+(EoCL[1]-CL[1]);
  Memo1.Lines.Add('Eventual Central Library size: '+IntToHex(CLsize,8));
  //This will be the eventual file size
  filesize:=CL[0]+CL[1]+CLsize+22;
  Memo1.Lines.Add('Eventual file size           : '+IntToHex(filesize,8));
  SetLength(outbuffer,filesize);
  //Write the files. The files from the second ZIP goes where the first CL was
  fileptr:=0;
  for cnt:=0 to 1 do
  begin
   Memo1.Lines.Add('Files from ZIP '+IntToStr(cnt+1)+' at          : '+IntToHex(fileptr,8));
   for ptr:=0 to CL[cnt]-1 do outbuffer[fileptr+ptr]:=inbuffer[cnt][ptr];
   inc(fileptr,CL[cnt]);
  end;
  //Write the CLs
  for cnt:=0 to 1 do
  begin
   Memo1.Lines.Add('CL from ZIP '+IntToStr(cnt+1)+' at             : '+IntToHex(fileptr,8));
   //We'll need to find each file entry and adjust by adding CL1 to the adddress
   for ptr:=CL[cnt] to EoCL[cnt]-1 do
   begin
    outbuffer[fileptr-CL[cnt]+ptr]:=inbuffer[cnt][ptr];
    if cnt>0 then
     //Found a file?
     if (inbuffer[cnt][ptr-$2E]=$50)
     and(inbuffer[cnt][ptr-$2D]=$4B)
     and(inbuffer[cnt][ptr-$2C]=$01)
     and(inbuffer[cnt][ptr-$2B]=$02)then
     begin
      //Get the data offset
      temp:=inbuffer[cnt][ptr-4]
           +inbuffer[cnt][ptr-3]<<8
           +inbuffer[cnt][ptr-2]<<16
           +inbuffer[cnt][ptr-1]<<24;
      Memo1.Lines.Add('CL file found at             : '+IntToHex((fileptr-CL[cnt]+ptr)-$2E,8));
      Memo1.Lines.Add('Data offset                  : '+IntToHex(temp,8));
      //Adjust the data offset
      inc(temp,CL[cnt-1]);
      Memo1.Lines.Add('New data offset              : '+IntToHex(temp,8));
      //Save back
      outbuffer[(fileptr-CL[cnt]+ptr)-4]:= temp AND $000000FF;
      outbuffer[(fileptr-CL[cnt]+ptr)-3]:=(temp AND $0000FF00)>>8;
      outbuffer[(fileptr-CL[cnt]+ptr)-2]:=(temp AND $00FF0000)>>16;
      outbuffer[(fileptr-CL[cnt]+ptr)-1]:=(temp AND $FF000000)>>24;
     end;
   end;
   inc(fileptr,CL[cnt]);
  end;
  //Write the central directory
  fileptr:=filesize-22;
  outbuffer[fileptr    ]:=$50;
  outbuffer[fileptr+$01]:=$4B;
  outbuffer[fileptr+$02]:=$05;
  outbuffer[fileptr+$03]:=$06;
  outbuffer[fileptr+$08]:= numfiles AND $00FF;
  outbuffer[fileptr+$09]:=(numfiles AND $FF00)>>8;
  outbuffer[fileptr+$0A]:= numfiles AND $00FF;
  outbuffer[fileptr+$0B]:=(numfiles AND $FF00)>>8;
  outbuffer[fileptr+$0C]:= CLsize AND $000000FF;
  outbuffer[fileptr+$0D]:=(CLsize AND $0000FF00)>>8;
  outbuffer[fileptr+$0E]:=(CLsize AND $00FF0000)>>16;
  outbuffer[fileptr+$0F]:=(CLsize AND $FF000000)>>24;
  outbuffer[fileptr+$10]:= (CL[0]+CL[1]) AND $000000FF;
  outbuffer[fileptr+$11]:=((CL[0]+CL[1]) AND $0000FF00)>>8;
  outbuffer[fileptr+$12]:=((CL[0]+CL[1]) AND $00FF0000)>>16;
  outbuffer[fileptr+$13]:=((CL[0]+CL[1]) AND $FF000000)>>24;
  //Save the data to a file
  output:=TFileStream.Create(Lfolder+'/Output.zip',fmCreate OR fmShareDenyNone);
  output.Position:=0;
  output.Write(outbuffer[0],Length(outbuffer));
  output.Free;
  //Output the notes
  Memo1.Lines.SaveToFile(LFolder+'/Output.txt');
 end;
end;

procedure TForm1.Button2Click(Sender: TObject);
//Create an empty ZIP file
var
 outbuffer: array of Byte;
 output   : TFileStream;
begin
 Memo1.Clear;
 SetLength(outbuffer,22);
 outbuffer[$00]:=$50;
 outbuffer[$01]:=$4B;
 outbuffer[$02]:=$05;
 outbuffer[$03]:=$06;
 output:=TFileStream.Create(Lfolder+'/Test-empty.zip',fmCreate OR fmShareDenyNone);
 output.Position:=0;
 output.Write(outbuffer[0],Length(outbuffer));
 output.Free;
 Memo1.Lines.Add('Empty ZIP file created');
end;

end.

