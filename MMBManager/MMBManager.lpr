program MMBManager;

{$mode objfpc}{$H+}

uses
 {$IFDEF UNIX}{$IFDEF UseCThreads}
 cthreads,
 {$ENDIF}{$ENDIF}
 Interfaces, // this includes the LCL widgetset
 Forms, MainUnit
 { you can add units after this };

{$R *.res}

begin
 RequireDerivedFormResource:=True;
 Application.Title:='MMB Manager';
 Application.Scaled:=True;
 Application.Initialize;
 Application.CreateForm(TMMBForm, MMBForm);
 Application.Run;
end.

