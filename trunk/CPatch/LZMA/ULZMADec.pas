unit ULZMADec;

interface

uses ULZMADecoder, UBufferedFS, ULZMACommon, uClass;

function lzma_decode(const infile, outfile: string): boolean; overload;
function lzma_decode(instream, outstream: TStream): boolean; overload;

implementation

function lzma_decode(const infile, outfile: string): boolean;
var
  inStream:TBufferedFS;
  outStream:TBufferedFS;
begin
  inStream:=TBufferedFS.Create(infile, fmOpenRead or fmsharedenynone);
  outStream:=TBufferedFS.Create(outfile, fmcreate);
  result := lzma_decode(instream, outstream);
  outStream.Free;
  inStream.Free;
end;

function lzma_decode(instream, outstream: TStream): boolean; overload;
var
  i:integer;
  properties:array[0..4] of byte;
  decoder:TLZMADecoder;
  outSize:int64;
  v:byte;
const
  propertiessize = 5;

begin
  result := false;
  decoder := TLZMADecoder.Create;

  if inStream.read(properties, propertiesSize) <> propertiesSize then
  begin
    decoder.Free;
    Exit;
  end;
  if not decoder.SetDecoderProperties(properties) then
  begin
    decoder.Free;
    Exit;
  end;
  outSize := 0;
  for i := 0 to 7 do begin
    v := (ReadByte(inStream));
    if v > 1 then
    begin
      decoder.Free;
      Exit;
    end;
    outSize := outSize or v shl (8 * i);
  end;
  if not decoder.Code(inStream, outStream, outSize) then
  begin
    decoder.Free;
    Exit;
  end;
  result := true;
  decoder.Free;
end;

end.
