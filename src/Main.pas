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
{ The Original Code is Main.pas.                                               }
{                                                                              }
{ Contains various graphics related classes and subroutines required for       }
{ creating a chart and its nodes, and visual chart interaction.                }
{                                                                              }
{ Unit owner:    Mišel Krstović                                                }
{ Last modified: March 8, 2010                                                 }
{                                                                              }
{******************************************************************************}

unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ShellAPI, ComCtrls, ExtCtrls, Menus,
  IniFiles, JvAppInst{, CommCtrl};

const
  NULL = 0;
  WM_HOOK_AND_TRANSLATE = WM_USER + 1;
  BLANK_TRANSLATION = '';

type
  TfrmHookAndTranslateMain = class(TForm)
    JvAppInstances1: TJvAppInstances;
    ShutdownTimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ShutdownTimerTimer(Sender: TObject);
  private
    { Private declarations }
    GlobalClose : Boolean;
    GlobalTraining : Boolean;
    GlobalGdiHooking : Boolean;
    GlobalTransHooking : Boolean;
    GlobalIniFile : TMemIniFile;
    GlobalSleepTime : Integer;
    FClassName : String;

    function GetKey(Section, Key : String) : String;

    procedure l8Translate(WindowName : String); overload;
    procedure l8Translate(hHandle : HWND); overload;

    procedure l8handlePrimaryObjects(Tray : HWND);
    procedure l8handleSecondaryObjects(Tray : HWND);
    procedure l8handleMenus(handle : HMENU; var MenuLevel : Integer);

    function l8GetClassName : String;
    procedure l8UpdateFont(adc : HDC);
  public
    { Public declarations }
    procedure WndProc(var AMessage: TMessage); override;
  end;

var
  frmHookAndTranslateMain: TfrmHookAndTranslateMain;

implementation

uses Global, GDIHook;

{$R *.dfm}

procedure StartHook; stdcall; external 'GdiHook.dll';
procedure StopHook; stdcall; external 'GdiHook.dll';

procedure TfrmHookAndTranslateMain.WndProc(var AMessage: TMessage);
var
  hHandle,
  FoundHandle : HWND;
  ClassName_ : array [0..200] of Char;
  MenuLevel : Integer;
begin
  if AMessage.Msg = WM_HOOK_AND_TRANSLATE then begin
    hHandle := LONGWORD(AMessage.lParam);
    if IsWindow(hHandle) then begin
      l8Translate(hHandle);
    end else begin
      FoundHandle := FindWindow(PChar(l8GetClassName), nil);
      if GetClassName(FoundHandle, ClassName_, SizeOf(ClassName_))<>NULL then begin
        if ClassName_=l8GetClassName then begin
          // Menu translation
          MenuLevel := -1;
          l8handleMenus(GetMenu(FoundHandle), MenuLevel);
          SendMessage(FoundHandle, WM_NCPAINT, 1, 0); // Refresh the translated menu items
        end;
      end;
    end;
  end else begin
    inherited WndProc(AMessage);
  end;
end;

procedure TfrmHookAndTranslateMain.l8UpdateFont(adc : HDC);
var
  newFont : HFONT;
  It, Ul, So: Cardinal;
  oldFont : TEXTMETRICA;
  faceName : String;
begin
  // Only if a current font exists shall we send a new one
  if GetTextMetrics(adc, oldFont) then begin
    if GetTextFace(adc, length(faceName), PChar(faceName))=0 then faceName := 'Times New Roman';

    if oldFOnt.tmItalic<>0 then It := 1 else It := 0;
    if oldFOnt.tmUnderlined<>0 then Ul := 1 else Ul := 0;
    if oldFOnt.tmStruckOut<>0 then So := 1 else So := 0;
    newFont := CreateFontA(oldFOnt.tmHeight, oldFOnt.tmAveCharWidth, 0, 0, FW_NORMAL, It, Ul, So, DEFAULT_CHARSET,
                       OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
                       DEFAULT_PITCH or FF_DONTCARE, PChar(faceName));
  end;

  SelectObject(adc, newFont);
end;

function TfrmHookAndTranslateMain.GetKey(Section, Key : String) : String;
begin
  result := BLANK_TRANSLATION;

//  writeln('['+section+'] '+Key);
  Section := trim(Section);
  Key := trim(Key);

  Key := StringReplace(Key, #10, '', [rfReplaceAll]);
  Key := StringReplace(Key, #13, '\n', [rfReplaceAll]);
  try
    if GlobalIniFile.ValueExists(Section, Key) then begin
      result := GlobalIniFile.ReadString(Section, Key, BLANK_TRANSLATION);
      result := StringReplace(result, '\n', #13#10, [rfReplaceAll]);
    end else begin
      if GlobalTraining then begin
        GlobalIniFile.WriteString(Section, Key, BLANK_TRANSLATION);
        GlobalIniFile.UpdateFile;
      end;
    end;
  finally

  end;
end;

procedure TfrmHookAndTranslateMain.l8Translate(hHandle: HWND);
begin
  if hHandle<>NULL then begin
    l8handlePrimaryObjects(hHandle);
  end;
end;

procedure TfrmHookAndTranslateMain.l8Translate(WindowName : String);
var
  FoundHandle: HWND;
begin
  FoundHandle := FindWindow(PChar(WindowName), nil);
  if FoundHandle<>NULL then begin
    l8handlePrimaryObjects(FoundHandle);
  end;
end;

procedure TfrmHookAndTranslateMain.ShutdownTimerTimer(Sender: TObject);
var
  FoundHandle : HWND;
  WindowName  : String;
begin
  if GlobalClose then exit;

  ShutdownTimer.Enabled := false;
  try
    WindowName := l8GetClassName;
    if WindowName<>'' then begin
      FoundHandle := FindWindow(PChar(WindowName), nil);
      if FoundHandle=NULL then begin
        GlobalClose := true;
        Close;
      end;
    end;
  finally
    if not(GlobalClose) then begin
      ShutdownTimer.Interval := 1500;
      ShutdownTimer.Enabled := true;
    end;
  end;

end;

procedure TfrmHookAndTranslateMain.l8handlePrimaryObjects(Tray: HWND);
var
  C: array [0..127] of Char;
  S: string;

  Len: Integer;
  Result : String;
  customfont : HFONT;
  faceName : String;
  TrayDC : HDC;
  oldFont : TEXTMETRICA;
begin
  if GetClassName(Tray, C, SizeOf(C)) > 0 then begin
    S := StrPas(C);

    Len := SendMessage(Tray, WM_GETTEXTLENGTH, 0, 0);
    if Len>0 then begin
      TrayDC := GetDC(Tray);
      try
      SetLength(Result, Len+1);
      SendMessage(Tray, WM_GETTEXT, length(Result), LPARAM(PChar(Result)));
        result := Copy(result, 0, length(result)-1);

        if GetTextMetrics(TrayDC, oldFont) then begin
          if GetTextFace(TrayDC, length(faceName), PChar(faceName))=0 then faceName := 'Tahoma';
          customfont := CreateFont(oldFOnt.tmHeight, oldFOnt.tmAveCharWidth, 0, 0, 400, 0, 0, 0, DEFAULT_CHARSET,
                     OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
                     DEFAULT_PITCH or FF_DONTCARE, PChar(faceName));
          SendMessage(Tray, WM_SETFONT, customfont, 0);
        end;

      Result := GetKey(UpperCase(S), result);
      if Result<>'' then begin
        SendMessage(Tray, WM_SETTEXT, 0, LPARAM(PChar(Result)));
      end;
      finally
        ReleaseDC(Tray, TrayDC);
      end;
    end else begin
      // SysTabControl32
//      if S='SysTabControl32' then begin
//      if S='#32770' then begin
//        SendMessage(Tray, TCM_DELETEALLITEMS, 0, 0);
//        SendMessage(Tray, WM_COMMAND, SC_CLOSE, 0);
//      end else begin
//        writeln(S);
//      end;
    end;

//    l8handleSecondaryObjects(Tray); // todo: experimental
  end;
end;

{
  This function is no longer required,
  since the method used by utilizing a reflector hook
  is more than adequate in passing all the created windows/classes
  back for processing.
}
procedure TfrmHookAndTranslateMain.l8handleSecondaryObjects(Tray : HWND);
var
  Child: HWND;
  C: array [0..127] of Char;
  S: string;

  Len: Integer;
  Result : String;
  customfont : HFONT;
  ChildDC : HDC;
  faceName : String;
  oldFont : TEXTMETRICA;
begin
  Child := GetWindow(Tray, GW_CHILD);
  while Child <> 0 do
  begin
    if GetClassName(Child, C, SizeOf(C)) > 0 then
    begin
      S := StrPas(C);

      Len := SendMessage(Child, WM_GETTEXTLENGTH, 0, 0);
      if Len>0 then begin
        ChildDC := GetDC(Child);
        try
        SetLength(Result, Len+1);
        SendMessage(Child, WM_GETTEXT, length(Result), LPARAM(PChar(Result)));
        result := Copy(result, 0, length(result)-1);

        Result := GetKey(UpperCase(S), result);
        if Result<>'' then begin
          SendMessage(Child, WM_SETTEXT, 0, LPARAM(PChar(Result)));
        end;
        finally
          ReleaseDC(Child, ChildDC);
        end;
      end;
    end;
    Child := GetWindow(Child, GW_HWNDNEXT);
    l8handleSecondaryObjects(Child);
  end;
end;

function TfrmHookAndTranslateMain.l8GetClassName: String;
begin
  if FClassName='' then begin
    FClassName := trim(GetKey('System','ClassName'));
  end;

  result := FClassName;
end;

procedure TfrmHookAndTranslateMain.l8handleMenus(handle : HMENU; var MenuLevel : Integer);
var
  hSubMenu : HMENU;
  MenuName : String;
  Len,
  Count : Integer;
  I : Cardinal;
  Buffer : String;
  MenuItemStruc : tagMENUITEMINFO;
begin
  if handle=NULL then exit;

  Count := GetMenuItemCount(handle);
  if Count=0 then exit;

  Inc(MenuLevel);

  for i := 0 to Count - 1 do begin
    len := GetMenuString(handle, i, PChar(MenuName), 0, MF_BYPOSITION);
    SetLength(MenuName, Len+1);
    if GetMenuString(handle, i, PChar(MenuName), length(MenuName), MF_BYPOSITION)<>0 then begin
      MenuName := Copy(MenuName, 0, length(MenuName)-1);
      Buffer := GetKey('THUNDERRT6MENU', MenuName);
      if Buffer<>'' then begin
        MenuItemStruc.cbSize := sizeof(MENUITEMINFO);
        MenuItemStruc.fMask      := MIIM_STRING;
        MenuItemStruc.cch        := length(Buffer)+1;
        MenuItemStruc.dwTypeData := PChar(Buffer);
        SetMenuItemInfo(handle, i, TRUE, MenuItemStruc);
      end;
    end;

    hSubMenu := GetSubMenu(handle, MenuLevel);
    if hSubMenu<>NULL then begin
      l8handleMenus(hSubMenu, MenuLevel);
    end;
  end;
end;

procedure TfrmHookAndTranslateMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  try
    ShutdownTimer.Enabled := false;
    Application.ProcessMessages;

    if GlobalTransHooking then begin
      RemoveGlobalHook;
      Sleep(GlobalSleepTime);
    end;
    if GlobalGdiHooking then begin
      StopHook;
      Sleep(GlobalSleepTime);
    end;
  finally
    GlobalIniFile.Free;
  end;
end;

procedure TfrmHookAndTranslateMain.FormCreate(Sender: TObject);
var
  FileName : String;
  ExecResult : Cardinal;
begin
  GlobalClose := false;

  GlobalIniFile := TMemIniFile.Create(ExtractFilePath(ParamStr(0))+PathDelim+'Settings.ini');

  FileName := trim(GetKey('System','FileName'));;
  GlobalSleepTime := StrToIntDef(GetKey('System', 'SleepTime'), 1000);
  ExecResult := ShellExecute(GetDesktopWindow, 'open', PChar(FileName), nil, nil, SW_SHOWNORMAL);
  Sleep(GlobalSleepTime);

  if ExecResult>32 then begin
    GHookInstalled := false;
    LibLoaded := false;
    try
      GlobalTraining := lowercase(GetKey('System', 'Training')) = 'true';
      GlobalGdiHooking := lowercase(GetKey('System', 'GdiHooking')) = 'true';
      GlobalTransHooking := lowercase(GetKey('System', 'TransHooking')) = 'true';

      if GlobalTransHooking then begin
        GHookInstalled := SetupGlobalHook;
        Sleep(GlobalSleepTime);
      end;
      if GlobalGdiHooking then begin
        StartHook;
        Sleep(GlobalSleepTime);
      end;
    finally
      // Do nothing
    end;

    ShutdownTimer.Interval := 10000;
    ShutdownTimer.Enabled := true;
  end;
end;

end.
