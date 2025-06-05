program project1;

{GUI and Console application combined
This can be used as a console application, but can also interact with the GUI
side of it. This means you don't need to repeat code for both the GUI and
Console sides.
Untested on more complex applications.
When the console exits to the GUI, the icon is not created, probably because it
is being launched from the console.
}

{$mode objfpc}{$H+}
{$IFDEF Darwin}
{$modeswitch objectivec1}
{$ENDIF}

uses
 {$IFDEF UNIX}
 cthreads,
 {$ENDIF}
 {$IFDEF HASAMIGA}
 athreads,
 {$ENDIF}
 //For the console side of this
 Classes, SysUtils, CustApp,
 {$IFDEF Windows}Windows,{$ENDIF} //For Windows console
 {$IFDEF Linux}BaseUnix,{$ENDIF}  //For Linux console
 {$IFDEF Darwin}typinfo,CocoaAll,{$ENDIF} //For macOS console
 //Back to normal definitions
 Interfaces, // this includes the LCL widgetset
 Forms, Unit1
 { you can add units after this };

{$R *.res}

type

 { TConsoleApp }

 TConsoleApp = class(TCustomApplication)
 public
  constructor Create(TheOwner: TComponent); override;
  destructor Destroy; override;
 end;

{ TConsoleApp }

constructor TConsoleApp.Create(TheOwner: TComponent);
begin
 inherited Create(TheOwner);
 StopOnException:=True;
end;

destructor TConsoleApp.Destroy;
begin
 inherited Destroy;
end;

function IsRunFromConsole: Boolean;
{$IFDEF Windows}
var
 StartUp: StartUpInfoA;
{$ENDIF}
begin
 Result:=False;//Default, if not covered by Windows, Linux or Darwin
{$IFDEF Windows}
 StartUp.dwFlags:=0;//Prevents 'variable not initialised' message
 GetStartupInfo(StartUp);
 Result:=(StartUp.dwFlags AND 1)<>1;
{$ENDIF}
{$IFDEF Linux}
 Result:=fpReadLink('/proc/'+fpGetppid.ToString+'/exe')<>'';
{$ENDIF}
{$IFDEF Darwin}
 Result:=NSProcessInfo.ProcessInfo.environment.objectForKey(NSStr('XPC_SERVICE_NAME')).UTF8String='0';
{$ENDIF}
end;

var
 ConsoleApp: TConsoleApp;
 B         : Byte;
 boldstyle,
 redstyle,
 nostyle,
 clrscreen,
 input,
 script    : String;
 tmp       : PChar;
 params    : TStringArray;
 Index     : Integer;
 F         : TFileStream;
 RunGUI    : Boolean;
 {$IFDEF Windows}
 hwConsole : hWnd;
 lwMode    : LongWord;
 {$ENDIF}
begin
 //Create GUI application
 RequireDerivedFormResource:=True;
 Application.Scaled:=True;
 Application.Title:='Console and GUI';
 Application.Initialize;
 Application.CreateForm(TForm1, Form1);
 //By default, we're going to run the GUI
 RunGUI:=True;
 //No errors, and 'console' passed as a parameter or is run from the console
 if((Application.HasOption('c','console'))
  OR(IsRunFromConsole))
 AND(not Application.HasOption('g','gui'))then
 begin
  {$IFDEF Windows}
  //Windows doesn't create a console with a GUI app, so we need to do it ourselves
  AllocConsole;
  IsConsole:=True;
  SysInitStdIO;
  //Setup so that the escape sequences will work
  SetConsoleOutputCP(CP_UTF8);
  //Try and enable virtual terminal processing
  hwConsole:=GetStdHandle(STD_OUTPUT_HANDLE);
  If GetConsoleMode(hwConsole,@lwMode)then
  begin
   lwMode:=lwMode or ENABLE_VIRTUAL_TERMINAL_PROCESSING;
   if SetConsoleMode(hwConsole,lwMode)then
   begin
    {$ENDIF}
    //Escape sequences for various styles
    boldstyle:=#$1B'[1m';
    redstyle :=#$1B'[91m';
    nostyle  :=#$1B'[0m';
    clrscreen:=#$1B'[H'#$1B'[2J'#$1B'[3J';
    {$IFDEF Windows}
   end
   else
   begin
    //Couldn't enable virtual terminal processing, so just output empty strings
    redstyle :='';
    boldstyle:='';
    nostyle  :='';
    clrscreen:='';
   end;
  end;
  {$ENDIF}
  //Create the console application
  ConsoleApp:=TConsoleApp.Create(nil);
  ConsoleApp.Title:=Application.Title;
  //Clear screen
  Write(clrscreen);
  //Write out a header
  WriteLn(redstyle+StringOfChar('*',80)+nostyle);
  WriteLn(boldstyle+ConsoleApp.Title+nostyle);
  WriteLn();
  WriteLn(boldstyle+'Console'+nostyle);
  WriteLn();
  //Did the user supply a file for commands to run?
  script:=Application.GetOptionValue('c','console');
  if script<>'' then
   if not FileExists(script) then
   begin
    WriteLn(redstyle+'File '''+script+''' does not exist.'+nostyle);
    script:='';
   end
   else
   begin
    WriteLn(boldstyle+'Running script '''+script+'''.'+nostyle);
    //Open the script file
    F:=TFileStream.Create(script,fmOpenRead or fmShareDenyNone);
   end;
  //Intialise the array
  params:=nil;
  repeat
   //Prompt for input
   write('>');
   //Read a line of input from the user
   if script='' then ReadLn(input)
   else
   begin //Or from the file
    input:='';
    B:=0;
    repeat
     if F.Position<F.Size then B:=F.ReadByte; //Read byte by byte
     if(B>31)and(B<127)then input:=input+Chr(B); //Valid printable character?
    until(B=$0A)or(F.Position=F.Size); //End of line with $0A or end of file
    WriteLn(input); //Output the line, as if entered by the user
   end;
   //Add to the memo on the main form
   Form1.Memo1.Lines.Add('>'+input);
   //Split the string at each space, unless enclosed by quotes
   params:=input.Split(' ','"');
   //Anything entered?
   if Length(params)>0 then
    //Remove the quotes
    for Index:=0 to Length(params)-1 do
     begin
      tmp:=PChar(params[Index]);
      params[Index]:=AnsiExtractQuotedStr(tmp,'"');
     end
   else //Input was empty, so create a blank entry
   begin
    SetLength(params,1);
    params[0]:='';
   end;
   //Convert the command to lower case
   params[0]:=LowerCase(params[0]);
   //Parse the command
   case params[0] of
    'add'      : //Add files - This doesn't actually add any files, it's just an example
      if Length(params)>1 then //Is there any files given?
       for Index:=1 to Length(params)-1 do
        if params[Index][1]='>' then //It is a directory to select
         WriteLn(boldstyle+'Select directory '''+Copy(params[Index],2)+'''.'+nostyle)
        else                         //Just add a file
         WriteLn(boldstyle+'Adding file: '''+params[Index]+'''.'+nostyle)
      else WriteLn(redstyle+'Nothing to add.'+nostyle);//Nothing has been passed
    'help'     : //Help command
     begin
      WriteLn(boldstyle+'Help'+nostyle);
      WriteLn(boldstyle+redstyle+'add'+nostyle+'      : Adds the files listed after the command.');
      WriteLn('           Use space to separate, and enclose in quotes if space required.');
      WriteLn(boldstyle+redstyle+'exit'+nostyle+'     : Quits console and application.');
      WriteLn(boldstyle+redstyle+'exittogui'+nostyle+': Quits the console and opens the GUI application.');
      WriteLn(boldstyle+redstyle+'help'+nostyle+'     : Shows this text.');
     end;
    'exit'     : WriteLn(boldstyle+'Exiting.'+nostyle);     //Exit the console application
    'exittogui': WriteLn(boldstyle+'Entering GUI.'+nostyle);//Exit the console and enter the GUI
    ''         :;//Blank entry, so just ignore
   otherwise WriteLn(redstyle+'Unknown command.'+nostyle);  //Something not recognised
   end;
   //End of the script? Then close the file
   if script<>'' then
    if F.Position=F.Size then
    begin
     F.Free;
     script:='';
    end;
   //Continue until the user specifies to exit
  until(params[0]='exit')or(params[0]='exittogui');
  //Script file still open? Then close it
  if script<>'' then F.Free;
  //Footer at close of console
  WriteLn(redstyle+StringOfChar('*',80)+nostyle);
  //Close the console application
  ConsoleApp.Free;
  //Close the application
  if params[0]='exit' then //'exittogui' will bypass this
  begin
   RunGUI:=False;
   Application.Terminate;
  end;
 end;
 //Run the GUI
 if RunGUI then
 begin
  {$IFDEF Windows}
  IsConsole:=False;
  {$ENDIF}
  Application.Run; //Console application not specified, so open as normal
 end;
end.
