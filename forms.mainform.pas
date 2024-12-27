unit forms.mainform;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  System.Skia, FMX.Objects, FMX.Skia, FMX.Controls.Presentation,
  FMX.StdCtrls, FMX.TabControl, FMX.Effects, FMX.Ani, FMX.Layouts,
  AWS.Rekognition, System.Generics.Collections,
  FMX.Media, FMX.Platform;

type
  TMainForm = class(TForm)
    MainTabControl: TTabControl;
    MainTab: TTabItem;
    RekognitionTab: TTabItem;
    TopPanel: TPanel;
    ShazamForFoodLabel: TSkLabel;
    TopRectangle2: TRectangle;
    TopRectangle1: TRectangle;
    TopLabell1: TSkLabel;
    ShadowEffect1: TShadowEffect;
    TouchToSeefoodLabel: TSkLabel;
    ShadowEffect2: TShadowEffect;
    Rectangle1: TRectangle;
    CameraOnButton: TCircle;
    CameraOnShadow: TShadowEffect;
    BackgroundRectangle: TRectangle;
    EvaluatingProgress: TCircle;
    FloatAnimation1: TFloatAnimation;
    EvaluatingLabel: TLabel;
    EvaluatingLayout: TLayout;
    ShadowEffect4: TShadowEffect;
    RekognitionImage: TImage;
    RekognitionRectangle: TRectangle;
    CameraComponent1: TCameraComponent;
    CameraOffButton: TCircle;
    ShadowEffect5: TShadowEffect;
    FakeDelayTimer: TTimer;
    NotHotDogLayout: TLayout;
    Rectangle2: TRectangle;
    NotHotdogCircle: TCircle;
    NotHotdogLabel: TSkLabel;
    ShadowEffect3: TShadowEffect;
    NotXLabel: TSkLabel;
    ShadowEffect6: TShadowEffect;
    HotdogLayout: TLayout;
    HotdogCircle: TCircle;
    HotdogRectangle: TRectangle;
    HotdogLabel: TSkLabel;
    ShadowEffect7: TShadowEffect;
    HotdogTickLabel: TSkLabel;
    ShadowEffect8: TShadowEffect;
    procedure CameraOnButtonClick(Sender: TObject);
    procedure TopLabell1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure CameraComponent1SampleBufferReady(Sender: TObject; const ATime: TMediaTime);
    procedure CameraOffButtonClick(Sender: TObject);
    procedure FakeDelayTimerTimer(Sender: TObject);
    procedure RekognitionImageClick(Sender: TObject);
  private
    FCapturing: Boolean;
    FWasHot: boolean;
    procedure TakeAPicture;
    procedure HideResults;
    procedure EndPictureCapture;
    procedure SetupLabels;
    procedure DecideIfAHotDog;
    procedure DisplayHotdogResult(const TheResult: boolean);
    function Recognise(const LookForThis: string): Boolean;
  public
    function HandleAppEvent(AAppEvent: TApplicationEvent; AContext: TObject): Boolean;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}
{$R *.LgXhdpiPh.fmx ANDROID}
{$R *.iPhone47in.fmx IOS}

uses modules.dragger, modules.fmx.locationmemory;

const
  HDogDetectionLabel = 'Hot dog'; // AWS Rekognition (and much of the rest of the planet) insists that "hotdog" is spelled as two words
  HDogScreenLabel = 'Hotdog';     // but in the spoof app, Jian Yiang spells it "Hotdog"

  // Change this value to use Appercept's AWS Reckognition client
  UseRekognition = True;

procedure TMainForm.CameraComponent1SampleBufferReady(Sender: TObject; const ATime: TMediaTime);
begin
  CameraComponent1.SampleBufferToBitmap(RekognitionImage.Bitmap, True);
end;

procedure TMainForm.CameraOnButtonClick(Sender: TObject);
begin
  MainTabControl.ActiveTab := RekognitionTab;
  TakeAPicture;
end;

procedure TMainForm.DecideIfAHotDog;
begin
  if UseRekognition then FWasHot := Recognise(HDogDetectionLabel.ToLower);
  DisplayHotdogResult(FWasHot);
  if not UseRekognition then FWasHot := Not FWasHot;
end;

procedure TMainForm.DisplayHotdogResult(const TheResult: boolean);
begin
  HotdogLayout.Visible    := TheResult;
  NotHotDogLayout.Visible := Not TheResult;
end;

procedure TMainForm.EndPictureCapture;
begin
  FCapturing               := False;
  CameraComponent1.Active  := False;
  EvaluatingLayout.Visible := True;
  FakeDelayTimer.Enabled   := True;
end;

procedure TMainForm.CameraOffButtonClick(Sender: TObject);
begin
  if not FCapturing then
    TakeAPicture
  else
    EndPictureCapture;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  try
    CameraComponent1.Active := False;
  except
    on E: Exception do
      Log.d('SeeFood camera exception: "' + E.Message + '"');
  end;

{$IFDEF MSWINDOWS}
  SaveFormLoc;
{$ENDIF}
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  var aFMXApplicationEventService: IFMXApplicationEventService;
  if TPlatformServices.Current.SupportsPlatformService(IFMXApplicationEventService, IInterface(aFMXApplicationEventService)) then
    aFMXApplicationEventService.SetApplicationEventHandler(HandleAppEvent)
  else
    ; // execute code here if you need when there is no app event service

{$IFDEF MSWINDOWS}
  LoadFormLoc;
{$ENDIF}
  FCapturing := False;
  FWasHot    := True;
  SetupLabels;
end;

function TMainForm.HandleAppEvent(AAppEvent: TApplicationEvent; AContext: TObject): Boolean;
begin
  try
    case AAppEvent of

      // This is one of the following...
      // TApplicationEvent.FinishedLaunching: ; // the app finished launching
      // TApplicationEvent.BecameActive: ; // the app became active
      // TApplicationEvent.WillBecomeForeground: ; // the app is about to become the foreground app (after we were in the background)
      // TApplicationEvent.TimeChange: ; // the time on the system was changed - i.e. daylight savings, or a new day
      // TApplicationEvent.OpenURL: ; // You application has received a request to open an URL
                                      // this usually means something asked you to handle a URL - and there are some parameters to examine
                                      // look at https://docwiki.embarcadero.com/Libraries/en/FMX.Platform.TApplicationEvent
                                      // for further details
      // TApplicationEvent.LowMemory: ; // system is low on memory, try to free memory and be prepared to stuggle with memory

      // In this app we **must** make sure the camera is turned off if we go into the background...
      TApplicationEvent.WillBecomeInactive, // the app is about to become inactive
      TApplicationEvent.EnteredBackground, // the app has entered background mode (something else is foreground)
      TApplicationEvent.WillTerminate: // The app is going to terminate (stop) now
      begin
        CameraComponent1.Active  := False;
        HideResults;
        MainTabControl.ActiveTab := MainTab;
      end;
    end;
  finally
    Result := True;
  end;
end;

procedure TMainForm.HideResults;
begin
  HotdogLayout.Visible    := False;
  NotHotDogLayout.Visible := False;
end;

procedure TMainForm.RekognitionImageClick(Sender: TObject);
begin
  HideResults;
  TakeAPicture;
end;

procedure TMainForm.SetupLabels;
begin
  HotdogLabel.Text    := HDogScreenLabel;
  NotHotdogLabel.Text := 'Not ' + HDogScreenLabel.ToLower;

  // Position the success/fail rectangles - they are not autoaligned
  NotHotDogLayout.Width      := RekognitionRectangle.Width;
  NotHotDogLayout.Position.Y := RekognitionRectangle.Height - NotHotDogLayout.Height;
  NotHotdogCircle.Position.X := (NotHotDogLayout.Width - NotHotdogCircle.Width) / 2;
  CameraOnButton.Position.X  := (BackgroundRectangle.Width - CameraOnButton.Width) / 2;
  CameraOffButton.Position.X := (NotHotDogLayout.Width - CameraOffButton.Width) / 2;
  NotXLabel.Width            := NotHotDogLayout.Width;
  HotdogLayout.Width         := NotHotDogLayout.Width;
  HotdogCircle.Width         := HotdogLayout.Width;
  HotdogCircle.Position.X    := (HotDogLayout.Width - HotdogCircle.Width) / 2;
  HotdogTickLabel.Width      := NotXLabel.Width;
end;

procedure TMainForm.FakeDelayTimerTimer(Sender: TObject);
begin
  FakeDelayTimer.Enabled   := False;
  EvaluatingLayout.Visible := False;
  CameraOffButton.Visible  := False;
  DecideIfAHotdog;
end;

procedure TMainForm.TakeAPicture;
begin
  FCapturing              := True;
  CameraOffButton.Visible := True;
  CameraComponent1.Active := True;
end;

procedure TMainForm.TopLabell1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
{$IFDEF MSWINDOWS}
  DragIt(Self.Handle);
{$ENDIF}
end;

function TMainForm.Recognise(const LookForThis: string): Boolean;
var
  LClient:         IRekognitionClient;
  LResponse:       IRekognitionDetectLabelsResponse;

  function HasMatchingAlias(const AAliases: TList<IRekognitionLabelAlias>): Boolean;
  begin
    Result := False;
    for var LAlias in AAliases do
      if LAlias.Name.ToLower.Contains(LookForThis) then
        Exit(True);
  end;

begin
  Result := False;
  LClient := TRekognitionClient.Create;
  var LStream := TBytesStream.Create;
  RekognitionImage.Bitmap.SaveToStream(LStream);
  LResponse := LClient.DetectLabels(TRekognitionImage.FromStream(LStream));
  if LResponse.IsSuccessful then
    for var RekLabel in LResponse.Labels do
      if RekLabel.Name.ToLower.Contains(LookForThis)
      or
      HasMatchingAlias(RekLabel.Aliases)
      then
        Exit(True);
end;

end.
