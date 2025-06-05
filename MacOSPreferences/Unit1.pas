unit Unit1;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, MacOSAll, CFPreferences,
 StdCtrls;

type

 { TForm1 }

 TForm1 = class(TForm)
  CheckBox1,
  CheckBox2,
  CheckBox3,
  CheckBox4: TCheckBox;
  procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
  procedure FormCreate(Sender: TObject);
 private
    IsValid: Boolean;  // On return indicates if key exists and has valid data
    Pref: Integer;
    ItemName: CFStringRef;
    ItemVal: CFPropertyListRef;
 public

 end;

var
 Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
    try
       if (CheckBox1.Checked) then
         begin
           ItemName := CFStr('Check1');
           ItemVal := CFStringCreateWithPascalString(kCFAllocatorDefault,'1',kCFStringEncodingUTF8);
           CFPreferencesSetAppValue(ItemName,ItemVal,kCFPreferencesCurrentApplication);
         end
       else
         begin
           ItemName := CFStr('Check1');
           ItemVal := CFStringCreateWithPascalString(kCFAllocatorDefault,'0',kCFStringEncodingUTF8);
           CFPreferencesSetAppValue(ItemName,ItemVal,kCFPreferencesCurrentApplication);
         end;

       if (CheckBox2.Checked) then
         begin
           ItemName := CFStr('Check2');
           ItemVal := CFStringCreateWithPascalString(kCFAllocatorDefault,'1',kCFStringEncodingUTF8);
           CFPreferencesSetAppValue(ItemName,ItemVal,kCFPreferencesCurrentApplication);
         end
       else
         begin
           ItemName := CFStr('Check2');
           ItemVal := CFStringCreateWithPascalString(kCFAllocatorDefault,'0',kCFStringEncodingUTF8);
           CFPreferencesSetAppValue(ItemName,ItemVal,kCFPreferencesCurrentApplication);
         end;

       if (CheckBox3.Checked) then
         begin
           ItemName := CFStr('Check3');
           ItemVal := CFStringCreateWithPascalString(kCFAllocatorDefault,'1',kCFStringEncodingUTF8);
           CFPreferencesSetAppValue(ItemName,ItemVal,kCFPreferencesCurrentApplication);
         end
       else
         begin
           ItemName := CFStr('Check3');
           ItemVal := CFStringCreateWithPascalString(kCFAllocatorDefault,'0',kCFStringEncodingUTF8);
           CFPreferencesSetAppValue(ItemName,ItemVal,kCFPreferencesCurrentApplication);
         end;

       if (CheckBox4.Checked) then
         begin
           ItemName := CFStr('Check4');
           ItemVal := CFStringCreateWithPascalString(kCFAllocatorDefault,'1',kCFStringEncodingUTF8);
           CFPreferencesSetAppValue(ItemName,ItemVal,kCFPreferencesCurrentApplication);
         end
       else
         begin
           ItemName := CFStr('Check4');
           ItemVal := CFStringCreateWithPascalString(kCFAllocatorDefault,'0',kCFStringEncodingUTF8);
           CFPreferencesSetAppValue(ItemName,ItemVal,kCFPreferencesCurrentApplication);
         end;

       // write out the preference data
       CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);

     except
       on E : Exception do
         ShowMessage(E.ClassName+' error raised, with message : '+E.Message);
     end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  try
     Pref := CFPreferencesGetAppIntegerValue(CFStr('Check1'),kCFPreferencesCurrentApplication,IsValid);
     if (Pref = 1) then
        CheckBox1.Checked := true
     else
        CheckBox1.Checked := false;

     Pref := CFPreferencesGetAppIntegerValue(CFStr('Check2'),kCFPreferencesCurrentApplication,IsValid);
     if (Pref = 1) then
        CheckBox2.Checked := true
     else
        CheckBox2.Checked := false;

     Pref := CFPreferencesGetAppIntegerValue(CFStr('Check3'),kCFPreferencesCurrentApplication,IsValid);
     if (Pref = 1) then
        CheckBox3.Checked := true
     else
        CheckBox3.Checked := false;

     Pref := CFPreferencesGetAppIntegerValue(CFStr('Check4'),kCFPreferencesCurrentApplication,IsValid);
     if (Pref = 1) then
        CheckBox4.Checked := true
     else
        CheckBox4.Checked := false;

  except
    on E : Exception do
      ShowMessage(E.ClassName+' error raised, with message : '+E.Message);
  end;
end;

end.

