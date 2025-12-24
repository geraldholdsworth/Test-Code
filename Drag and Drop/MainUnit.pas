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
   procedure SetupControl(Ctrl: TImage); 
   procedure SetupControl(Ctrl: TPanel); overload;
   procedure FormKeyPress(Sender: TObject; var Key: char);
   procedure ControlMouseDown(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Integer);
   procedure ControlMouseMove(Sender:TObject;Shift:TShiftState;X,Y:Integer);
   procedure EndDrag;
   procedure ControlMouseUp(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Integer);
 private
  Fmouseisdown: Boolean;
  Fstart      : TPoint;
  Fimg        : TPoint;
  Fdragctrl   : TControl;
  Fparent     : TWinControl;
  FmaxscrollW : Integer;
  FmaxscrollH : Integer;
  const
   //Options for dragging icons
   ChangeParent = False; //Change of parent when control is dropped
   MoveHorz     = True;  //Allow horizontal movement
   MoveVert     = True;  //Allow vertical movement
 public

 end;

var
 MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

procedure TMainForm.ControlMouseDown(Sender: TObject; Button: TMouseButton;
 Shift: TShiftState; X, Y: Integer);
begin
 if not Fmouseisdown then
 begin
  //Make sure we remember which control is being dragged
  Fdragctrl:=TControl(Sender);
  //Set the flag to indicate the mouse button is pressed
  Fmouseisdown :=True;
  //Note the maximum work area
  FmaxscrollW:=0;
  FmaxscrollH:=0;
  //Form scroll bars
  if Fdragctrl.Parent is TForm then
  begin
   FmaxscrollW:=HorzScrollBar.Range;
   FmaxscrollH:=VertScrollBar.Range;
  end;
  //ScrollBox scroll bars
  if Fdragctrl.Parent is TScrollBox then
  begin
   FmaxscrollW:=TScrollBox(Fdragctrl.Parent).HorzScrollBar.Range;
   FmaxscrollH:=TScrollBox(Fdragctrl.Parent).VertScrollBar.Range;
  end;
  //Still at zero? Then get the client area
  if FmaxscrollW=0 then FmaxscrollW:=Fdragctrl.Parent.ClientWidth;
  if FmaxscrollH=0 then FmaxscrollH:=Fdragctrl.Parent.ClientHeight;
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
 end;
end;

procedure TMainForm.ControlMouseMove(Sender:TObject;Shift:TShiftState;X,Y:Integer);
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
  //Adjust for the scroll position
  if Fdragctrl.Parent is TForm then       //Form
  begin
   inc(P.X,HorzScrollBar.Position);
   inc(P.Y,VertScrollBar.Position);
  end;
  if Fdragctrl.Parent is TScrollBox then //ScrollBox
  begin
   inc(P.X,TScrollBox(Fdragctrl.Parent).HorzScrollBar.Position);
   inc(P.Y,TScrollBox(Fdragctrl.Parent).VertScrollBar.Position);
  end;
  //Make sure the mouse isn't off the parent control
  if P.X-Fstart.X<0 then P.X:=Fstart.X;
  if P.Y-Fstart.Y<0 then P.Y:=Fstart.Y;
  if P.X-Fstart.X+Fdragctrl.Width >FmaxscrollW then P.X:=FmaxscrollW-Fstart.X;
  if P.Y-Fstart.Y+Fdragctrl.Height>FmaxscrollH then P.Y:=FmaxscrollH-Fstart.Y;
  //Then move the control relative to where it was.
  if MoveHorz then Fdragctrl.Left:=P.X-Fstart.X;
  if MoveVert then Fdragctrl.Top :=P.Y-Fstart.Y;
  //Move the scroll bars, if needed
  if Fdragctrl.Parent is TForm then       //Form
   ScrollInView(Fdragctrl)
  else                                    //ScrollBox
   TScrollBox(Fdragctrl.Parent).ScrollInView(Fdragctrl);
 end;
end;

procedure TMainForm.EndDrag;
var
 F: TControl;
begin
 //Reset the flag
 Fmouseisdown :=False;
 //And change the mouse cursor back
 Fdragctrl.Cursor:=crDefault;
end;

procedure TMainForm.ControlMouseUp(Sender: TObject; Button: TMouseButton;
 Shift: TShiftState; X, Y: Integer);
var
 F,P: TWinControl; //Only TWinControl can have children
begin
 EndDrag;
 //Change of parent?
 if ChangeParent then
 begin
  Fdragctrl.Visible:=False; //Making the control invisible means it won't find itself
  F:=ControlAtPos(ScreenToClient(Mouse.CursorPos),
                  [capfAllowWinControls,capfOnlyWinControls]) as TWinControl;
  Fdragctrl.Visible:=True;
  //Do we have a control, that isn't already the control's parent?
  if(F<>nil)and(F<>Fdragctrl.Parent)then
  begin
   //Make it the parent
   P:=Fdragctrl.Parent;
   Fdragctrl.Parent:=F;
   //Compensate the position for the parent's position
   while F<>P do
   begin
    Fdragctrl.Left:=Fdragctrl.Left-F.Left;
    Fdragctrl.Top :=Fdragctrl.Top -F.Top;
    F:=F.Parent;
   end;
  end;
 end;
end;

//We can't use TObject as the three events are protected.
procedure TMainForm.SetupControl(Ctrl: Timage);
begin
 Ctrl.OnMouseDown:=@ControlMouseDown;
 Ctrl.OnMouseMove:=@ControlMouseMove;
 Ctrl.OnMouseUp  :=@ControlMouseUp;
end;
procedure TMainForm.SetupControl(Ctrl: TPanel);
begin
 Ctrl.OnMouseDown:=@ControlMouseDown;
 Ctrl.OnMouseMove:=@ControlMouseMove;
 Ctrl.OnMouseUp  :=@ControlMouseUp;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
 //Set the intial state of the mouse down flag
 Fmouseisdown:=False;
 //Set the events
 SetupControl(Image1);
 SetupControl(Image2);
 SetupControl(Image3);
 SetupControl(Panel1);
end;

procedure TMainForm.FormKeyPress(Sender: TObject; var Key: char);
begin
 if Fmouseisdown then
  if Key=#27 then //Pressing ESCAPE stops the drag operation
  begin
   EndDrag;
   //Put the control back where it started
   Fdragctrl.Left  :=Fimg.X;
   Fdragctrl.Top   :=Fimg.Y;
   Fdragctrl.Parent:=Fparent;
   Key:=#0;
  end;
end;

end.

