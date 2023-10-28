unit MainUnit;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
 Buttons, Emails;

type

 { TForm1 }

 TForm1 = class(TForm)
  btnClearAttach: TButton;
  btnAttach: TButton;
  btnTest: TButton;
  cbSSL: TCheckBox;
  edFrom: TLabeledEdit;
  edPort: TLabeledEdit;
  edPassword: TLabeledEdit;
  edUserName: TLabeledEdit;
  edSMTPHost: TLabeledEdit;
  edSubject: TLabeledEdit;
  edTo: TLabeledEdit;
  edMessage: TMemo;
  Message: TGroupBox;
  Attachments: TGroupBox;
  ServerDetails: TGroupBox;
  lblResult: TLabel;
  lblMessage: TLabel;
  lbAttachments: TListBox;
  OpenDialog1: TOpenDialog;
  btnSend: TSpeedButton;
  procedure btnAttachClick(Sender: TObject);
  procedure btnClearAttachClick(Sender: TObject);
  procedure btnSendClick(Sender: TObject);
  procedure btnTestClick(Sender: TObject);
  procedure edSMTPHostChange(Sender: TObject);
  procedure FormShow(Sender: TObject);
  procedure EnableButtons;
 private
 public

 end;

var
 Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.btnSendClick(Sender: TObject);
begin
 lblResult.Caption:=SendEmail(edFrom.Text,
                              edTo.Text,
                              edSubject.Text,
                              edMessage.Lines,
                              edSMTPHost.Text,
                              edPort.Text,
                              edUsername.Text,
                              edPassword.Text,
                              cbSSL.Checked,
                              lbAttachments.Items);
end;

procedure TForm1.btnTestClick(Sender: TObject);
begin
 if TestServer(edSMTPHost.Text,
               edPort.Text,
               edUsername.Text,
               edPassword.Text,
               cbSSL.Checked)then lblResult.Caption:='Server details OK'
                            else lblResult.Caption:='Authentication failure';
end;

procedure TForm1.edSMTPHostChange(Sender: TObject);
begin
 EnableButtons;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
 EnableButtons;
end;

procedure TForm1.EnableButtons;
begin
 btnTest.Enabled:=edSMTPHost.Text<>'';
 btnSend.Enabled:=edSMTPHost.Text<>'';
 btnClearAttach.Enabled:=lbAttachments.Count>0;
end;

procedure TForm1.btnAttachClick(Sender: TObject);
var
 FileName: String;
begin
 if OpenDialog1.Execute then
  if OpenDialog1.Files.Count>0 then
   for FileName in OpenDialog1.Files do lbAttachments.Items.Add(FileName);
 EnableButtons;
end;

procedure TForm1.btnClearAttachClick(Sender: TObject);
begin
 lbAttachments.Clear;
 EnableButtons;
end;

end.

