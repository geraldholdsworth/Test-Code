unit MainUnit;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
 Clipbrd,LCLType;

type

 { TMainForm }

 TMainForm = class(TForm)
  Button1: TButton;
  Image1: TImage;
  Panel2: TPanel;
  SaveBtn: TButton;
  SaveDialog1: TSaveDialog;
  ScrollBox1: TScrollBox;
  Splitter1: TSplitter;
  StartStopBtn: TButton;
  Memo1: TMemo;
  Panel1: TPanel;
  procedure Button1Click(Sender: TObject);
  procedure CheckClipboard();
  procedure ReadClip(TheFormat:TClipboardFormat);//TheFormat:String);
  procedure SaveBtnClick(Sender: TObject);
  procedure StartStopBtnClick(Sender: TObject);
 private
  {$INCLUDE 'SpriteFilePalettes.pas'}
 public

 end;

var
 MainForm: TMainForm;

implementation

{$R *.lfm}

procedure TMainForm.CheckClipboard();
var
 I   : integer;
 List: TStringList;
begin
 memo1.clear;
 {$IFDEF Darwin}
 Memo1.Lines.Add('macOS');
 {$ENDIF}
 {$IFDEF Windows}
 Memo1.Lines.Add('Windows');
 {$ENDIF}
 {$IFDEF Linux}
 Memo1.Lines.Add('Linux');
 {$ENDIF}
 {$IFDEF Darwin}
 List := TStringList.Create;
 ClipBoard.SupportedFormats(List);
 for i := 0 to List.Count-1 do
 begin
  Memo1.Append('['+IntToStr(ClipBoard.FindFormatID(List.Strings[i]))+']:'
            +List.Strings[i]);
  ReadClip(ClipBoard.FindFormatID(List.Strings[i]));
 end;
 List.Free;
 {$ENDIF}
 {$IFNDEF Darwin}
 for i:=0 to Clipboard.FormatCount-1 do
 begin
  Memo1.Lines.Add('['+IntToHex(Clipboard.Formats[i],4)+']');
  ReadClip(Clipboard.Formats[i]);
 end;
 {$ENDIF}
end;

procedure TMainForm.Button1Click(Sender: TObject);
var
 F: TFileStream;
 tfn: String;
 fmt: TClipboardFormat;
 ms: TMemoryStream;
begin
 //Get temporary filename
 tfn:={GetTempDir+}GetTempFileName;
 //Save the data to the file
 F:=TFileStream.Create(tfn,fmCreate);
 F.WriteBuffer(ColourPalette256[0],Length(ColourPalette256));
 F.Free;
 ms:=TMemoryStream.Create;
 ms.Write(tfn[1],Length(tfn));
 ms.Position:=0;
 //Populate the clipboard
 Clipboard.Clear;
 fmt:=Clipboard.AddFormat('public.file-url');
 Clipboard.SetFormat(fmt,ms);
 ms.Free;
end;

procedure TMainForm.ReadClip(TheFormat:TClipboardFormat);//TheFormat:String);
var
 Stream: TMemoryStream;
 Fmt   : TClipboardFormat;
 List  : TStringList;
 output: String;
 buffer: array of Byte;
 i     : Integer;
begin
 Memo1.Lines.BeginUpdate;
 buffer:=nil;
 Stream:= TMemoryStream.Create;
 List  := TStringList.Create;
// if Clipboard.HasFormatName(TheFormat) then
 if Clipboard.HasFormat(TheFormat) then
 begin
//  Fmt:= ClipBoard.FindFormatID(TheFormat);
  Fmt:=TheFormat;
  ClipBoard.GetFormat(Fmt, Stream);
  Memo1.Lines.Add(#09+'Size: '+IntToStr(Stream.Size)+' bytes');
  if Clipboard.HasPictureFormat then
   if Clipboard.FindPictureFormatID=Fmt then
   begin
    Memo1.Lines.Add(#09+'Picture data');
    Stream.Position:=0;
    Image1.Picture.LoadFromStream(Stream);
   end;
  output:='';
  if Stream.Size>0 then
  begin
   SetLength(buffer,Stream.Size);
   Stream.Position:=0;
   Stream.Read(buffer[0],Stream.Size);
   if Length(buffer)<2048 then
   for i:=0 to Length(buffer)-1 do
   begin
    if(buffer[i]=13)or(buffer[i]=10)then
    begin
     if output<>'' then Memo1.Lines.Add(#09#09+output);
     output:='';
    end
    else
     if((buffer[i]>31)and(buffer[i]<127))or(buffer[i]=9)then
      output:=output+Chr(buffer[i])
     else
      output:=output+'{0x'+IntToHex(buffer[i],2)+'}';
   end;
   if output<>'' then Memo1.Lines.Add(#09#09+output);
{   if TheFormat='image/bmp' then
   begin
    Stream.Position:=0;
    Image1.Picture.LoadFromStream(Stream);
   end;}
  end;
 end;
 List.Free;
 Stream.Free;
 Memo1.Lines.EndUpdate;
end;

procedure TMainForm.SaveBtnClick(Sender: TObject);
begin
 {$IFDEF Darwin}
 SaveDialog1.FileName:='macOS.txt';
 {$ENDIF}
 {$IFDEF Windows}
 SaveDialog1.FileName:='Windows.txt';
 {$ENDIF}
 {$IFDEF Linux}
 SaveDialog1.FileName:='Linux.txt';
 {$ENDIF}
 if SaveDialog1.Execute then Memo1.Lines.SaveToFile(SaveDialog1.FileName);
end;

procedure TMainForm.StartStopBtnClick(Sender: TObject);
begin
 CheckClipboard;
end;

end.

