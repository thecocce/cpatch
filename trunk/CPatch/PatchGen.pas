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

function GeneratePatch(const pf: THandle; const sfile, dfile: PWideChar; gpcb: TGPCallback):Boolean;

implementation

const
  BUF_SIZE = 256 * 1024;

function GeneratePatch(const pf: THandle; const sfile, dfile: PWideChar; gpcb: TGPCallback): Boolean;
var
  sf, df: THandle;
  Buf1, Buf2: array of Byte;
  pbuf: packed array [0..$7FFF] of Byte;
  size, hsize, i, r, poff: Cardinal;
  dsize, off, loff: UINT64;
  inp: Boolean;

  procedure WriteSize(const value: Cardinal);
  var
    w, v: Cardinal;
  begin
    if value < $80 then
      WriteFile(pf, value, 1, w, nil)
    else if value < $8000 then
    begin
      v := ((value and $7F00) shr 8) + ((value and $FF) shl 8) + $80;
      WriteFile(pf, v, 2, w, nil);
    end;
  end;

  procedure WriteOff(value: UINT64);
  var
    w, v, p: Cardinal;
  begin
    while value > $FFFFFFFF do
    begin
      p := $FFFFFFFF;
      WriteFile(pf, p, 4, w, nil);
      WriteSize(0);
      Dec(value, $FFFFFFFF);
    end;
    if value < $40 then
      WriteFile(pf, value, 1, w, nil)
    else if value < $4000 then
    begin
      v := ((value and $3F00) shr 8) + ((value and $FF) shl 8) + $40;
      WriteFile(pf, v, 2, w, nil);
    end
    else if value < $400000 then
    begin
      v := ((value and $3F0000) shr 16) + (value and $FF00) + ((value and $FF) shl 16) + $80;
      WriteFile(pf, v, 3, w, nil);
    end
    else if value < $40000000 then
    begin
      v := ((value and $3F000000) shr 24) + ((value and $FF0000) shr 8) + ((value and $FF00) shl 8) + ((value and $FF) shl 24) + $C0;
      WriteFile(pf, v, 4, w, nil);
    end
  end;

begin
  result := false;
  sf := CreateFileW(sfile, GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  df := CreateFileW(dfile, GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if (sf = INVALID_HANDLE_VALUE) or (df = INVALID_HANDLE_VALUE) then
  begin
    CloseHandle(sf);
    CloseHandle(df);
    Exit;
  end;
  hsize := 0;
  dsize := SetFilePointer(df, 0, @hsize, FILE_END);
  dsize := dsize + UINT64(hsize) shl 32;
  SetFilePointer(sf, 0, nil, FILE_BEGIN);
  SetFilePointer(df, 0, nil, FILE_BEGIN);
  if (@gpcb = nil) or gpcb(GPO_LENGTH, dsize) then
  begin
    result := true;
    WriteFile(pf, dsize, sizeof(dsize), size, nil);
    SetLength(Buf1, BUF_SIZE + 2);
    SetLength(Buf2, BUF_SIZE + 2);
    Buf1[BUF_SIZE] := 0;
    Buf1[BUF_SIZE + 1] := 0;
    Buf2[BUF_SIZE] := 0;
    Buf2[BUF_SIZE + 1] := 0;
    off := 0;
    poff := 0;
    loff := 0;
    inp := false;
    while off < dsize do
    begin
      ZeroMemory(@Buf1[0], BUF_SIZE);
      ZeroMemory(@Buf2[0], BUF_SIZE);
      ReadFile(sf, Buf1[0], BUF_SIZE, size, nil);
      if not ReadFile(df, Buf2[0], BUF_SIZE, size, nil) then
      begin
        result := false;
        break;
      end;
      i := 0;
      while i < size do
      begin
        if Buf1[i] <> Buf2[i] then
        begin
          if not inp then
          begin
            WriteOff(off + UINT64(i) - loff);
            loff := off + i;
            inp := true;
          end;
          pbuf[poff] := Buf2[i];
          Inc(poff);
          if poff = $7FFF then
          begin
            inp := false;
            hsize := off + i + 1 - loff;
            WriteSize(hsize);
            WriteFile(pf, pbuf[0], hsize, r, nil);
            loff := off + i + 1;
            poff := 0;
          end;
        end
        else if inp then
        begin
          if (Buf1[i + 1] <> Buf2[i + 1]) or (Buf1[i + 2] <> Buf2[i + 2]) then
          begin
            pbuf[poff] := Buf2[i];
            Inc(poff);
            Inc(i);
            pbuf[poff] := Buf2[i];
            Inc(poff);
            if poff = $7FFF then
            begin
              inp := false;
              hsize := off + i + 1 - loff;
              WriteSize(hsize);
              WriteFile(pf, pbuf[0], hsize, r, nil);
              loff := off + i + 1;
              poff := 0;
            end;
          end
          else
          begin
            inp := false;
            hsize := off + i - loff;
            WriteSize(hsize);
            WriteFile(pf, pbuf[0], hsize, r, nil);
            loff := off + i;
            poff := 0;
          end;
        end;
        Inc(i);
      end;
      Inc(off, size);
      if (@gpcb <> nil) and not gpcb(GPO_POSITION, off) then
      begin
        result := false;
        break;
      end;
    end;
    if inp then
    begin
      hsize := off - loff;
      WriteSize(hsize);
      WriteFile(pf, pbuf[0], hsize, r, nil);
    end;
    Finalize(Buf1);
    Finalize(Buf2);
  end;
  CloseHandle(sf);
  CloseHandle(df);
end;

{function CompressBlock(data: array of Byte; var size: Cardinal): Boolean;
var
  dest: array [0..$FFFF] of Byte;
  soff, doff: Cardinal;
  match: boolean;
begin
  result := false;
  if size < 8 then
    exit;
  soff := 0;
  doff := 0;
  while soff < size do
  begin
    match := false;
    if soff >= 8 then
    begin

    end;
    if not match then
    begin
      dest[doff] := data[soff];;
      Inc(doff);
      if dest[doff] = $CA then
      begin
        dest[doff] := $0;
        Inc(doff);
      end;
      Inc(soff);
    end;
  end;
end;}

end.

