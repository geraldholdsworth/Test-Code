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

uses
 {$IFDEF UNIX}
 cthreads,
 {$ENDIF}
 {$IFDEF HASAMIGA}
 athreads,
 {$ENDIF}
 Interfaces, // this includes the LCL widgetset
 Classes, SysUtils, CustApp,//For the console side of this
 Forms, Unit1
 {$IFDEF Windows},Windows,Registry{$ENDIF}
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

var
 ConsoleApp: TConsoleApp;
 B         : Byte;
 input,
 script    : String;
 tmp       : PChar;
 params    : TStringArray;
 Index     : Integer;
 F         : TFileStream;
 {$IFDEF Windows}
 R         : TRegistry;
 {$ENDIF}
begin
 //Create GUI application
 RequireDerivedFormResource:=True;
 Application.Scaled:=True;
 Application.Initialize;
 Application.CreateForm(TForm1, Form1);
 {$IFDEF Windows}
 if Application.HasOption('c','console') then
 begin
  R:=TRegistry.Create;
  R.OpenKey('Console',True);
  R.WriteInteger('VirtualTerminalLevel',1);
  R.Free;
  AllocConsole;
  IsConsole:=True;
  SysInitStdIO;
  SetConsoleOutputCP(CP_UTF8);
 end;
 {$ENDIF}
 //No errors, and 'console' passed as a parameter
 if Application.HasOption('c','console') then
 begin
  //Create the console application
  ConsoleApp:=TConsoleApp.Create(nil);
  ConsoleApp.Title:='Console Application';
  //Write out a header
  WriteLn(#$1B'[91m'+StringOfChar('*',80)+#$1B'[0m');
  WriteLn('Entering Console');
  //Did the user supply a file for commands to run?
  script:=Application.GetOptionValue('c','console');
  if script<>'' then
   if not FileExists(script) then
   begin
    WriteLn('File '''+script+''' does not exist.');
    script:='';
   end
   else
   begin
    WriteLn('Running script '''+script+'''.');
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
    'add'      : //Add files
      if Length(params)>1 then //Is there any files given?
       for Index:=1 to Length(params)-1 do
        if params[Index][1]='>' then //It is a directory to select
         WriteLn('Select directory '''+Copy(params[Index],2)+'''.')
        else                         //Just add a file
         WriteLn('Adding file: '''+params[Index]+'''.')
      else WriteLn('Nothing to add.');//Nothing has been passed
    'help'     : //Help command
     begin
      WriteLn('Help');
      WriteLn('----');
      WriteLn('add      : Adds the files listed after the command.');
      WriteLn('           Use space to separate, and enclose in quotes if space required.');
      WriteLn('exit     : Quits console and application.');
      WriteLn('exittogui: Quits the console and opens the GUI application.');
      WriteLn('help     : Shows this text.');
     end;
    'exit',      //Exit the console application
    'exittogui': WriteLn('Exiting.');
    ''         :;//Blank entry, so just ignore
   otherwise WriteLn('Unknown command.'); //Something not recognised
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
  WriteLn(#$1B'[91m'+StringOfChar('*',80)+#$1B'[0m');
  //Close the console application
  ConsoleApp.Free;
  //Close the GUI application
  if params[0]='exit' then Application.Terminate
  else
  begin //Otherwise open the GUI application
   {$IFDEF Windows}
   IsConsole:=False;
   {$ENDIF}
   Application.Run;
  end;
 end else
 begin
  {$IFDEF Windows}
  IsConsole:=False;
  {$ENDIF}
  Application.Run; //Console application not specified, so open as normal
 end;
end.
