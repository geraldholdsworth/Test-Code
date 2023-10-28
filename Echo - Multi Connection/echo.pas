unit echo;

{This is the Synapse 'echo' demo, converted to Lazarus then adapted to utilise a
Memo to log the incoming messages. I've written it so it logs the remote
machine's IP address and Port number used.

I've also changed the button behaviour so it starts and stops the logging.

Gerald J Holdsworth
11th September 2023}

{$MODE objfpc}{$H+}{$M+}

interface

uses
  Classes,BlckSock,SynSock,LCLIntf,LCLType,SysUtils;

type
  TTCPEchoDaemon = class(TThread)
  type
   TTCPEchoThrd = class(TThread)
   private
    Sock  : TTCPBlockSocket;
    CSock : TSocket;
    FLog  : TStringList;
    FCS   : TCriticalSection;
    FOwner: TTCPEchoDaemon;
    procedure AddToLog(Msg: String);
   public
    Constructor Create (hsock:tSocket);
    Destructor Destroy; override;
    procedure Execute; override;
  published
   function Fetch(out Msg: String): Boolean;
   property Owner : TTCPEchoDaemon read FOwner write FOwner;
   end;
  private
   Sock   : TTCPBlockSocket;
   Clients: array of TTCPEchoThrd;
   procedure AddClient(Client: TTCPEchoThrd);
   function GetNumberOfClients: Integer;
  public
   Constructor Create;
   Destructor Destroy; override;
   procedure Execute; override;
  published
   function Fetch(out Msg: String): Boolean;
   procedure RemoveClient(Client: TTCPEchoThrd);
   property ClientCount: Integer read GetNumberOfClients;
  end;

implementation

{ TEchoDaemon }

Constructor TTCPEchoDaemon.Create;
begin
 inherited Create(False);
 Sock:=TTCPBlockSocket.Create;
 SetLength(Clients,0);
end;

Destructor TTCPEchoDaemon.Destroy;
begin
 Sock.Free;
 inherited Destroy;
end;

procedure TTCPEchoDaemon.Execute;
var
 ReturnSock: TSocket;
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
   AddClient(TTCPEchoThrd.Create(ReturnSock));
  end;
 until(Terminated)or(Sock.LastError<>0);
end;

procedure TTCPEchoDaemon.AddClient(Client: TTCPEchoThrd);
var
 L: Integer;
begin
 L:=Length(Clients);
 SetLength(Clients,L+1);
 Clients[L]:=Client;
 Client.Owner:=Self;
end;

procedure TTCPEchoDaemon.RemoveClient(Client: TTCPEchoThrd);
var
 Cntr,
 Index: Integer;
begin
 Index:=0;
 if Length(Clients)>0 then
 begin
  while(Index<Length(Clients))and(Clients[Index]<>Client)do inc(Index);
  if Index<Length(Clients) then
   if Clients[Index]=Client then
   begin
    if Index<Length(Clients)-1 then
     for Cntr:=Index+1 to Length(Clients)-1 do
      Clients[Cntr-1]:=Clients[Cntr];
    SetLength(Clients,Length(Clients)-1);
   end;
 end;
end;

function TTCPEchoDaemon.Fetch(out Msg: String): Boolean;
var
 Index: Integer;
begin
 Result:=False;
 if Length(Clients)>0 then
 begin
  Index:=0;
  while(Index<Length(Clients))and(not Result)do
  begin
   Result:=Clients[Index].Fetch(Msg);
   inc(Index);
  end;
 end;
end;

function TTCPEchoDaemon.GetNumberOfClients: Integer;
begin
 Result:=Length(Clients);
end;

{ TTCPEchoDaemon.TTCPEchoThrd }

Constructor TTCPEchoDaemon.TTCPEchoThrd.Create(Hsock:TSocket);
begin
 inherited Create(False);
 CSock:=HSock;
 InitializeCriticalSection(FCS);
 FLog:=TStringList.Create;
 FreeOnTerminate:=True;
end;

Destructor TTCPEchoDaemon.TTCPEchoThrd.Destroy;
begin
 FOwner.RemoveClient(Self);
 DeleteCriticalSection(FCS);
end;

procedure TTCPEchoDaemon.TTCPEchoThrd.Execute;
var
 Msg: string;
begin
 Sock:=TTCPBlockSocket.Create;
 try
  Sock.Socket:=CSock;
  Sock.GetSins;
  repeat
   if not Terminated then
   begin
    Msg:=Sock.RecvPacket(60000);
    if Sock.LastError=0 then
    begin
     Sock.SendString('Received');
     AddToLog(Msg);
    end;
   end;
  until(Terminated)or(Sock.LastError<>0);
 finally
  Sock.Free;
 end;
end;

procedure TTCPEchoDaemon.TTCPEchoThrd.AddToLog(Msg: String);
begin
 EnterCriticalSection(FCS);
 try
  FLog.Add(Msg);
 finally
  LeaveCriticalSection(FCS);
 end;
end;

function TTCPEchoDaemon.TTCPEchoThrd.Fetch(out Msg: String): Boolean;
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
