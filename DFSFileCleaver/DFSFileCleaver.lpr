program DFSFileCleaver;

{$MODE objFPC}{$H+}

uses
  Forms, Interfaces,
  SplitDFSUnit in 'SplitDFSUnit.pas';
{$R *.res}

begin
 Application.Scaled:=True;
 Application.Title:='DFSFileCleaver';
 Application.Initialize;
 Application.CreateForm(TSplitDFSForm, SplitDFSForm);
 Application.Run;
end.
