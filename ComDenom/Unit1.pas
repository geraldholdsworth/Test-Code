unit Unit1;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls;

type

 { TForm1 }

 TForm1 = class(TForm)
  Button1: TButton;
  Edit1: TEdit;
  Edit2: TEdit;
  Memo1: TMemo;
  Panel1: TPanel;
  procedure Button1Click(Sender: TObject);
 private

 public

 end;

var
 Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
var
 x,sx,cnt,
 num,den,
 srcSize,
 dstSize : Integer;
procedure AddPixel;
begin
 if cnt<dstSize then
 begin
  Memo1.Lines.Add(IntToStr(cnt)+' : '+IntToStr(x));
  inc(cnt);
 end else Memo1.Lines.Add('Error');
end;
begin
 srcSize:=StrToIntDef(Edit1.Text,16);
 dstSize:=StrToIntDef(Edit2.Text,12);
 Memo1.Clear;
 Memo1.Lines.Add('Source = '+IntToStr(srcSize));
 Memo1.Lines.Add('Destination = '+IntToStr(dstSize));
 den:=dstSize;
 while (dstSize/den<>dstSize div den)
   or (srcSize/den<>srcSize div den) do
  dec(den);
 num:=dstSize div den;
 den:=srcSize div den;
 Memo1.Lines.Add('num = '+IntToStr(num));
 Memo1.Lines.Add('den = '+IntToStr(den));
 if num>den then
  Memo1.Lines.Add('num mod den = '+IntToStr(num mod den));
 cnt:=0;
 for x:=0 to srcSize-1 do
 begin
  if x mod den<num then AddPixel;
  if num>den then
  begin
   if num mod den>0 then
   begin
    for sx:=0 to (num div den)-2 do AddPixel;
    if x mod den=den-1 then for sx:=0 to (num mod den)-1 do AddPixel;
   end
   else for sx:=den to num-1 do AddPixel;
  end;
 end;
end;

end.

