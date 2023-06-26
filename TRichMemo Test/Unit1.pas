unit Unit1;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
 RichMemo;

type

 { TForm1 }

 TForm1 = class(TForm)
  Button1: TButton;
  Panel1: TPanel;
  RichMemo1: TRichMemo;
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
 procedure AddColorStr(s: string; const col: TColor=clBlack;
                                                   const NewLine: boolean=true);
 begin
  with RichMemo1 do
  begin
   if NewLine then
   begin
    if RichMemo1.Lines.Count=0 then
    begin
     RichMemo1.Lines.Add('');
     Lines.Delete(Lines.Count-1);
    end
    else AddColorStr(#$0D#$0A,clBlack,False);
   end;
   SelStart :=Length(Text);
   SelText  :=s;
   SelLength:=Length(s);
   SetRangeColor(SelStart,SelLength,col);
   SelStart :=Length(Text);
   SelText  :='';
  end;
 end;
begin
 AddColorStr('Black, ');
 AddColorStr('Green, '  ,$00FF00,false);
 AddColorStr('Blue, '   ,$FF0000,false);
 AddColorStr('Red, '    ,$0000FF,false);
 AddColorStr('Yellow, ' ,$00FFFF,False);
 AddColorStr('Magenta, ',$FF00FF,false);
 AddColorStr('Cyan, '   ,$FFFF00,false);
 AddColorStr('Black, '  ,$000000,false);
 AddColorStr('Green, '  ,$00FF00,false);
 AddColorStr('Blue, '   ,$FF0000,false);
 AddColorStr('Red, '    ,$0000FF,false);
 AddColorStr('Yellow, ' ,$00FFFF,False);
 AddColorStr('Magenta, ',$FF00FF,false);
 AddColorStr('Cyan'     ,$FFFF00,false);
end;

end.
