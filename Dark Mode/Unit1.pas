unit Unit1;

{$mode objfpc}{$H+}
{$modeswitch ObjectiveC1}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs
 {$IFDEF Darwin},CocoaAll, CocoaUtils, MacOSAll{$ENDIF}
 {$IFDEF Windows},Windows, Win32Proc, Registry{$ENDIF};

type

 { TForm1 }

 TForm1 = class(TForm)
  procedure FormPaint(Sender: TObject);
 private

 public

 end;

function IsDarkTheme: boolean;
{$IFDEF Darwin}function MojaveOrNewer: boolean;{$ENDIF}

var
 Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormPaint(Sender: TObject);
begin
 if IsDarkTheme then Caption:='Dark Mode' else Caption:='Light Mode';
end;

{$IFDEF Darwin}
function MojaveOrNewer: boolean;
var
  minOsVer: NSOperatingSystemVersion;
begin
 //Setup minimum version (Mojave)
 minOsVer.majorVersion:=10;
 minOsVer.minorVersion:=14;
 minOsVer.patchVersion:=0;
 // Check minimum version
 if(NSProcessInfo.ProcessInfo.isOperatingSystemAtLeastVersion(minOSVer)) then
  Result:=True
 else
  Result:=False;
end;

function IsDarkTheme: boolean;
var
 sMode: string;
begin
 Result:=false;
 if MojaveOrNewer then
 begin
  sMode :=CFStringToStr(CFStringRef(NSApp.effectiveAppearance.name));
  Result:=Pos('Dark',sMode)>0;
 end;
end;
{$ENDIF}

{$IFDEF Windows}
function IsDarkTheme: boolean;
const
 KEYPATH='\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize';
 KEYNAME='AppsUseLightTheme';
var
 LightKey: boolean;
 Registry: TRegistry;
begin
 Result  :=false;
 Registry:=TRegistry.Create;
 try
  Registry.RootKey:=HKEY_CURRENT_USER;
  if Registry.OpenKeyReadOnly(KEYPATH) then
  begin
   if Registry.ValueExists(KEYNAME) then
    LightKey:=Registry.ReadBool(KEYNAME)
   else
    LightKey:=true;
  end
  else
   LightKey:=true;
  Result:=not LightKey
 finally
  Registry.Free;
 end;
end;
{$ENDIF}

end.

