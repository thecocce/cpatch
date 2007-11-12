{$IFDEF VER185 or VER180}
{$SetPEFlags 1}
{$ENDIF}
{$Q-}
{$R-}
{$T-}

program CPatchMaker;

{$R 'resource.res' 'resource.rc'}
uses
  Maker in 'Maker.pas';

begin
  Maker_Main;
end.

