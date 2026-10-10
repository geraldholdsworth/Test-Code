unit UDPServer;

{$mode ObjFPC}{$H+}
{$M+}

interface

uses
 Classes, SysUtils, sockets, LCLType, LCLIntf;

type
  TUDPServer = class(TThread) //Server thread definition
  type
   TLog = record
     Host: String;
     Msg : String;
   end;
  private
   FPort         : LongInt;
   FRunning      : Boolean;
   FTimedOut     : Boolean;
   FSocket       : TSocket;
   FHosts        : array of String;
   FCS           : TCriticalSection;
   FMsgs         : array of TLog;
   procedure AddLogItem(Host,Msg: String);
   procedure RemoveLogItem;
  public
   Constructor Create;
   Destructor Destroy; override;
   procedure Execute; override;
  published
   function Fetch(out Host,Msg: String): Boolean;
   property Port         : LongInt     read FPort        write FPort;
   property Running      : Boolean     read FRunning;
  end;

implementation

{ TTCPServer }

{-------------------------------------------------------------------------------
Creates the overall thread
-------------------------------------------------------------------------------}
constructor TUDPServer.Create;
begin
 inherited Create(True); //Create, but don't start, the thread
 //Create the socket
 FSocket     :=FPSocket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
 FPort       :=4001;
 //Set some flags
 FRunning    :=False;
 FTimedOut   :=False;
 InitializeCriticalSection(FCS);
end;

{-------------------------------------------------------------------------------
Destroys the thread
-------------------------------------------------------------------------------}
destructor TUDPServer.Destroy;
var
 Index: Integer;
begin
 CloseSocket(FSocket);
 DeleteCriticalSection(FCS);
 inherited Destroy;
end;

{-------------------------------------------------------------------------------
Runs when the thread starts
-------------------------------------------------------------------------------}
procedure TUDPServer.Execute;
var
 len       : integer;
 retval    : integer;
 localaddr : TSockAddr;
 remotaddr : TSockAddr;
 slen      : TSockLen;
 buf       : array[0..1023] of char;
begin
 localaddr.sin_family      := AF_INET;
 localaddr.sin_port        := htons(FPort);
 localaddr.sin_addr.s_addr := htonl(INADDR_ANY);
 retval                    := FPBind(FSocket, @localaddr, sizeof(localaddr));
 slen                      := SizeOf(remotaddr);
 FRunning                  :=True;
 while not Terminated do
 begin
  len:=FPRecvFrom(FSocket, @buf[0], sizeof(buf), 0, @remotaddr, @slen);
  if len<>-1 then
  begin
   EnterCriticalSection(FCS);
   try
    AddLogItem(NetAddrToStr(remotaddr.sin_addr),Copy(buf, 0, len));
   finally
    LeaveCriticalSection(FCS);
   end;
  end;
 end;
 FRunning:=False;
end;

{-------------------------------------------------------------------------------
Get a message from the stack
-------------------------------------------------------------------------------}
function TUDPServer.Fetch(out Host,Msg: String): Boolean;
var
 Index: Integer;
begin
 Result:=False;
 if Length(FMsgs)>0 then
 begin
  EnterCriticalSection(FCS);
  try
   Host:=FMsgs[0].Host;
   Msg :=FMsgs[0].Msg;
   RemoveLogItem;
   Result:=True;
  finally
   LeaveCriticalSection(FCS);
  end;
 end;
end;

{-------------------------------------------------------------------------------
Add an item to the end of the stack
-------------------------------------------------------------------------------}
procedure TUDPServer.AddLogItem(Host,Msg: String);
begin
 SetLength(FMsgs, Length(FMsgs)+1);
 FMsgs[Length(FMsgs)-1].Host:=Host;
 FMsgs[Length(FMsgs)-1].Msg :=Msg;
end;

{-------------------------------------------------------------------------------
Remove an item from the front of the stack
-------------------------------------------------------------------------------}
procedure TUDPServer.RemoveLogItem;
var
 I: Integer=0;
begin
 if Length(FMsgs)>0 then
 begin
  if Length(FMsgs)>1 then for I:=1 to Length(FMsgs)-1 do FMsgs[I-1]:=FMsgs[I];
  SetLength(FMsgs,Length(FMsgs)-1);
 end;
end;

end.

