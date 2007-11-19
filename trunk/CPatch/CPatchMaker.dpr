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
  UpdateIcon in 'UpdateIcon.pas';

begin
  Maker_Main;
end.

