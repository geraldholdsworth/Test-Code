unit Unit1;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Types,ExtCtrls;

type

 { TForm1 }

 TForm1 = class(TForm)
  Image1: TImage;
  procedure FormContextPopup(Sender:TObject;MousePos:TPoint;var Handled:Boolean
   );
  procedure Image1ContextPopup(Sender:TObject;MousePos:TPoint;
   var Handled:Boolean);
 private

 public

 end;

var
 Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormContextPopup(Sender:TObject;MousePos:TPoint;
 var Handled:Boolean);
begin
 Handled:=True;
 Caption:='OnContextPopup '+IntToStr(MousePos.X)+','+IntToStr(MousePos.Y);
end;

procedure TForm1.Image1ContextPopup(Sender:TObject;MousePos:TPoint;
 var Handled:Boolean);
begin
 Handled:=True;
 Caption:='Image OnContextPopup '+IntToStr(MousePos.X)+','+IntToStr(MousePos.Y);
end;

end.

