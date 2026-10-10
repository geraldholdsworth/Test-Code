unit UDPClient;

{$mode ObjFPC}{$H+}

interface

uses
 Classes, SysUtils, sockets;

procedure SendUDPMessage(IP: String; Port: Cardinal; Msg: PChar);

implementation

procedure SendUDPMessage(IP: String; Port: Cardinal; Msg: PChar);
var
 Sock     : TSocket;
 RemotAddr: TSockAddr;
 OptVal   : int32 = 1;
begin
 //Broadcast a UDP Message
 RemotAddr.SIn_Family:=AF_INET;
 RemotAddr.SIn_Port  :=HtoNS(Port);
 RemotAddr.SIn_Addr  :=StrToNetAddr(IP);
 Sock:=FPSocket(AF_INET,SOCK_DGRAM,IPPROTO_UDP);
 FPSetSockOpt(Sock,SOL_SOCKET,SO_BROADCAST,@OptVal,SizeOf(OptVal));
 FPSendTo(Sock,Msg,Length(Msg),0,@RemotAddr,SizeOf(RemotAddr));
 CloseSocket(sock);
end;

end.

