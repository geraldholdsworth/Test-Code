program AcornInfToJSON;

{$mode objfpc}{$H+}
{$modeswitch TypeHelpers}

uses
 {$IFDEF UNIX}
 cthreads,
 {$ENDIF}
 Classes,SysUtils,StrUtils,
 HTTPProtocol,fpjson,DOM,XMLWrite; //Need these

//Class helper for XML documents
type
  TXMLHelper = type helper for TXMLDocument
    procedure Add(name,value: String);
    function AsString: String;
  end;

{-------------------------------------------------------------------------------
Adds an element to the XML tree
-------------------------------------------------------------------------------}
procedure TXMLHelper.Add(name, value: String);
var
 Parent: TDOMNode=nil;
 LChar : Integer=0;
const
 //Allowed characters in an XML node name
 AllowedChars='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_-.';
begin
 //Validate the value (no control characters)
 for LChar:=0 to 31 do value:=StringReplace(value,chr(LChar),'_',[rfReplaceAll]);
 //Validate the name (only the characters above are allowed)
 for LChar:=1 to Length(name) do
  if Pos(name[LChar],AllowedChars)=0 then
   name:=StringReplace(name,name[LChar],'_',[rfReplaceAll]);
 //Create the parent
 Parent:=self.CreateElement(UnicodeString(name));
 //Create and append the value
 Parent.AppendChild(self.CreateTextNode(UnicodeString(value)));
 //Add it to the document
 self.DocumentElement.AppendChild(Parent);
end;

{-------------------------------------------------------------------------------
Outputs the XML document as a string
-------------------------------------------------------------------------------}
function TXMLHelper.AsString: String;
var
 S: TStringStream;
begin
 //Set up the string stream
 S:=TStringStream.Create;
 //Output the XML to the stream
 WriteXMLFile(self,S);
 //Reset to the start
 S.Position:=0;
 //And output as a string
 Result:=Trim(S.ReadString(S.Size));
 //Clear up
 S.Free;
end;

{-------------------------------------------------------------------------------
Parses an inf (passed in line) and outputs as JSON (passed in output)
-------------------------------------------------------------------------------}
procedure ParseInf(output: TObject; line: String);
var
 element : String='';
 elements: TStringArray=();
 fields  : TStringArray=();
 index   : Integer=0;
 start   : Integer=1;
 offset  : Integer=0;
const
 //Known field names (Filename is first)
 Field: array[0..9] of String=('Load Address'
                              ,'Execution Address'
                              ,'Length'
                              ,'Access'
                              ,'Modification Date'
                              ,'Modification Time'
                              ,'Creation Date'
                              ,'Creation Time'
                              ,'User Account'
                              ,'Auxliiary Account');
 //And their type (0=String, 1=Hex);
 FieldType: array[0..9] of Integer=(1,1,1,0,1,1,1,1,1,1);
 //De Quote a string (different to the string helper DeQuotedString) -----------
 function DeQuote(input: String): String;
 begin
  Result:=input;
  if Length(input)>1 then
   if(input[1]='"')and(input.EndsWith('"'))then
    Result:=Copy(input,2,Length(input)-2);
 end;
 //Parse a string according, dequoting and percent decoding --------------------
 function ParseString(input: String): String;
 begin
  //Remove any quotes, and de-escape quotes contained
  Result:=DeQuote(input);
  //Inside of quotes, then put it through HTTP Decoding
  if Result<>input then Result:=HTTPDecode(Result); //Opposite is HTTPEncode
 end;
 //Validate the input string as a valid hex number. Return 0 if not ------------
 function ValidateHex(input: String): String;
 begin
  Result:=IntToHex(StrToIntDef('$'+input,0),8);
 end;
 //Check for a Key=Value -------------------------------------------------------
 function CheckForKeyValue(input: String): Boolean;
 begin
  Result:=Pos('=',input)>0;
 end;
 //Get a KEY=VALUE -------------------------------------------------------------
 function GetKeyValue(input: String): TStringArray;
 begin
  Result:=[];
  if CheckForKeyValue(input) then Result:=input.Split('=');
 end;
 //Parse a field ---------------------------------------------------------------
 procedure ParseField(num: Integer; name: String; Ltype: Byte);
 var
  value : String='';
  keyval: TStringArray=();
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
   //Add the result to the output
   if output is TJSONObject then
    (output as TJSONObject).Add(name,value); //JSON output
   if output is TXMLDocument then
    (output as TXMLDocument).Add(name,value);//XML output
  end;
 end;
//Main procedure definition ----------------------------------------------------
begin
 if(output is TJSONObject)
 or(output is TXMLDocument)then
 begin
  //Do we have a 'CRC= '?
  line:=StringReplace(line,'CRC= ','CRC=',[rfReplaceAll]);
  //Only act on it if it is not blank
  if not line.IsEmpty then
  begin
   //Split the string into separate words, but not within quotes
   elements:=line.Split(' ','"');
   //Iterate through the elements
   for element in elements do //To add non-blank elements
    if not element.IsEmpty then Insert(element,fields,Length(fields));
   //Only continue if there is something to show
   if Length(fields)>0 then
   begin
    //Add the elements in the inf order
    if DeQuote(fields[0])='TAPE' then start:=1 else start:=0;
    ParseField(start,'Filename',0); //Filename
    offset:=0;
    if Length(fields)>start+1 then
     for Index:=start+1 to Length(fields)-1 do
      if Index<Length(Field) then //Known field (above)
      begin
       //Syntax 1 is <filename> <load> <exec> <access> <extra info> : for DFS
       if(Index=start+3)and(Length(fields)>start+3)then
        if(fields[Index]='Locked')or(UpperCase(fields[Index])='L')
        or(fields[Index]='00')    or(fields[index]='08')then offset:=1;
       //Syntax 3 is <filename> <access> <extra info> : for directories
       if(Index=start+1)and(Length(fields)>start+1)then
        if((Length(fields[index])=2) and(StrToIntDef(fields[index],$FFF)<>$FFF))
        or((Pos('=',fields[index])=0)and(StrToIntDef(fields[index],$FFF)=$FFF)
        and(UpperCase(fields[index])<>'FFF'))then
         offset:=3;
       //Everything else - syntax 2
       ParseField(Index,Field[offset+Index-(start+1)],FieldType[offset+Index-(start+1)]);
      end
      else                        //Extra field
       ParseField(Index,'Field '+IntToStr(Index),0);
   end;
  end;
 end;
end;

//Used for testing out the above - not needed in production
var
 line : String='';
 JAB  : TJSONObject=nil;
 XML  : TXMLDocument=nil;
begin
 WriteLn(#$1B'[91m'#$1B'[7m'+StringOfChar('*',80)+#$1B'[0m');
 WriteLn(#$1B'[1m*.inf to JSON and XML converter by Gerald J Holdsworth');
 WriteLn('Version 0.03'#$1B'[0m');
 WriteLn('');
 WriteLn(#$1B'[92mPress ENTER on an empty line to exit'#$1B'[0m');
 repeat
   Write(#$1B'[1m>'#$1B'[0m');
   ReadLn(line);
   if Trim(line)<>'' then
   begin
    WriteLn(#$1B'[1m'#$1B'[91mResults'#$1B'[0m');
    //JSON
    JAB:=TJSONObject.Create;
    ParseInf(JAB,line);
    WriteLn(#$1B'[1mJSON Output'#$1B'[0m');
    WriteLn(#$1B'[94m'+JAB.FormatJSON+#$1B'[0m');
    JAB.Free;
    //XML
    XML:=TXMLDocument.Create;
    XML.AppendChild(XML.CreateElement('Acorn_File'));
    ParseInf(XML,line);
    WriteLn(#$1B'[1mXML Output'#$1B'[0m');
    WriteLn(#$1B'[94m'+XML.AsString+#$1B'[0m');
    XML.Free;
   end;
 until Trim(line)='';
 WriteLn(#$1B'[91m'#$1B'[7m'+StringOfChar('*',80)+#$1B'[0m');
end.

