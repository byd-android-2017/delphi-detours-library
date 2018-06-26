unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  DDetours;

type

  IMyInterface = Interface
    ['{C300234F-BCE6-4A79-9235-4006D4F89102}']
    procedure ShowMsg(const Msg: String);
  end;

  TMain = class(TForm)
    BtnCallShowMsg: TButton;
    BtnHook: TButton;
    BtnUnHook: TButton;
    procedure BtnCallShowMsgClick(Sender: TObject);
    procedure BtnHookClick(Sender: TObject);
    procedure BtnUnHookClick(Sender: TObject);
  private
    class var
      FMyInterface: IMyInterface;
      TrampolineShowMsg: procedure(const Self; const Msg: String);

    class constructor Create;
  public
    { Public declarations }
  end;


  TMyObject = class(TInterfacedObject, IMyInterface)
  protected
    procedure ShowMsg(const Msg: String);
  end;

var
  Main: TMain;


implementation

{$R *.dfm}


{ TMyObject }

procedure TMyObject.ShowMsg(const Msg: String);
var
  S: String;
begin
  S := 'Your Message : ' + Msg;
  ShowMessage(S);
end;


{
  TMain
}

class constructor TMain.Create;
begin
  FMyInterface := TMyObject.Create;
  TrampolineShowMsg := nil;
end;

procedure InterceptShowMsg(const Target; const Msg: String);
begin
  TMain.TrampolineShowMsg(Target, 'Hooked ->' + Msg);
end;

procedure TMain.BtnHookClick(Sender: TObject);
begin
  if not Assigned(TMain.TrampolineShowMsg ) then
    @TMain.TrampolineShowMsg := InterceptCreate(TMain.FMyInterface, 3, @InterceptShowMsg);
end;

procedure TMain.BtnUnHookClick(Sender: TObject);
begin
  if Assigned(TMain.TrampolineShowMsg) then
  begin
    InterceptRemove(@TMain.TrampolineShowMsg);
    TMain.TrampolineShowMsg := nil;
  end;
end;

procedure TMain.BtnCallShowMsgClick(Sender: TObject);
begin
  TMain.FMyInterface.ShowMsg('This is a test !');
end;


end.
