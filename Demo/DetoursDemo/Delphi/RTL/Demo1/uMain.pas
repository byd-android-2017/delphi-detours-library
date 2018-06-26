unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  DDetours;

type
  TMyForm = class(TForm)
  private
    class var FInit: Boolean;
    class constructor Create;
  end;

  TMain = class(TMyForm)
    MemLog: TMemo;
    BtnTest: TButton;
    procedure FormCreate(Sender: TObject);
    procedure BtnTestClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Main: TMain;

implementation

{$R *.dfm}

var
  TrampolineGetMemory: function(Size: NativeInt): Pointer; cdecl = nil;
  TrampolineFreeMemory: function(P: Pointer): Integer; cdecl = nil;

function GetMemory_Hooked(Size: NativeInt): Pointer; cdecl;
begin
  Result := TrampolineGetMemory(Size);
  if Main.FInit then
  begin
    Main.MemLog.Lines.Add(Format('Allocating %d bytes at %p.', [Size, Result]));
  end;
end;

function FreeMemory_Hooked(P: Pointer): Integer; cdecl;
begin
  Result := TrampolineFreeMemory(P);
  if Main.FInit then
  begin
    Main.MemLog.Lines.Add(Format('Freeing %p address.', [P]));
  end;
end;

{ TMyForm }

class constructor TMyForm.Create;
begin
  FInit := False;
end;

{
\TMain
}

procedure TMain.FormCreate(Sender: TObject);
begin
  FInit := True;
  MemLog.Clear;
end;

procedure TMain.BtnTestClick(Sender: TObject);
var
  P: PByte;
begin
  P := GetMemory(16);
  FreeMemory(P);
  MemLog.Lines.Add('---------------------------------');
end;

initialization

BeginHooks;
@TrampolineGetMemory := InterceptCreate(@GetMemory, @GetMemory_Hooked);
@TrampolineFreeMemory := InterceptCreate(@FreeMemory, @FreeMemory_Hooked);
EndHooks;

finalization

BeginUnHooks;
InterceptRemove(@TrampolineGetMemory);
InterceptRemove(@TrampolineFreeMemory);
EndUnHooks;

end.
