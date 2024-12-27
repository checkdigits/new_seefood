program new_seefood;

uses
  System.StartUpCopy,
  FMX.Forms,
  FMX.Skia,
  forms.mainform in 'forms.mainform.pas' {MainForm},
  modules.dragger in 'modules.dragger.pas',
  modules.fmx.locationmemory in 'modules.fmx.locationmemory.pas';

{$R *.res}

begin
  GlobalUseSkia := True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
