{ ****************************************************************************** }
{ * jemalloc for pascal library  written by QQ 600585@qq.com                   * }
{ ****************************************************************************** }
{ * https://zpascal.net                                                        * }
{ * https://github.com/PassByYou888/zAI                                        * }
{ * https://github.com/PassByYou888/ZServer4D                                  * }
{ * https://github.com/PassByYou888/PascalString                               * }
{ * https://github.com/PassByYou888/zRasterization                             * }
{ * https://github.com/PassByYou888/CoreCipher                                 * }
{ * https://github.com/PassByYou888/zSound                                     * }
{ * https://github.com/PassByYou888/zChinese                                   * }
{ * https://github.com/PassByYou888/zExpression                                * }
{ * https://github.com/PassByYou888/zGameWare                                  * }
{ * https://github.com/PassByYou888/zAnalysis                                  * }
{ * https://github.com/PassByYou888/FFMPEG-Header                              * }
{ * https://github.com/PassByYou888/zTranslate                                 * }
{ * https://github.com/PassByYou888/InfiniteIoT                                * }
{ * https://github.com/PassByYou888/FastMD5                                    * }
{ ****************************************************************************** }
unit jemalloc4p;

{$IFDEF FPC}
{$MODE objfpc}
{$ENDIF FPC}

interface

implementation

const
{$IF Defined(WIN32)}
  jemalloc4p_Lib = 'jemalloc_IA32.dll';
{$ELSEIF Defined(WIN64)}
  jemalloc4p_Lib = 'jemalloc_X64.dll';
{$ELSEIF Defined(OSX)}
  jemalloc4p_Lib = 'libjemalloc.2.dylib';
{$ELSEIF Defined(IOS)}
  jemalloc4p_Lib = 'libjemalloc.a';
{$ELSEIF Defined(ANDROID)}
  jemalloc4p_Lib = 'libjemalloc.so.2';
{$ELSEIF Defined(Linux)}
  jemalloc4p_Lib = 'libjemalloc.so.2';
{$ELSE}
{$MESSAGE FATAL 'unknow system.'}
{$IFEND}

function je_malloc(Size: NativeUInt): Pointer; cdecl; external jemalloc4p_Lib Name 'je_malloc';
procedure je_free(P: Pointer); cdecl; external jemalloc4p_Lib Name 'je_free';
function je_realloc(P: Pointer; Size: NativeUInt): Pointer; cdecl; external jemalloc4p_Lib Name 'je_realloc';

procedure Fast_FillByte(const dest: Pointer; Count: NativeUInt; const Value: byte); inline;
var
  d: PByte;
  v: UInt64;
begin
  if Count <= 0 then
      Exit;
  v := Value or (Value shl 8) or (Value shl 16) or (Value shl 24);
  v := v or (v shl 32);
  d := dest;
  while Count >= 8 do
    begin
      PUInt64(d)^ := v;
      Dec(Count, 8);
      Inc(d, 8);
    end;
  if Count >= 4 then
    begin
      PCardinal(d)^ := PCardinal(@v)^;
      Dec(Count, 4);
      Inc(d, 4);
    end;
  if Count >= 2 then
    begin
      PWORD(d)^ := PWORD(@v)^;
      Dec(Count, 2);
      Inc(d, 2);
    end;
  if Count > 0 then
      d^ := Value;
end;

{$IFDEF FPC}


var
  OriginMM: TMemoryManager;
  HookMM: TMemoryManager;

function do_GetMem(Size: ptruint): Pointer;
begin
  Result := je_malloc(Size);
end;

function do_FreeMem(P: Pointer): ptruint;
begin
  je_free(P);
  Result := 0;
end;

function do_FreememSize(P: Pointer; Size: ptruint): ptruint;
begin
  je_free(P);
  Result := 0;
end;

function do_AllocMem(Size: ptruint): Pointer;
begin
  Result := je_malloc(Size);
  Fast_FillByte(Result, Size, 0);
end;

function do_ReallocMem(var P: Pointer; Size: ptruint): Pointer;
begin
  P := je_realloc(P, Size);
  Result := P;
end;

procedure InstallMemoryHook;
begin
  GetMemoryManager(OriginMM);
  HookMM := OriginMM;

  HookMM.GetMem := @do_GetMem;
  HookMM.FreeMem := @do_FreeMem;
  HookMM.FreememSize := @do_FreememSize;
  HookMM.AllocMem := @do_AllocMem;
  HookMM.ReallocMem := @do_ReallocMem;

  SetMemoryManager(HookMM);
end;

procedure UnInstallMemoryHook;
begin
  SetMemoryManager(OriginMM);
end;

{$ELSE FPC}


var
  OriginMM: TMemoryManagerEx;
  HookMM: TMemoryManagerEx;

function do_GetMem(Size: NativeInt): Pointer;
begin
  Result := je_malloc(Size);
end;

function do_FreeMem(P: Pointer): integer;
begin
  je_free(P);
  Result := 0;
end;

function do_ReallocMem(P: Pointer; Size: NativeInt): Pointer;
begin
  Result := je_realloc(P, Size);
end;

function do_AllocMem(Size: NativeInt): Pointer;
begin
  Result := je_malloc(Size);
  Fast_FillByte(Result, Size, 0);
end;

procedure InstallMemoryHook;
begin
  GetMemoryManager(OriginMM);
  HookMM := OriginMM;

  HookMM.GetMem := do_GetMem;
  HookMM.FreeMem := do_FreeMem;
  HookMM.ReallocMem := do_ReallocMem;
  HookMM.AllocMem := do_AllocMem;

  SetMemoryManager(HookMM);
end;

procedure UnInstallMemoryHook;
begin
  SetMemoryManager(OriginMM);
end;

{$ENDIF FPC}

initialization

InstallMemoryHook;

finalization

UnInstallMemoryHook;

end.
