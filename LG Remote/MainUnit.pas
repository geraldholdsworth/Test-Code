unit MainUnit;

{$mode objfpc}{$H+}

interface

uses
 Classes,SysUtils,Forms,Controls,Graphics,Dialogs,ExtCtrls,Crt,
 StdCtrls,ActnList,LazSynaSer;

type

 { TMainForm }

 TMainForm = class(TForm)
  btnRemAutoConfig:TButton;
  btnPwrStat:TButton;
  btnRemLeft:TButton;
  btnRemRight:TButton;
  btnRemDown:TButton;
  btnRemOK:TButton;
  btnRemBack:TButton;
  btnRemInfo:TButton;
  btnRemEnterPasscode:TButton;
  btnVolumeZero:TButton;
  SetID:TComboBox;
  lblChangeInput:TLabel;
  lblSetID:TLabel;
  btnRemVolMute:TButton;
  btnRemVolDown:TButton;
  btnRemVolUp:TButton;
  btnKeyLkStat:TButton;
  btnPwrOn:TButton;
  btnPwrOff:TButton;
  btnKeyLkOn:TButton;
  btnKeyLkOff:TButton;
  btnRemMenu:TButton;
  btnRemExit:TButton;
  btnRemUp:TButton;
  cbChangeInput:TComboBox;
  DisplayLog:TMemo;
  ControlPanel:TPanel;
  RemotePanel:TPanel;
  procedure btnRemEnterPasscodeClick(Sender:TObject);
  procedure btnVolumeZeroClick(Sender:TObject);
  procedure PowerClick(Sender: TObject);
  procedure KeyLockClick(Sender: TObject);
  procedure RemoteButtonClick(Sender:TObject);
  procedure cbChangeInputChange(Sender:TObject);
  procedure SendCommand(command: String);
 private
  Connection  : TBlockSerial;
  const
   cmdPower   = 'ka';
   cmdKeylock = 'km';
   cmdRemote  = 'mc';
   cmdChgInput= 'xb';
   cmdVolume  = 'kf';
 public

 end;

var
 MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

procedure TMainForm.PowerClick(Sender: TObject);
begin
 SendCommand(cmdPower+' '+IntToHex(SetID.ItemIndex,2)+' '
                         +IntToHex(TButton(Sender).Tag,2)+#$0D);
end;

procedure TMainForm.KeyLockClick(Sender: TObject);
begin
 SendCommand(cmdKeylock+' '+IntToHex(SetID.ItemIndex,2)+' '
                           +IntToHex(TButton(Sender).Tag,2)+#$0D);
end;

procedure TMainForm.btnRemEnterPasscodeClick(Sender:TObject);
var
 count: Integer;
begin
 //Sends the passcode, simulating the remote control. '0000'
 for count:=1 to 4 do
 begin
  SendCommand(cmdRemote+' '+IntToHex(SetID.ItemIndex,2)+' 10'+#$0D);
  Delay(500);
 end;
end;

procedure TMainForm.btnVolumeZeroClick(Sender:TObject);
begin
 SendCommand(cmdVolume+' '+IntToHex(SetID.ItemIndex,2)+' 00'+#$0D);
end;

procedure TMainForm.RemoteButtonClick(Sender:TObject);
begin
 SendCommand(cmdRemote+' '+IntToHex(SetID.ItemIndex,2)+' '
                          +IntToHex(TButton(Sender).Tag,2)+#$0D);
end;

procedure TMainForm.cbChangeInputChange(Sender:TObject);
begin
 SendCommand(cmdChgInput+' '+IntToHex(SetID.ItemIndex,2)+' '
                            +IntToStr(cbChangeInput.ItemIndex+90)+#$0D);
 cbChangeInput.ItemIndex:=-1;
end;

procedure TMainForm.SendCommand(command: String);
var
 commname : String;
 commnames: TStringArray;
 i,j      : Integer;
 reply    : String;
 return   : String;
 status   : Integer;
begin
 //We'll check to see if we have a serial connection, if not we'll find one
 if Connection=nil then //If this is nil, then there is no connection
 begin
  //Get device names - ls /dev/tty.* in bash to see the names
  commname:='/dev/cu.PL2303G-USBtoUART110,/dev/tty.PL2303G-USBtoUART10';//GetSerialPortNames;
  //Only continue if there are any ports
  if commname<>'' then
  begin
   //Split into an array
   commnames:=commname.Split(',');
   //Go through each serial port
   i:=1;
//   while i<Length(commnames) do
//   begin
    //Check if we have a valid port
    if commnames[i]<>'' then
    begin
     //DisplayLog.Lines.Add('Looking for LG TV on '+commnames[i]);
     Application.ProcessMessages;
     //Open each port in turn
     Connection:=TBlockSerial.Create;
     Connection.LinuxLock:=False;
     {$IFDEF UNIX}
     Connection.NonBlock:=True;
     {$ENDIF}
     Connection.Connect(commnames[i]);
     Connection.Config(9600,8,'N',SB1,false,false);
     if Connection=nil then exit;
     //Is there anything in the buffer? if so, then flush it out
     if Connection.WaitingData>0 then Connection.RecvPacket(0);
     //Send the command
     DisplayLog.Lines.Add('Sending '+command);
     Connection.SendString(AnsiString(command));
     Sleep(100); //Don't go too fast
     reply:='';
     if Connection.LastError=0 then //If sent OK
     begin
      status:=0;
      //And while there is data to be read
      while Connection.WaitingData>0 do
      begin
       return:=Connection.RecvPacket(0);
       status:=Connection.LastError;
       if status=0 then reply:=reply+return; //Add it to the return string
      end;
     end;
     return:='';
     for j:=1 to Length(reply) do
      if(ord(reply[j])<32)or(ord(reply[j])>126)then
       return:=return+'0x'+IntToHex(ord(reply[j]),2)
      else
       return:=return+reply[j];
     DisplayLog.Lines.Add('Response: '+return);
     // i:=Length(commnames);//Exit the loop if found
     Connection.Free; //Nothing here, try the next one
     Connection:=nil; //If it was the last one, this needs to be nil
    end;
    inc(i);
//   end;
  end else DisplayLog.Lines.Add('No comm ports');
 end;
end;

end.

