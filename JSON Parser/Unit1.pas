unit Unit1;

{$mode objfpc}{$H+}
{$M+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
 fpjson, jsonparser, StrUtils, UDPServer, UDPClient;

type

 { TForm1 }

 TForm1 = class(TForm)
  Memo1: TMemo;
  Panel1: TPanel;
  Button1: TButton;
  Timer1: TTimer;
  Edit1: TEdit;
  procedure Button1Click(Sender: TObject);
  procedure Edit1EditingDone(Sender: TObject);
  procedure FormDestroy(Sender: TObject);
  procedure FormShow(Sender: TObject);
  procedure Timer1Timer(Sender: TObject);
  procedure DecodeText(device: String);
 private
  UDPServer: TUDPServer;
 public

 end;

var
 Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormShow(Sender: TObject);
begin
 Memo1.Lines.Clear;
 UDPServer:=TUDPServer.Create;
 UDPServer.Port:=4502;
 UDPServer.Start;
 Timer1.Enabled:=True;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
 Host: String='';
 Msg : String='';
begin
 if Assigned(UDPServer) then
  while UDPServer.Fetch(Host,Msg) do DecodeText(Msg);
end;

procedure TForm1.DecodeText(device: String);
var
 J: TJSONData;
 function GetString(search: String): String;
 begin
  if J.FindPath(search)<>nil then
   Result:=J.FindPath(search).AsString
  else
   Result:='';
 end;
 procedure PrintString(Subject,Search: String);
 var
  T: String='';
 begin
  T:=GetString(Search);
  if T<>'' then Memo1.Lines.Add(PadRight(Subject,13)+': '+T);
 end;
begin                                                   
 device:=StringReplace(device,'\\','\',[rfReplaceAll]);
 J:=GetJSON(Copy(device,Pos('[',device)+1,Pos(']',device)-Pos('[',device)));
 PrintString('Model','value.model');
 PrintString('Description','value.descr');
 PrintString('Part Number','value.partnum');
 PrintString('Serial Number','value.snum');
 PrintString('Firmware','value.version');
 PrintString('Hostname','value.hostname');
 PrintString('MAC Address','value.mac_address');
 PrintString('IP Address','value.ip_address');
 Memo1.Lines.Add(StringOfChar('-',60));
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
 //Broadcast a UDP Message
 SendUDPMessage('255.255.255.255',4502,'fD2200007FFFFFFF0000FFF0FFFFFFF00000004E[{"method":"get","uri":"/scm/devices/self","replyto":"/scm/devices/self"}]fE');
end;

procedure TForm1.Edit1EditingDone(Sender: TObject);
begin
 if Edit1.Text<>'' then DecodeText(Edit1.Text);
 Edit1.Text:='';
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
 Timer1.Enabled:=False;
 UDPServer.Terminate;
// WriteLn('Waiting for it');
// UDPServer.WaitFor;
 UDPServer.Free;
end;

end.

