unit Unit1;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
 ExtCtrls, Buttons;

type

 { TForm1 }

 TForm1 = class(TForm)
  Control: TPanel;
  Label1: TLabel;
  Label2: TLabel;
  Label3: TLabel;
  Page1: TPanel;
  Page2: TPanel;
  Page3: TPanel;
  Tabs: TPanel;
  procedure Button1Click(Sender: TObject);
  procedure FormCreate(Sender: TObject);
  procedure FormShow(Sender: TObject);
 private

 public
  Pages : array[0..2] of TPanel;
  PageTab:array[0..2] of TLabel;
 end;

var
 Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
var
 Index: Integer;
begin
 for Index:=0 to 2 do
 begin
  Pages[Index].Visible:=False;
  PageTab[Index].Color:=clBlue;
 end;
 Pages[TLabel(Sender).Tag].Visible:=True;
 PageTab[TLabel(Sender).Tag].Color:=clNavy;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 Pages[0]:=Page1;
 Pages[1]:=Page2;
 Pages[2]:=Page3;
 PageTab[0]:=Label1;
 PageTab[1]:=Label2;
 PageTab[2]:=Label3;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
 Page1.Visible:=True;
 Page2.Visible:=False;
 Page3.Visible:=False;
 Label1.Color:=clNavy;
 Label2.Color:=clBlue;
 Label3.Color:=clBlue;
end;

end.

