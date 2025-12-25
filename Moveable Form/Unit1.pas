unit Unit1;

{$mode objfpc}{$H+}

interface

uses
 Classes,SysUtils,Forms,Controls,Graphics,Dialogs,ExtCtrls,LCLType,LCLIntf;

type

 { TForm1 }

 TForm1 = class(TForm)
   Image1: TImage;
   procedure FormCreate(Sender: TObject);
   procedure FormDblClick(Sender: TObject);
   procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Integer);
   procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
   procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Integer);
 private
  MouseIsDown: Boolean;
  Start      : TPoint;
  Pos        : TPoint;
 public

 end;

var
 Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure CreateRegion(const AIm:TImage;const AMaskColour:TColor;out ARegion:HRGN);
var
 X1          : Integer=0;
 X2          : Integer=0;
 Y           : Integer=0;
 Colour      : TColor=clNone;
 DeleteRegion: HRGN=0;
begin
 ARegion:=CreateRectRgn(0,0,AIm.Width,AIm.Height);
 for Y:=0 to AIm.Picture.Bitmap.Height-1 do
 begin
  X1:=0;
  X2:=0;
  repeat
   if(X2<=AIm.Picture.Bitmap.Width-1)and(Y<=AIm.Picture.Bitmap.Height-1)then
    Colour:=AIm.Picture.Bitmap.Canvas.Pixels[X2,Y]
   else
    Colour:=-1;
   if Colour<>AMaskColour then
   begin
    if X1<>X2 then
    begin
     DeleteRegion:=CreateRectRgn(X1,Y,X2,Y+1);
     try
      CombineRgn(ARegion,ARegion,DeleteRegion,RGN_DIFF);
     finally
      DeleteObject(DeleteRegion);
     end;
    end;
    Inc(X2);
    X1 := X2;
   end
   else
    Inc(X2);
  until (Colour=-1);
 end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
 FormRegion: HRGN=0;
begin
 //This bit should make the form transparent. But it doesn't work on macOS
 CreateRegion(Image1,Color,FormRegion);
 SetWindowRgn(Form1.Handle,FormRegion,True);
 //Makes the form draggable.
 MouseIsDown:=False;
 Image1.OnMouseDown:=@FormMouseDown;
 Image1.OnMouseMove:=@FormMouseMove;
 Image1.OnMouseUp  :=@FormMouseUp;
 Image1.OnDblClick :=@FormDblClick;
end;

procedure TForm1.FormDblClick(Sender: TObject);
begin
 Application.Terminate;
end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
 Shift: TShiftState; X, Y: Integer);
begin
 if not MouseIsDown then
 begin
  Start.X:=Mouse.CursorPos.X;
  Start.Y:=Mouse.CursorPos.Y;
  Pos.X:=Left;
  Pos.Y:=Top;
  MouseIsDown:=True;
  AlphaBlendValue:=128;
 end;
end;

procedure TForm1.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
 Y: Integer);
begin
 if MouseIsDown then
 begin
  Left:=(Mouse.CursorPos.X-Start.X)+Pos.X;
  Top :=(Mouse.CursorPos.Y-Start.Y)+Pos.Y;
 end;
end;

procedure TForm1.FormMouseUp(Sender: TObject; Button: TMouseButton;
 Shift: TShiftState; X, Y: Integer);
begin
 MouseIsDown:=False;
 AlphaBlendValue:=255;
end;

end.

