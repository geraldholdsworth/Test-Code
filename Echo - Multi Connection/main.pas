unit main;

{This is the Synapse 'echo' demo, converted to Lazarus then adapted to utilise a
Memo to log the incoming messages. I've written it so it logs the remote
machine's IP address and Port number used.

I've also changed the button behaviour so it starts and stops the logging.

Gerald J Holdsworth
11th September 2023}

{$MODE objfpc}{$H+}

interface

uses
  Forms, StdCtrls, ExtCtrls, echo, Classes, SysUtils;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Label1: TLabel;
    Memo1: TMemo;
    Timer1: TTimer;
    procedure Button1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    Daemon: TTCPEchoDaemon;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
 if not Timer1.Enabled then
 begin
  Daemon:=TTCPEchoDaemon.Create;
  Button1.Caption:='Stop TCP Echo Server';
  Timer1.Enabled:=True;
 end
 else
 begin
  Timer1.Enabled:=False;
  Daemon.Free;
  Button1.Caption:='Run TCP Echo Server';
 end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  S: String;
begin
 If Daemon.Fetch(S) then Memo1.Lines.Add(S);
 Label1.Caption:='Connected Clients: '+IntToStr(Daemon.ClientCount);
end;

end.
