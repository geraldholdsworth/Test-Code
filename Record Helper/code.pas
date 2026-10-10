program Project1;

{$mode objfpc}{$H+}
{$MODESWITCH ADVANCEDRECORDS}

{for type helpers, use {$modeswitch TypeHelpers} }

uses
 {$IFDEF UNIX}
 cthreads,
 {$ENDIF}
 Classes,
 SysUtils
 { you can add units after this };

type
  TMaths = record
   a,b: Integer;
  end;
type
  TMathsHelper = record helper for TMaths
   function Add: Integer;
   function Subtract: Integer;
   function Multiply: Integer;
   function Divide: Real;
  end;

function TMathsHelper.Add: Integer;
begin
 Result:=Self.a+Self.b;
end;

function TMathsHelper.Subtract: Integer;
begin
 Result:=Self.a-Self.b;
end;
function TMathsHelper.Multiply: Integer;
begin
 Result:=Self.a*Self.b;
end;
function TMathsHelper.Divide: Real;
begin
 Result:=Self.a/Self.b;
end;

var
 M: TMaths;
begin
 WriteLn('Assign numbers');
 M.a:=45;
 M.b:=56;
 WriteLn('Add: '+IntToStr(M.Add));
 WriteLn('Subtract: '+IntToStr(M.Subtract));
 WriteLn('Multiply: '+IntToStr(M.Multiply));
// WriteLn('Divide: '+RealToStr(M.Divide));
end.