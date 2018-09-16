{******************************************************************************}
{                                                                              }
{ Hook and Translate                                                           }
{                                                                              }
{ The contents of this file are subject to the MIT License (the "License");    }
{ you may not use this file except in compliance with the License.             }
{ You may obtain a copy of the License at https://opensource.org/licenses/MIT  }
{                                                                              }
{ Software distributed under the License is distributed on an "AS IS" basis,   }
{ WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for }
{ the specific language governing rights and limitations under the License.    }
{                                                                              }
{ The Original Code is Global.pas.                                             }
{                                                                              }
{ Contains various graphics related classes and subroutines required for       }
{ creating a chart and its nodes, and visual chart interaction.                }
{                                                                              }
{ Unit owner:    Mišel Krstović                                                }
{ Last modified: March 8, 2010                                                 }
{                                                                              }
{******************************************************************************}

unit Global;

interface

uses Windows, IniFiles, SysUtils;

//define the structure of the SetHookHandle function in transhook.dll
type
  TSetHookHandle = procedure(HookHandle: HHook); stdcall;

var
  LibLoaded: boolean; //true if transhook.dll is already loaded
  LibHandle: HInst;   //dll handle
  HookProcAdd: pointer;  //memory address of hook procedure in windows
  GHookInstalled: boolean;
  SetHookHandle: TSetHookHandle;
  CurrentHook: HHook; //contains the handle of the currently installed hook
  SettingsPath: String;
  GlobalINIFile: TMemIniFile;

function LoadHookProc: boolean;
function SetupGlobalHook: boolean;
function RemoveGlobalHook: boolean;

implementation

const
  BLANK_TRANSLATION = '';

function DllPath : String;
var
  Path : Array[0..MAX_PATH-1] of char;
begin
  if IsLibrary then SetString(Result, path, GetModuleFileName(hInstance, path, sizeof(path)))
  else result := ParamStr(0);
end;

function GetKey(Section : String; Key : String) : String;
begin
  result := BLANK_TRANSLATION;

  Section := trim(Section);
  Key := trim(Key);
  try
    if Key<>'' then result := GlobalIniFile.ReadString(Section, Key, BLANK_TRANSLATION);
  finally
    if result=BLANK_TRANSLATION then result := Key;
  end;
end;

{
  LoadHookProc
  ------------
  This function loads the hook procedure from the dll created in transhook.dll
  and obtains a handle for the dll and the address of the procedure in the
  dll. The procedure will be called 'GlobalWndProcHook'
  This procedure also loads the SetHookHandle procedure in transhook.dll. As
  explained in the dll code, this procedure is simply used to inform the dll
  of the handle for the current hook, which is needed to call CallNextHookEx
  and also to initialise the keyarray (see the dll code).
}
function LoadHookProc: boolean;
begin
  //attempt to load the dll containing our hook proc
  LibHandle:=LoadLibrary('transhook.dll');
  if LibHandle=0 then begin  //if loading fails, exit and return false
    LoadHookProc:=false;
    exit;
  end;
  //once the dll is loaded, get the address in the dll of our hook proc
  HookProcAdd:=GetProcAddress(LibHandle,'GlobalWndProcHook');
  @SetHookHandle:=GetProcAddress(LibHandle,'SetHookHandle');
  if (HookProcAdd=nil)or(@SetHookHandle=nil) then begin //if loading fails, unload library, exit and return false
    FreeLibrary(LibHandle);
    LoadHookProc:=false;
    exit;
  end;
  LoadHookProc:=true;
end;

{
  SetupGlobalHook
  ---------------
  This function installs a global hook. To the install a global hook, we first have
  to load the hook procedure that we have written from transhook.dll, using the LoadHookProc
  above. If succesful use the setwindowshookex function specifying the hook type as WH_CALLWNDPROC,
  the address of the hook procedure is that loaded from transhook.dll, the hMod is the handle
  of the loaded transhook.dll and the threadid is set to 0 to indicate a global hook.
}
function SetupGlobalHook: boolean;
var
  FoundHandle,
  FoundThreadId : HWND;
  ClassName_ : String;
begin
  SetupGlobalHook:=false;
  if LibLoaded=false then LibLoaded:=LoadHookProc; //if transhook isnt loaded, load it
  if LibLoaded=false then exit;                    //if dll loading fails, exit

  ClassName_ := trim(GetKey('System','ClassName'));
  FoundHandle := FindWindow(PChar(ClassName_), nil);
  if FoundHandle<>0 then begin
    FoundThreadID := GetWindowThreadProcessId(FoundHandle, nil);
    CurrentHook := setwindowshookex(WH_CALLWNDPROC,HookProcAdd,LibHandle,FoundThreadID); //install hook
    SetHookHandle(CurrentHook);

    if CurrentHook<>0  then SetupGlobalHook:=true; //return true if it worked
  end;
end;

function RemoveGlobalHook: boolean;
begin
  result := UnhookWindowsHookEx(CurrentHook);
end;

initialization
  SettingsPath := ExtractFilePath(DllPath)+PathDelim+'Settings.ini';
  if GlobalIniFile=nil then begin
    GlobalIniFile := TMemIniFile.Create(SettingsPath);
    GlobalIniFile.CaseSensitive := false;
  end;
end.
