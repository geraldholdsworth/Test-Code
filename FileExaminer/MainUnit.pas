unit MainUnit;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls, StrUtils;

type

 { TMainForm }

 TMainForm = class(TForm)
  Button1: TButton;
  CheckBox1: TCheckBox;
  Memo1: TMemo;
  Panel1: TPanel;
  DirSelector: TSelectDirectoryDialog;
  procedure Button1Click(Sender: TObject);
 private

 public

 end;

var
 MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

procedure TMainForm.Button1Click(Sender: TObject);
var
 FindResult,
 size,
 filesize,
 Index      : integer;
 SearchRec  : TSearchRec;
 dir,dos,
 fname      : String;
 F          : TFileStream;
 buffer     : array of Byte;
begin
 if DirSelector.Execute then
 begin
  //First part gets a list of files in the current directory
  Memo1.Clear;
  dir:=DirSelector.FileName;
  FindResult:=FindFirst(dir+'/*.*',faAnyFile-faDirectory,SearchRec);
  index:=0;
  buffer:=nil;
  SetLength(buffer,4);
  while FindResult=0 do
  begin
   F:=TFileStream.Create(dir+'/'+SearchRec.Name,fmOpenReadWrite OR fmShareDenyNone);
   F.Position:=0;
   F.Read(buffer[0],4);
   filesize:=F.Size;
   F.Free;
   dos:='';
   for size:=0 to 3 do
    if(buffer[size]>31)and(buffer[size]<127)then dos:=dos+chr(buffer[size]);
   dos:=UpperCase(dos);
   if dos='DOS' then
   begin
    dos:='OFS';
    if buffer[3]AND 1=1 then dos:='FFS';
    if buffer[3]AND 2=2 then dos:=dos+' INTL';
    if buffer[3]AND 4=4 then dos:=dos+' DIRC';
   end;
   if not CheckBox1.Checked then
   begin
    fname:=SearchRec.Name;
    if Length(fname)>120 then fname:=LeftStr(fname,59)+'..'+RightStr(fname,59);
    Memo1.Lines.Add(PadRight(fname,120)+' : '+dos);
   end else
    Memo1.Lines.Add('"'+SearchRec.Name+'","'+dos+'","'+IntToStr(filesize div 1024)+'KB"');
   inc(Index);
   Caption:=IntToStr(Index)+' files found';
   Application.ProcessMessages;
   FindResult:=FindNext(SearchRec);
  end;
  FindClose(SearchRec);
  if CheckBox1.Checked then
   Memo1.Lines.SaveToFile(dir+'/zzz_Summary.csv')
  else
   Memo1.Lines.SaveToFile(dir+'/zzz_Summary.txt');
 end;
end;

end.

