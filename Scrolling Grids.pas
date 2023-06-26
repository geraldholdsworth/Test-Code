unit Unit1;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, Types;

type

 { TForm1 }

 TForm1 = class(TForm)
  StringGrid1: TStringGrid;
  procedure FormResize(Sender: TObject);
  procedure FormShow(Sender: TObject);
  procedure StringGrid1MouseWheel(Sender: TObject; Shift: TShiftState;
   WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
  procedure PopulateGrid;
 private
  ptr: Integer;
 public

 end;

var
 Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormShow(Sender: TObject);
begin
 ptr:=0;
 PopulateGrid;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
 StringGrid1.RowCount:=(StringGrid1.Height div StringGrid1.DefaultRowHeight)+1;
 PopulateGrid;
end;

procedure TForm1.StringGrid1MouseWheel(Sender: TObject; Shift: TShiftState;
 WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
 inc(ptr,WheelDelta div 240); //sensitivity: multiples of 120
 PopulateGrid;
 Handled:=True; //Make sure that the OS doesn't shift the position
end;

procedure TForm1.PopulateGrid;
var
 i,m: Integer;
begin
 m:=StringGrid1.VisibleRowCount;
 if StringGrid1.RowCount<m then m:=StringGrid1.RowCount;
 if ptr<0 then ptr:=0; //0 is the minimum (at the top)
 if ptr+StringGrid1.VisibleRowCount>5000 then
  ptr:=5000-StringGrid1.VisibleRowCount; //5000 is the maximum (at the bottom)
 for i:=0 to m-1 do StringGrid1.Cells[0,i]:=IntToStr(ptr+i);
end;

end.