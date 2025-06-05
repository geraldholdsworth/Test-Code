program project1;

{$mode objfpc}{$H+}

uses
 {$IFDEF UNIX}
 cthreads,
 {$ENDIF}
 Classes, SysUtils, CustApp
 {$IFDEF Windows},Registry,Windows{$ENDIF}
 { you can add units after this };

type

 { TMyApplication }

 TMyApplication = class(TCustomApplication)
 protected
  procedure DoRun; override;
 public
  constructor Create(TheOwner: TComponent); override;
  destructor Destroy; override;
  procedure WriteHelp; virtual;
 end;

{ TMyApplication }

procedure TMyApplication.DoRun;
var
 ErrorMsg: String;
 input: String;
 {$IFDEF Windows}
 su: StartUpInfoA;
 {$ENDIF}
begin
 // quick check parameters
 ErrorMsg:=CheckOptions('h', 'help');
 if ErrorMsg<>'' then begin
  ShowException(Exception.Create(ErrorMsg));
  Terminate;
  Exit;
 end;

 // parse parameters
 if HasOption('h', 'help') then begin
  WriteHelp;
  Terminate;
  Exit;
 end;
 {$IFDEF Windows}
 WriteLn('Start Up info');
 GetStartUpInfo(su);
 WriteLn('dwFlags: 0x'+IntToHex(su.dwFlags));
 WriteLn('wShowWindow: 0x'+IntToHex(su.wShowWindow));
 WriteLn('stdOutput: 0x'+IntToHex(su.hStdOutput));
 WriteLn('lpTitle: '+su.lpTitle);
 {$ENDIF}
WriteLn(#$1B'[91m'+StringOfChar('*',80)+#$1B'[0m');
repeat
 write('>');
 ReadLn(Input);
until Input='exit';

 // stop program loop
 Terminate;
end;

constructor TMyApplication.Create(TheOwner: TComponent);
begin
 inherited Create(TheOwner);
 StopOnException:=True;
end;

destructor TMyApplication.Destroy;
begin
 inherited Destroy;
end;

procedure TMyApplication.WriteHelp;
begin
 { add your help code here }
 writeln('Usage: ', ExeName, ' -h');
end;

var
 Console: TMyApplication;
 {$IFDEF Windows}R:TRegistry;{$ENDIF}
begin
 {$IFDEF Windows}
 R:=TRegistry.Create;
 R.OpenKey('Console',True);
 R.WriteInteger('VirtualTerminalLevel',1);
 R.Free;
 {$ENDIF}
 Console:=TMyApplication.Create(nil);
 Console.Title:='My Application';
 Console.Run;
 Console.Free;
end.

