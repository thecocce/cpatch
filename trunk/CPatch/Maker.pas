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
  RichEdit,
  Messages,
  ShellAPI,
  FastMM4,
  CommDlg,
  ComCtl32,
  UpdateIcon,
  PatchGen;

const
  IDC_SRCFILE = 101;
  IDC_DSTFILE = 102;
  IDC_SRCBTN = 103;
  IDC_DSTBTN = 104;
  IDC_ICONBTN = 105;
  IDC_DESC = 106;
  IDC_GOBTN = 107;
  IDC_PROGRESS = 108;

  MAIN_WIDTH = 500;
  MAIN_HEIGHT = 450;

var
  MainWnd, SrcFileWnd, SrcFileBtn, DstFileWnd, DstFileBtn, IconBtn, DescWnd, GoBtnWnd, ProgWnd: HWND;
  Terminated: Boolean;
  icon: HICON;
  iconf: packed array [0..259] of WideChar;

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

function GPCallback(OP: Integer; Value: UINT64): Boolean;
begin
  case OP of
  GPO_LENGTH:
  begin
    SendMessage(ProgWnd, PBM_SETRANGE32, 0, Value div 256);
    SendMessage(ProgWnd, PBM_SETPOS, 0, 0);
  end;
  GPO_POSITION:
    SendMessage(ProgWnd, PBM_SETPOS, Value div 256, 0);
  end;
  result := ProcessMessages;
end;

type
  PDesc = ^TDesc;
  TDesc = packed record
    desc: array of Byte;
    size: Integer;
  end;

function sicb(dwCookie: Longint; pbBuff: PByte;
  cb: Longint; var pcb: Longint): Longint; stdcall;
var
  desc: PDesc;
begin
  desc := PDesc(dwCookie);
  result := 0;
  while Length(desc.desc) < desc.size + cb do
    SetLength(desc.desc, Length(desc.desc) + 256);
  Move(pbBuff^, desc.desc[desc.size], cb);
  Inc(desc.size, cb);
  pcb := cb;
end;

type
  PHICON = ^HICON;

function MyExtractIconExW(lpszFile: PWideChar; nIconIndex: Integer;
  phiconLarge, phiconSmall: PHICON; nIcons: UINT): UINT; stdcall; external 'shell32.dll' name 'ExtractIconExW';

procedure ExtIcons(fn: PWideChar);
var
  icount: integer;
begin
  icount := MyExtractIconExW(fn, -1, nil, nil, 0);
  if icount > 0 then
  begin
    DestroyIcon(icon);
    MyExtractIconExW(fn, 0, @icon, nil, 1);
    lstrcpyW(@iconf[0], fn);
  end;
end;

function WndProc(hWnd: HWND; message: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  ofn: OPENFILENAMEW;
  szFile: packed array [0..259] of WCHAR;
  point: TPoint;
  FWnd, size, w: Cardinal;
  orgfn, newfn: array [0..259] of WideChar;
  pf: THandle;
  hrsrc: Cardinal;
  hres: HGLOBAL;
  es: TEditStream;
  desc: TDesc;
  dc: HDC;
  ps: TPaintStruct;
const
  Magic: ShortString = 'PATCHDAT';
begin
	case message of
  WM_PAINT:
    begin
      dc := BeginPaint(MainWnd, ps);
      DrawIconEx(dc, 200, 55, icon, 32, 32, 0, 0, DI_NORMAL);
      EndPaint(MainWnd, ps);
    end;
	WM_COMMAND:
    begin
      case HIWORD(wParam) of
      BN_CLICKED:
        begin
          case LOWORD(wParam) of
          IDC_ICONBTN:
            begin
    					ZeroMemory(@ofn, sizeof(ofn));
    					ofn.lStructSize := sizeof(ofn);
		    			ofn.hwndOwner := hWnd;
				    	ofn.lpstrFile := szFile;
    					ofn.lpstrFile[0] := #0;
    					ofn.nMaxFile := sizeof(szFile);
		    			ofn.lpstrFilter := 'Icon files'#0'*.ico;*.exe'#0;
				    	ofn.nFilterIndex := 1;
    					ofn.lpstrFileTitle := nil;
		    			ofn.nMaxFileTitle := 0;
				    	ofn.lpstrInitialDir := nil;
    					ofn.Flags := OFN_PATHMUSTEXIST or OFN_FILEMUSTEXIST;

              if GetOpenFileNameW(ofn) then
              begin
                ExtIcons(ofn.lpstrFile);
              end;
            end;
          IDC_GOBTN:
            begin
    					ZeroMemory(@ofn, sizeof(ofn));
    					ofn.lStructSize := sizeof(ofn);
		    			ofn.hwndOwner := hWnd;
				    	ofn.lpstrFile := szFile;
    					ofn.lpstrFile[0] := #0;
    					ofn.nMaxFile := sizeof(szFile);
		    			ofn.lpstrFilter := 'exe files'#0'*.exe'#0;
				    	ofn.nFilterIndex := 1;
    					ofn.lpstrFileTitle := nil;
		    			ofn.nMaxFileTitle := 0;
				    	ofn.lpstrInitialDir := nil;
              ofn.lpstrDefExt := 'exe';
    					ofn.Flags := OFN_PATHMUSTEXIST or OFN_OVERWRITEPROMPT;

              if GetSaveFileNameW(ofn) then
              begin
                GetWindowTextW(SrcFileWnd, orgfn, 260);
                GetWindowTextW(DstFileWnd, newfn, 260);
                pf := CreateFileW(ofn.lpstrFile, GENERIC_WRITE, FILE_SHARE_READ, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
                hrsrc := FindResourceW(0, PWideChar(150), 'DATA');
                hres := LoadResource(0, hrsrc);
                size := SizeofResource(0, hrsrc);
                WriteFile(pf, LockResource(hres)^, size, w, nil);
                UnlockResource(hres);
                FreeResource(hrsrc);
                CloseHandle(pf);

                UpdateIconFromFile(@iconf[0], ofn.lpstrFile);

                pf := CreateFileW(ofn.lpstrFile, GENERIC_WRITE or GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
                SetFilePointer(pf, 0, nil, FILE_END);
                SetLength(desc.desc, 256);
                desc.size := 0;
                es.dwError := 0;
                es.dwCookie := Integer(@desc);
                es.pfnCallback := sicb;
                SendMessage(DescWnd, EM_STREAMOUT, SF_RTF or SF_USECODEPAGE or (CP_UTF8 shl 16), Cardinal(@es));
                WriteFile(pf, Magic[1], 8, w, nil);
                WriteFile(pf, desc.size, 4, w, nil);
                WriteFile(pf, desc.desc[0], desc.size, w, nil);
                Finalize(desc.desc);
                if not GeneratePatch(pf, orgfn, newfn, GPCallback) then
                begin
                  CloseHandle(pf);
                  if Terminated then
                    Halt;
                  MessageBox(hWnd,
{$IFDEF LANG_CHS}
                    '制作补丁失败!', '错误'
{$ELSE}
                    'Failed to create patch!', 'Error'
{$ENDIF}
                    , 0);
                end
                else
                begin
                  CloseHandle(pf);
                  MessageBox(hWnd,
{$IFDEF LANG_CHS}
                    '补丁生成成功!', '成功'
{$ELSE}
                    'Generated patch!', 'Success'
{$ENDIF}
                    , 0);
                end;
              end;
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
	wcex.hIcon			:= LoadIconW(hInstance, 'MAINICON');
	wcex.hCursor		:= LoadCursor(0, IDC_ARROW);
	wcex.hbrBackground	:= HBRUSH(COLOR_BTNSHADOW);
	wcex.lpszMenuName	:= nil;
	wcex.lpszClassName	:= 'CPatchMaker';
	wcex.hIconSm		:= LoadIconW(wcex.hInstance, 'MAINICONSMALL');

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
  icon := LoadIconW(hInstance, '#200');
  lstrcpyW(iconf, PWideChar(WideString(ParamStr(0))));
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
  , WS_VISIBLE or WS_CHILD, rect.Left + 8, rect.Top + 11, 60, 16, MainWnd, 0, hInstance, nil);
  SrcFileWnd := UserWin(WS_EX_CLIENTEDGE, 'EDIT', nil, WS_VISIBLE or WS_CHILD or ES_READONLY or ES_AUTOHSCROLL,
    rect.Left + 70, rect.Top + 8, rect.Right - rect.Left - 140, 20, MainWnd, IDC_SRCFILE,
    hInstance, nil);
  SrcFileBtn := UserWin(0, 'BUTTON', '...', WS_VISIBLE or WS_CHILD or
    BS_PUSHBUTTON, rect.Right - rect.Left - 68, rect.Top + 8, 60, 20, MainWnd, IDC_SRCBTN,
    hInstance, nil);

  UserWin(0, 'STATIC',
{$IFDEF LANG_CHS}
  '目标文件:'
{$ELSE}
  'Target:'
{$ENDIF}
  , WS_VISIBLE or WS_CHILD, rect.Left + 8, rect.Top + 33, 60, 16, MainWnd, 0, hInstance, nil);
  DstFileWnd := UserWin(WS_EX_CLIENTEDGE, 'EDIT', nil, WS_VISIBLE or WS_CHILD or ES_READONLY or ES_AUTOHSCROLL,
    rect.Left + 70, 30, rect.Right - rect.Left - 140, 20, MainWnd, IDC_DSTFILE,
    hInstance, nil);
  DstFileBtn := UserWin(0, 'BUTTON', '...', WS_VISIBLE or WS_CHILD or
    BS_PUSHBUTTON, rect.Right - rect.Left - 68, rect.Top + 30, 60, 20, MainWnd, IDC_DSTBTN,
    hInstance, nil);

  IconBtn := UserWin(0, 'BUTTON',
{$IFDEF LANG_CHS}
    '选择图标'
{$ELSE}
    'Select Icon'
{$ENDIF}
    , WS_VISIBLE or WS_CHILD or
    BS_PUSHBUTTON, rect.Left + 70, rect.Top + 52, 100, 20, MainWnd, IDC_ICONBTN,
    hInstance, nil);

  UserWin(0, 'STATIC',
{$IFDEF LANG_CHS}
  '补丁说明:'
{$ELSE}
  'Description:'
{$ENDIF}
  , WS_VISIBLE or WS_CHILD, rect.Left + 8, rect.Top + 77, 180, 16, MainWnd, 0, hInstance, nil);

  DescWnd := UserWin(0, RICHEDIT_CLASSNAME, nil, WS_VISIBLE or WS_CHILD or ES_AUTOHSCROLL or ES_AUTOVSCROLL or ES_WANTRETURN or WS_HSCROLL or WS_VSCROLL or ES_MULTILINE,
    1, 1, rect.Right - rect.Left - 18, rect.Bottom - rect.Top - 129,
    UserWin(0, 'STATIC', nil, WS_BORDER or WS_VISIBLE or WS_CHILD, rect.Left + 8, rect.Top + 95, rect.Right - rect.Left - 16, rect.Bottom - rect.Top - 127, MainWnd, 0, hInstance, nil),
    IDC_DESC, hInstance, nil);

  GoBtnWnd := UserWin(0, 'BUTTON', 'GO!', WS_VISIBLE or WS_CHILD or
    BS_PUSHBUTTON, rect.Right - 88, rect.Bottom - 28, 80, 20, MainWnd, IDC_GOBTN,
    hInstance, nil);

  ProgWnd := UserWin(0, PROGRESS_CLASS, nil, WS_VISIBLE or WS_CHILD, rect.Left + 8,
    rect.Bottom - 28, rect.Right - rect.Left - 98, 20, MainWnd, IDC_PROGRESS,
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
  InitCommonControlsEx($FFFF);
  g_font := GetAFont;
  InitWindows;
  MessageLoop;
  DeleteObject(g_font);
end;

begin
  Terminated := false;
end.

