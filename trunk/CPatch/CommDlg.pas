unit CommDlg;

interface

uses Windows, Messages;

const
  SID_IShellFolder       = '{000214E6-0000-0000-C000-000000000046}';
  SID_IEnumIDList        = '{000214F2-0000-0000-C000-000000000046}';

type
  POleStr = PWideChar;

{ Interface ID }

  PIID = PGUID;
  TIID = TGUID;

{ TSHItemID -- Item ID }
  PSHItemID = ^TSHItemID;
  {$EXTERNALSYM _SHITEMID}
  _SHITEMID = record
    cb: Word;                         { Size of the ID (including cb itself) }
    abID: array[0..0] of Byte;        { The item ID (variable length) }
  end;
  TSHItemID = _SHITEMID;
  {$EXTERNALSYM SHITEMID}
  SHITEMID = _SHITEMID;

{ TItemIDList -- List if item IDs (combined with 0-terminator) }
  PItemIDList = ^TItemIDList;
  {$EXTERNALSYM _ITEMIDLIST}
  _ITEMIDLIST = record
     mkid: TSHItemID;
   end;
  TItemIDList = _ITEMIDLIST;
  {$EXTERNALSYM ITEMIDLIST}
  ITEMIDLIST = _ITEMIDLIST;

  {$EXTERNALSYM IEnumIDList}
  IEnumIDList = interface(IUnknown)
    [SID_IEnumIDList]
    function Next(celt: ULONG; out rgelt: PItemIDList;
      var pceltFetched: ULONG): HResult; stdcall;
    function Skip(celt: ULONG): HResult; stdcall;
    function Reset: HResult; stdcall;
    function Clone(out ppenum: IEnumIDList): HResult; stdcall;
  end;

{ record for returning strings from IShellFolder member functions }

  PSTRRet = ^TStrRet;
  {$EXTERNALSYM _STRRET}
  _STRRET = record
     uType: UINT;              { One of the STRRET_* values }
     case Integer of
       0: (pOleStr: LPWSTR);                    { must be freed by caller of GetDisplayNameOf }
       1: (pStr: LPSTR);                        { NOT USED }
       2: (uOffset: UINT);                      { Offset into SHITEMID (ANSI) }
       3: (cStr: array[0..MAX_PATH-1] of Char); { Buffer to fill in }
    end;
  TStrRet = _STRRET;
  {$EXTERNALSYM STRRET}
  STRRET = _STRRET;

  {$EXTERNALSYM IShellFolder}
  IShellFolder = interface(IUnknown)
    [SID_IShellFolder]
    function ParseDisplayName(hwndOwner: HWND;
      pbcReserved: Pointer; lpszDisplayName: POLESTR; out pchEaten: ULONG;
      out ppidl: PItemIDList; var dwAttributes: ULONG): HResult; stdcall;
    function EnumObjects(hwndOwner: HWND; grfFlags: DWORD;
      out EnumIDList: IEnumIDList): HResult; stdcall;
    function BindToObject(pidl: PItemIDList; pbcReserved: Pointer;
      const riid: TIID; out ppvOut): HResult; stdcall;
    function BindToStorage(pidl: PItemIDList; pbcReserved: Pointer;
      const riid: TIID; out ppvObj): HResult; stdcall;
    function CompareIDs(lParam: LPARAM;
      pidl1, pidl2: PItemIDList): HResult; stdcall;
    function CreateViewObject(hwndOwner: HWND; const riid: TIID;
      out ppvOut): HResult; stdcall;
    function GetAttributesOf(cidl: UINT; var apidl: PItemIDList;
      var rgfInOut: UINT): HResult; stdcall;
    function GetUIObjectOf(hwndOwner: HWND; cidl: UINT; var apidl: PItemIDList;
      const riid: TIID; prgfInOut: Pointer; out ppvOut): HResult; stdcall;
    function GetDisplayNameOf(pidl: PItemIDList; uFlags: DWORD;
      var lpName: TStrRet): HResult; stdcall;
    function SetNameOf(hwndOwner: HWND; pidl: PItemIDList; lpszName: POLEStr;
      uFlags: DWORD; var ppidlOut: PItemIDList): HResult; stdcall;
  end;
  POpenFilenameW = ^TOpenFilenameW;
  tagOFNW = packed record
    lStructSize: DWORD;
    hWndOwner: HWND;
    hInstance: HINST;
    lpstrFilter: PWideChar;
    lpstrCustomFilter: PWideChar;
    nMaxCustFilter: DWORD;
    nFilterIndex: DWORD;
    lpstrFile: PWideChar;
    nMaxFile: DWORD;
    lpstrFileTitle: PWideChar;
    nMaxFileTitle: DWORD;
    lpstrInitialDir: PWideChar;
    lpstrTitle: PWideChar;
    Flags: DWORD;
    nFileOffset: Word;
    nFileExtension: Word;
    lpstrDefExt: PWideChar;
    lCustData: LPARAM;
    lpfnHook: function(Wnd: HWND; Msg: UINT; wParam: WPARAM; lParam: LPARAM): UINT stdcall;
    lpTemplateName: PWideChar;
    pvReserved: Pointer;
    dwReserved: DWORD;
    FlagsEx: DWORD;
  end;
  TOpenFilenameW = tagOFNW;
  OPENFILENAMEW = tagOFNW;

const
  {$EXTERNALSYM OFN_READONLY}
  OFN_READONLY = $00000001;
  {$EXTERNALSYM OFN_OVERWRITEPROMPT}
  OFN_OVERWRITEPROMPT = $00000002;
  {$EXTERNALSYM OFN_HIDEREADONLY}
  OFN_HIDEREADONLY = $00000004;
  {$EXTERNALSYM OFN_NOCHANGEDIR}
  OFN_NOCHANGEDIR = $00000008;
  {$EXTERNALSYM OFN_SHOWHELP}
  OFN_SHOWHELP = $00000010;
  {$EXTERNALSYM OFN_ENABLEHOOK}
  OFN_ENABLEHOOK = $00000020;
  {$EXTERNALSYM OFN_ENABLETEMPLATE}
  OFN_ENABLETEMPLATE = $00000040;
  {$EXTERNALSYM OFN_ENABLETEMPLATEHANDLE}
  OFN_ENABLETEMPLATEHANDLE = $00000080;
  {$EXTERNALSYM OFN_NOVALIDATE}
  OFN_NOVALIDATE = $00000100;
  {$EXTERNALSYM OFN_ALLOWMULTISELECT}
  OFN_ALLOWMULTISELECT = $00000200;
  {$EXTERNALSYM OFN_EXTENSIONDIFFERENT}
  OFN_EXTENSIONDIFFERENT = $00000400;
  {$EXTERNALSYM OFN_PATHMUSTEXIST}
  OFN_PATHMUSTEXIST = $00000800;
  {$EXTERNALSYM OFN_FILEMUSTEXIST}
  OFN_FILEMUSTEXIST = $00001000;
  {$EXTERNALSYM OFN_CREATEPROMPT}
  OFN_CREATEPROMPT = $00002000;
  {$EXTERNALSYM OFN_SHAREAWARE}
  OFN_SHAREAWARE = $00004000;
  {$EXTERNALSYM OFN_NOREADONLYRETURN}
  OFN_NOREADONLYRETURN = $00008000;
  {$EXTERNALSYM OFN_NOTESTFILECREATE}
  OFN_NOTESTFILECREATE = $00010000;
  {$EXTERNALSYM OFN_NONETWORKBUTTON}
  OFN_NONETWORKBUTTON = $00020000;
  {$EXTERNALSYM OFN_NOLONGNAMES}
  OFN_NOLONGNAMES = $00040000;
  {$EXTERNALSYM OFN_EXPLORER}
  OFN_EXPLORER = $00080000;
  {$EXTERNALSYM OFN_NODEREFERENCELINKS}
  OFN_NODEREFERENCELINKS = $00100000;
  {$EXTERNALSYM OFN_LONGNAMES}
  OFN_LONGNAMES = $00200000;
  {$EXTERNALSYM OFN_ENABLEINCLUDENOTIFY}
  OFN_ENABLEINCLUDENOTIFY = $00400000;
  {$EXTERNALSYM OFN_ENABLESIZING}
  OFN_ENABLESIZING = $00800000;
  { #if (_WIN32_WINNT >= 0x0500) }
  {$EXTERNALSYM OFN_DONTADDTORECENT}
  OFN_DONTADDTORECENT = $02000000;
  {$EXTERNALSYM OFN_FORCESHOWHIDDEN}
  OFN_FORCESHOWHIDDEN = $10000000;    // Show All files including System and hidden files
  { #endif // (_WIN32_WINNT >= 0x0500) }

  { FlagsEx Values }
  { #if (_WIN32_WINNT >= 0x0500) }
  {$EXTERNALSYM OFN_EX_NOPLACESBAR}
  OFN_EX_NOPLACESBAR = $00000001;
  { #endif // (_WIN32_WINNT >= 0x0500) }

{ Return values for the registered message sent to the hook function
  when a sharing violation occurs.  OFN_SHAREFALLTHROUGH allows the
  filename to be accepted, OFN_SHARENOWARN rejects the name but puts
  up no warning (returned when the app has already put up a warning
  message), and OFN_SHAREWARN puts up the default warning message
  for sharing violations.

  Note:  Undefined return values map to OFN_SHAREWARN, but are
         reserved for future use. }

  {$EXTERNALSYM OFN_SHAREFALLTHROUGH}
  OFN_SHAREFALLTHROUGH = 2;
  {$EXTERNALSYM OFN_SHARENOWARN}
  OFN_SHARENOWARN = 1;
  {$EXTERNALSYM OFN_SHAREWARN}
  OFN_SHAREWARN = 0;

type
  POFNotifyW = ^TOFNotifyW;
  _OFNOTIFYW = packed record
    hdr: TNMHdr;
    lpOFN: POpenFilenameW;
    pszFile: PWideChar;
  end;
  TOFNotifyW = _OFNOTIFYW;
  OFNOTIFYW = _OFNOTIFYW;
  POFNotifyExW = ^TOFNotifyExW;
  _OFNOTIFYEXW = packed record
    hdr: TNMHdr;
    lpOFN: POpenFilenameW;
    psf: IShellFolder;
    pidl: Pointer;
  end;
  TOFNotifyExW = _OFNOTIFYEXW;
  OFNOTIFYEXW = _OFNOTIFYEXW;

const
  {$EXTERNALSYM CDN_FIRST}
  CDN_FIRST = -601;
  {$EXTERNALSYM CDN_LAST}
  CDN_LAST = -699;

{ Notifications when Open or Save dialog status changes }

  {$EXTERNALSYM CDN_INITDONE}
  CDN_INITDONE = CDN_FIRST - 0;
  {$EXTERNALSYM CDN_SELCHANGE}
  CDN_SELCHANGE = CDN_FIRST - 1;
  {$EXTERNALSYM CDN_FOLDERCHANGE}
  CDN_FOLDERCHANGE = CDN_FIRST - 2;
  {$EXTERNALSYM CDN_SHAREVIOLATION}
  CDN_SHAREVIOLATION = CDN_FIRST - 3;
  {$EXTERNALSYM CDN_HELP}
  CDN_HELP = CDN_FIRST - 4;
  {$EXTERNALSYM CDN_FILEOK}
  CDN_FILEOK = CDN_FIRST - 5;
  {$EXTERNALSYM CDN_TYPECHANGE}
  CDN_TYPECHANGE = CDN_FIRST - 6;
  {$EXTERNALSYM CDN_INCLUDEITEM}
  CDN_INCLUDEITEM = CDN_FIRST - 7;

  {$EXTERNALSYM CDM_FIRST}
  CDM_FIRST = WM_USER + 100;
  {$EXTERNALSYM CDM_LAST}
  CDM_LAST = WM_USER + 200;

{ Messages to query information from the Open or Save dialogs }

{ lParam = pointer to text buffer that gets filled in
  wParam = max number of characters of the text buffer (including NULL)
  return = < 0 if error; number of characters needed (including NULL) }

  {$EXTERNALSYM CDM_GETSPEC}
  CDM_GETSPEC = CDM_FIRST + 0;

{ lParam = pointer to text buffer that gets filled in
  wParam = max number of characters of the text buffer (including NULL)
  return = < 0 if error; number of characters needed (including NULL) }

  {$EXTERNALSYM CDM_GETFILEPATH}
  CDM_GETFILEPATH = CDM_FIRST + 1;

{ lParam = pointer to text buffer that gets filled in
  wParam = max number of characters of the text buffer (including NULL)
  return = < 0 if error; number of characters needed (including NULL) }

  {$EXTERNALSYM CDM_GETFOLDERPATH}
  CDM_GETFOLDERPATH = CDM_FIRST + 2;

{ lParam = pointer to ITEMIDLIST buffer that gets filled in
  wParam = size of the ITEMIDLIST buffer
  return = < 0 if error; length of buffer needed }

  {$EXTERNALSYM CDM_GETFOLDERIDLIST}
  CDM_GETFOLDERIDLIST = CDM_FIRST + 3;

{ lParam = pointer to a string
  wParam = ID of control to change
  return = not used }

  {$EXTERNALSYM CDM_SETCONTROLTEXT}
  CDM_SETCONTROLTEXT = CDM_FIRST + 4;

{ lParam = not used
  wParam = ID of control to change
  return = not used }

  {$EXTERNALSYM CDM_HIDECONTROL}
  CDM_HIDECONTROL = CDM_FIRST + 5;

{ lParam = pointer to default extension (no dot)
  wParam = not used
  return = not used }

  {$EXTERNALSYM CDM_SETDEFEXT}
  CDM_SETDEFEXT = CDM_FIRST + 6;

function GetOpenFileNameW(var OpenFile: TOpenFilenameW): Bool; stdcall;
function GetSaveFileNameW(var OpenFile: TOpenFilenameW): Bool; stdcall;
function GetFileTitleW(FileName: PWideChar; Title: PWideChar; TitleSize: Word): Smallint; stdcall;

implementation

const
  commdlg32 = 'comdlg32.dll';

function GetOpenFileNameW;      external commdlg32  name 'GetOpenFileNameW';
function GetSaveFileNameW;   external commdlg32  name 'GetSaveFileNameW';
function GetFileTitleW;      external commdlg32  name 'GetFileTitleW';

end.

