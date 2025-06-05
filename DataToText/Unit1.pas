unit Unit1;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs;

type

 { TForm1 }

 TForm1 = class(TForm)
  SaveDialog1: TSaveDialog;
  procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
 private

 public

 end;

var
 Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormDropFiles(Sender: TObject; const FileNames: array of string
 );
var
 outbyte,
 input,output: String;
 FIn,FOut: TFileStream;
 counter,
 b: Byte;
begin
 SaveDialog1.FileName:=ExtractFilename(FileNames[0])+'.txt';
 if SaveDialog1.Execute then
 begin
  input:=FileNames[0];
  output:=SaveDialog1.FileName;
  FIn:=TFileStream.Create(input,fmOpenRead);
  FOut:=TFileStream.Create(output,fmCreate);
  outbyte:=ExtractFilename(FileNames[0]);
  for counter:=1 to Length(outbyte) do
   if(outbyte[counter]='.')
   or(outbyte[counter]=' ')then outbyte[counter]:='_';
  outbyte:='const F'+outbyte+': array[0..'+IntToStr(FIn.Size-1)+'] of Byte=(';
  for counter:=1 to Length(outbyte) do FOut.WriteByte(Ord(outbyte[counter]));
  FOut.WriteByte($0A);
  counter:=0;
  while FIn.Position<FIn.Size do
  begin
   b:=FIn.ReadByte;
   outbyte:=IntToHex(b,2);
   FOut.WriteByte(Ord('$'));
   FOut.WriteByte(Ord(outbyte[1]));
   FOut.WriteByte(Ord(outbyte[2]));
   if Fin.Position<>FIn.Size then FOut.WriteByte(Ord(','))
   else
   begin
    FOut.WriteByte(Ord(')'));
    FOut.WriteByte(Ord(';'));
   end;
   inc(counter);
   if counter=20 then
   begin
    FOut.WriteByte($0A);
    counter:=0;
   end;
  end;
  FIn.Free;
  FOut.Free;
 end;
end;

end.

