unit HookTextUnit;

interface

uses Windows, SysUtils, Classes, PEStuff;

type
  TConvertTextFunction = function(text: String): String;
  TTextOutA = function(hdc: HDC; x,y: Integer; text: PAnsiChar; len: Integer): BOOL; stdcall;
  TTextOutW = function(hdc: HDC; x,y: Integer; text: PWideChar; len: Integer): BOOL; stdcall;
  TExtTextOutA = function(hdc: HDC; x,y: Integer; Options: DWORD; Clip: PRect;
                        text: PAnsiChar; len: Integer; dx: PInteger): BOOL; stdcall;
  TExtTextOutW = function(hdc: HDC; x,y: Integer; Options: DWORD; Clip: PRect;
                        text: PWideChar; len: Integer; dx: PInteger): BOOL; stdcall;
  TDrawTextA = function(hdc: HDC; text: PAnsiChar; len: Integer; rect: PRect;
                        Format: DWORD): Integer; stdcall;
  TDrawTextW = function(hdc: HDC; text: PWideChar; len: Integer; rect: PRect;
                        Format: DWORD): Integer; stdcall;
  TDrawTextExA = function(hdc: HDC; text: PAnsiChar; len: Integer; rect: PRect;
                        Format: DWORD; DTParams: PDrawTextParams): Integer; stdcall;
  TDrawTextExW = function(hdc: HDC; text: PWideChar; len: Integer; rect: PRect;
                        Format: DWORD; DTParams: PDrawTextParams): Integer; stdcall;

  TTabbedTextOutA = function(hdc: HDC; x,y: Integer; text: PAnsiChar; len: Integer;
                         TabCount: Integer; TabPositions: PInteger; TabOrigin: Integer): Integer; stdcall;
  TTabbedTextOutW = function(hdc: HDC; x,y: Integer; text: PWideChar; len: Integer;
                         TabCount: Integer; TabPositions: PInteger;
TabOrigin: Integer): Integer; stdcall;
  TPolyTextOutA = function(hdc: HDC; pptxt: PPOLYTEXTA; count: Integer):
BOOL; stdcall;
  TPolyTextOutW = function(hdc: HDC; pptxt: PPOLYTEXTW; count: Integer):
BOOL; stdcall;

  TGetTextExtentExPointA = function(hdc: HDC; text: PAnsiChar; len:
Integer;
                          maxExtent: Integer; Fit: PInteger; Dx:
PInteger; Size: Pointer): BOOL; stdcall;
  TGetTextExtentExPointW = function(hdc: HDC; text: PWideChar; len:
Integer;
                          maxExtent: Integer; Fit: PInteger; Dx:
PInteger; Size: Pointer): BOOL; stdcall;
  TGetTextExtentPoint32A = function(hdc: HDC; text: PAnsiChar; len:
Integer; Size: Pointer): BOOL; stdcall;
  TGetTextExtentPoint32W = function(hdc: HDC; text: PWideChar; len:
Integer; Size: Pointer): BOOL; stdcall;
  TGetTextExtentPointA = function(hdc: HDC; text: PAnsiChar; len:
Integer; Size: Pointer): BOOL; stdcall;
  TGetTextExtentPointW = function(hdc: HDC; text: PWideChar; len:
Integer; Size: Pointer): BOOL; stdcall;

  PPointer = ^Pointer;

  TImportCode = packed record
    JumpInstruction: Word; // should be $25FF
    AddressOfPointerToFunction: PPointer;
  end;
  PImportCode = ^TImportCode;

procedure HookTextOut(ConvertFunction: TConvertTextFunction);
procedure UnhookTextOut;

implementation

Var
  ConvertTextFunction: TConvertTextFunction = nil;
  OldTextOutA: TTextOutA = nil;
  OldTextOutW: TTextOutW = nil;
  OldExtTextOutA: TExtTextOutA = nil;
  OldExtTextOutW: TExtTextOutW = nil;
  OldDrawTextA: TDrawTextA = nil;
  OldDrawTextW: TDrawTextW = nil;
  OldDrawTextExA: TDrawTextExA = nil;
  OldDrawTextExW: TDrawTextExW = nil;
  OldTabbedTextOutA: TTabbedTextOutA = nil;
  OldTabbedTextOutW: TTabbedTextOutW = nil;
  OldPolyTextOutA: TPolyTextOutA = nil;
  OldPolyTextOutW: TPolyTextOutW = nil;
  OldGetTextExtentExPointA: TGetTextExtentExPointA = nil;
  OldGetTextExtentExPointW: TGetTextExtentExPointW = nil;
  OldGetTextExtentPoint32A: TGetTextExtentPoint32A = nil;
  OldGetTextExtentPoint32W: TGetTextExtentPoint32W = nil;
  OldGetTextExtentPointA: TGetTextExtentPointA = nil;
  OldGetTextExtentPointW: TGetTextExtentPointW = nil;

function StrLenW(s: PWideChar): Integer;
Var i: Integer;
begin
  if s=nil then begin
    Result:=0; exit;
  end;
  i:=0;
  try
    while (s[i]<>#0) do inc(i);
  except
  end;
  Result:=i;
end;

procedure UpdateFont(adc : HDC);
var
  newFont : HFONT;
  It, Ul, So: Cardinal;
  oldFont : TEXTMETRICA;
  faceName : String;
  oldObject : HGDIOBJ;
begin
  // Only if a current font exists shall we send a new one
  if GetTextMetricsA(adc, oldFont) then begin
    if GetTextFaceA(adc, length(faceName), PChar(faceName))=0 then faceName := 'Tahoma';

    if oldFOnt.tmItalic<>0 then It := 1 else It := 0;
    if oldFOnt.tmUnderlined<>0 then Ul := 1 else Ul := 0;
    if oldFOnt.tmStruckOut<>0 then So := 1 else So := 0;
    newFont := CreateFontA(oldFOnt.tmHeight, oldFOnt.tmAveCharWidth, 0, 0, FW_NORMAL, It, Ul, So, DEFAULT_CHARSET,
                       OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
                       DEFAULT_PITCH or FF_DONTCARE, PChar(faceName));

    oldObject := SelectObject(adc, newFont);
    if oldObject<>0 then DeleteObject(oldObject);
  end;
end;

procedure UpdateFontW(adc : HDC);
var
  newFont : HFONT;
  It, Ul, So: Cardinal;
  oldFont : TEXTMETRICW;
  faceName : WideString;
  oldObject : HGDIOBJ;
begin
  // Only if a current font exists shall we send a new one
  if GetTextMetricsW(adc, oldFont) then begin
    if GetTextFaceW(adc, length(faceName), PWideChar(faceName))=0 then faceName := 'Tahoma';

    if oldFOnt.tmItalic<>0 then It := 1 else It := 0;
    if oldFOnt.tmUnderlined<>0 then Ul := 1 else Ul := 0;
    if oldFOnt.tmStruckOut<>0 then So := 1 else So := 0;
    newFont := CreateFontW(oldFOnt.tmHeight, oldFOnt.tmAveCharWidth, 0, 0, FW_NORMAL, It, Ul, So, DEFAULT_CHARSET,
                       OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
                       DEFAULT_PITCH or FF_DONTCARE, PWideChar(faceName));

    oldObject := SelectObject(adc, newFont);
    if oldObject<>0 then DeleteObject(oldObject);
  end;
end;

function NewTextOutA(hdc: HDC; x,y: Integer; text: PAnsiChar; len:
Integer): BOOL; stdcall;
Var s: String;
begin
  UpdateFont(hdc);
  try
  if Len<0 then Len:=strlen(text);
    If Len>0 then begin
      SetLength(s,len);
      FillChar(s[1],len+1,0);
      Move(text^,s[1],len);
      if @ConvertTextFunction<>nil then
        s:=ConvertTextFunction(s);
      if @OldTextOutA<>nil then
        Result:=OldTextOutA(hdc,x,y,PAnsiChar(s),length(s))
      else
        Result:=False;
    end else Result:=OldTextOutA(hdc,x,y,PAnsiChar(s),0);
  except
    Result:=False;
  end;
end;

function NewTextOutW(hdc: HDC; x,y: Integer; text: PWideChar; len:
Integer): BOOL; stdcall;
Var s: WideString;
begin
  UpdateFontW(hdc);
  try
  if Len<0 then Len:=strlenW(text);
    If Len>0 then begin
      SetLength(s,len);
      FillChar(s[1],len*2+2,0);
      Move(text^,s[1],len*2);
      if @ConvertTextFunction<>nil then
        s:=ConvertTextFunction(s);
      if @OldTextOutW<>nil then
        Result:=OldTextOutW(hdc,x,y,PWideChar(s),length(s))
      else
        Result:=False;
    end else Result:=OldTextOutW(hdc,x,y,PWideChar(s),0);
  except
    Result:=False;
  end;
end;

function NewExtTextOutA(hdc: HDC; x,y: Integer; Options: DWORD; Clip:
PRect;
  text: PAnsiChar; len: Integer; dx: PInteger): BOOL; stdcall;
Var s: String;
begin
  UpdateFont(hdc);
  try
    if Len<0 then Len:=strlen(text); // ???
    if Len>0 then begin
      SetLength(s,len);
      FillChar(s[1],len+1,0);
      Move(text^,s[1],len);
      if @ConvertTextFunction<>nil then s:=ConvertTextFunction(s);
      if @OldExtTextOutA<>nil then

Result:=OldExtTextOutA(hdc,x,y,Options,Clip,PAnsiChar(s),length(s),dx)
      else Result:=False;
    end else Result:=OldExtTextOutA(hdc,x,y,Options,Clip,text,0,dx);
  except
    Result:=False;
  end;
end;

function NewExtTextOutW(hdc: HDC; x,y: Integer; Options: DWORD; Clip:
PRect;
  text: PWideChar; len: Integer; dx: PInteger): BOOL; stdcall;
Var s: WideString;
begin
  UpdateFontW(hdc);
  try
    if Len<0 then Len:=strlenW(text);
    If Len>0 then begin
      SetLength(s,len);
      FillChar(s[1],len*2+2,0);
      Move(text^,s[1],len*2);
      if @ConvertTextFunction<>nil then
        s:=ConvertTextFunction(s);
      if @OldExtTextOutW<>nil then

Result:=OldExtTextOutW(hdc,x,y,Options,Clip,PWideChar(s),length(s),dx)
      else Result:=False;
    end else Result:=OldExtTextOutW(hdc,x,y,Options,Clip,text,0,dx);
  except
    Result:=False;
  end;
end;

function NewDrawTextA(hdc: HDC; text: PAnsiChar; len: Integer; rect:
PRect;
  Format: DWORD): Integer; stdcall;
Var s: String;
begin
  UpdateFont(hdc);
  try
    if Len<0 then Len:=strlen(text); // ???
    if Len>0 then begin
      SetLength(s,len);
      FillChar(s[1],len+1,0);
      Move(text^,s[1],len);
      if @ConvertTextFunction<>nil then
        s:=ConvertTextFunction(s);
      if @OldDrawTextA<>nil then
        Result:=OldDrawTextA(hdc,PAnsiChar(s),length(s),rect,Format)
      else Result:=0;
    end else Result:=OldDrawTextA(hdc,text,0,rect,Format);
  except
    Result:=0;
  end;
end;

function NewDrawTextW(hdc: HDC; text: PWideChar; len: Integer; rect:
PRect;
  Format: DWORD): Integer; stdcall;
Var s: WideString;
begin
  UpdateFontW(hdc);
  try
    if Len<0 then Len:=strlenW(text);
    if len>0 then begin
      SetLength(s,len);
      FillChar(s[1],len*2+2,0);
      Move(text^,s[1],len*2);
      if @ConvertTextFunction<>nil then
        s:=ConvertTextFunction(s);
      if @OldDrawTextW<>nil then
        Result:=OldDrawTextW(hdc,PWideChar(s),length(s),rect,Format)
      else Result:=0;
    end else Result:=OldDrawTextW(hdc,text,0,rect,Format);
  except
    Result:=0;
  end;
end;

function NewDrawTextExA(hdc: HDC; text: PAnsiChar; len: Integer; rect:
PRect;
  Format: DWORD; DTParams: PDrawTextParams): Integer; stdcall;
Var s: String;
begin
  UpdateFont(hdc);
  try
    if Len<0 then Len:=strlen(text);
    if len>0 then begin
      SetLength(s,len);
      FillChar(s[1],len+1,0);
      Move(text^,s[1],len);
      if @ConvertTextFunction<>nil then
        s:=ConvertTextFunction(s);
      if @OldDrawTextExA<>nil then

Result:=OldDrawTextExA(hdc,PAnsiChar(s),length(s),rect,Format,DTParams)
      else Result:=0;
    end else Result:=OldDrawTextExA(hdc,text,0,rect,Format,DTParams);
  except
    Result:=0;
  end;
end;

function NewDrawTextExW(hdc: HDC; text: PWideChar; len: Integer; rect:
PRect;
  Format: DWORD; DTParams: PDrawTextParams): Integer; stdcall;
Var s: WideString;
begin
  UpdateFontW(hdc);
  try
    if Len<0 then Len:=strlenW(text);
    if Len>0 then begin
      SetLength(s,len);
      FillChar(s[1],len*2+2,0);
      Move(text^,s[1],len*2);
      if @ConvertTextFunction<>nil then
        s:=ConvertTextFunction(s);
      if @OldDrawTextExW<>nil then

Result:=OldDrawTextExW(hdc,PWideChar(s),length(s),rect,Format,DTParams)
      else Result:=0;
    end else Result:=OldDrawTextExW(hdc,text,0,rect,Format,DTParams);
  except
    Result:=0;
  end;
end;

function NewTabbedTextOutA(hdc: HDC; x,y: Integer; text: PAnsiChar; len:
Integer;
                         TabCount: Integer; TabPositions: PInteger;
TabOrigin: Integer): Integer; stdcall;
Var s: AnsiString;
begin
  UpdateFont(hdc);
  try
    if Len<0 then Len:=strlen(text);
    if Len>0 then begin
      SetLength(s,len);
      FillChar(s[1],len+1,0);
      Move(text^,s[1],len);
      if @ConvertTextFunction<>nil then
        s:=ConvertTextFunction(s);
      if @OldTabbedTextOutA<>nil then

Result:=OldTabbedTextOutA(hdc,x,y,PAnsiChar(s),length(s),TabCount,TabPositions,TabOrigin)

      else Result:=0;
    end else
Result:=OldTabbedTextOutA(hdc,x,y,text,0,TabCount,TabPositions,TabOrigin);

  except
    Result:=0;
  end;
end;

function NewTabbedTextOutW(hdc: HDC; x,y: Integer; text: PWideChar; len:
Integer;
                         TabCount: Integer; TabPositions: PInteger;
TabOrigin: Integer): Integer; stdcall;
Var s: WideString;
begin
  UpdateFontW(hdc);
  try
    if Len<0 then Len:=strlenW(text);
    if Len>0 then begin
      SetLength(s,len);
      FillChar(s[1],len*2+2,0);
      Move(text^,s[1],len*2);
      if @ConvertTextFunction<>nil then
        s:=ConvertTextFunction(s);
      if @OldTabbedTextOutW<>nil then

Result:=OldTabbedTextOutW(hdc,x,y,PWideChar(s),length(s),TabCount,TabPositions,TabOrigin)

      else Result:=0;
    end else
Result:=OldTabbedTextOutW(hdc,x,y,text,0,TabCount,TabPositions,TabOrigin);

  except
    Result:=0;
  end;
end;

function NewPolyTextOutA(hdc: HDC; pptxt: PPOLYTEXTA; count: Integer):
BOOL; stdcall;
Var s: String; i: Integer; ppnew: PPOLYTEXTA;
begin
  UpdateFont(hdc);
  ppnew:=nil;
  try
    Result:=False;
    if Count<0 then exit;
    if Count=0 then begin Result:=True; exit; end;
    GetMem(ppnew,count*sizeof(TPOLYTEXTA));
    For i:=1 to count do begin
      ppnew^:=pptxt^;
      if ppnew^.n<0 then ppnew^.n:=strlen(ppnew^.PAnsiChar);
      if ppnew^.n>0 then begin
        SetLength(s,ppnew^.n);
        FillChar(s[1],ppnew^.n+1,0);
        Move(ppnew^.PAnsiChar,s[1],ppnew^.n);
        if @ConvertTextFunction<>nil then
          s:=ConvertTextFunction(s);
        ppnew^.PAnsiChar:=PAnsiChar(s);
        ppnew^.n:=length(s);
        if @OldPolyTextOutA<>nil then
          Result:=OldPolyTextOutA(hdc,ppnew,1);
      end;
      Inc(pptxt);
    end;
  except
    Result:=False;
  end;
  if ppnew<>nil then FreeMem(ppnew);
end;

function NewPolyTextOutW(hdc: HDC; pptxt: PPOLYTEXTW; count: Integer):
BOOL; stdcall;
begin
  UpdateFontW(hdc);
  Result:=OldPolyTextOutW(hdc,pptxt,count);
end;

function NewGetTextExtentExPointA(hdc: HDC; text: PAnsiChar; len:
Integer;
        maxExtent: Integer; Fit: PInteger; Dx: PInteger; Size: Pointer):
BOOL; stdcall;
Var s: AnsiString;
begin
  UpdateFont(hdc);
  try
    if Len<0 then Len:=strlen(text);
    if Len>0 then begin
      SetLength(s,len);
      FillChar(s[1],len+1,0);
      Move(text^,s[1],len);
      if @ConvertTextFunction<>nil then
        s:=ConvertTextFunction(s);
      if @OldGetTextExtentExPointA<>nil then

Result:=OldGetTextExtentExPointA(hdc,PAnsiChar(s),length(s),maxExtent,Fit,Dx,Size)

      else Result:=False;
    end else
Result:=OldGetTextExtentExPointA(hdc,text,0,maxExtent,Fit,Dx,Size);
  except
    Result:=False;
  end;
end;

Function NewGetTextExtentExPointW(hdc: HDC; text: PWideChar; len:
Integer;
  maxExtent: Integer; Fit: PInteger; Dx: PInteger; Size: Pointer): BOOL;
stdcall;
Var s: WideString;
begin
  UpdateFontW(hdc);
  try
    if Len<0 then Len:=strlenW(text);
    if Len>0 then begin
      SetLength(s,len);
      FillChar(s[1],len*2+2,0);
      Move(text^,s[1],len);
      if @ConvertTextFunction<>nil then
        s:=ConvertTextFunction(s);
      if @OldGetTextExtentExPointW<>nil then

Result:=OldGetTextExtentExPointW(hdc,PWideChar(s),length(s),maxExtent,Fit,Dx,Size)

      else Result:=False;
    end else
Result:=OldGetTextExtentExPointW(hdc,text,0,maxExtent,Fit,Dx,Size);
  except
    Result:=False;
  end;
end;
function NewGetTextExtentPoint32A(hdc: HDC; text: PAnsiChar; len:
Integer; Size: Pointer): BOOL; stdcall;
Var s: AnsiString;
begin
  UpdateFont(hdc);
  try
    if Len<0 then Len:=strlen(text);
    if Len>0 then begin
      SetLength(s,len);
      FillChar(s[1],len+1,0);
      Move(text^,s[1],len);
      if @ConvertTextFunction<>nil then
        s:=ConvertTextFunction(s);
      if @OldGetTextExtentPoint32A<>nil then

Result:=OldGetTextExtentPoint32A(hdc,PAnsiChar(s),length(s),Size)
      else Result:=False;
    end else Result:=OldGetTextExtentPoint32A(hdc,text,0,Size);
  except
    Result:=False;
  end;
end;

function NewGetTextExtentPoint32W(hdc: HDC; text: PWideChar; len:
Integer; Size: Pointer): BOOL; stdcall;
Var s: WideString;
begin
  UpdateFontW(hdc);
  try
    if Len<0 then Len:=strlenW(text);
    if Len>0 then begin
      SetLength(s,len);
      FillChar(s[1],len*2+2,0);
      Move(text^,s[1],len);
      if @ConvertTextFunction<>nil then
        s:=ConvertTextFunction(s);
      if @OldGetTextExtentPoint32W<>nil then

Result:=OldGetTextExtentPoint32W(hdc,PWideChar(s),length(s),Size)
      else Result:=False;
    end else Result:=OldGetTextExtentPoint32W(hdc,text,0,Size);
  except
    Result:=False;
  end;
end;

function NewGetTextExtentPointA(hdc: HDC; text: PAnsiChar; len: Integer;
Size: Pointer): BOOL; stdcall;
Var s: AnsiString;
begin
  UpdateFont(hdc);
  try
    if Len<0 then Len:=strlen(text);
    if Len>0 then begin
      SetLength(s,len);
      FillChar(s[1],len+1,0);
      Move(text^,s[1],len);
      if @ConvertTextFunction<>nil then
        s:=ConvertTextFunction(s);
      if @OldGetTextExtentPointA<>nil then
        Result:=OldGetTextExtentPointA(hdc,PAnsiChar(s),length(s),Size)
      else Result:=False;
    end else Result:=OldGetTextExtentPointA(hdc,text,0,Size);
  except
    Result:=False;
  end;
end;

function NewGetTextExtentPointW(hdc: HDC; text: PWideChar; len: Integer;
Size: Pointer): BOOL; stdcall;
Var s: WideString;
begin
  UpdateFontW(hdc);
  try
    if Len<0 then Len:=strlenW(text);
    if Len>0 then begin
      SetLength(s,len);
      FillChar(s[1],len*2+2,0);
      Move(text^,s[1],len);
      if @ConvertTextFunction<>nil then
        s:=ConvertTextFunction(s);
      if @OldGetTextExtentPoint32W<>nil then
        Result:=OldGetTextExtentPointW(hdc,PWideChar(s),length(s),Size)
      else Result:=False;
    end else Result:=OldGetTextExtentPointW(hdc,text,0,Size);
  except
    Result:=False;
  end;
end;

function PointerToFunctionAddress(Code: Pointer): PPointer;
Var func: PImportCode;
begin
  Result:=nil;
  if Code=nil then exit;
  try
    func:=code;
    if (func.JumpInstruction=$25FF) then begin
      Result:=func.AddressOfPointerToFunction;
    end;
  except
    Result:=nil;
  end;
end;

function FinalFunctionAddress(Code: Pointer): Pointer;
Var func: PImportCode;
begin
  Result:=Code;
  if Code=nil then exit;
  try
    func:=code;
    if (func.JumpInstruction=$25FF) then begin
      Result:=func.AddressOfPointerToFunction^;
    end;
  except
    Result:=nil;
  end;
end;


Function PatchAddress(OldFunc, NewFunc: Pointer): Integer;
Var BeenDone: TList;

Function PatchAddressInModule(hModule: THandle; OldFunc, NewFunc:
Pointer): Integer;
Var Dos: PImageDosHeader; NT: PImageNTHeaders;
ImportDesc: PImage_Import_Entry; rva: DWORD;
Func: PPointer; DLL: String; f: Pointer; written: DWORD;
begin
  Result:=0;
  Dos:=Pointer(hModule);
  if BeenDone.IndexOf(Dos)>=0 then exit;
  BeenDone.Add(Dos);
  OldFunc:=FinalFunctionAddress(OldFunc);
  if IsBadReadPtr(Dos,SizeOf(TImageDosHeader)) then exit;
  if Dos.e_magic<>IMAGE_DOS_SIGNATURE then exit;
  NT :=Pointer(Integer(Dos) + dos._lfanew);
//  if IsBadReadPtr(NT,SizeOf(TImageNtHeaders)) then exit;

RVA:=NT^.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress;

  if RVA=0 then exit;
  ImportDesc := pointer(integer(Dos)+RVA);
  While (ImportDesc^.Name<>0) do begin
    DLL:=PChar(Integer(Dos)+ImportDesc^.Name);
    PatchAddressInModule(GetModuleHandle(PChar(DLL)),OldFunc,NewFunc);
    Func:=Pointer(Integer(DOS)+ImportDesc.LookupTable);
    While Func^<>nil do begin
      f:=FinalFunctionAddress(Func^);
      if f=OldFunc then begin
        WriteProcessMemory(GetCurrentProcess,Func,@NewFunc,4,written);
        If Written>0 then Inc(Result);
      end;
      Inc(Func);
    end;
    Inc(ImportDesc);
  end;
end;


begin
  BeenDone:=TList.Create;
  try
    Result:=PatchAddressInModule(GetModuleHandle(nil),OldFunc,NewFunc);
  finally
    BeenDone.Free;
  end;
end;

procedure HookTextOut(ConvertFunction: TConvertTextFunction);
begin
  if @OldTextOutA=nil then
    @OldTextOutA:=FinalFunctionAddress(@TextOutA);
  if @OldTextOutW=nil then
    @OldTextOutW:=FinalFunctionAddress(@TextOutW);

  if @OldExtTextOutA=nil then
    @OldExtTextOutA:=FinalFunctionAddress(@ExtTextOutA);
  if @OldExtTextOutW=nil then
    @OldExtTextOutW:=FinalFunctionAddress(@ExtTextOutW);

  if @OldDrawTextA=nil then
    @OldDrawTextA:=FinalFunctionAddress(@DrawTextA);
  if @OldDrawTextW=nil then
    @OldDrawTextW:=FinalFunctionAddress(@DrawTextW);

  if @OldDrawTextExA=nil then
    @OldDrawTextExA:=FinalFunctionAddress(@DrawTextExA);
  if @OldDrawTextExW=nil then
    @OldDrawTextExW:=FinalFunctionAddress(@DrawTextExW);

  if @OldTabbedTextOutA=nil then
    @OldTabbedTextOutA:=FinalFunctionAddress(@TabbedTextOutA);
  if @OldTabbedTextOutW=nil then
    @OldTabbedTextOutW:=FinalFunctionAddress(@TabbedTextOutW);

  if @OldPolyTextOutA=nil then
    @OldPolyTextOutA:=FinalFunctionAddress(@PolyTextOutA);
  if @OldPolyTextOutW=nil then
    @OldPolyTextOutW:=FinalFunctionAddress(@PolyTextOutW);

  if @OldGetTextExtentExPointA=nil then

@OldGetTextExtentExPointA:=FinalFunctionAddress(@GetTextExtentExPointA);

  if @OldGetTextExtentExPointW=nil then
@OldGetTextExtentExPointW:=FinalFunctionAddress(@GetTextExtentExPointW);

  if @OldGetTextExtentPoint32A=nil then

@OldGetTextExtentPoint32A:=FinalFunctionAddress(@GetTextExtentPoint32A);

  if @OldGetTextExtentPoint32W=nil then

@OldGetTextExtentPoint32W:=FinalFunctionAddress(@GetTextExtentPoint32W);

  if @OldGetTextExtentPointA=nil then
    @OldGetTextExtentPointA:=FinalFunctionAddress(@GetTextExtentPointA);

  if @OldGetTextExtentPointW=nil then
    @OldGetTextExtentPointW:=FinalFunctionAddress(@GetTextExtentPointW);



  @ConvertTextFunction:=@ConvertFunction;

  PatchAddress(@OldTextOutA, @NewTextOutA);
  PatchAddress(@OldTextOutW, @NewTextOutW);
  PatchAddress(@OldExtTextOutA, @NewExtTextOutA);
  PatchAddress(@OldExtTextOutW, @NewExtTextOutW);
  PatchAddress(@OldDrawTextA, @NewDrawTextA);
  PatchAddress(@OldDrawTextW, @NewDrawTextW);
  PatchAddress(@OldDrawTextExA, @NewDrawTextExA);
  PatchAddress(@OldDrawTextExW, @NewDrawTextExW);
  PatchAddress(@OldTabbedTextOutA, @NewTabbedTextOutA);
  PatchAddress(@OldTabbedTextOutW, @NewTabbedTextOutW);
  PatchAddress(@OldPolyTextOutA, @NewPolyTextOutA);
  PatchAddress(@OldPolyTextOutW, @NewPolyTextOutW);
  PatchAddress(@OldGetTextExtentExPointA, @NewGetTextExtentExPointA);
  PatchAddress(@OldGetTextExtentExPointW, @NewGetTextExtentExPointW);
  PatchAddress(@OldGetTextExtentPoint32A, @NewGetTextExtentPoint32A);
  PatchAddress(@OldGetTextExtentPoint32W, @NewGetTextExtentPoint32W);
  PatchAddress(@OldGetTextExtentPointA, @NewGetTextExtentPointA);
//  PatchAddress(@OldGetTextExtentPointW, @NewGetTextExtentPointW);
end;

procedure UnhookTextOut;
begin
  If @OldTextOutA<>nil then begin
    PatchAddress(@NewTextOutA, @OldTextOutA);
    PatchAddress(@NewTextOutW, @OldTextOutW);
    PatchAddress(@NewExtTextOutA, @OldExtTextOutA);
    PatchAddress(@NewExtTextOutW, @OldExtTextOutW);
    PatchAddress(@NewDrawTextA, @OldDrawTextA);
    PatchAddress(@NewDrawTextW, @OldDrawTextW);
    PatchAddress(@NewDrawTextExA, @OldDrawTextExA);
    PatchAddress(@NewDrawTextExW, @OldDrawTextExW);
    PatchAddress(@NewTabbedTextOutA, @OldTabbedTextOutA);
    PatchAddress(@NewTabbedTextOutW, @OldTabbedTextOutW);
    PatchAddress(@NewPolyTextOutA, @OldPolyTextOutA);
    PatchAddress(@NewPolyTextOutW, @OldPolyTextOutW);
    PatchAddress(@NewGetTextExtentExPointA, @OldGetTextExtentExPointA);
    PatchAddress(@NewGetTextExtentExPointW, @OldGetTextExtentExPointW);
    PatchAddress(@NewGetTextExtentPoint32A, @OldGetTextExtentPoint32A);
    PatchAddress(@NewGetTextExtentPoint32W, @OldGetTextExtentPoint32W);
    PatchAddress(@NewGetTextExtentPointA, @OldGetTextExtentPointA);
//    PatchAddress(@NewGetTextExtentPointW, @OldGetTextExtentPointW);
  end;
end;

initialization
finalization
  UnhookTextOut;
end.
