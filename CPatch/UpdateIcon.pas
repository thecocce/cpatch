unit UpdateIcon;

interface

uses
  Windows;

function UpdateIconFromFile(const IconFile, ExeFile: PWideChar): Boolean;

implementation

type
  ICONDIRENTRY = packed record
    bWidth: BYTE;
    bHeight: BYTE;
    bColorCount: BYTE;
    bReserved: BYTE;
    wPlanes: WORD;
    wBitCount: WORD;
    dwBytesInRes: DWORD;
    dwImageOffset: DWORD;
  end;


  ICONDIR = packed record
    idReserved: WORD;
    idType: WORD;
    idCount: WORD;
  end;

  GRPICONDIRENTRY = packed record
    bWidth: BYTE;
    bHeight: BYTE;
    bColorCount: BYTE;
    bReserved: BYTE;
    wPlanes: WORD;
    wBitCount: WORD;
    dwBytesInRes: DWORD;
    nID: WORD;
  end;

  PGRPICONDIR = ^GRPICONDIR;
  GRPICONDIR = packed record
    idReserved: WORD;
    idType: WORD;
    idCount: WORD;
    idEntries: packed array [0..0] of GRPICONDIRENTRY;
  end;

  PEnumRec = ^EnumRec;
  EnumRec = packed record
    iconf, exef: PWideChar;
  end;

function enumproc(hModule: Cardinal; lpszType, lpszName: PWideChar; lParam: Integer): Boolean; stdcall;
var
  er: PEnumRec;
  i, hmod, hrsrc, hres, size: Cardinal;
  hUpdate: THandle;
  stGID: PGRPICONDIR;
begin
  result := false;
  er := PEnumRec(lParam);
  hmod := LoadLibraryW(er.iconf);
  hrsrc := FindResourceW(hmod, lpszName, lpszType);
  if hrsrc = 0 then
    exit;
  hres := LoadResource(hmod, hrsrc);
  size := SizeofResource(hmod, hrsrc);
  GetMem(stGID, size);
  Move(LockResource(hres)^, stGID^, size);
  hUpdate := BeginUpdateResourceW(er.exef, false);
  UpdateResourceW(hUpdate, lpszType, lpszName, 0, stGID, size);
  UnlockResource(hres);
  FreeResource(hrsrc);
  for i := 0 to stGID.idCount - 1 do
  begin
    hrsrc := FindResourceW(hmod, PWideChar(stGID.idEntries[i].nID), PWideChar(RT_ICON));
    if hrsrc = 0 then
      continue;
    hres := LoadResource(hmod, hrsrc);
    UpdateResourceW(hUpdate, PWideChar(RT_ICON), PWideChar(stGID.idEntries[i].nID), 0, LockResource(hres), SizeofResource(hmod, hrsrc));
    UnlockResource(hres);
    FreeResource(hrsrc);
  end;
  FreeMem(stGID);
  EndUpdateResourceW(hUpdate, false);
  FreeLibrary(hmod);
end;

function UpdateIconFromExeFile(const IconFile, ExeFile: PWideChar): Boolean;
var
  fm: Cardinal;
  er: EnumRec;
begin
  fm := LoadLibraryW(IconFile);
  er.iconf := IconFile;
  er.exef := ExeFile;
  EnumResourceNamesW(fm, PWideChar(RT_GROUP_ICON), @ enumproc, Integer(@er));
  EnumResourceNamesW(fm, PWideChar(RT_ICON), @ enumproc, Integer(@er));
  result := true;
end;

function UpdateIconFromIcoFile(const IconFile, ExeFile: PWideChar): Boolean;
var
  stID: ICONDIR;
  stIDE: array of ICONDIRENTRY;
  stGID: PGRPICONDIR;
  hFile, hUpdate: THANDLE;
  nSize, nGSize, dwReserved: DWORD;
  pIcon: PBYTE;
  i: Integer;
begin
  result := false;
  hFile := CreateFileW(IconFile, GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if hFile = INVALID_HANDLE_VALUE then
    exit;

  ZeroMemory(@stID, sizeof(ICONDIR));
  ReadFile(hFile, stID, sizeof(ICONDIR), dwReserved, nil);
  SetLength(stIDE, stID.idCount);
  ReadFile(hFile, stIDE[0], sizeof(ICONDIRENTRY) * stID.idCount, dwReserved, nil);

  nGSize := sizeof(GRPICONDIR) + sizeof(GRPICONDIRENTRY) * (stID.idCount - 1);
  GetMem(stGID, nGSize);
  stGID.idCount := stID.idCount;
  stGID.idReserved := 0;
  stGID.idType := 1;
  for i := 0 to stGID.idCount - 1 do
  begin
    Move(stIDE[i], stGID.idEntries[i], 12);
    stGID.idEntries[i].nID := i + 1;
  end;

  hUpdate := BeginUpdateResourceW(ExeFile, false);
  UpdateResourceW(hUpdate, MakeIntResourceW(RT_GROUP_ICON), MAKEINTRESOURCEW(1), 0, stGID, nGSize);
  for i := 0 to stGID.idCount - 1 do
  begin
    nSize := stIDE[i].dwBytesInRes;
    GetMem(pIcon, nSize);
    SetFilePointer(hFile, stIDE[i].dwImageOffset, nil, FILE_BEGIN);
    ReadFile(hFile, pIcon^, stIDE[i].dwBytesInRes, dwReserved, nil);
    UpdateResourceW(hUpdate, MakeIntResourceW(RT_ICON), MAKEINTRESOURCEW(1 + i), 0, pIcon, nSize);
    FreeMem(pIcon);
  end;
  EndUpdateResourceW(hUpdate, false);

  FreeMem(stGID);
  CloseHandle(hFile);
  result := true;
end;

function UpdateIconFromFile(const IconFile, ExeFile: PWideChar): Boolean;
var
  fh: THandle;
  m: Char;
  r: DWORD;
begin
  result := false;
  fh := CreateFileW(IconFile, GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if fh = INVALID_HANDLE_VALUE then
    exit;
  ReadFile(fh, m, 1, r, nil);
  CloseHandle(fh);
  if m < ' ' then
    result := UpdateIconFromIcoFile(IconFile, ExeFile)
  else
    result := UpdateIconFromExeFile(IconFile, ExeFile);
end;

end.

