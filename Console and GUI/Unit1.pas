unit Unit1;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

 { TForm1 }

 TForm1 = class(TForm)
  Memo1: TMemo;
  procedure FormShow(Sender: TObject);
  function ParseCommand(long: String; short: Char; multiple: Boolean;var fields: TStringArray): String;
 private

 public

 end;

var
 Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormShow(Sender: TObject);
const
 cmds: array[0..6] of array[0..1] of String = (
 ('add','a:+'),
 ('create','f:+'),
 ('another','n: '),
 ('rename','r: '),
 ('console','c: '),
 ('single','i  '),
 ('short','s: '));
var
 short,
 long   : String;
 i,j    : Integer;
 fields : TStringArray;
begin
 fields:=nil;
 SetLength(fields,0);
 short:='';
 long:='';
 for i:=0 to Length(cmds)-1 do
 begin
  short:=short+cmds[i,1][1];
  long:=long+cmds[i,0];
  if cmds[i,1][2]=':' then
  begin
   short:=short+':';
   long:=long+':';
  end;
  if i<Length(cmds)-1 then long:=long+' ';
 end;
 Memo1.Lines.Add('Errors: '+Application.CheckOptions(short,long));
 Memo1.Lines.Add('===============================');
 for i:=0 to Length(cmds)-1 do
 begin
  long:=ParseCommand(cmds[i,0],cmds[i,1][1],cmds[i,1][3]='+',fields);
  if long<>'' then
  begin
   Memo1.Lines.Add('Command: '+long);
   if Length(fields)>0 then
    for j:=0 to Length(fields)-1 do
     Memo1.Lines.Add('Parameter '+IntToStr(j)+': '+fields[j]);
   Memo1.Lines.Add('------------------');
  end;
 end;
end;

function TForm1.ParseCommand(long: String; short: Char; multiple: Boolean; var fields: TStringArray): String;
var
 expflds : TStringArray;
 i,j     : Integer;
 tmp     : PChar;
begin
 Result:='';
 fields:=nil;
 SetLength(fields,0);
 expflds:=nil;
 SetLength(expflds,0);
 if Application.HasOption(short,long) then
 begin
  Result:=long;
  if multiple then fields:=Application.GetOptionValues(short,long)
  else
  begin
   SetLength(fields,1);
   fields[0]:=Application.GetOptionValue(short,long);
  end;
  if Length(fields)>0 then
  begin
   SetLength(expflds,Length(fields));
   for i:=0 to Length(fields)-1 do expflds[i]:=fields[i];
   for i:=0 to Length(expflds)-1 do fields[i]:=expflds[(Length(expflds)-i)-1];
   i:=0;
   while i<Length(fields) do
   begin
    if fields[i]<>'' then
    begin
     SetLength(expflds,0);
     expflds:=fields[i].Split('|','"');
     if Length(expflds)>0 then
     begin
      for j:=0 to Length(expflds)-1 do
      begin
       tmp:=PChar(expflds[j]);
       expflds[j]:=AnsiExtractQuotedStr(tmp,'"');
      end;
      SetLength(fields,Length(fields)+Length(expflds)-1);
      for j:=Length(fields)-1 downto i+1 do fields[j]:=fields[j-Length(expflds)+1];
      for j:=0 to Length(expflds)-1 do fields[i+j]:=expflds[j];
      inc(i,Length(expflds)-1);
     end;
    end;
    inc(i);
   end;
  end;
 end;
 if Length(fields)=1 then if fields[0]='' then SetLength(fields,0);
end;

end.

