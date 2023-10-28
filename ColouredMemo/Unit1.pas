unit Unit1;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
 ColouredMemo, Unit2;

type

 { TForm1 }

 TForm1 = class(TForm)
  Button1: TButton;
  Button2: TButton;
  Button3: TButton;
  Button4: TButton;
  MyMemo: TColouredMemo;
  MyLabel: TColouredLabel;
  Panel1: TPanel;
  procedure Button1Click(Sender: TObject);
  procedure Button2Click(Sender: TObject);
  procedure Button3Click(Sender: TObject);
  procedure Button4Click(Sender: TObject);
  procedure FormCreate(Sender: TObject);
  procedure FormShow(Sender: TObject);
  procedure TestLines;
 private

 public

 end;

var
 Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
 MyMemo:=TColouredMemo.Create(Self);
 MyMemo.Parent:=Form1;
 MyMemo.Align:=alClient;
 MyMemo.Visible:=True;
 MyMemo.AutoScroll:=True;
 MyMemo.Font.Name:='Courier New';
 MyMemo.TextWrap:=True;
 MyLabel:=TColouredLabel.Create(Panel1);
 MyLabel.Parent:=Panel1;
 MyLabel.Visible:=True;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
 I: Integer;
 S,F: TDateTime;
begin
 S:=Now;
 for I:=0 to 99 do
 begin
  Caption:=IntToStr(I);//+' ('+IntToStr(MyMemo.Lines.Count)+')';
  TestLines;
  Application.ProcessMessages;
 end;
 F:=Now-S;
 Caption:=FormatDateTime('s.zzz',F);
end;

procedure TForm1.Button2Click(Sender: TObject);
var
 fontsize: Integer;
begin
 fontsize:=MyMemo.Font.Size;
 if fontsize=0 then fontsize:=10;
 MyMemo.Font.Size:=fontsize+1;
end;

procedure TForm1.Button3Click(Sender: TObject);
var
 fontsize: Integer;
begin
 fontsize:=MyMemo.Font.Size;
 if fontsize<9 then fontsize:=9;
 MyMemo.Font.Size:=fontsize-1;
end;

procedure TForm1.Button4Click(Sender: TObject);
var
 Index: Integer;
begin
 Form2.Memo1.Clear;
 Form2.Memo1.Lines.Add(MyLabel.PlainText);
 if Length(MyMemo.PlainText)>0 then
  for Index:=0 to Length(MyMemo.PlainText)-1 do
   Form2.Memo1.Lines.Add(MyMemo.PlainText[Index]);
 Form2.Show;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
 MyLabel.Caption:=cmColRed+'Testing'+cmColDefault+' just the label'#$0A+cmBold+'Along'+cmResetAll+' with '+cmHighYellow+'carriage return'+cmHighDefault;
 TestLines;
end;

procedure TForm1.TestLines;
begin
 MyMemo.Lines.Add('Some '+cmColRed   +'red'  +cmBold      +' bold'+cmResetAll+' text');
 MyMemo.Lines.Add('');
 MyMemo.Lines.Add('Some '+cmColBlue  +'blue' +cmItalic    +' italic'+cmResetAll+' text');
 MyMemo.Lines.Add('');
 MyMemo.Lines.Add('Some '+cmColGreen+'green'+cmBold+cmItalic+' bold italic'+cmResetAll+' text');
 MyMemo.Lines.Add('');
 MyMemo.Lines.Add('Some '+cmHighYellow+'highlighted'+cmHighDefault+' text');
 MyMemo.Lines.Add('');
 MyMemo.Lines.Add(cmUnder+'Some '+cmNoUnder+cmStrike+'more'+cmNoStrike+cmBold+' text'+cmResetAll);
 MyMemo.Lines.Add('');
 MyMemo.Lines.Add('Just a plain, boring, no style or coloured line');
end;

end.
