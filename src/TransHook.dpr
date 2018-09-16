library TransHook;

uses
  SysUtils,
  Classes,
  Windows,
  Messages;

var
  CurrentHook : HHook;
  DestWin     : HWND;

const
  WM_HOOK_AND_TRANSLATE = WM_USER + 1;
  APPWINDOWNAME = 'TfrmHookAndTranslateMain';

{
  GlobalWndProcHook
  ------------
  This is the hook procedure to be loaded from hooks.exe when you
  try and create a global hook. It is similar in structure to that defined
  in hook.dpr for creating a local hook, but this time it does not beep!
  Instead it stores each key pressed in an array of bytes (20 long). Whenever
  this array gets full, it writes it to a file, log.txt and starts again.
}
function GlobalWndProcHook(code: integer; wParam: word; lParam: longword): longword; stdcall;
var
  HookInfo : CWPSTRUCT;
begin
  if code<0 then begin  //if code is <0 your wndproc hook should always run CallNextHookEx instantly and
     result := CallNextHookEx(CurrentHook,code,wParam,lparam); //then return the value from it.
     Exit;
  end;

  if DestWin>0 then begin
    if (Code = HC_ACTION) then
    begin
      HookInfo := PCWPSTRUCT(lParam)^;

      case HookInfo.message of
        WM_CREATE, WM_INITDIALOG : begin
          if DestWin<>0 then begin
            SendMessage(
              DestWin,
              WM_HOOK_AND_TRANSLATE,
              0,
              HookInfo.hwnd
            );
          end;
        end;
        WM_SHOWWINDOW{, WM_INITMENU, WM_INITMENUPOPUP, WM_ACTIVATE} : begin
          if DestWin<>0 then begin
            SendMessage(
              DestWin,
              WM_HOOK_AND_TRANSLATE,
              0,
              0
            );
          end;
        end;
      end
    end;
  end;

  //call the next hook proc if there is one
  //if WndProcHook returns a non-zero value, the window that should get
  //the wndproc message doesnt get it.
  result := CallNextHookEx(CurrentHook,code,wParam,lparam);
end;

{
  SetHookHandle
  -------------
  This procedure is called by hooks.exe simply to 'inform' the dll of
  the handle generated when creating the hook. This is required
  if the hook procedure is to call CallNextHookEx. It also resets the
  position in the key list to 0.
}
procedure SetHookHandle(HookHandle: HHook); stdcall;
begin
  CurrentHook := HookHandle;
end;

exports
  GlobalWndProcHook index 1,
  SetHookHandle index 2;

begin
  DestWin := FindWindow(PChar(APPWINDOWNAME), nil);
end.
