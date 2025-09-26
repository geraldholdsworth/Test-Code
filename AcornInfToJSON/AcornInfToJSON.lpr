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
 elements: TStringArray=();
 fields  : TStringArray=();
 index   : Integer=0;
 //De Quote a string (different to the string helper DeQuotedString)
 function DeQuote(input: String): String;
 begin
  Result:=input;
  if Length(input)>1 then
   if(input[1]='"')and(input[Length(input)]='"')then
    Result:=Copy(input,2,Length(input)-2);
 end;
 //Parse a string according, dequoting and percent decoding
 function ParseString(input: String): String;
 begin
  //Remove any quotes, and de-escape quotes contained
  Result:=DeQuote(input);
  //Inside of quotes, then put it through HTTP Decoding
  if Result<>input then Result:=HTTPDecode(Result); //Opposite is HTTPEncode
 end;
 //Validate the input string as a valid hex number. Return 0 if not.
 function ValidateHex(input: String;len: Integer=8): String;
 begin
  Result:=IntToHex(StrToIntDef('$'+input,0),len);
 end;
begin
 //Start with an empty output container
 Result:=TJSONObject.Create;
 //Do we have a 'CRC= '?
 line:=StringReplace(line,'CRC= ','CRC=',[rfReplaceAll]);
 //Only act on it if it is not blank
 if not line.IsEmpty then
  //Split the string into separate words, but not within quotes
  elements:=line.Split(' ','"');
  //Iterate through the elements
  for element in elements do //To add non-blank elements
   if not element.IsEmpty then Insert(element,fields,Length(fields));
  //Only continue if there is something to show
  if Length(fields)>0 then
  begin
   //Add the elements in the inf order
   Result.Add('Filename',ParseString(fields[0]));             //Filename
   element:='00000000';
   if Length(fields)>1 then element:=ValidateHex(fields[1]);
   Result.Add('Load Address','0x'+element);                   //Load Address
   element:='00000000';
   if Length(fields)>2 then element:=ValidateHex(fields[2]);
   Result.Add('Exec Address','0x'+element);                   //Execution Address
   element:='00000000';
   if Length(fields)>3 then element:=ValidateHex(fields[3],6);
   Result.Add('Length','0x'+element);                         //Length
   element:='';
   if Length(fields)>4 then element:=fields[4];
   Result.Add('Access',element);                              //Access attributes
   //Extra info - should be KEY=VALUE style
   if Length(fields)>5 then
    for index:=5 to Length(fields)-1 do
     if Pos('=',fields[index])>0 then
     begin //Split the string around '='...even if inside quotes
      elements:=fields[index].Split('=');
      //And add the result to the JSON - we're only interested in first 2
      Result.Add(ParseString(elements[0]),ParseString(elements[1]));
     end
     else //If not, we'll just use a generic field name
      Result.Add('Field '+IntToStr(index),ParseString(fields[index]));
  end;
end;

var
 line : String='';
 JAB  : TJSONObject;
begin
 Write(#$1B'[91m'#$1B'[7m');
 WriteLn(StringOfChar('*',80));
 Write(#$1B'[0m'#$1B'[1m');
 WriteLn('*.inf to JSON converter by Gerald J Holdsworth');
 WriteLn();
 WriteLn(#$1B'[0m');
 WriteLn(#$1B'[92mPress ENTER on an empty line to exit'#$1B'[0m');
 WriteLn(#$1B'[1m Filename LoadAddr ExecAddr Length Access Extra-fields'#$1B'[0m');
 repeat
   Write(#$1B'[1m>'#$1B'[0m');
   ReadLn(line);
   if Trim(line)<>'' then
   begin
    JAB:=BreakDownInf(line);
    WriteLn('');
    WriteLn(#$1B'[1mResult'#$1B'[0m');
    WriteLn(#$1B'[94m'+JAB.FormatJSON+#$1B'[0m');//AsJSON returns it in one line
    JAB.Free;
   end;
 until Trim(line)='';
end.

