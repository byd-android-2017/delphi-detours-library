# Introduction #
The **Delphi Detours Library** is a library allowing you to insert and remove hook from function . It supports both (x86 and x64) architecture.

The basic idea of this library is to replace the prologue of the target function with the JMP (unconditional jump) instruction to the intercepted function.

## Hooking Rules : #

In order to run your hook correctly, you must follow those rules:
  * Intercept procedure must have the same original procedure signature. That means same parameters (types) and same calling convention.
  * When hooking Delphi Object/COM Object, the first parameter of the `InterceptProc`/`Trampoline` must be a pointer to that object, that's what we call `Self`.
  * In multi-hooks, each hook needs its own `NextHook`/`Trampoline` function.
  * When hooking a lot of functions, make sure that you are hooking inside (**BeginHooks/EndHooks**) **frame** and unhooking inside (**BeginUnHooks/EndUnHooks**)**frame**. This will speed up hooks installation.
  * Never try to call the original function directly inside Intercept function. Always use `NextHook`/`Trampoline` function.

## DDL functions

This library contains the following functions 
  * **InterceptCreate**
  * **InterceptRemove**
  * **GetNHook**
  * **IsHooked**
  * **BeginHooks**
  * **EndHooks**
  * **BeginUnHooks**
  * **EndUnHooks**

### InterceptCreate 

```pascal
function InterceptCreate(const TargetProc, InterceptProc: Pointer; Options: Byte = v1compatibility): Pointer; overload;

function InterceptCreate(const Module, Method: string; const InterceptProc: Pointer; ForceLoadModule: Boolean = False; Options: Byte = v1compatibility)
  : Pointer; overload;
  
function InterceptCreate(const TargetInterface; MethodIndex: Integer; const InterceptProc: Pointer; Options: Byte = v1compatibility): Pointer; overload;
```
This function can hook (redirect) the TargetProc to the InterceptProc.

| Parameter           | Description                                                  |
| ------------------- | ------------------------------------------------------------ |
| **TargetProc**      | A pointer to the target function that you are going to hook. |
| **InterceptProc**   | A pointer to the intercept function, this one will be executed instead of the original function. |
| **Options**         | Actually, there is only one option that can be used ('ST').<br />    ST:**Suspend all thread.** |
|                     |                                                              |
| **Module**          | Library or Module Name.                                      |
| **MethodName**      | Function name that you will hook.                            |
| **ForceLoadModule** | if True, the DDL will try to load the module/library if it's not loaded. |
|                     |                                                              |
| **TargetInterface** | The interface that containts the method that you are going to hook. |
| **MethodIndex**     | Method's Index inside the interface .<br />  a)  Zero based counting: you must start counting from **zero**.<br />  b)  Counting must be from the top to the bottom.<br />  c)  You must count all methods declared in parents interface. |
|                     |                                                              |
| **Return**          | The return value is a pointer to the **TrampoLine function**. |

The **TrampoLine function** can execute the original function (TargetProc).

If the function succeeds, the return value is a pointer to the `TrampoLine` function. If the function fails , the return value is **nil**.

### InterceptRemove 

```pascal
function InterceptRemove(const Trampo: Pointer; Options: Byte = v1compatibility): Integer;
```
Remove the registered hook from the `TargetProc`.

| Parameter      | Description                                                  |
| -------------- | ------------------------------------------------------------ |
| **Trampoline** | A pointer to the Trampoline that was returned by the **InterceptCreate** function .It is necessary that you provide a valid parameter . |
| **Return**     | The function returns the number of hook that are still alive. |

### GetNHook

```pascal
function GetNHook(const TargetProc: Pointer): ShortInt;
```
Return the number of hook which are in current use.

### IsHooked 

```delphi
function IsHooked(const TargetProc: Pointer): Boolean;
```
Check if TargetProc is hooked.

## Speeding up DDL 

Sometimes when hooking a lot of functions, DDL can take some time, because it suspends all threads when hooking and unhooking for every Hook/UnHook action. To speed things up a bit, you could Hook/UnHook inside (**BeginHooks/EndHooks**) and (**BeginUnHooks/EndUnHooks**)**frame**. In that way DDL will suspend/resume threads only once.

## Example 

### 1. Hooking Api function

```pascal
uses
  System.SysUtils,
  WinApi.Windows,
  DDetours;
var
  TrampolineMessageBoxW: function(hWnd: hWnd; lpText, lpCaption: LPCWSTR; uType: UINT): Integer; stdcall;

function InterceptMessageBoxW(hWnd: hWnd; lpText, lpCaption: LPCWSTR; uType: UINT): Integer; stdcall;
begin
  Result := TrampolineMessageBoxW(hWnd, 'Hooked', lpCaption, uType);
end;

begin
  TrampolineMessageBoxW := InterceptCreate(@MessageBoxW, @InterceptMessageBoxW);
  MessageBoxW(0, 'Org Txt', 'Caption', MB_OK);
  InterceptRemove(@TrampolineMessageBoxW);
  MessageBoxW(0, 'Org Txt', 'Caption', MB_OK);
end.
```

###  2. Hooking COM Object

```pascal

uses
  System.SysUtils,
  ActiveX, ShlObj, ComObj,
  WinApi.Windows,
  CPUID
  DDetours,
  InstDecode;
var
  { First parameter must be Self! }
  Trampoline_FileOpenDialog_Show: function(const Self; hwndParent: HWND): HRESULT; stdcall;
  Trampoline_FileOpenDialog_SetTitle: function(const Self; pszTitle: LPCWSTR): HRESULT; stdcall;

function Intercept_FileOpenDialog_SetTitle(const Self; pszTitle: LPCWSTR): HRESULT; stdcall;
begin
  Writeln('Original Title = ' + pszTitle);
  Result := Trampoline_FileOpenDialog_SetTitle(Self, 'Hooked');
end;

function Intercept_FileOpenDialog_Show(const Self; hwndParent: HWND): HRESULT; stdcall;
begin
  Writeln('Execution FileOpenDialog.Show ..');
  Result := Trampoline_FileOpenDialog_Show(Self, hwndParent);
end;

var
  FileOpenDialog: IFileOpenDialog;

begin
  { initialization }
  CoInitialize(0);
  FileOpenDialog := CreateComObject(CLSID_FileOpenDialog) as IFileOpenDialog;

  { Installing Hook }
  BeginHooks();
  @Trampoline_FileOpenDialog_Show := InterceptCreate(FileOpenDialog, 3, @Intercept_FileOpenDialog_Show);
  Trampoline_FileOpenDialog_SetTitle := InterceptCreate(FileOpenDialog, 17, @Intercept_FileOpenDialog_SetTitle);
  EndHooks();

  { Show OpenDialog }
  FileOpenDialog.SetTitle('Open..');
  FileOpenDialog.Show(0);

  { Removing Hook }
  BeginUnHooks();
  InterceptRemove(@Trampoline_FileOpenDialog_Show);
  InterceptRemove(@Trampoline_FileOpenDialog_SetTitle);
  EndUnHooks();
end.
```

### 3. Hooking Delphi Methods inside interface

```pascal
type
  IMyInterface = Interface
    procedure ShowMsg(const Msg: String);
  end;

  TMyObject = class(TInterfacedObject, IMyInterface)
  public
    procedure ShowMsg(const Msg: String);
  end;

  { TMyObject }

procedure TMyObject.ShowMsg(const Msg: String);
begin
  Writeln(Msg);
end;

var
  FMyInterface: IMyInterface;
  TrampolineShowMsg: procedure(const Self; const Msg: String) = nil;

procedure InterceptShowMsg(const Self; const Msg: String);
begin
  TrampolineShowMsg(Self, 'Msg Hooked !');
end;
```
You can hook using two way:

#### Hooking By Method Index

```pascal
begin
  FMyInterface := TMyObject.Create;
  @TrampolineShowMsg := InterceptCreate(FMyInterface, 3, @InterceptShowMsg);
  FMyInterface.ShowMsg('SimpleMsg');
  ReadLn;
end.
```
#### Hooking By Method Name

```pascal
begin
  FMyInterface := TMyObject.Create;
  @TrampolineShowMsg := InterceptCreate(FMyInterface, 'ShowMsg', @InterceptShowMsg);
  FMyInterface.ShowMsg('SimpleMsg');
  ReadLn;
end.
```

### 4. Hooking a Delphi Constructor

```pascal
type
  TCreate = function(InstanceOrVMT: Pointer; Alloc: ShortInt; [Constructor Arguments]): Pointer;
```

First parameter is a pointer to the VMT, the second is a one byte length argument (a Boolean like type to specify whether to alloc memory or not). After that the object constructors arguments can safely be declared.

```pascal
type
  TMyObj = class(TObject)
  public
    Constructor Create(Arg: Integer); virtual;
  end;

type
  TCreate = function(InstanceOrVMT: Pointer; Alloc: ShortInt; Arg: Integer): Pointer;
var
  TrampoCreate: TCreate;

function Hooked(InstanceOrVMT: Pointer; Alloc: ShortInt; Arg: Integer): Pointer;
begin
  ShowMessage(IntToStr(Arg));
  Result := TrampoCreate(InstanceOrVMT, Alloc, Arg);
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  m: TMyObj;
begin
  m := TMyObj.Create(5);
end;

{ TMyObj }

constructor TMyObj.Create(Arg: Integer);
begin
  ShowMessage('Created!');
end;

begin
  TrampoCreate := InterceptCreate(@TMyObj.Create, @Hooked);
end
```
