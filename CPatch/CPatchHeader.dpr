{$IFDEF VER185 or VER180}
{$SetPEFlags 1}
{$ENDIF}
{$Q-}
{$R-}
{$T-}

program CPatchHeader;

{$R 'resource.res' 'resource.rc'}

uses
  Windows,
  ComCtl32 in 'ComCtl32.pas',
  CommDlg in 'CommDlg.pas',
  Header in 'Header.pas',
  Patcher in 'Patcher.pas',
  UBufferedFS in 'LZMA\UBufferedFS.pas',
  uClass in 'LZMA\uClass.pas',
  UCRC in 'LZMA\UCRC.pas',
  ULZMADec in 'LZMA\ULZMADec.pas',
  ULZOutWindow in 'LZMA\compression\LZ\ULZOutWindow.pas',
  ULZMABase in 'LZMA\compression\LZMA\ULZMABase.pas',
  ULZMACommon in 'LZMA\compression\LZMA\ULZMACommon.pas',
  ULZMADecoder in 'LZMA\compression\LZMA\ULZMADecoder.pas',
  UBitTreeDecoder in 'LZMA\compression\RangeCoder\UBitTreeDecoder.pas',
  URangeDecoder in 'LZMA\compression\RangeCoder\URangeDecoder.pas';

begin
  Header_Main;
end.
