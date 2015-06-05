# Introduction #

it's easy to add icons from exe/dll resource to another exe/dll, but hard to add from raw icon files, I've found the way to do it


# Details #

there're 2 structures for Icon: normal icon data, and group icon package, both Windows icon raw file and resource support it.

here's definitions in Object Pascal:
// raw icon data
> ICONDIRENTRY = packed record
> > bWidth: BYTE;
> > bHeight: BYTE;
> > bColorCount: BYTE;
> > bReserved: BYTE;
> > wPlanes: WORD;
> > wBitCount: WORD;
> > dwBytesInRes: DWORD;
> > dwImageOffset: DWORD;

> end;

// raw group icon package
> ICONDIR = packed record
> > idReserved: WORD;
> > idType: WORD;
> > idCount: WORD;

> end;

// icon data for UpdateResource
> GRPICONDIRENTRY = packed record
> > bWidth: BYTE;
> > bHeight: BYTE;
> > bColorCount: BYTE;
> > bReserved: BYTE;
> > wPlanes: WORD;
> > wBitCount: WORD;
> > dwBytesInRes: DWORD;
> > nID: WORD;

> end;

// group icon for UpdateResource
> GRPICONDIR = packed record
> > idReserved: WORD;
> > idType: WORD;
> > idCount: WORD;
> > idEntries: GRPICONDIRENTRY;

> end;