unit Emails;

{$mode ObjFPC}{$H+}

interface

uses
 Classes,SysUtils,smtpsend,synautil,ssl_openssl,mimemess,mimepart,synachar;

function SendEmail(LFrom,LTo,LSubject: String;LContent: TStrings;
                   LServer,LPort,LUsername,LPassword: String;
                   UseSSL: Boolean;LAttachments: TStrings): String;
function TestServer(LServer,LPort,LUsername,LPassword: String;
                    UseSSL: Boolean):Boolean;

implementation

function TestServer(LServer,LPort,LUsername,LPassword: String;
                    UseSSL: Boolean):Boolean;
var
 SMTP      : TSMTPSend;
begin
 Result:=False;
 if LServer<>'' then
 begin
  //Create the sender
  SMTP:=TSMTPSend.Create;
  try
   //TLS Automatic
   SMTP.AutoTLS:=True;
   //Use SSL if box is ticked
   SMTP.FullSSL:=UseSSL;
   //SMTP Server details
   SMTP.TargetHost:=LServer;
   if LPort<>'' then SMTP.TargetPort:=LPort;
   //Authentication
   SMTP.Username:=LUsername;
   SMTP.Password:=LPassword;
   //Can we log in?
   Result:=SMTP.Login;
   //Log out of the server
   SMTP.Logout;
  finally
   //Free up the control
   SMTP.Free;
  end;
 end;
end;

function SendEmail(LFrom,LTo,LSubject: String;LContent: TStrings;
                   LServer,LPort,LUsername,LPassword: String;
                   UseSSL: Boolean;LAttachments: TStrings): String;
var
 OK        : Boolean;
 LError,
 s,t       : String;
 LMessage  : TStrings;
 SMTP      : TSMTPSend;
 Mime      : TMimeMess;
 P         : TMimePart;
const
 XMailer = 'Emailer by Gerald J Holdsworth';
begin
 if LServer<>'' then
 begin
  LMessage:=TStringList.Create;
  //Build the message header
  if LAttachments.Count=0 then
  begin
  LMessage.Assign(LContent);
  LMessage.Insert(0,'');
  LMessage.Insert(0,'X-mailer: '+XMailer);
  LMessage.Insert(0,'Subject: '+LSubject);
  LMessage.Insert(0,'Date: '+Rfc822DateTime(now));
  LMessage.Insert(0,'To: '+LTo);
  LMessage.Insert(0,'From: '+LFrom);
  end
  //Add any attachments
  else
  begin
   Mime:=TMimeMess.Create;
   //Build a header
   Mime.Header.CharsetCode:=UTF_8;
   Mime.Header.ToList.Text:=LTo;
   Mime.Header.Subject:=LSubject;
   Mime.Header.From:=LFrom;
   // Create a MultiPart part
   P:=Mime.AddPartMultipart('mixed',Nil);
   // Add as first part the mail text
   Mime.AddPartTextEx(LContent,P,UTF_8,True,ME_8BIT);
   // Add all attachments:
   for s in LAttachments do Mime.AddPartBinaryFromFile(s,P);
   // Compose message
   Mime.EncodeMessage;
   //Copy across to the main message body
   LMessage.Assign(Mime.Lines);
   //Free up the MIME message
   Mime.Free;
  end;
  //Set the flag
  OK:=False;
  //Default error message
  LError:='';
  //Create the sender
  SMTP:=TSMTPSend.Create;
  try
   //TLS Automatic
   SMTP.AutoTLS:=True;
   //Use SSL if box is ticked
   SMTP.FullSSL:=UseSSL;
   //SMTP Server details
   SMTP.TargetHost:=LServer;
   if LPort<>'' then SMTP.TargetPort:=LPort;
   //Authentication
   SMTP.Username:=LUsername;
   SMTP.Password:=LPassword;
   //Can we log in?
   if SMTP.Login then
   begin
    //Set the 'From:' field
    if SMTP.MailFrom(GetEmailAddr(LFrom),Length(LMessage.Text))then
    begin
     //Now split the 'To:' file into separate addresses
     s:=LTo;
     repeat
      t:=GetEmailAddr(Trim(FetchEx(s,',','"')));//A comma separates the addresses
      if t<>'' then OK:=SMTP.MailTo(t);
      if not OK then Break; //Break out of the loop with an invalid address
     until s='';
     //All senders OK? Then continue
     if OK then
     begin
      //Now send the message
      OK:=SMTP.MailData(LMessage);
      //Failed? Get the error
      if not OK then LError:=SMTP.ResultString;
     end else LError:='Invalid To Address(es)';
    end else LError:='Invalid From address';
    //Log out of the server
    SMTP.Logout;
   end else LError:='Login failure'; //Report a login failure
  finally
   //Free up the control
   SMTP.Free;
  end;
  //And the message container
  LMessage.Free;
  //Report back to the user the result
  if OK then Result:='Email sent OK'
        else Result:='Email not sent: '+LError;
 end else Result:='No SMTP server provided';
end;

end.

