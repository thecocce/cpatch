{$WARN SYMBOL_PLATFORM OFF}
{$Q-}
{$R-}
{$T-}
//{$DEFINE LANG_CHS}

unit Header;

interface

procedure Header_Main;

implementation

uses
  Windows,
  RichEdit,
  Messages,
  ShellAPI,
  CommDlg,
  ComCtl32,
  Patcher,
  uClass;

const
  IDC_SRCFILE = 101;
  IDC_SRCBTN = 102;
  IDC_DESC = 103;
  IDC_GOBTN = 104;
  IDC_PROGRESS = 105;

  MAIN_WIDTH = 300;
  MAIN_HEIGHT = 280;

var
  MainWnd, SrcFileWnd, SrcFileBtn, DescWnd, ResCheck, GoBtnWnd, ProgWnd: HWND;
  pst: TFileStream;
  patchoff: Cardinal;
  Terminated: Boolean;

function ProcessMessage: Integer;
var Msg: TMsg;
begin
   Result := 0;
   if PeekMessage( Msg, 0, 0, 0, PM_REMOVE ) then
   begin
      if Msg.message <> 0 then
        Result := 2;
      if (Msg.message = WM_QUIT) then
      begin
        Terminated := true;
        Result := 1;
      end
      else
      begin
        TranslateMessage( Msg );
        DispatchMessage( Msg );
      end;
   end;
end;

function ProcessMessages: Boolean;
var
  r: Integer;
begin
  repeat
    r := ProcessMessage;
  until r < 2;
  Result := r = 0;
end;

function PCallback(OP: Integer; Value: UINT64): Boolean;
begin
  case OP of
  PO_LENGTH:
  begin
    SendMessage(ProgWnd, PBM_SETRANGE32, 0, Value div 256);
    SendMessage(ProgWnd, PBM_SETPOS, 0, 0);
  end;
  PO_OFFSET:
    SendMessage(ProgWnd, PBM_SETPOS, Value div 256, 0);
  end;
  result := ProcessMessages;
end;

function WndProc(hWnd: HWND; message: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  szFile: packed array [0..259] of WCHAR;
  point: TPoint;
  ofn: OPENFILENAMEW;
  orgfn: array [0..259] of WideChar;
begin
	case message of
	WM_COMMAND:
    begin
      case HIWORD(wParam) of
      BN_CLICKED:
        begin
          case LOWORD(wParam) of
          IDC_GOBTN:
            begin
              GetWindowTextW(SrcFileWnd, orgfn, 260);
              pst.Position := patchoff;
              if not DoPatch(orgfn, pst, PCallback, (ResCheck = 0) or (SendMessage(ResCheck, BM_GETCHECK, 0, 0) = BST_CHECKED)) then
              begin
                if not Terminated then
                  MessageBox(hWnd,
{$IFDEF LANG_CHS}
                    '应用补丁失败!', '错误'
{$ELSE}
                    'Failed to apply patch!', 'Error'
{$ENDIF}
                    , 0);
              end
              else
              begin
                MessageBox(hWnd,
{$IFDEF LANG_CHS}
                  '补丁应用成功!', '成功'
{$ELSE}
                  'Applied patch!', 'Success'
{$ENDIF}
                  , 0);
              end;
            end;
          IDC_SRCBTN:
            begin
    					ZeroMemory(@ofn, sizeof(ofn));
    					ofn.lStructSize := sizeof(ofn);
		    			ofn.hwndOwner := hWnd;
				    	ofn.lpstrFile := szFile;
    					ofn.lpstrFile[0] := #0;
    					ofn.nMaxFile := sizeof(szFile);
		    			ofn.lpstrFilter := 'All files'#0'*.*'#0;
				    	ofn.nFilterIndex := 1;
    					ofn.lpstrFileTitle := nil;
		    			ofn.nMaxFileTitle := 0;
				    	ofn.lpstrInitialDir := nil;
    					ofn.Flags := OFN_PATHMUSTEXIST or OFN_FILEMUSTEXIST;

              if GetOpenFileNameW(ofn) then
              begin
                SetWindowTextW(SrcFileWnd, ofn.lpstrFile);
                if GetWindowTextLengthW(SrcFileWnd) > 0 then
                  EnableWindow(GoBtnWnd, TRUE);
              end;
            end;
          end;
        end;
      end;
    end;
  WM_DROPFILES:
    begin
      if DragQueryFileW(wParam, $FFFFFFFF, nil, 0) > 0 then
      begin
        DragQueryFileW(wParam, 0, szFile, 260);
        DragQueryPoint(wParam, point);
        SetWindowTextW(SrcFileWnd, szFile);
        DragFinish(wParam);
        if GetWindowTextLengthW(SrcFileWnd) > 0 then
          EnableWindow(GoBtnWnd, TRUE);
     end;
    end;
	WM_DESTROY:
  	PostQuitMessage(0);
  else
    begin
		  result := DefWindowProcW(hWnd, message, wParam, lParam);
      exit;
    end;
	end;
	result := 0;
end;

function MyRegisterClass(hInstance: HINST): ATOM;
var
  wcex: WNDCLASSEXW;
begin
	wcex.cbSize := sizeof(WNDCLASSEXW);

	wcex.style	:= CS_HREDRAW or CS_VREDRAW;
	wcex.lpfnWndProc	:= @WndProc;
	wcex.cbClsExtra		:= 0;
	wcex.cbWndExtra		:= 0;
	wcex.hInstance		:= hInstance;
	wcex.hIcon			:= LoadIconW(hInstance, MAKEINTRESOURCEW(1));
	wcex.hCursor		:= LoadCursor(0, IDC_ARROW);
	wcex.hbrBackground	:= HBRUSH(COLOR_BTNSHADOW);
	wcex.lpszMenuName	:= nil;
	wcex.lpszClassName	:= 'CPatchMaker';
	wcex.hIconSm		:= 0;

	result := RegisterClassExW(wcex);
end;

function GetAFont:HFONT;
var
  lf: TLOGFONTW;
begin
    GetObjectW(GetStockObject(ANSI_VAR_FONT), sizeof(TLOGFONT), @lf);
    result := CreateFontW(-12, 0, lf.lfEscapement, lf.lfOrientation, 0,
      lf.lfItalic, lf.lfUnderline, lf.lfStrikeOut, lf.lfCharSet,
      lf.lfOutPrecision, lf.lfClipPrecision, lf.lfQuality, lf.lfPitchAndFamily,
{$ifdef LANG_CHS}
		'宋体'
{$else}
		'Courier New'
{$endif}
		);
end;

var
  g_font: HFONT;

function UserWin(dwExStyle: DWORD; lpClassName: PWideChar; lpWindowName: PWideChar; dwStyle:
  DWORD; x, y, nWidth, nHeight: integer; hWndParent: HWND; hMenu: HMENU;
  hInstance: HINST; lpParam: Pointer): HWND;
begin
  result := CreateWindowExW(dwExStyle, lpClassName, lpWindowName, dwStyle, x, y, nWidth, nHeight,
    hWndParent, hMenu, hInstance, lpParam);
	SendMessageW(result, WM_SETFONT, WPARAM(g_font), LPARAM(1));
end;

procedure InitWindows;
var
  cx, cy: Integer;
  rect: TRect;
  flag, size: Cardinal;
  wt: array of Byte;
begin
	MyRegisterClass(hInstance);
 	cx := GetSystemMetrics(SM_CXSCREEN);
	cy := GetSystemMetrics(SM_CYSCREEN);
	MainWnd := UserWin(WS_EX_ACCEPTFILES, 'CPatchMaker', 'CPatch Maker', WS_OVERLAPPED or WS_CAPTION
    or WS_SYSMENU, (cx - MAIN_WIDTH) div 2, (cy - MAIN_HEIGHT) div 2, MAIN_WIDTH, MAIN_HEIGHT, 0, 0,
    hInstance, nil);
  GetClientRect(MainWnd, rect);

  UserWin(0, 'STATIC',
{$IFDEF LANG_CHS}
  '目标文件:'
{$ELSE}
  'Filename:'
{$ENDIF}
  , WS_VISIBLE or WS_CHILD, rect.Left + 8, rect.Bottom - 50, 60, 16, MainWnd, 0, hInstance, nil);
  SrcFileWnd := UserWin(WS_EX_CLIENTEDGE, 'EDIT', nil, WS_VISIBLE or WS_CHILD or ES_READONLY or ES_AUTOHSCROLL,
    rect.Left + 70, rect.Bottom - 53, rect.Right - rect.Left - 160, 20, MainWnd, IDC_SRCFILE,
    hInstance, nil);
  SrcFileBtn := UserWin(0, 'BUTTON',
{$IFDEF LANG_CHS}
  '浏览'
{$ELSE}
  'Browse'
{$ENDIF}
    ,WS_VISIBLE or WS_CHILD or
    BS_PUSHBUTTON, rect.Right - rect.Left - 88, rect.Bottom - 53, 80, 20, MainWnd, IDC_SRCBTN,
    hInstance, nil);

  DescWnd := UserWin(WS_EX_TRANSPARENT, RICHEDIT_CLASSNAME, nil, WS_VISIBLE or WS_CHILD or ES_AUTOVSCROLL or ES_WANTRETURN or WS_VSCROLL or ES_MULTILINE or ES_READONLY,
    1, 1, rect.Right - rect.Left - 18, rect.Bottom - rect.Top - 67,
    UserWin(0, 'STATIC', nil, WS_BORDER or WS_VISIBLE or WS_CHILD, rect.Left + 8, rect.Top + 8, rect.Right - rect.Left - 16, rect.Bottom - rect.Top - 65, MainWnd, 0, hInstance, nil),
    IDC_DESC, hInstance, nil);

  pst.Read(size, 4);
  SetLength(wt, size * 2 + 2);
  pst.Read(wt[0], size * 2);
  SetWindowTextW(MainWnd, @wt[0]);
  wt[size * 2] := 0;
  wt[size * 2 + 1] := 0;
  pst.Read(size, 4);
  SetLength(wt, size + 1);
  pst.Read(wt[0], size);
  SetWindowTextW(DescWnd, @wt[0]);
  Finalize(wt);
  patchoff := pst.Position;
  pst.Read(flag, 4);
  if (flag and 1) > 0 then
  begin
    ProgWnd := UserWin(0, PROGRESS_CLASS, nil, WS_VISIBLE or WS_CHILD, rect.Left + 8,
      rect.Bottom - 28, rect.Right - rect.Left - 164, 20, MainWnd, IDC_PROGRESS,
      hInstance, nil);

    ResCheck := UserWin(0, 'BUTTON',
{$IFDEF LANG_CHS}
    '还原数据'
{$ELSE}
    'Restore'
{$ENDIF}
      , WS_VISIBLE or WS_CHILD or BS_AUTOCHECKBOX, rect.Right - 154, rect.Bottom - 28, 64, 20, MainWnd, 0, hInstance, nil);
  end
  else
  begin
    ResCheck := 0;
    ProgWnd := UserWin(0, PROGRESS_CLASS, nil, WS_VISIBLE or WS_CHILD, rect.Left + 8,
      rect.Bottom - 28, rect.Right - rect.Left - 98, 20, MainWnd, IDC_PROGRESS,
      hInstance, nil);
  end;

  GoBtnWnd := UserWin(0, 'BUTTON',
{$IFDEF LANG_CHS}
  '应用补丁!'
{$ELSE}
  'Apply!'
{$ENDIF}
  , WS_VISIBLE or WS_CHILD or
    BS_PUSHBUTTON, rect.Right - 88, rect.Bottom - 28, 80, 20, MainWnd, IDC_GOBTN,
    hInstance, nil);
  EnableWindow(GoBtnWnd, false);

  ShowWindow(MainWnd, CmdShow);
	UpdateWindow(MainWnd);
end;

procedure MessageLoop;
var
  hAccelTable: HACCEL;
  msg: TMSG;
begin
	hAccelTable := LoadAcceleratorsW(hInstance, 'CPatchMakerAccel');
	while GetMessageW(msg, 0, 0, 0) do
	begin
		if TranslateAcceleratorW(msg.hwnd, hAccelTable, msg) = 0 then
		begin
			TranslateMessage(msg);
			DispatchMessageW(msg);
		end;
	end;
end;

function InitPatch: Boolean;
var
  off: Cardinal;
  mdata: packed array [0..7] of Char;
const
  magic: ShortString = 'PATCHDAT';
begin
  result := false;
  pst := TFileStream.Create(ParamStr(0), fmOpenRead or fmShareDenyNone);
  off := 0;
  mdata[0] := #0;
  repeat
    Inc(off, 512);
    pst.Position := off;
    if pst.Read(mdata[0], 8) < 8 then
      break;
  until (magic = mdata);
  if magic <> mdata then
  begin
    pst.Free;
    exit;
  end;
  result := true;
end;

procedure Header_Main;
begin
  if not InitPatch then
    Halt;
  InitCommonControlsEx($FFFF);
  g_font := GetAFont;
  InitWindows;
  MessageLoop;
  DeleteObject(g_font);
  pst.Free;
end;

end.

