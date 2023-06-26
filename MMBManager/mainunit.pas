unit MainUnit;

{$mode objfpc}{$H+}

interface

uses
 Classes,SysUtils,Forms,Controls,Graphics,Dialogs,ExtCtrls,StdCtrls,StrUtils;

type

 { TMMBForm }

 TMMBForm = class(TForm)
  Memo1: TMemo;
  Panel1: TPanel;
  procedure FormDropFiles(Sender: TObject; const FileNames: array of String);
  procedure FormShow(Sender: TObject);
 private
  buffer: array of Byte;
 public

 end;

var
 MMBForm: TMMBForm;

implementation

{$R *.lfm}

{ TMMBForm }

procedure TMMBForm.FormShow(Sender: TObject);
begin
 Memo1.Clear;
end;

procedure TMMBForm.FormDropFiles(Sender: TObject;
 const FileNames: array of String);
var
 F: TFileStream;
 ID: Boolean;
 i,c,ptr: Integer;
 line: String;
begin
 Memo1.Clear;
 F:=TFileStream.Create(Filenames[0],fmOpenRead);
 SetLength(buffer,F.Size);
 F.Read(buffer[0],F.Size);
 F.Free;
 //ID Checks
 ID:=True;
 //File size
 if Length(buffer)<>$63D0000 then ID:=False;
 if ID then Memo1.Lines.Add('File Size check OK');
 //Disc status bytes
 c:=0;
 for i:=1 to 512 do
 begin
  ptr:=(16*i)-1;
  if(buffer[ptr]=$00)or(buffer[ptr]=$0F)or(buffer[ptr]=$F0)or(buffer[ptr]=$FF)then
   inc(c);
 end;
 if c<511 then ID:=False;
 if ID then Memo1.Lines.Add('Status byte check OK');
 //Read the disc names
 if ID then
 begin
  line:='Images inserted at boot time: ';
  line:=line+IntToStr(buffer[0]+buffer[4]<<8)+', ';
  line:=line+IntToStr(buffer[1]+buffer[5]<<8)+', ';
  line:=line+IntToStr(buffer[2]+buffer[6]<<8)+' & ';
  line:=line+IntToStr(buffer[3]+buffer[7]<<8);
  Memo1.Lines.Add(line);
  for i:=0 to 510 do
  begin
   ptr:=16+16*i;
   line:='Disc '+PadLeft(IntToStr(i),3)+': ';
   case buffer[ptr+15] of
    $00 : line:=line+'Locked   "';
    $0F : line:=line+'Unlocked "';
    $F0 : line:=line+'Empty     ';
   end;
   if(buffer[ptr+15]=$00)or(buffer[ptr+15]=$0F)then
   begin
    for c:=0 to 11 do
     if(buffer[ptr+c]>31)and(buffer[ptr+c]<127)then
      line:=line+chr(buffer[ptr+c]);
    line:=line+'"';
   end;
   line:=PadRight(line,33);
   line:=line+' Image address: 0x'+IntToHex(i*$32000+$2000,7);
   Memo1.Lines.Add(line);
  end;
 end;
end;

end.

