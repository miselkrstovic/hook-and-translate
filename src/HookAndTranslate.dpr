program HookAndTranslate;

{%File 'Settings.ini'}

uses
  Forms,
  Main in 'Main.pas' {frmHookAndTranslateMain},
  Global in 'Global.pas',
  GdiHook in 'GdiHook.pas';

{$R *.res}

begin
//  ReportMemoryLeaksOnShutdown := (DebugHook <> 0);
  Application.Initialize;
  Application.CreateForm(TfrmHookAndTranslateMain, frmHookAndTranslateMain);
  Application.Run;
end.
