library GdiHook;

uses
  Windows,
  SysUtils,
  IniFiles,
  HookTextUnit in 'units\HookTextUnit.pas',
  PEStuff in 'units\PEStuff.pas';

const
  BLANK_TRANSLATION = '';

var
  HookHandle     : THandle;
  GlobalIniFile  : TMemIniFile;
  GlobalSettingsPath : WideString;

function DllPath : WideString;
var
  Path : Array[0..MAX_PATH-1] of WideChar;
begin
  if IsLibrary then SetString(Result, path, GetModuleFileNameW(hInstance, path, sizeof(path)))
  else result := WideParamStr(0);
end;

function GetKey(Section : WideString; Key : WideString) : WideString;
begin
  result := BLANK_TRANSLATION;

  Key := trim(Key);
  try
    if Key<>'' then result := GlobalIniFile.ReadString(Section, Key, BLANK_TRANSLATION);
  finally
    if result=BLANK_TRANSLATION then result := Key;
  end;
end;

function GetTrans(Key : WideString) : WideString;
begin
  result := BLANK_TRANSLATION;

  Key := trim(Key);
  try
    if Key<>'' then result := GlobalIniFile.ReadString('STATIC', Key, BLANK_TRANSLATION);
  finally
    if result=BLANK_TRANSLATION then result := Key;
  end;
end;

function Conv(s: WideString): WideString;
Var
  i : Integer;
  w : WideString;
begin
  Result:='';
  try
    if s='' then exit;
    i:=1;
    while (i<=length(s)) do begin
      // convert everything
      w:='';
      while (i<=length(s)) do begin
        w := w + s[i];
        Inc(i);
      end;
      Result := Result + GetTrans(w);
    end;
  except
  end;
end;

function GetMsgProc(code: integer; removal: integer; msg: Pointer): Integer; stdcall;
begin
  Result:=0;
end;

procedure StartHook; stdcall;
var
  FoundHandle,
  FoundThreadID : HWND;
  ClassName_ : WideString;
begin
  ClassName_ := trim(GetKey('System','ClassName'));
  FoundHandle := FindWindowW(PWideChar(ClassName_), nil);
  if FoundHandle<>0 then begin
    FoundThreadID := GetWindowThreadProcessId(FoundHandle, nil);
    HookHandle := SetWindowsHookExW(WH_GETMESSAGE, @GetMsgProc, hInstance, FoundThreadID);
  end;
end;

procedure StopHook; stdcall;
begin
  UnhookWindowsHookEx(HookHandle);

  GlobalIniFile.Free;
end;

exports
  StartHook,
  StopHook;

begin
  if GlobalIniFile=nil then begin
    GlobalSettingsPath := ExtractFilePath(DllPath)+PathDelim+'Settings.ini';  
    GlobalIniFile := TMemIniFile.Create(GlobalSettingsPath);
    GlobalIniFile.CaseSensitive := false;
  end;

  HookTextOut(Conv);
end.

