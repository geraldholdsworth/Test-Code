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
 input,
 script    : String;
 tmp       : PChar;
 params    : TStringArray;
 Index     : Integer;
begin
 //Create GUI application
 RequireDerivedFormResource:=True;
 Application.Scaled:=True;
 Application.Title:='Console Application Demo';
 Application.Initialize;
 Application.CreateForm(TForm1, Form1);
 //Do we have 'console' passed as a parameter?
 input:=Application.CheckOptions('d:','console:');
 //No, we have something else so quit to the GUI
 if input<>'' then //This will also quit if 'console' was supplied, but there was other text too
 begin
  WriteLn(input); //Display the errors
  WriteLn('Exiting to GUI.');
 end;
 //No errors, and 'console' passed as a parameter
 if(input='')and(Application.HasOption('d','console'))then
 begin
  //Create the console application
  ConsoleApp:=TConsoleApp.Create(nil);
  ConsoleApp.Title:='Console Application';
  //Write out a header
  WriteLn('********************************************************************************');
  WriteLn('Entering Console');
  //Did the user supply a file for commands to run?
  script:=Application.GetOptionValue('d','console');
  //Intialise the array
  params:=nil;
  //No script to run, so open for user input
  if script='' then
   repeat
    //Prompt for input
    write('>');
    //Read a line of input from the user
    readln(input);
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
     ''             : ;//Blank entry, so just ignore
    otherwise WriteLn('Unknown command'); //Something not recognised
    end;
    //Continue until the user specifies to exit
   until(params[0]='exit')or(params[0]='exittogui')
  else //Run the script file specified
  begin
   SetLength(params,1);
   params[0]:='exit';
   //On production code, this would be higher up and use the same parsing code as above
   WriteLn('At this point we would be running the script file '''+script+'''.');
  end;
  //Footer at close of console
  WriteLn('********************************************************************************');
  //Close the console application
  ConsoleApp.Free;
  //Close the GUI application
  if params[0]='exit' then Application.Terminate
  else Application.Run //Otherwise open the GUI application
 end else Application.Run; //Console application not specified, so open as normal
end.

