{$WARN SYMBOL_PLATFORM OFF}
{$Q-}
{$R-}
{$T-}

unit PatchGen;
interface

uses
  Windows;

type
  TGPCallback = function(OP: Integer; Value: UINT64): Boolean;

const
  GPO_LENGTH = 0;
  GPO_POSITION = 1;

function GeneratePatch(const pfile, sfile, dfile: PWideChar; gpcb: TGPCallback):Boolean;

implementation

function GeneratePatch(const pfile, sfile, dfile: PWideChar; gpcb: TGPCallback): Boolean;
const
  BUF_SIZE = 256 * 1024;
var
  pf, sf, df: THandle;
  Buf1, Buf2: array of Byte;
  size, hsize: Cardinal;
  ssize, dsize, off: UINT64;
begin
  result := false;
  pf := CreateFileW(pfile, GENERIC_WRITE, FILE_SHARE_READ, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  sf := CreateFileW(sfile, GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  df := CreateFileW(dfile, GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if (pf = INVALID_HANDLE_VALUE) or (sf = INVALID_HANDLE_VALUE) or (df = INVALID_HANDLE_VALUE) then
  begin
    CloseHandle(pf);
    CloseHandle(sf);
    CloseHandle(df);
    Exit;
  end;
  hsize := 0;
  ssize := SetFilePointer(sf, 0, @hsize, FILE_END);
  ssize := ssize + UINT64(hsize) shl 32;
  hsize := 0;
  dsize := SetFilePointer(df, 0, @hsize, FILE_END);
  dsize := dsize + UINT64(hsize) shl 32;
  SetFilePointer(sf, 0, nil, FILE_BEGIN);
  SetFilePointer(df, 0, nil, FILE_BEGIN);
  if (@gpcb = nil) or gpcb(GPO_LENGTH, dsize) then
  begin
    WriteFile(pf, dsize, sizeof(dsize), size, nil);
    SetLength(Buf1, BUF_SIZE);
    SetLength(Buf2, BUF_SIZE);
    off := 0;
    while off < dsize do
    begin
      ReadFile(sf, Buf1[0], BUF_SIZE, size, nil);
      ReadFile(df, Buf2[0], BUF_SIZE, size, nil);
      Inc(off, size);
      if (@gpcb <> nil) and not gpcb(GPO_POSITION, off) then
      begin
        Finalize(Buf1);
        Finalize(Buf2);
        CloseHandle(pf);
        CloseHandle(sf);
        CloseHandle(df);
        Halt;
      end;
    end;
    Finalize(Buf1);
    Finalize(Buf2);
  end;
  CloseHandle(pf);
  CloseHandle(sf);
  CloseHandle(df);
  result := true;
end;

end.
