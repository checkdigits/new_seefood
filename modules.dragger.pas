unit modules.dragger;

interface
uses
{$IFDEF MSWINDOWS}
  fmx.platform.Win,
  Winapi.Windows,
{$ENDIF}
  FMX.Types;


  procedure DragIt(TheHandle: TWindowHandle);

implementation

procedure DragIt(TheHandle: TWindowHandle);
{$IFDEF MSWINDOWS}
const
  WM_SYSCOMMAND = $0112;
  SC_DRAGMOVE = $F012;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  SendMessage(FmxHandleToHWND(TheHandle), WM_SYSCOMMAND, SC_DRAGMOVE, 0);
{$ENDIF}
end;

end.
