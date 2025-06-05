unit Unit1;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, MacOSAll;

type

 { TForm1 }

 TForm1 = class(TForm)
  Memo1: TMemo;
  procedure FormShow(Sender: TObject);
 private

 public

 end;

var
 Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

function GetBundlePath(): string;
var
  pathRef: CFURLRef;
  pathCFStr: CFStringRef;
  pathStr: shortstring;
  status: Boolean = false;
begin
  pathRef := CFBundleCopyBundleURL(CFBundleGetMainBundle());
  pathCFStr := CFURLCopyFileSystemPath(pathRef, kCFURLPOSIXPathStyle);

  status := CFStringGetPascalString(pathCFStr, @pathStr, 255, CFStringGetSystemEncoding());

  if(status = true) then
    Result := pathStr
  else
    raise Exception.Create('Error in GetBundlePath()');
end;

procedure TForm1.FormShow(Sender: TObject);
var
  path,ext: String;
begin
  path:=GetBundlePath;
 Memo1.Lines.Add(path);
 Memo1.Lines.Add(ExtractFileName(path));
 Memo1.Lines.Add(ExtractFileExt(path));
end;

end.

