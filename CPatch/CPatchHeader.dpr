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
  Patcher in 'Patcher.pas';

begin
  Header_Main;
end.
