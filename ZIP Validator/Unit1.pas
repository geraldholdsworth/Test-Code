unit Unit1;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls;

type

 { TForm1 }

 TForm1 = class(TForm)
  Panel1: TPanel;
  Memo1: TMemo;
  function FindCL(var EoCL: Integer;var buffer: array of Byte): Integer;
  procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
  procedure ValidateZIPFile(filename: String);
 private

 public

 end;

var
 Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }


//Finds the central library and returns the end of central library
function TForm1.FindCL(var EoCL: Integer;var buffer: array of Byte): Integer;
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

procedure TForm1.FormDropFiles(Sender: TObject; const FileNames: array of string
 );
var
 i: Integer=0;
begin
 Memo1.Lines.Clear;
 for i:=0 to Length(FileNames)-1 do
 begin
  ValidateZIPFile(FileNames[i]);
  if i<>Length(FileNames)-1 then
   Memo1.Lines.Add('----------------------------------------------------------');
 end;
end;

procedure TForm1.ValidateZIPFile(filename: String);
var
 Lfile   : TFileStream;
 Lbuffer : array of Byte;
 CL      : Integer=-1;
 EoCL    : Integer=-1;
 valid   : Boolean=False;
 check   : Boolean=False;
 temp    : Cardinal=0;
 numfiles: Integer=0;
 index   : Integer=0;
 ptr     : Cardinal=0;
 data    : Cardinal=0;
 size    : Cardinal=0;
 usize   : Cardinal=0;
 //Check the length of the extra field
 function CheckExtraField(addr,len: Cardinal): Boolean;
 var
  total: Cardinal=0;
 begin
  Result:=False;
  Memo1.Lines.Add('Extra field offset           : '+IntToHex(addr,8));
  Memo1.Lines.Add('Extra field given length     : '+IntToHex(len,8));
  while(total<len)and(addr<Length(Lbuffer)-4)do
  begin
   //Extra field has pairs of 2 byte tag + 2 byte length
   inc(total,4+Lbuffer[addr+2]+Lbuffer[addr+3]<<8);
   inc(addr,4+Lbuffer[addr+2]+Lbuffer[addr+3]<<8);
  end;
  Memo1.Lines.Add('Extra field calculated length: '+IntToHex(total,8));
  Result:=total=len;
 end;
begin
 //Read the file into the buffer
 Memo1.Lines.Add('Opening file '+ExtractFilename(filename));
 Lfile:=TFileStream.Create(filename,fmOpenRead OR fmShareDenyNone);
 Lfile.Position:=0;
 SetLength(Lbuffer,LFile.Size);
 Lfile.Read(Lbuffer[0],Lfile.Size);
 Lfile.Free;
 //File length
 Memo1.Lines.Add('File length                  : '+IntToHex(Length(Lbuffer),8));
 //Find the central library
 CL:=FindCL(EoCL,Lbuffer);
 if CL=-1   then Memo1.Lines.Add('Central Library not found');
 if EoCL=-1 then Memo1.Lines.Add('End of Central Library not found');
 if(CL<>-1)and(EoCL<>-1)then
 begin
  valid:=True;
  Memo1.Lines.Add('Central Library              : '+IntToHex(CL,8));
  Memo1.Lines.Add('End of Central Library       : '+IntToHex(EoCL,8));
  //Size of Central Library
  temp:=Lbuffer[EoCL+$C]
       +Lbuffer[EoCL+$D]<<8
       +Lbuffer[EoCL+$E]<<16
       +Lbuffer[EoCL+$F]<<24;
  Memo1.Lines.Add('Central Library size         : '+IntToHex(temp,8));
  //Test to see if it matches the references already found
  check:=temp=EoCL-CL;
  if check then Memo1.Lines.Add('Matches references')
  else Memo1.Lines.Add('Does not match references');
  valid:=(check)AND(valid);
  //Total number of files
  numfiles:=Lbuffer[EoCL+$A]
           +Lbuffer[EoCL+$B]<<8;
  Memo1.Lines.Add('Total number of files        : '+IntToStr(numfiles));
  Memo1.Lines.Add('Checking files');
  ptr:=CL;
  index:=0;
  while(index<numfiles)and(ptr<EoCL)do
  begin
   Memo1.Lines.Add('File #'+IntToStr(index+1)+' at offset '+IntToHex(ptr,8));
   //Check the signature
   check:=(Lbuffer[ptr]=$50)
       and(Lbuffer[ptr+1]=$4B)
       and(Lbuffer[ptr+2]=$01)
       and(Lbuffer[ptr+3]=$02);
   if check then Memo1.Lines.Add('Valid signature')
            else Memo1.Lines.Add('Invalid signature');
   valid:=(check)AND(valid);
   //Check the extra field
   temp:=Lbuffer[ptr+$1E]+Lbuffer[ptr+$1F]<<8;
   check:=True;
   if temp>0 then
    check:=CheckExtraField(ptr+$2E+Lbuffer[ptr+$1C]+Lbuffer[ptr+$1D]<<8,temp);
   if check then Memo1.Lines.Add('Extra field size match')
            else Memo1.Lines.Add('Extra field size mis-match');
   valid:=(check)AND(valid);
   //Compressed size
   size:=Lbuffer[ptr+$14]
        +Lbuffer[ptr+$15]<<8
        +Lbuffer[ptr+$16]<<16
        +Lbuffer[ptr+$17]<<24;
   Memo1.Lines.Add('Compressed size              : '+IntToHex(size,8));
   //Uncompressed size
   usize:=Lbuffer[ptr+$18]
         +Lbuffer[ptr+$19]<<8
         +Lbuffer[ptr+$1A]<<16
         +Lbuffer[ptr+$1B]<<24;
   Memo1.Lines.Add('Uncompressed size            : '+IntToHex(usize,8));
   //Data pointer
   data:=Lbuffer[ptr+$2A]
        +Lbuffer[ptr+$2B]<<8
        +Lbuffer[ptr+$2C]<<16
        +Lbuffer[ptr+$2D]<<24;
   Memo1.Lines.Add('Data pointer                 : '+IntToHex(data,8));
   //Check the local file entry
   Memo1.Lines.Add('Checking local file entry');
   check:=(Lbuffer[data]=$50)
       and(Lbuffer[data+1]=$4B)
       and(Lbuffer[data+2]=$03)
       and(Lbuffer[data+3]=$04);
   if check then Memo1.Lines.Add('Valid signature')
            else Memo1.Lines.Add('Invalid signature');
   valid:=(check)AND(valid);
   //Check compressed size
   check:=Lbuffer[data+$12]
         +Lbuffer[data+$13]<<8
         +Lbuffer[data+$14]<<16
         +Lbuffer[data+$15]<<24=size;
   if check then Memo1.Lines.Add('Compressed size match')
            else Memo1.Lines.Add('Compressed size mis-match');
   valid:=(check)AND(valid);
   //Check uncompressed size
   check:=Lbuffer[data+$16]
         +Lbuffer[data+$17]<<8
         +Lbuffer[data+$18]<<16
         +Lbuffer[data+$19]<<24=usize;
   if check then Memo1.Lines.Add('Uncompressed size match')
            else Memo1.Lines.Add('Uncompressed size mis-match');
   valid:=(check)AND(valid);
   //Check the extra field
   temp:=Lbuffer[data+$1C]+Lbuffer[data+$1D]<<8;
   check:=True;
   if temp>0 then
    check:=CheckExtraField(data+$1E+Lbuffer[data+$1A]+Lbuffer[data+$1B]<<8,temp);
   if check then Memo1.Lines.Add('Extra field size match')
            else Memo1.Lines.Add('Extra field size mis-match');
   valid:=(check)AND(valid);
   //Next entry - here we work out where it should be
   temp:=ptr+$2E
            +Lbuffer[ptr+$1C]+Lbuffer[ptr+$1D]<<8
            +Lbuffer[ptr+$1E]+Lbuffer[ptr+$1F]<<8
            +Lbuffer[ptr+$20]+Lbuffer[ptr+$21]<<8;
   //Now we find the next marker
   repeat
    inc(ptr,1);
   until(ptr=EoCL)or((Lbuffer[ptr  ]=$50)
                  and(Lbuffer[ptr+1]=$4B)
                  and(Lbuffer[ptr+2]=$01)
                  and(Lbuffer[ptr+3]=$02));
   //And check if they match
   check:=ptr=temp;
   if check then Memo1.Lines.Add('Central Library entry size match')
            else Memo1.Lines.Add('Central Library entry size mis-match');
   valid:=(check)AND(valid);
   //Next file
   inc(index);
   Application.ProcessMessages;
  end;
  //Check we got all the files
  check:=index=numfiles;
  if check then Memo1.Lines.Add('Correct number of files found')
           else Memo1.Lines.Add('Incorrect number of files');
  valid:=(check)AND(valid);
 end;
 if valid then Memo1.Lines.Add('File is a valid ZIP file')
          else Memo1.Lines.Add('File is an invalid ZIP file');
end;

end.

