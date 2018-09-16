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
{ The Original Code is GdiHook.pas.                                            }
{                                                                              }
{ Contains various graphics related classes and subroutines required for       }
{ creating a chart and its nodes, and visual chart interaction.                }
{                                                                              }
{ Unit owner:    Mišel Krstović                                                }
{ Last modified: March 8, 2010                                                 }
{                                                                              }
{******************************************************************************}

unit GdiHook;

interface

uses Windows;

implementation

const NULL = 0;

function InjectDLL(idProcess : DWORD) : integer;
var
  hProcess : THandle;
  szDLLPath : string; //array[0..100-1] of char;
  exitCode : DWORD;
  lpDLLName : Pointer;
  hThread : THandle;
  BytesWritten : Cardinal;
  idThread : DWORD;
begin
  // Get the process handle
  hProcess := OpenProcess(PROCESS_ALL_ACCESS, false, idProcess);
  if (hProcess = NULL) then begin
    result := 0;
    exit;
  end;

  szDLLPath := 'GdiHook.dll'; // this is the name of your DLL to inject

  // Allocate memory for writing data within the process
  lpDLLName := VirtualAllocEx(hProcess, nil, sizeof(szDLLPath), MEM_RESERVE OR MEM_COMMIT, PAGE_EXECUTE_READWRITE);
  if (lpDLLName = nil) then begin
    result := -1;
    exit;
  end;

  // Write the library path to the allocated memory
  if not(
    WriteProcessMemory(
      hProcess,
      lpDLLName,
      PChar(szDLLPath),
      sizeof(szDLLPath),
      BytesWritten
    )
  ) then begin
    result := -2;
    exit;
  end;

  // use CreateRemoteThread to call LoadLibrary within the remote process with the
  // pDLLName as its parameter, so the library is mapped into the remote process
  hThread := CreateRemoteThread(hProcess, nil, 0, GetProcAddress(GetModuleHandle('kernel32.dll'), 'LoadLibraryA'),
    lpDLLName, 0, idThread);

  if (hThread = NULL) then begin
    result := -3;
    exit;
  end;

  WaitForSingleObject(hThread, INFINITE);
  GetExitCodeThread(hThread, exitCode);
  CloseHandle(hThread);

  // Free the memory
  VirtualFreeEx(hProcess, lpDLLName, sizeof(szDLLPath), MEM_RELEASE);

  result := exitCode;
end;

end.
