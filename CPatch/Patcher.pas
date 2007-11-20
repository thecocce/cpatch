unit Patcher;

interface

uses
  Windows;

type
  TPCallback = function(OP: Integer; Value: UINT64): Boolean;

const
  PO_LENGTH = 0;
  PO_OFFSET = 1;

function DoPatch(const sfile: PWideChar; const pf: THandle; pcb: TPCallback; restore: Boolean = false):Boolean;

implementation

function DoPatch(const sfile: PWideChar; const pf: THandle; pcb: TPCallback; restore: Boolean):Boolean;
var
  flag, hsize, off, size, rr: Cardinal;
  osize, fsize, foff, nsize: UINT64;
  sf: THandle;
  data: packed array [0..$7FFF] of Byte;
  resdata: boolean;

  function ReadSize: Cardinal;
  var
    b: Byte;
    r: Cardinal;
  begin
    ReadFile(pf, b, 1, r, nil);
    if b < $80 then
    begin
      result := b;
      Inc(foff);
    end
    else
    begin
      result := (Cardinal(b) and $7F) shl 8;
      ReadFile(pf, b, 1, r, nil);
      result := result + Cardinal(b);
      Inc(foff, 2);
    end;
  end;

  function ReadOff: Cardinal;
  var
    b: Byte;
    r: Cardinal;
  begin
    ReadFile(pf, b, 1, r, nil);
    if b < $40 then
    begin
      result := b;
      Inc(foff);
    end
    else if b < $80 then
    begin
      result := (Cardinal(b) and $3F) shl 8;
      ReadFile(pf, b, 1, r, nil);
      result := result + Cardinal(b);
      Inc(foff, 2);
    end
    else if b < $C0 then
    begin
      result := (Cardinal(b) and $3F) shl 16;
      ReadFile(pf, b, 1, r, nil);
      result := result + (Cardinal(b) shl 8);
      ReadFile(pf, b, 1, r, nil);
      result := result + Cardinal(b);
      Inc(foff, 3);
    end
    else
    begin
      result := (Cardinal(b) and $3F) shl 24;
      ReadFile(pf, b, 1, r, nil);
      result := result + (Cardinal(b) shl 16);
      ReadFile(pf, b, 1, r, nil);
      result := result + (Cardinal(b) shl 8);
      ReadFile(pf, b, 1, r, nil);
      result := result + Cardinal(b);
      Inc(foff, 4);
    end;
  end;

begin
  result := false;
  sf := CreateFileW(sfile, GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if sf = INVALID_HANDLE_VALUE then
    Exit;
  ReadFile(pf, flag, 4, rr, nil);
  resdata := (flag and 1) > 0;

  ReadFile(pf, nsize, 8, rr, nil);
  if resdata then
    ReadFile(pf, osize, 8, rr, nil);
  hsize := 0;
  foff := SetFilePointer(pf, 0, @hsize, FILE_CURRENT);
  foff := foff + (UINT64(hsize) shl 32);
  hsize := 0;
  fsize := SetFilePointer(pf, 0, @hsize, FILE_END);
  fsize := fsize + (UINT64(hsize) shl 32);
  hsize := foff shr 32;
  SetFilePointer(pf, foff and $FFFFFFFF, @hsize, FILE_BEGIN);
  if (@pcb = nil) or pcb(PO_LENGTH, fsize) then
  begin
    result := true;
    pcb(PO_OFFSET, foff);
    while foff < fsize do
    begin
      off := ReadOff;
      size := ReadSize;
      if resdata then
      begin
        if restore then
        begin
          SetFilePointer(pf, size, nil, FILE_CURRENT);
          if (not ReadFile(pf, data[0], size, rr, nil)) or (rr < size) then
            break;
        end
        else
        begin
          if (not ReadFile(pf, data[0], size, rr, nil)) or (rr < size) then
            break;
          SetFilePointer(pf, size, nil, FILE_CURRENT);
        end;
      end
      else
      begin
        if (not ReadFile(pf, data[0], size, rr, nil)) or (rr < size) then
          break;
      end;
      SetFilePointer(sf, off, nil, FILE_CURRENT);
      WriteFile(sf, data[0], size, rr, nil);
      Inc(foff, size);
      if (@pcb <> nil) and not pcb(PO_OFFSET, foff) then
      begin
        result := false;
        break;
      end;
    end;
  end;
  if resdata and restore then
  begin
    hsize := osize shr 32;
    SetFilePointer(sf, osize and $FFFFFFFF, @hsize, FILE_BEGIN);
  end
  else
  begin
    hsize := nsize shr 32;
    SetFilePointer(sf, nsize and $FFFFFFFF, @hsize, FILE_BEGIN);
  end;
  SetEndOfFile(sf);
  CloseHandle(sf);
end;

end.
