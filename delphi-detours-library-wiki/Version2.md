# Delphi Detours Library version 2 #

# Major changes #

  1. Introduced new hooking model architecture.
  1. Many BugFix
  1. Added multi hook support.
  1. Added hook detecting feature.
  1. Introduced instructions mapping feature.
  1. Added COM object hooking support.
  1. Generate better opcodes.
  1. New InstDecode Library

## New hooking model architecture ##

The new version introduces a new hooking model architecture, allowing support for **multi hooks** as well as a **single hook**.

Whatever, your hook is installed from you application process or via (dll,..), DDL will mange your hook to run without problems with others hooks.

![ddl](https://cloud.githubusercontent.com/assets/12677682/23681969/a37f09b0-0391-11e7-8c39-39d2ea2ab603.png)

With this new architecture, DDL guaranties:
  * New hooks will never override valid adjacent routines.
  * A single TrampoLine function for all installed hooks.
  * The TrampoLine is as much as possible small in size.
  * Removing a hook does not affect others hooks.

## BugFix ##

  * Fixed instructions decoding related bugs.
  * Fixed memory allocation bug.
  * Fixed branch calculation.
  * Fixed VirtualFree bug.
  * Fixed hooking functions that have many jmp before entering main implementation.

## Multi Hooking ##
  * A target function can be hooked by **several hooks.**
  * Calling TrampoLine will result in calling next installed hook.
  * The last caller for TrampoLine executes the original code.

You can think like functions overriding inside a class.

## Detecting Hook ##
In this version, I introduced new functions to detect if a function is being hooked:
```pascal
{Return the number of installed hooks on a function}
function GetNHook(const TargetProc: Pointer): ShortInt;

{Check if the function is hooked}
function IsHooked(const TargetProc: Pointer): Boolean;
```

## Instructions Mapping ##

DDL will try to correct relative offset when it's possible, however when the new offset size is greater than 32-bits (especially on x64) it will try to map the instruction to an alternative instruction or even generate an opcodes that will act as the original.

![map](https://cloud.githubusercontent.com/assets/12677682/23681981/b4e2cd04-0391-11e7-9f11-21885dbaa498.png)

This process is used only when DDL detects that executing a TrampoLine routine may fail.

## COM object/Interface hooking support ##
The new version provides support for hooking methods declared inside interface.
The hook will be installed at the top of function code implementation.
```pascal
const
  IID_MyInterface = '{569B8AF2-0C44-4AE4-827D-56FE49367F24}';

type
  IMyInterface = Interface(IInterface)
    [IID_MyInterface]
    procedure ShowMsg(const Msg: string);
  end;

  TMyObject = class(TInterfacedObject, IMyInterface)
    procedure ShowMsg(const Msg: string);
  end;

var
  FMyInterface: IMyInterface; 
	
{ TMyObject }

procedure TMyObject.ShowMsg(const Msg: string);
begin
  // Your hook will be installed here !
  ShowMessage(Msg);
end;

procedure MyInterface_ShowMsg_Hook(const Self; const Msg: string);
begin
  Trampo_MyInterface_ShowMsg(Self, 'Message Hooked!');
end;

@Trampo_MyInterface_ShowMsg := InterceptCreate(FMyInterface, 3, @MyInterface_ShowMsg_Hook);

```
The snippet below, shown how to hook COM object:
```pas
{Simple example showing how to hook COM object }
var
  { First parameter must be Self! }
  Trampoline_FileOpenDialog_SetTitle: function(const Self; pszTitle: LPCWSTR): HRESULT; stdcall;

function Intercept_FileOpenDialog_SetTitle(const Self; pszTitle: LPCWSTR): HRESULT; stdcall;
begin
  Writeln('Original Title = ' + pszTitle);
  Result := Trampoline_FileOpenDialog_SetTitle(Self, 'Hooked');
end;

var
  FileOpenDialog: IFileOpenDialog;

begin
  { initialization }
  CoInitialize(0);
  FileOpenDialog := CreateComObject(CLSID_FileOpenDialog) as IFileOpenDialog;

  { Installing Hook }
  Trampoline_FileOpenDialog_SetTitle := InterceptCreate(FileOpenDialog, 17, @Intercept_FileOpenDialog_SetTitle);
 
  { Show OpenDialog }
  FileOpenDialog.SetTitle('Open..');
  FileOpenDialog.Show(0);

  { Removing Hook }
  InterceptRemove(@Trampoline_FileOpenDialog_SetTitle); 
end.
```

## Generate better opcodes ##
In this new version, DDL generates better opcodes for branch and for nop instructions.

<u><b>Branch instructions:</b></u>

DDL calculates the offset first then it decides what's the perfect branch/jump to use :
  1. JMP Rel8
  1. JMP Rel16 (x32 only)
  1. JMP Rel32
  1. JMP Mem32 (x32 only)
  1. JMP Mem64 (x64 only)
  1. JMP Rip Zero (x64 only)

Using better jmp will result in a small trampoline size.

<u><b>Nop instructions:</b></u>

DDL uses multi-bytes Nop instructions instead of the traditional (Nop N) instructions.

The use of multi-bytes nop is determined by your CPU. If your CPU supports it, DDL will use it when it's possible. Otherwise
it uses traditional Nop instructions.

## InstDecode Library ##
The new InstDecode Library includes the following updates :
  * Updated opcodes map .
  * Improved Decoding Process .=> Very faster than the old one !
  * Added support to three byte opcodes escape Table.
  * Added support to vex decoding (two & three bytes).
  * Added support to groups opcodes instructions.
  * Added support to decode invalid opcodes .
  * Added support to 16-bits ModRm .
  * Added support to handling errors.
  * Added support for mandatory prefixes.
  * Reduce memory usage .
  * Removed inused fields.
  * Better support for REX prefix.
  * Reduce OpCodesTable data size (the old : 8670 bytes => the new one : 1020 bytes !)
  * BugFix : FPU instructions length.
  * BugFix : Invalid instructions on x64/x32.
  * BugFix : Calculating branch destination.
  * BugFix : Instructions that use two immediat .
  * BugFix : Invalid instructions .
  * BugFix : Invalid instructions for some mandatory prefixes.
  * Many Others Bug Fix.
