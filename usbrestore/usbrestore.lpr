program usbrestore;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  Unit1,
  start_trd, Unit2 { you can add units after this };

  {$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Title:='USBRestore-v1.0 (MgaRemix Tools)';
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TSelectForm, SelectForm);
  Application.Run;
end.
