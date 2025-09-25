program AcornInfToJSON;

{$mode objfpc}{$H+}
{$modeswitch TypeHelpers}

uses
 {$IFDEF UNIX}
 cthreads,
 {$ENDIF}
 Classes,SysUtils,StrUtils,HTTPProtocol,fpjson;

function BreakDownInf(line: String): TJSONObject;
var
 element : String='';
 temp    : String='';
 elements: TStringArray=();
 fields  : TStringArray=();
 index   : Integer=0;
begin
 //Start with an empty output container
 Result:=TJSONObject.Create;
 //Convert /" to ""
 line:=StringReplace(line,'/"','""',[rfReplaceAll]);
 //Only act on it if it is not blank
 if not line.IsEmpty then
  //Split the string into separate words, but not within quotes
  elements:=line.Split(' ','"');
  SetLength(temp,0);
  //Iterate through the elements
  for element in elements do
   //If an element is not blank
   if not element.IsEmpty then
   begin
    //Remove any quotes, and de-escape quotes contained
    temp:=element.DeQuotedString('"'); //Opposite is QuotedString('"')
    //Outside of quotes, then put it through HTTP Decoding
    if temp<>element then temp:=HTTPDecode(temp); //Opposite is HTTPEncode
    //Add to the output container, if not empty
    if not temp.IsEmpty then Insert(temp,fields,Length(fields));
   end;
  //Only continue if there is something to show
  if Length(fields)>0 then
  begin
   //Add the elements in the inf order
   Result.Add('Filename',fields[0]);
   element:='00000000';
   if Length(fields)>1 then element:=IntToHex(StrToIntDef('$'+fields[1],0),8);
   Result.Add('Load Address','0x'+element);
   element:='00000000';
   if Length(fields)>2 then element:=IntToHex(StrToIntDef('$'+fields[2],0),8);
   Result.Add('Exec Address','0x'+element);
   element:='00000000';
   if Length(fields)>3 then element:=IntToHex(StrToIntDef('$'+fields[3],0),8);
   Result.Add('Length','0x'+element);
   element:='';
   if Length(fields)>4 then element:=fields[4];
   Result.Add('Access',element);
   //Extra info - should be KEY=VALUE style
   if Length(fields)>5 then
    for index:=5 to Length(fields)-1 do
    begin
     if Pos('=',fields[index])>0 then
      Result.Add(LeftStr(fields[index],Pos('=',fields[index])-1)
                ,Copy(fields[index],Pos('=',fields[index])+1))
     else //If not, we'll just use a generic field name
      Result.Add('Field '+IntToStr(index),fields[index]);
    end;
  end;
end;

var
 line : String='';
 e    : String='';
 JAB  : TJSONObject;
begin
 Write(#$1B'[91m'#$1B'[7m');
 WriteLn(StringOfChar('*',80));
 Write(#$1B'[0m'#$1B'[1m');
 WriteLn('*.inf to JSON converter by Gerald J Holdsworth');
 WriteLn();
 WriteLn(#$1B'[0m');
 WriteLn(#$1B'[92mPress ENTER on an empty line to exit'#$1B'[0m');
 repeat
   Write(#$1B'[1m>'#$1B'[0m');
   ReadLn(line);
   if Trim(line)<>'' then
   begin
    JAB:=BreakDownInf(line);
    WriteLn('');
    WriteLn(#$1B'[1mResult'#$1B'[0m');
    WriteLn(#$1B'[94m'+JAB.AsJSON+#$1B'[0m');
    JAB.Free;
   end;
 until Trim(line)='';
end.

