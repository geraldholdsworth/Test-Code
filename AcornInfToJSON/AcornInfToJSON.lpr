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
   if(input[1]='"')and(input.EndsWith('"'))then
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
 function ValidateHex(input: String): String;
 begin
  Result:=IntToHex(StrToIntDef('$'+input,0),8);
 end;
 //Check for a Key=Value
 function CheckForKeyValue(input: String): Boolean;
 begin
  Result:=Pos('=',input)>0;
 end;
 //Get a KEY=VALUE
 function GetKeyValue(input: String): TStringArray;
 begin
  if CheckForKeyValue(input) then Result:=input.Split('=');
 end;
 //Parse a field
 procedure ParseField(num: Integer; name: String; Ltype: Byte);
 var
  value: String='';
  keyval : TStringArray=();
 begin
  //Are there enough fields?
  if Length(fields)>num then
  begin
   //Default values
   if Ltype=0 then value:='';         //String
   if Ltype=1 then value:='00000000'; //Hex
   //Is it a key=value
   if not CheckForKeyValue(fields[num]) then
   begin //No
    if Ltype=0 then value:=ParseString(fields[num]); //Parse a string
    if Ltype=1 then value:=ValidateHex(fields[num]); //Parse a hex
   end
   else
   begin //Yes
    //Get the Key and Value
    keyval:=GetKeyValue(fields[num]);
    //Assign them
    name  :=ParseString(keyval[0]);
    value :=ParseString(keyval[1]);
   end;
   //Add the result to the JSON...only if there is a value
   Result.Add(name,value);
   WriteLn(#$1B'[94m'+name+#$1B'[0m : '#$1B'[94m'+value+#$1B'[0m'); //REMOVE THIS FOR PRODUCTION
  end;
 end;
//Known field names (Filename is first)
const
 Field: array[0..9] of String=('LoadAddress'
                              ,'ExecutionAddress'
                              ,'Length'
                              ,'Access'
                              ,'ModificationDate'
                              ,'ModificationTime'
                              ,'CreationDate'
                              ,'CreationTime'
                              ,'UserAccount'
                              ,'AuxliiaryAccount');
 //And their type (0=String, 1=Hex);
 FieldType: array[0..9] of Integer=(1,1,1,0,0,0,0,0,0,0);
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
   ParseField(0,'Filename',0); //Filename is always first
   if Length(fields)>1 then
    for Index:=1 to Length(fields)-1 do
     if Index<Length(Field) then //Known field (above)
      ParseField(Index,Field[Index-1],FieldType[Index-1])
     else                        //Extra field
      ParseField(Index,'Field '+IntToStr(Index),0);
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
 WriteLn('Version 0.02');
 WriteLn(#$1B'[0m');
 WriteLn(#$1B'[92mPress ENTER on an empty line to exit'#$1B'[0m');
 repeat
   Write(#$1B'[1m>'#$1B'[0m');
   ReadLn(line);
   if Trim(line)<>'' then
   begin
    WriteLn(#$1B'[1mResult'#$1B'[0m');
    JAB:=BreakDownInf(line);
    WriteLn(#$1B'[1mJSON Output'#$1B'[0m');
    WriteLn(#$1B'[94m'+JAB.FormatJSON+#$1B'[0m');//AsJSON returns it in one line
    JAB.Free;
   end;
 until Trim(line)='';
end.

