unit Unit1;

{$mode objfpc}{$H+}
{$M+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
 StrUtils, UDPServer, UDPClient;

type

 { TForm1 }

 TForm1 = class(TForm)
  Memo1: TMemo;
  Panel1: TPanel;
  Button1: TButton;
  Timer1: TTimer;
  procedure Button1Click(Sender: TObject);
  procedure FormDestroy(Sender: TObject);
  procedure FormShow(Sender: TObject);
  procedure Timer1Timer(Sender: TObject);
 private
  UDPServer: TUDPServer;
  const
   //DMP Part numbers and models (from www.Extron.com)
   Devices    : array[0..29] of String = ('60-1211-01','DMP 128',
                                          '60-1179-01','DMP 128 C P',
                                          '60-1179-10','DMP 128 C P AT',
                                          '60-1511-01','DMP 128 Plus',
                                          '60-1511-10','DMP 128 Plus AT',
                                          '60-1512-01','DMP 128 PLus C',
                                          '60-1512-10','DMP 128 Plus C AT',
                                          '60-1513-01','DMP 128 Plus C V',
                                          '60-1513-10','DMP 128 Plus C V AT',
                                          '60-1054-01','DMP 64',
                                          '60-1823-01','DMP 64 Plus',
                                          '60-1823-10','DMP 64 Plus C AT',
                                          '60-1824-01','DMP 64 Plus C V',
                                          '60-1824-10','DMP 64 Plus C V AT',
                                          '60-2041-01','DMP 44 xi');
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
 UDPServer.Port:=1230;
 UDPServer.Start;
 Timer1.Enabled:=True;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
 Host : String='';
 Msg  : String='';
begin
 if Assigned(UDPServer) then
  while UDPServer.Fetch(Host,Msg) do
  begin
   Msg:=Trim(Msg);
   if Msg in Devices then
    Memo1.Lines.Add(Host+' : '+Devices[IndexStr(Msg,Devices)+1]+' ('+Msg+')')
   else
    Memo1.Lines.Add(Host+' : Unknown ('+Msg+')');
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
 //Broadcast a UDP Message - this will query all DMP units for their part number
 SendUDPMessage('255.255.255.255',1231,'UDPC'#$FF#$FF#$FF#$FF'             N'#$0D);
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

