unit dbstructures.oracle;

{$mode delphi}{$H+}

interface

uses
  dbstructures, SysUtils;

const
  // OCI return codes
  OCI_SUCCESS            = 0;
  OCI_SUCCESS_WITH_INFO  = 1;
  OCI_NO_DATA            = 100;
  OCI_ERROR              = -1;
  OCI_INVALID_HANDLE     = -2;
  OCI_NEED_DATA          = 99;

  // OCI handle types
  OCI_HTYPE_ENV      = 1;
  OCI_HTYPE_ERROR    = 2;
  OCI_HTYPE_SVCCTX   = 3;
  OCI_HTYPE_STMT     = 4;
  OCI_HTYPE_BIND     = 5;
  OCI_HTYPE_DEFINE   = 6;
  OCI_HTYPE_DESCRIBE = 7;
  OCI_HTYPE_SERVER   = 8;
  OCI_HTYPE_SESSION  = 9;

  // OCI descriptor types
  OCI_DTYPE_PARAM    = 53;

  // OCI modes
  OCI_DEFAULT            = 0;
  OCI_THREADED           = $00000001;
  OCI_OBJECT             = $00000002;
  OCI_CRED_RDBMS         = 1;
  OCI_CRED_EXT           = 2;
  OCI_SYSDBA             = 2;
  OCI_SYSOPER            = 4;
  OCI_FETCH_NEXT         = $00000002;
  OCI_COMMIT_ON_SUCCESS  = $00000020;
  OCI_DESCRIBE_ONLY      = $00000010;
  OCI_STMT_CACHE_NO_REUSE = $00000100;

  // OCI attribute constants
  OCI_ATTR_DATA_SIZE     = 1;
  OCI_ATTR_DATA_TYPE     = 2;
  OCI_ATTR_NAME          = 4;
  OCI_ATTR_PRECISION     = 5;
  OCI_ATTR_SCALE         = 6;
  OCI_ATTR_IS_NULL       = 7;
  OCI_ATTR_SERVER        = 6;
  OCI_ATTR_SESSION       = 7;
  OCI_ATTR_ROW_COUNT     = 9;
  OCI_ATTR_PARAM_COUNT   = 18;
  OCI_ATTR_USERNAME      = 22;
  OCI_ATTR_PASSWORD      = 23;
  OCI_ATTR_STMT_TYPE     = 24;

  // OCI statement types
  OCI_STMT_SELECT        = 1;
  OCI_STMT_UPDATE        = 2;
  OCI_STMT_DELETE        = 3;
  OCI_STMT_INSERT        = 4;
  OCI_STMT_CREATE        = 5;
  OCI_STMT_DROP          = 6;
  OCI_STMT_ALTER         = 7;
  OCI_STMT_BEGIN         = 8;
  OCI_STMT_DECLARE       = 9;

  // SQLT type codes (subset used for fetching as strings)
  SQLT_CHR           = 1;    // VARCHAR2
  SQLT_NUM           = 2;    // NUMBER
  SQLT_INT           = 3;    // INTEGER
  SQLT_FLT           = 4;    // FLOAT
  SQLT_STR           = 5;    // null-terminated string
  SQLT_LNG           = 8;    // LONG
  SQLT_DAT           = 12;   // DATE
  SQLT_BIN           = 23;   // RAW / BINARY
  SQLT_LBI           = 24;   // LONG RAW
  SQLT_AFC           = 96;   // CHAR
  SQLT_CLOB          = 112;  // CLOB
  SQLT_BLOB          = 113;  // BLOB
  SQLT_TIMESTAMP     = 187;  // TIMESTAMP
  SQLT_TIMESTAMP_TZ  = 188;  // TIMESTAMP WITH TIME ZONE
  SQLT_INTERVAL_YM   = 189;  // INTERVAL YEAR TO MONTH
  SQLT_INTERVAL_DS   = 190;  // INTERVAL DAY TO SECOND
  SQLT_TIMESTAMP_LTZ = 232;  // TIMESTAMP WITH LOCAL TIME ZONE

  // Max fetch buffer per column (chars)
  OCI_MAX_COL_SIZE   = 4096;

type
  // Opaque OCI handle pointer types
  POCIEnv      = Pointer;
  POCIError    = Pointer;
  POCIServer   = Pointer;
  POCISvcCtx   = Pointer;
  POCISession  = Pointer;
  POCIStmt     = Pointer;
  POCIDefine   = Pointer;
  POCIParam    = Pointer;
  PPOCIEnv     = ^POCIEnv;
  PPOCIError   = ^POCIError;
  PPOCIServer  = ^POCIServer;
  PPOCISvcCtx  = ^POCISvcCtx;
  PPOCISession = ^POCISession;
  PPOCIStmt    = ^POCIStmt;
  PPOCIDefine  = ^POCIDefine;
  PPOCIParam   = ^POCIParam;

  TOracleLib = class(TDbLib)
    OCIEnvCreate:    function(envhpp: PPOCIEnv; mode: Cardinal;
                       ctxp, malocfp, ralocfp, mfreefp: Pointer;
                       xtramemsz: NativeUInt; usrmempp: PPointer): Integer; cdecl;
    OCIHandleAlloc:  function(parenth: Pointer; hndlpp: PPointer;
                       htype, xtramem_sz: Cardinal;
                       usrmempp: PPointer): Integer; cdecl;
    OCIHandleFree:   function(hndlp: Pointer; htype: Cardinal): Integer; cdecl;
    OCIDescriptorFree: function(descp: Pointer; htype: Cardinal): Integer; cdecl;
    OCIServerAttach: function(srvhp, errhp: Pointer;
                       dblink: PAnsiChar; dblink_len: Integer;
                       mode: Cardinal): Integer; cdecl;
    OCIServerDetach: function(srvhp, errhp: Pointer;
                       mode: Cardinal): Integer; cdecl;
    OCISessionBegin: function(svchp, errhp, usrhp: Pointer;
                       credt, mode: Cardinal): Integer; cdecl;
    OCISessionEnd:   function(svchp, errhp, usrhp: Pointer;
                       mode: Cardinal): Integer; cdecl;
    OCIAttrSet:      function(trgthndlp: Pointer; trghndltyp: Cardinal;
                       attributep: Pointer; size: Cardinal;
                       attrtype: Cardinal; errhp: Pointer): Integer; cdecl;
    OCIAttrGet:      function(trgthndlp: Pointer; trghndltyp: Cardinal;
                       attributep: Pointer; sizep: PCardinal;
                       attrtype: Cardinal; errhp: Pointer): Integer; cdecl;
    OCIStmtPrepare2: function(svchp: Pointer; stmthpp: PPOCIStmt;
                       errhp: Pointer; stmttext: PAnsiChar;
                       stmt_len, keylen: Cardinal;
                       key: PAnsiChar;
                       language, mode: Cardinal): Integer; cdecl;
    OCIStmtRelease:  function(stmthp, errhp: Pointer;
                       key: PAnsiChar; keylen: Cardinal;
                       mode: Cardinal): Integer; cdecl;
    OCIStmtExecute:  function(svchp, stmthp, errhp: Pointer;
                       iters, rowoff: Cardinal;
                       snap_in, snap_out: Pointer;
                       mode: Cardinal): Integer; cdecl;
    OCIStmtFetch2:   function(stmthp, errhp: Pointer;
                       nrows: Cardinal; orientation: Word;
                       fetchOffset: Integer; mode: Cardinal): Integer; cdecl;
    OCIParamGet:     function(hndlp: Pointer; htype: Cardinal;
                       errhp: Pointer; parmdpp: PPointer;
                       pos: Cardinal): Integer; cdecl;
    OCIDefineByPos:  function(stmthp, defnpp, errhp: Pointer;
                       position: Cardinal; valuep: Pointer;
                       value_sz: Integer; dty: Word;
                       indp: PSmallInt; rlenp, rcodep: PWord;
                       mode: Cardinal): Integer; cdecl;
    OCIErrorGet:     function(hndlp: Pointer; recordno: Cardinal;
                       sqlstate: PAnsiChar; errcodep: PInteger;
                       bufp: PAnsiChar; bufsiz: Cardinal;
                       htype: Cardinal): Integer; cdecl;
    OCIClientVersion: procedure(major_version, minor_version,
                       update_num, patch_num,
                       port_update_num: PInteger); cdecl;
    OCIPing:          function(svchp, errhp: Pointer;
                       mode: Cardinal): Integer; cdecl;
  protected
    procedure AssignProcedures; override;
  public
    constructor Create(UsedDllFile, HintDefaultDll: String); override;
    destructor Destroy; override;
  end;

  TOracleProvider = class(TSqlProvider)
  public
    function GetSql(AId: TQueryId): string; override;
  end;

var
  OracleDatatypes: Array[0..24] of TDBDatatype = (
    (Index: dbdtUnknown;     Name: 'UNKNOWN';             HasLength: False; Category: dtcOther),
    (Index: dbdtVarchar;     Name: 'VARCHAR2';            HasLength: True;  Category: dtcText),
    (Index: dbdtChar;        Name: 'CHAR';                HasLength: True;  Category: dtcText),
    (Index: dbdtNvarchar;    Name: 'NVARCHAR2';           HasLength: True;  Category: dtcText),
    (Index: dbdtText;        Name: 'CLOB';                HasLength: False; Category: dtcText),
    (Index: dbdtText;        Name: 'NCLOB';               HasLength: False; Category: dtcText),
    (Index: dbdtText;        Name: 'LONG';                HasLength: False; Category: dtcText),
    (Index: dbdtInt;         Name: 'INTEGER';             HasLength: False; Category: dtcInteger),
    (Index: dbdtInt;         Name: 'NUMBER';              HasLength: True;  Category: dtcInteger),
    (Index: dbdtFloat;       Name: 'FLOAT';               HasLength: True;  Category: dtcReal),
    (Index: dbdtFloat;       Name: 'BINARY_FLOAT';        HasLength: False; Category: dtcReal),
    (Index: dbdtDouble;      Name: 'BINARY_DOUBLE';       HasLength: False; Category: dtcReal),
    (Index: dbdtDate;        Name: 'DATE';                HasLength: False; Category: dtcTemporal),
    (Index: dbdtDatetime;    Name: 'TIMESTAMP';           HasLength: True;  Category: dtcTemporal),
    (Index: dbdtDatetime;    Name: 'TIMESTAMP WITH TIME ZONE';       HasLength: True; Category: dtcTemporal),
    (Index: dbdtDatetime;    Name: 'TIMESTAMP WITH LOCAL TIME ZONE'; HasLength: True; Category: dtcTemporal),
    (Index: dbdtDate;        Name: 'INTERVAL YEAR TO MONTH'; HasLength: True; Category: dtcTemporal),
    (Index: dbdtDate;        Name: 'INTERVAL DAY TO SECOND'; HasLength: True; Category: dtcTemporal),
    (Index: dbdtBlob;        Name: 'BLOB';                HasLength: False; Category: dtcBinary),
    (Index: dbdtBlob;        Name: 'RAW';                 HasLength: True;  Category: dtcBinary),
    (Index: dbdtBlob;        Name: 'LONG RAW';            HasLength: False; Category: dtcBinary),
    (Index: dbdtBlob;        Name: 'BFILE';               HasLength: False; Category: dtcBinary),
    (Index: dbdtVarchar;     Name: 'ROWID';               HasLength: False; Category: dtcOther),
    (Index: dbdtVarchar;     Name: 'UROWID';              HasLength: True;  Category: dtcOther),
    (Index: dbdtVarchar;     Name: 'XMLTYPE';             HasLength: False; Category: dtcOther)
  );

implementation


procedure TOracleLib.AssignProcedures;
begin
  AssignProc(@OCIEnvCreate,     'OCIEnvCreate');
  AssignProc(@OCIHandleAlloc,   'OCIHandleAlloc');
  AssignProc(@OCIHandleFree,    'OCIHandleFree');
  AssignProc(@OCIDescriptorFree,'OCIDescriptorFree');
  AssignProc(@OCIServerAttach,  'OCIServerAttach');
  AssignProc(@OCIServerDetach,  'OCIServerDetach');
  AssignProc(@OCISessionBegin,  'OCISessionBegin');
  AssignProc(@OCISessionEnd,    'OCISessionEnd');
  AssignProc(@OCIAttrSet,       'OCIAttrSet');
  AssignProc(@OCIAttrGet,       'OCIAttrGet');
  AssignProc(@OCIStmtPrepare2,  'OCIStmtPrepare2');
  AssignProc(@OCIStmtRelease,   'OCIStmtRelease');
  AssignProc(@OCIStmtExecute,   'OCIStmtExecute');
  AssignProc(@OCIStmtFetch2,    'OCIStmtFetch2');
  AssignProc(@OCIParamGet,      'OCIParamGet');
  AssignProc(@OCIDefineByPos,   'OCIDefineByPos');
  AssignProc(@OCIErrorGet,      'OCIErrorGet');
  AssignProc(@OCIClientVersion, 'OCIClientVersion', False);
  AssignProc(@OCIPing,          'OCIPing', False);
end;


constructor TOracleLib.Create(UsedDllFile, HintDefaultDll: String);
begin
  inherited Create(UsedDllFile, HintDefaultDll);
end;

destructor TOracleLib.Destroy;
begin
  // Oracle Instant Client on Linux cannot safely be unloaded (dlclose) and
  // reloaded within the same process — the next OCIEnvCreate crashes.
  // Zero the handle so the parent destructor skips FreeLibrary, intentionally
  // keeping the library resident for the lifetime of the process.
  FHandle := 0;
  inherited;
end;


function TOracleProvider.GetSql(AId: TQueryId): string;
begin
  case AId of
    qDatabaseTable:     Result := 'ALL_USERS';
    qDatabaseTableId:   Result := 'USERNAME';
    qDatabaseDrop:      Result := 'DROP USER %s CASCADE';
    qEmptyTable:        Result := 'TRUNCATE TABLE %s';
    qRenameTable:       Result := 'ALTER TABLE %s RENAME TO %s';
    qFuncNow:           Result := 'SYSDATE';
    qFuncLength:        Result := 'LENGTH';
    qFuncCeil:          Result := 'CEIL';
    qFuncLeft:          Result := 'SUBSTR(%s, 1, %d)';
    qOrderAsc:          Result := 'ASC NULLS LAST';
    qOrderDesc:         Result := 'DESC NULLS LAST';
    qGetTableColumns:
      Result :=
        'SELECT COLUMN_NAME, DATA_TYPE, DATA_LENGTH, DATA_PRECISION, DATA_SCALE,' +
        ' NULLABLE, DATA_DEFAULT, COLUMN_ID' +
        ' FROM ALL_TAB_COLUMNS' +
        ' WHERE OWNER = %s AND TABLE_NAME = %s' +
        ' ORDER BY COLUMN_ID';
    qGetRowCountApprox:
      Result :=
        'SELECT NVL(NUM_ROWS, 0) FROM ALL_TABLES' +
        ' WHERE OWNER = :EscapedDatabase AND TABLE_NAME = :EscapedName';
    qUSEQuery:
      Result := 'ALTER SESSION SET CURRENT_SCHEMA = %s';
    else
      Result := inherited;
  end;
end;


end.
