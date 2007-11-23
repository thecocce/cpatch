{$WARN SYMBOL_PLATFORM OFF}
{$Q-}
{$R-}
{$T-}

unit PatchGen;
interface

uses
  Windows, UBufferedFS;

type
  TGPCallback = function(OP: Integer; Value: UINT64): Boolean;

const
  GPO_LENGTH = 0;
  GPO_POSITION = 1;

function GeneratePatch(pst: TBufferedFS; const sfile, dfile: PWideChar; gpcb: TGPCallback; resdata: Boolean = false):Boolean;

implementation

uses ULZMAEnc, uClass;

const
  BUF_SIZE = 2 * 1024 * 1024;
  BLOCK_SIZE = 4 * 1024 * 1024;

function GeneratePatch(pst: TBufferedFS; const sfile, dfile: PWideChar; gpcb: TGPCallback; resdata: Boolean): Boolean;
var
  sf, df: THandle;
  Buf1, Buf2: array of Byte;
  pbuf, rbuf: packed array [0..$7FFF] of Byte;
  size, hsize, i, poff: Cardinal;
  ssize, dsize, off, loff: UINT64;
  inp: Boolean;
  fst: TMemoryStream;

  procedure WriteSize(const value: Cardinal);
  var
    v: Cardinal;
  begin
    if value < $80 then
      fst.Write(value, 1)
    else if value < $8000 then
    begin
      v := ((value and $7F00) shr 8) + ((value and $FF) shl 8) + $80;
      fst.Write(v, 2);
    end;
  end;

  procedure WriteOff(value: UINT64);
  var
    v: Cardinal;
  begin
    while value > $3FFFFFFF do
    begin
      WriteOff($3FFFFFFF);
      WriteSize(0);
      Dec(value, $3FFFFFFF);
    end;
    if value < $40 then
      fst.Write(value, 1)
    else if value < $4000 then
    begin
      v := ((value and $3F00) shr 8) + ((value and $FF) shl 8) + $40;
      fst.Write(v, 2);
    end
    else if value < $400000 then
    begin
      v := ((value and $3F0000) shr 16) + (value and $FF00) + ((value and $FF) shl 16) + $80;
      fst.Write(v, 3);
    end
    else if value < $40000000 then
    begin
      v := ((value and $3F000000) shr 24) + ((value and $FF0000) shr 8) + ((value and $FF00) shl 8) + ((value and $FF) shl 24) + $C0;
      fst.Write(v, 4);
    end;
  end;

  procedure WriteData2(const data; size: cardinal);
  begin
    fst.Write(data, size);
  end;

  procedure WriteBack;
  begin
    fst.Position := 0;
    lzma_encode(fst, pst);
    fst.Clear;
  end;

  procedure WriteData(const data; size: cardinal);
  begin
    fst.Write(data, size);
    if fst.Size > BLOCK_SIZE then
      WriteBack;
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
  fst := TMemoryStream.Create;
  hsize := 0;
  dsize := SetFilePointer(df, 0, @hsize, FILE_END);
  dsize := dsize + UINT64(hsize) shl 32;
  if resdata then
  begin
    hsize := 0;
    ssize := SetFilePointer(sf, 0, @hsize, FILE_END);
    ssize := ssize + UINT64(hsize) shl 32;
  end;
  SetFilePointer(sf, 0, nil, FILE_BEGIN);
  SetFilePointer(df, 0, nil, FILE_BEGIN);
  if resdata then
    size := 1
  else
    size := 0;
  pst.Write(size, 4);
  pst.Write(dsize, sizeof(dsize));
  if resdata then
  begin
    pst.Write(ssize, sizeof(ssize));
    if ssize > dsize then
      dsize := ssize;
  end;
  if (@gpcb = nil) or gpcb(GPO_LENGTH, dsize) then
  begin
    result := true;
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
      if (@gpcb <> nil) and not gpcb(GPO_POSITION, off) then
      begin
        result := false;
        break;
      end;
      ZeroMemory(@Buf1[0], BUF_SIZE);
      ZeroMemory(@Buf2[0], BUF_SIZE);
      ReadFile(sf, Buf1[0], BUF_SIZE, hsize, nil);
      ReadFile(df, Buf2[0], BUF_SIZE, size, nil);
      if size < hsize then
        size := hsize;
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
          if resdata then
            rbuf[poff] := Buf1[i];
          Inc(poff);
          if poff > $7FFD then
          begin
            inp := false;
            hsize := off + i + 1 - loff;
            WriteSize(hsize);
            if resdata then
            begin
              WriteData2(pbuf[0], hsize);
              WriteData(rbuf[0], hsize);
            end
            else
              WriteData(pbuf[0], hsize);
            loff := off + i + 1;
            poff := 0;
          end;
        end
        else if inp then
        begin
          if (Buf1[i + 1] <> Buf2[i + 1]) or (Buf1[i + 2] <> Buf2[i + 2]) then
          begin
            pbuf[poff] := Buf2[i];
            if resdata then
              rbuf[poff] := Buf1[i];
            Inc(poff);
            Inc(i);
            pbuf[poff] := Buf2[i];
            if resdata then
              rbuf[poff] := Buf1[i];
            Inc(poff);
            if poff > $7FFD then
            begin
              inp := false;
              hsize := off + i + 1 - loff;
              WriteSize(hsize);
              if resdata then
              begin
                WriteData2(pbuf[0], hsize);
                WriteData(rbuf[0], hsize);
              end
              else
                WriteData(pbuf[0], hsize);
              loff := off + i + 1;
              poff := 0;
            end;
          end
          else
          begin
            inp := false;
            hsize := off + i - loff;
            WriteSize(hsize);
            if resdata then
            begin
              WriteData2(pbuf[0], hsize);
              WriteData(rbuf[0], hsize);
            end
            else
              WriteData(pbuf[0], hsize);
            loff := off + i;
            poff := 0;
          end;
        end;
        Inc(i);
      end;
      Inc(off, size);
    end;
    if inp then
    begin
      hsize := off - loff;
      WriteSize(hsize);
      WriteData2(pbuf[0], hsize);
      if resdata then
        WriteData2(rbuf[0], hsize);
      WriteBack;
    end;
    Finalize(Buf1);
    Finalize(Buf2);
    if (@gpcb <> nil) and not gpcb(GPO_POSITION, off) then
      result := false;
  end;
  fst.Free;
  CloseHandle(sf);
  CloseHandle(df);
end;

end.

