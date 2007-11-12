{$WARN SYMBOL_PLATFORM OFF}
{$Q-}
{$R-}
{$T-}
//{$DEFINE LANG_CHS}

unit Maker;

interface

procedure Maker_Main;

implementation

uses
  Windows,
  Messages,
  ShellAPI,
  FastMM4,
  CommDlg,
  ComCtl32;

const
  IDC_SRCFILE = 101;
  IDC_DSTFILE = 102;
  IDC_SRCBTN = 103;
  IDC_DSTBTN = 104;
  IDC_DESC = 105;
  IDC_GOBTN = 106;
  IDC_PROGRESS = 107;

  MAIN_WIDTH = 500;
  MAIN_HEIGHT = 450;

var
  MainWnd, SrcFileWnd, SrcFileBtn, DstFileWnd, DstFileBtn, GoBtnWnd, ProgWnd: HWND;

function WndProc(hWnd: HWND; message: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  ofn: OPENFILENAMEW;
  szFile: packed array [0..259] of WCHAR;
  point: TPoint;
  FWnd: Cardinal;
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
{					char ofn[260], nfn[260];
					int i = 0;
					GetWindowText(hF1, ofn, 260);
					sprintf(nfn, "%s.bak", ofn);
					while(MoveFile(ofn, nfn) == FALSE)
						sprintf(nfn, "%s.b%02d", ofn, i ++);
					if(xd3_patch(nfn, lfn, patchoff, ofn) == -1)
					begin
						DeleteFile(ofn);
						MoveFile(nfn, ofn);
#ifdef LANG_CHS
						MessageBox(hWnd, "应用补丁失败!", "错误", 0);
#else
						MessageBox(hWnd, "Failed to apply patch!", "Error", 0);
#endif
					end
					else
					begin
						if(SendMessage(hBak, BM_GETCHECK, 0, 0) != BST_CHECKED)
						begin
							DeleteFile(nfn);
						end;
#ifdef LANG_CHS
						MessageBox(hWnd, "应用补丁成功!", "成功", 0);
#else
						MessageBox(hWnd, "Applied patch!", "Success", 0);
#endif
					end;
          }
            end;
          IDC_SRCBTN, IDC_DSTBTN:
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
                if LOWORD(wParam) = IDC_SRCBTN then
                  SetWindowTextW(SrcFileWnd, ofn.lpstrFile)
                else
                  SetWindowTextW(DstFileWnd, ofn.lpstrFile);
                if (GetWindowTextLengthW(SrcFileWnd) > 0) and (GetWindowTextLengthW(DstFileWnd) > 0) then
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
        FWnd := ChildWindowFromPoint(MainWnd, point);
        if FWnd = SrcFileWnd then
          SetWindowTextW(SrcFileWnd, szFile)
        else if FWnd = DstFileWnd then
          SetWindowTextW(DstFileWnd, szFile)
        else
        begin
          if GetWindowTextLengthW(SrcFileWnd) <= 0 then
            SetWindowTextW(SrcFileWnd, szFile)
          else
            SetWindowTextW(DstFileWnd, szFile);
        end;
        DragFinish(wParam);
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
	wcex.hIcon			:= LoadIcon(hInstance, 'MAINICON');
	wcex.hCursor		:= LoadCursor(0, IDC_ARROW);
	wcex.hbrBackground	:= HBRUSH(COLOR_BTNSHADOW);
	wcex.lpszMenuName	:= nil;
	wcex.lpszClassName	:= 'CPatchMaker';
	wcex.hIconSm		:= LoadIcon(wcex.hInstance, 'MAINICONSMALL');

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
  '原始文件:'
{$ELSE}
  'Original:'
{$ENDIF}
  , WS_VISIBLE or WS_CHILD, rect.Left + 8, 11, 60, 16, MainWnd, IDC_SRCFILE, hInstance, nil);
  SrcFileWnd := UserWin(WS_EX_CLIENTEDGE, 'EDIT', nil, WS_VISIBLE or WS_CHILD or ES_READONLY or ES_AUTOHSCROLL,
    rect.Left + 70, 8, rect.Right - rect.Left - 140, 20, MainWnd, IDC_SRCFILE,
    hInstance, nil);
  SrcFileBtn := UserWin(0, 'BUTTON', '...', WS_VISIBLE or WS_CHILD or
    BS_PUSHBUTTON, rect.Right - rect.Left - 68, 8, 60, 20, MainWnd, IDC_SRCBTN,
    hInstance, nil);

  UserWin(0, 'STATIC',
{$IFDEF LANG_CHS}
  '目标文件:'
{$ELSE}
  'Target:'
{$ENDIF}
  , WS_VISIBLE or WS_CHILD, rect.Left + 8, 33, 60, 16, MainWnd, IDC_SRCFILE, hInstance, nil);
  DstFileWnd := UserWin(WS_EX_CLIENTEDGE, 'EDIT', nil, WS_VISIBLE or WS_CHILD or ES_READONLY or ES_AUTOHSCROLL,
    rect.Left + 70, 30, rect.Right - rect.Left - 140, 20, MainWnd, IDC_DSTFILE,
    hInstance, nil);
  DstFileBtn := UserWin(0, 'BUTTON', '...', WS_VISIBLE or WS_CHILD or
    BS_PUSHBUTTON, rect.Right - rect.Left - 68, 30, 60, 20, MainWnd, IDC_DSTBTN,
    hInstance, nil);

  UserWin(0, 'STATIC',
{$IFDEF LANG_CHS}
  '补丁说明:'
{$ELSE}
  'Description:'
{$ENDIF}
  , WS_VISIBLE or WS_CHILD, rect.Left + 8, 55, rect.Right - rect.Left - 16, 16, MainWnd, IDC_SRCFILE, hInstance, nil);

  ProgWnd := UserWin(0, PROGRESS_CLASS, nil, WS_VISIBLE or WS_CHILD, rect.Left,
    rect.Bottom - 18, rect.Right - rect.Left, 18, MainWnd, IDC_PROGRESS,
    hInstance, nil);
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

procedure Maker_Main;
begin
  InitCommonControlsEx($20);
  g_font := GetAFont;
  InitWindows;
  MessageLoop;
  DeleteObject(g_font);
end;

end.

