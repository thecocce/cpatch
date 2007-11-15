{$WARN SYMBOL_PLATFORM OFF}
{$Q-}
{$R-}
{$T-}

unit ComCtl32;

interface
uses
  Windows, Messages;

var
  RICHEDIT_CLASSNAME: PWideChar;

type
  {$EXTERNALSYM PBRANGE}
  PBRANGE = record
    iLow: Integer;
    iHigh: Integer;
  end;
  PPBRange = ^TPBRange;
  TPBRange = PBRANGE;

const
  SF_USECODEPAGE = $20;
  PROGRESS_CLASS = 'msctls_progress32';

  {$EXTERNALSYM CCM_FIRST}
  CCM_FIRST               = $2000;      { Common control shared messages }
  {$EXTERNALSYM CCM_LAST}
  CCM_LAST                = CCM_FIRST + $200;

  {$EXTERNALSYM CCM_SETBKCOLOR}
  CCM_SETBKCOLOR          = CCM_FIRST + 1; // lParam is bkColor

  {$EXTERNALSYM PBS_SMOOTH}
  PBS_SMOOTH              = 01;
  {$EXTERNALSYM PBS_VERTICAL}
  PBS_VERTICAL            = 04;

  {$EXTERNALSYM PBM_SETRANGE}
  PBM_SETRANGE            = WM_USER+1;
  {$EXTERNALSYM PBM_SETPOS}
  PBM_SETPOS              = WM_USER+2;
  {$EXTERNALSYM PBM_DELTAPOS}
  PBM_DELTAPOS            = WM_USER+3;
  {$EXTERNALSYM PBM_SETSTEP}
  PBM_SETSTEP             = WM_USER+4;
  {$EXTERNALSYM PBM_STEPIT}
  PBM_STEPIT              = WM_USER+5;
  {$EXTERNALSYM PBM_SETRANGE32}
  PBM_SETRANGE32          = WM_USER+6;   // lParam = high, wParam = low
  {$EXTERNALSYM PBM_GETRANGE}
  PBM_GETRANGE            = WM_USER+7;   // lParam = PPBRange or Nil
					 // wParam = False: Result = high
					 // wParam = True: Result = low
  {$EXTERNALSYM PBM_GETPOS}
  PBM_GETPOS              = WM_USER+8;
  {$EXTERNALSYM PBM_SETBARCOLOR}
  PBM_SETBARCOLOR         = WM_USER+9;		// lParam = bar color
  {$EXTERNALSYM PBM_SETBKCOLOR}
  PBM_SETBKCOLOR          = CCM_SETBKCOLOR;  // lParam = bkColor

  { For Windows >= XP }
  {$EXTERNALSYM PBS_MARQUEE}
  PBS_MARQUEE             = $08;
  {$EXTERNALSYM PBM_SETMARQUEE}
  PBM_SETMARQUEE          = WM_USER+10;

  { For Windows >= Vista }
  {$EXTERNALSYM PBS_SMOOTHREVERSE}
  PBS_SMOOTHREVERSE       = $10;

  { For Windows >= Vista }
  {$EXTERNALSYM PBM_GETSTEP}
  PBM_GETSTEP             = WM_USER+13;
  {$EXTERNALSYM PBM_GETBKCOLOR}
  PBM_GETBKCOLOR          = WM_USER+14;
  {$EXTERNALSYM PBM_GETBARCOLOR}
  PBM_GETBARCOLOR         = WM_USER+15;
  {$EXTERNALSYM PBM_SETSTATE}
  PBM_SETSTATE            = WM_USER+16;  { wParam = PBST_[State] (NORMAL, ERROR, PAUSED) }
  {$EXTERNALSYM PBM_GETSTATE}
  PBM_GETSTATE            = WM_USER+17;

  { For Windows >= Vista }
  {$EXTERNALSYM PBST_NORMAL}
  PBST_NORMAL             = $0001;
  {$EXTERNALSYM PBST_ERROR}
  PBST_ERROR              = $0002;
  {$EXTERNALSYM PBST_PAUSED}
  PBST_PAUSED             = $0003;

  EDITPartFiller0 = 0;
  {$EXTERNALSYM EDITPartFiller0}
  EP_EDITTEXT = 1;
  {$EXTERNALSYM EP_EDITTEXT}
  EP_CARET = 2;
  {$EXTERNALSYM EP_CARET}

type
  TInitCommonControlsEx = packed record
    dwSize: DWORD;
    dwICC: DWORD;
  end;
  PInitCommonControlsEx = ^TInitCommonControlsEx;

procedure InitCommonControls; external 'comctl32.dll' name 'InitCommonControls';

procedure InitCommonControlsEx( dwICC: DWORD );

implementation

var
  ComCtl32_Module, RichEdit_Module: HModule;

procedure InitCommonControlsEx( dwICC: DWORD );
var Proc: procedure( ICC: PInitCommonControlsEx ); stdcall;
    ICC: TInitCommonControlsEx;
begin
  InitCommonControls;
  if RichEdit_Module = 0 then
  begin
    RichEdit_Module := LoadLibrary( 'msftedit' );
    if RichEdit_Module = 0 then
    begin
      RichEdit_Module := LoadLibrary( 'riched20' );
      RICHEDIT_CLASSNAME := 'RichEdit20W';
    end
    else
      RICHEDIT_CLASSNAME := 'RichEdit50W';
  end;
  if ComCtl32_Module = 0 then
    ComCtl32_Module := LoadLibrary( 'comctl32' );
  @ Proc := GetProcAddress( ComCtl32_Module, 'InitCommonControlsEx' );
  if Assigned( Proc ) then
  begin
    ICC.dwSize := Sizeof( ICC );
    ICC.dwICC := dwICC;
    Proc( @ ICC );
  end;
  FreeLibrary( ComCtl32_Module );
end;

end.

