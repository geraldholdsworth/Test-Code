program HardDriveCalculator;

{$mode objfpc}{$H+}

uses
 {$IFDEF UNIX}{$IFDEF UseCThreads}
 cthreads,
 {$ENDIF}{$ENDIF}
 Interfaces, // this includes the LCL widgetset
 Forms, MainUnit;

{$R *.res}

begin
 RequireDerivedFormResource:=True;
 Application.Title:='Hard Drive Calculator';
 Application.Scaled:=True;
 Application.Initialize;
 Application.CreateForm(TMainForm, MainForm);
 Application.Run;
end.

