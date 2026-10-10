program AcornInfToJSON;
{
Test program for parsing Acorn .inf files
Version 0.04
Outputs to either JSON or XML
Written by and (c) Gerald J Holdsworth 2025
gerald@hollypops.co.uk
}

{$modeswitch TypeHelpers}          //Needed to create a helper

uses
 Classes,SysUtils,
 HTTPProtocol,fpjson,DOM,XMLWrite; //Need these

//Class helper for XML documents
type
  TXMLHelper = type helper for TXMLDocument
    procedure Add(name, value: String);
    function AsString: String;
    procedure ValidateName(var name: String);
  end;

{-------------------------------------------------------------------------------
Adds an element to the XML tree
-------------------------------------------------------------------------------}
procedure TXMLHelper.Add(name, value: String);
var
 Parent: TDOMNode=nil;
 LChar : Integer=0;
const
 //Allowed characters in an XML value
 PubidChar    =#$0D#$0A' ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
              +'0123456789-''()+,./:=?;!*#@$_%&';
begin
 if not name.IsEmpty then
 begin
  //Validate the value
  if not value.IsEmpty then
   for LChar:=1 to Length(value) do
    if Pos(value[LChar],PubidChar)=0 then value[LChar]:=' ';
  ValidateName(name);
  //Create the parent
  Parent:=self.CreateElement(UnicodeString(name));
  //Create and append the value, if not empty
  if not value.IsEmpty then
   Parent.AppendChild(self.CreateTextNode(UnicodeString(value)));
  //Add it to the document at the root level
  self.DocumentElement.AppendChild(Parent);
 end;
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
Validate the name for allowed characters
-------------------------------------------------------------------------------}
procedure TXMLHelper.ValidateName(var name: String);
var
 LChar : Integer=0;
const
 //Allowed characters in an XML node name
 NameStartChar=':ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz';
 NameChar     =NameStartChar+'-.0123456789';
begin
 if not name.IsEmpty then
 begin
  //Validate the name
  if Pos(name[1],NameStartChar)=0 then name[1]:='_';      //Start character
  if Length(name)>1 then
   for LChar:=2 to Length(name) do                        //Subsequent characters
    if Pos(name[LChar],NameChar)=0 then name[LChar]:='_';
 end;
end;

{-------------------------------------------------------------------------------
Creates an XML document and adds a root
-------------------------------------------------------------------------------}
function CreateXML(name: String): TXMLDocument;
begin
 if not name.IsEmpty then
 begin
  Result:=TXMLDocument.Create;
  Result.ValidateName(name);
  Result.AppendChild(Result.CreateElement(name));
 end;
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
  if Result<>input then Result:=HTTPDecode(Result);
 end;
 //Validate the input string as a valid hex number. Return 0 if not ------------
 function ValidateHex(input: String): String;
 var
  TestHex: String='';
 begin
  //Default result
  Result:='0';
  //Only continue if there is something
  if(not input.IsEmpty)and(Length(input)<9)then
  begin
   //Remove any '$' at the start
   while input[1]='$' do
   begin
    input:=Copy(input,2);
    if input.IsEmpty then input:='0';
   end;
   //Now remove any '0x' at the start
   if Length(line)>1 then while LeftStr(line,2)='0x' do line:=Copy(line,3);
   //Create a test hex
   TestHex:=StringOfChar('F',Length(input)+1);
   //Finally, see if it is a valid hex and convert, if it is
   if IntToHex(StrToIntDef('$'+input,StrToInt('$'+TestHex))
              ,Length(input)+1)<>TestHex then
    Result:=input;
  end;
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
 //Check a field to see if it contains an attribute (access) field
 function CheckForAccess(entry: String): Boolean;
 begin
  entry:=UpperCase(entry);
  Result:=(entry='LOCKED')or(entry='L')//DFS Locked flag
        or((Length(entry)=2)and(StrToIntDef('$'+entry,$FFF)<>$FFF))//2 digit hex
        or((not CheckForKeyValue(entry)) //Is not a key/value pair
           and(StrToIntDef('$'+entry,$FFF)=$FFF)and(UpperCase(entry)<>'FFF'));
 end;
//Main procedure definition ----------------------------------------------------
begin
 if(output is TJSONObject)      //Currently, only outputs to JSON or XML
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
       if CheckForAccess(fields[Index]) then offset:=1;
       //Syntax 3 is <filename> <access> <extra info> : for directories
       if(Index=start+1)and(Length(fields)>start+1)then
        if CheckForAccess(fields[Index]) then offset:=3;
       //Everything else - syntax 2
       ParseField(Index,Field[offset+Index-(start+1)]
                       ,FieldType[offset+Index-(start+1)]);
      end
      else                        //Extra field
       ParseField(Index,'Field '+IntToStr(Index),0);
   end;
  end;
 end;
end;

//Used for testing out the above - not needed in production ********************
var
 line : String='';
 JAB  : TJSONObject=nil;
 XML  : TXMLDocument=nil;
begin
 WriteLn(#$1B'[91m'#$1B'[7m'+StringOfChar('*',80)+#$1B'[0m');
 WriteLn(#$1B'[1m*.inf to JSON and XML converter by Gerald J Holdsworth');
 WriteLn('Version 0.04'#$1B'[0m');
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
    XML:=CreateXML('Acorn_File');
    ParseInf(XML,line);
    WriteLn(#$1B'[1mXML Output'#$1B'[0m');
    WriteLn(#$1B'[94m'+XML.AsString+#$1B'[0m');
    XML.Free;
   end;
 until Trim(line)='';
 WriteLn(#$1B'[91m'#$1B'[7m'+StringOfChar('*',80)+#$1B'[0m');
end.

