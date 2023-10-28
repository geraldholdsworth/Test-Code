unit echo;

{This is the Synapse 'echo' demo, converted to Lazarus then adapted to utilise a
Memo to log the incoming messages. I've also reduced it to a single thread,
which responds to the incoming message, and it also logs the remote machine's
IP address and Port number used.

I've also changed the button behaviour so it starts and stops the logging.

Gerald J Holdsworth
11th September 2023}

{$MODE objfpc}{$H+}{$M+}

interface

uses
  Classes,BlckSock,SynSock,LCLIntf,LCLType,SysUtils;

type
  TTCPEchoDaemon = class(TThread)
  private
   Sock : TTCPBlockSocket;
   FLog : TStringList;
   FCS  : TCriticalSection;
   procedure AddToLog(Msg: String);
  public
   Constructor Create;
   Destructor Destroy; override;
   procedure Execute; override;
  published
   function Fetch(out Msg: String): Boolean;
  end;

implementation

{ TEchoDaemon }

Constructor TTCPEchoDaemon.Create;
begin
 inherited Create(False);
 Sock:=TTCPBlockSocket.Create;
 InitializeCriticalSection(FCS);
 FLog:=TStringList.Create;
end;

Destructor TTCPEchoDaemon.Destroy;
begin
 FLog.Free;
 DeleteCriticalSection(FCS);
 Sock.Free;
 inherited Destroy;
end;

procedure TTCPEchoDaemon.Execute;
var
 ReturnSock: TSocket;
 ClientSock: TTCPBlockSocket;
 Msg       : String;
begin
 Sock.CreateSocket;
 Sock.SetLinger(True,10000);
 Sock.Bind('0.0.0.0','8008');
 Sock.Listen;
 repeat
  if not Terminated then
  if Sock.CanRead(1000) then
  begin
   ReturnSock:=Sock.Accept;
   if Sock.LastError=0 then
   begin
    ClientSock:=TTCPBlockSocket.Create;
    try
     ClientSock.Socket:=ReturnSock;
     ClientSock.GetSins;
     AddToLog('Connection opened');
     repeat
      if not Terminated then
      begin
       Msg:=ClientSock.RecvPacket(60000);
       if ClientSock.LastError=0 then
       begin
        AddToLog(Msg);
        ClientSock.SendString('Received');
       end;
      end;
     until(Terminated)or(ClientSock.LastError<>0);
     AddToLog('Connection closed');
    finally
     ClientSock.Free;
    end;
   end;
  end;
 until(Terminated)or(Sock.LastError<>0);
end;

procedure TTCPEchoDaemon.AddToLog(Msg: String);
begin
 EnterCriticalSection(FCS);
 try
  FLog.Add(Msg);
 finally
  LeaveCriticalSection(FCS);
 end;
end;

function TTCPEchoDaemon.Fetch(out Msg: String): Boolean;
begin
 Result:=False;
 EnterCriticalSection(FCS);
 try
  if FLog.Count>0 then
  begin
   Msg:=FormatDateTime('dd/mm/yyyy hh:nn:ss',Now)
       +' ('+Sock.GetRemoteSinIP+':'+IntToStr(Sock.GetRemoteSinPort)+'): '
       +FLog[0];
   FLog.Delete(0);
   Result:=True;
  end;
 finally
  LeaveCriticalSection(FCS);
 end;
end;

end.
