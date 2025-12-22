unit MainUnit;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls,LCLType;

type

 { TMainForm }

 TMainForm = class(TForm)
   Image1: TImage;
   Image2: TImage;
   Image3: TImage;
   Panel1: TPanel;
   procedure FormCreate(Sender: TObject);
   procedure FormKeyPress(Sender: TObject; var Key: char);
   procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Integer);
   procedure Image1MouseMove(Sender:TObject;Shift:TShiftState;X,Y:Integer);
   procedure Image1MouseUp(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Integer);
 private
  Fmouseisdown: Boolean;
  Fstart      : TPoint;
  Fimg        : TPoint;
  Fdragctrl   : TControl;
  Fparent     : TWinControl;
 public

 end;

var
 MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

procedure TMainForm.Image1MouseDown(Sender: TObject; Button: TMouseButton;
 Shift: TShiftState; X, Y: Integer);
begin
 //Make sure we remember which control is being dragged
 Fdragctrl:=TControl(Sender);
 //Set the flag to indicate the mouse button is pressed
 Fmouseisdown :=True;
 //Change the mouse cursor
 Fdragctrl.Cursor:=crDrag;
 //X and Y will be the position within the control of the mouse pointer
 Fstart.X     :=X;
 Fstart.Y     :=Y;
 //Make a note of the original position, within the parent control
 Fimg.X       :=Fdragctrl.Left;
 Fimg.Y       :=Fdragctrl.Top;
 Fparent      :=Fdragctrl.Parent;
 //Bring the control to the top
 Fdragctrl.BringToFront;
 //*****************************************************************************
 //NOTE: BringToFront will still keep the image behind the panel, and therefore
 //inaccessible to being clicked on.
 //
 //Possible solution: create a TPanel and make the image it's child. Then move
 //the panel around, keeping to the front, until it is placed then return it to
 //the original parent (or new parent, if required and over the top of it).
 //The Panel should be the exact same size as the Image, with no borders or
 //bevels. The image should be Left=0, Top=0.
 //*****************************************************************************
end;

procedure TMainForm.Image1MouseMove(Sender:TObject;Shift:TShiftState;X,Y:Integer);
var
 P: TPoint;
 F: TWinControl;
begin
 if Fmouseisdown then
 begin
  //X and Y will still be the position within the control. But, as we've moved
  //it, this will change. So we need to get the mouse position within the form.
  P:=ScreenToClient(Mouse.CursorPos);
  //Compensate for any parent controls
  F:=Fdragctrl.Parent;
  while not(F is TForm) do
  begin
   dec(P.X,F.Left);
   dec(P.Y,F.Top);
   F:=F.Parent;
  end;
  //Make sure the mouse isn't off the parent control
  if P.X<0 then P.X:=0;
  if P.Y<0 then P.Y:=0;
  if P.X>Fdragctrl.Parent.ClientWidth  then
   P.X:=Fdragctrl.Parent.ClientWidth;
  if P.Y>Fdragctrl.Parent.ClientHeight then
   P.Y:=Fdragctrl.Parent.ClientHeight;
  //Then move the control relative to where it was.
  Fdragctrl.Left:=P.X-Fstart.X;
  Fdragctrl.Top :=P.Y-Fstart.Y;
 end;
end;

procedure TMainForm.Image1MouseUp(Sender: TObject; Button: TMouseButton;
 Shift: TShiftState; X, Y: Integer);
var
 F: TControl;
begin
 //Reset the flag
 Fmouseisdown :=False;
 //And change the mouse cursor back
 Fdragctrl.Cursor:=crDefault;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
 //Set the intial state of the mouse down flag
 Fmouseisdown:=False;
 //Set the events
 Image1.OnMouseDown:=@Image1MouseDown;
 Image1.OnMouseMove:=@Image1MouseMove;
 Image1.OnMouseUp  :=@Image1MouseUp;
 Image2.OnMouseDown:=@Image1MouseDown;
 Image2.OnMouseMove:=@Image1MouseMove;
 Image2.OnMouseUp  :=@Image1MouseUp;
 Image3.OnMouseDown:=@Image1MouseDown;
 Image3.OnMouseMove:=@Image1MouseMove;
 Image3.OnMouseUp  :=@Image1MouseUp;
 Panel1.OnMouseDown:=@Image1MouseDown;
 Panel1.OnMouseMove:=@Image1MouseMove;
 Panel1.OnMouseUp  :=@Image1MouseUp;
end;

procedure TMainForm.FormKeyPress(Sender: TObject; var Key: char);
begin
 if Fmouseisdown then
  if Key=#27 then //Pressing ESCAPE stops the drag operation
  begin
   //Reset the flag
   Fmouseisdown :=False;
   //And change the mouse cursor back
   Fdragctrl.Cursor:=crDefault;
   //Put the control back where it started
   Fdragctrl.Left  :=Fimg.X;
   Fdragctrl.Top   :=Fimg.Y;
   Fdragctrl.Parent:=Fparent;
  end;
end;

end.

