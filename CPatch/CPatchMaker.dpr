{$IFDEF VER185 or VER180}
{$SetPEFlags 1}
{$ENDIF}
{$Q-}
{$R-}
{$T-}

program CPatchMaker;

{$R 'resource.res' 'resource.rc'}
{$R 'headerdata.res' 'headerdata.rc'}
uses
  Maker in 'Maker.pas',
  ComCtl32 in 'ComCtl32.pas',
  CommDlg in 'CommDlg.pas',
  PatchGen in 'PatchGen.pas',
  UpdateIcon in 'UpdateIcon.pas',
  UBufferedFS in 'LZMA\UBufferedFS.pas',
  uClass in 'LZMA\uClass.pas',
  UCRC in 'LZMA\UCRC.pas',
  ULZBinTree in 'LZMA\compression\LZ\ULZBinTree.pas',
  ULZInWindow in 'LZMA\compression\LZ\ULZInWindow.pas',
  ULZMABase in 'LZMA\compression\LZMA\ULZMABase.pas',
  ULZMACommon in 'LZMA\compression\LZMA\ULZMACommon.pas',
  ULZMAEncoder in 'LZMA\compression\LZMA\ULZMAEncoder.pas',
  UBitTreeEncoder in 'LZMA\compression\RangeCoder\UBitTreeEncoder.pas',
  URangeEncoder in 'LZMA\compression\RangeCoder\URangeEncoder.pas',
  ULZMAEnc in 'LZMA\ULZMAEnc.pas',
  URangeDecoder in 'LZMA\compression\RangeCoder\URangeDecoder.pas';

begin
  Maker_Main;
end.

