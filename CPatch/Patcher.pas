unit Patcher;

interface

uses
  Windows, uClass;

type
  TPCallback = function(OP: Integer; Value: UINT64): Boolean;

const
  PO_LENGTH = 0;
  PO_OFFSET = 1;

function DoPatch(const sfile: PWideChar; const pst: TFileStream; pcb: TPCallback; restore: Boolean = false):Boolean;

implementation

uses
  ULZMADec;
  
function DoPatch(const sfile: PWideChar; const pst: TFileStream; pcb: TPCallback; restore: Boolean):Boolean;
var
  flag, hsize, off, size, rr: Cardinal;
  osize, fsize, foff, nsize: UINT64;
  sf: THandle;
  data: packed array [0..$7FFF] of Byte;
  resdata: boolean;
  dst: TMemoryStream;

  function ReadSize: Cardinal;
  var
    b: Byte;
  begin
    dst.Read(b, 1);
    if b < $80 then
    begin
      result := b;
    end
    else
    begin
      result := (Cardinal(b) and $7F) shl 8;
      dst.Read(b, 1);
      result := result + Cardinal(b);
    end;
  end;

  function ReadOff: Cardinal;
  var
    b: Byte;
  begin
    dst.Read(b, 1);
    if b < $40 then
    begin
      result := b;
    end
    else if b < $80 then
    begin
      result := (Cardinal(b) and $3F) shl 8;
      dst.Read(b, 1);
      result := result + Cardinal(b);
    end
    else if b < $C0 then
    begin
      result := (Cardinal(b) and $3F) shl 16;
      dst.Read(b, 1);
      result := result + (Cardinal(b) shl 8);
      dst.Read(b, 1);
      result := result + Cardinal(b);
    end
    else
    begin
      result := (Cardinal(b) and $3F) shl 24;
      dst.Read(b, 1);
      result := result + (Cardinal(b) shl 16);
      dst.Read(b, 1);
      result := result + (Cardinal(b) shl 8);
      dst.Read(b, 1);
      result := result + Cardinal(b);
    end;
  end;

begin
  result := false;
  sf := CreateFileW(sfile, GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if sf = INVALID_HANDLE_VALUE then
    Exit;
  pst.Read(flag, 4);
  resdata := (flag and 1) > 0;

  pst.Read(nsize, 8);
  fsize := nsize;
  if resdata then
  begin
    pst.Read(osize, 8);
    if restore then
      fsize := osize;
  end;
  dst := TMemoryStream.Create;
  if (@pcb = nil) or pcb(PO_LENGTH, fsize) then
  begin
    result := true;
    while pst.Position < pst.Size do
    begin
      dst.Clear;
      lzma_decode(pst, dst);
      dst.Position := 0;
      while dst.Position < dst.Size do
      begin
        off := ReadOff;
        size := ReadSize;
        if resdata then
        begin
          if restore then
          begin
            dst.Position := dst.Position + size;
            dst.Read(data[0], size);
          end
          else
          begin
            dst.Read(data[0], size);
            dst.Position := dst.Position + size;
          end;
        end
        else
        begin
          dst.Read(data[0], size);
        end;
        foff := SetFilePointer(sf, off, @hsize, FILE_CURRENT);
        WriteFile(sf, data[0], size, rr, nil);
        if (@pcb <> nil) and not pcb(PO_OFFSET, foff + (UINT64(hsize) shl 32)) then
        begin
          result := false;
          break;
        end;
      end;
    end;
  end;
  dst.Free;
  hsize := fsize shr 32;
  SetFilePointer(sf, fsize and $FFFFFFFF, @hsize, FILE_BEGIN);
  SetEndOfFile(sf);
  CloseHandle(sf);
  if (@pcb <> nil) and not pcb(PO_OFFSET, fsize) then
    result := false;
end;

end.
