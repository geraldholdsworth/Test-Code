unit Unit1;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
 RichMemo, RichMemoUtils;

type

 { TForm1 }

 TForm1 = class(TForm)
  Button1: TButton;
  Button2: TButton;
  Panel1: TPanel;
  RichMemo1: TRichMemo;
  procedure Button1Click(Sender: TObject);
  procedure Button2Click(Sender: TObject);
 private

 public

 end;

var
 Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
const
 LineNum = 1;
 KeyWord = 2;
 Quote   = 3;
 procedure InsertText(t: String; s: Byte=0);
 var
  c: TColor;
  f: TFontStyles;
 begin
  //Default
  c:=$FFFFFF;
  f:=[];
  case s of
   LineNum: //Line number
   begin
    c:=$00FF00;
    f:=[fsBold,fsItalic];
   end;
   KeyWord: //Keyword
   begin
    c:=$FFFF00;
    f:=[fsBold];
   end;
   Quote  : //Quote
   begin
    c:=$00FFFF;
    f:=[];
   end;
  end;
  InsertColorStyledText(RichMemo1,t,c,f);
 end;
begin
 if RichMemo1.Lines.Count=0 then RichMemo1.Lines.Add('')
 else InsertColorStyledText(RichMemo1,#$0D#$0A,clBlack,[]);//New Line
 InsertText('   10 ',LineNum);
 InsertText('FOR',KeyWord);
 InsertText(' X=0 ');
 InsertText('TO',KeyWord);
 InsertText(' 255 ');
 InsertText('STEP',KeyWord);
 InsertText(' 16');
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
 ShowMessage(RichMemo1.Text);
end;

end.