unit Unit1;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs;

type

 { TForm1 }

 TForm1 = class(TForm)
  procedure FormCreate(Sender: TObject);
 private
  TCPServer: TTCPBlockSocket;
 public

 end;

var
 Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
 TCPServer:=TTCPBlockServer.Create;
end;

end.

