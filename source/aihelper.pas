unit aihelper;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, fphttpclient, fpjson, jsonparser, dbconnection;

type
  TAIResultCallback = procedure(SQL, Explanation, ErrorMsg: String) of object;

  TAIThread = class(TThread)
  private
    FApiKey: String;
    FModel: String;
    FPrompt: String;
    FSchema: String;
    FOnResult: TAIResultCallback;
    FSQL: String;
    FExplanation: String;
    FError: String;
    procedure FireResult;
  protected
    procedure Execute; override;
  public
    constructor Create(const AApiKey, AModel, APrompt, ASchema: String;
      AOnResult: TAIResultCallback);
  end;

function BuildSchemaContext(Connection: TDBConnection; Database: String): String;

implementation

const
  ANTHROPIC_URL = 'https://api.anthropic.com/v1/messages';
  ANTHROPIC_VERSION = '2023-06-01';

constructor TAIThread.Create(const AApiKey, AModel, APrompt, ASchema: String;
  AOnResult: TAIResultCallback);
begin
  inherited Create(False);
  FApiKey := AApiKey;
  FModel := AModel;
  FPrompt := APrompt;
  FSchema := ASchema;
  FOnResult := AOnResult;
  FreeOnTerminate := True;
end;


procedure TAIThread.FireResult;
begin
  if Assigned(FOnResult) then
    FOnResult(FSQL, FExplanation, FError);
end;


procedure TAIThread.Execute;
var
  Http: TFPHttpClient;
  RequestBody, ResponseBody: TStringStream;
  ReqObj, MsgObj: TJSONObject;
  MsgArr: TJSONArray;
  RespData: TJSONData;
  RespParser: TJSONParser;
  ContentArr: TJSONArray;
  ContentText: String;
  InnerParser: TJSONParser;
  InnerData: TJSONData;
  SystemPrompt: String;
begin
  FSQL := '';
  FExplanation := '';
  FError := '';

  SystemPrompt :=
    FSchema + #10 +
    'Respond ONLY with raw JSON (no markdown, no code blocks): {"sql":"...","explanation":"one sentence"}' + #10 +
    'Rules: use exact column/table names from the schema; ' +
    'use database-appropriate row limit syntax — ' +
    'MySQL/MariaDB/SQLite/PostgreSQL: append LIMIT 200; ' +
    'Oracle: append FETCH FIRST 200 ROWS ONLY (never use LIMIT); ' +
    'MS SQL Server: use TOP 200 after SELECT or OFFSET 0 ROWS FETCH NEXT 200 ROWS ONLY after ORDER BY; ' +
    'column aliases with spaces must be quoted with double quotes; ' +
    'never use DROP/TRUNCATE/ALTER unless explicitly asked.';

  ReqObj := TJSONObject.Create;
  try
    ReqObj.Strings['model'] := FModel;
    ReqObj.Integers['max_tokens'] := 1024;
    ReqObj.Strings['system'] := SystemPrompt;
    MsgArr := TJSONArray.Create;
    MsgObj := TJSONObject.Create;
    MsgObj.Strings['role'] := 'user';
    MsgObj.Strings['content'] := FPrompt;
    MsgArr.Add(MsgObj);
    ReqObj.Arrays['messages'] := MsgArr;

    Http := TFPHttpClient.Create(nil);
    RequestBody := TStringStream.Create(ReqObj.AsJSON, TEncoding.UTF8);
    ResponseBody := TStringStream.Create('', TEncoding.UTF8);
    try
      Http.AddHeader('Content-Type', 'application/json');
      Http.AddHeader('x-api-key', FApiKey);
      Http.AddHeader('anthropic-version', ANTHROPIC_VERSION);
      Http.IOTimeout := 60000;
      Http.AllowRedirect := True;
      try
        Http.RequestBody := RequestBody;
        Http.Post(ANTHROPIC_URL, ResponseBody);
        if Http.ResponseStatusCode <> 200 then begin
          FError := Format('HTTP %d: %s', [Http.ResponseStatusCode, ResponseBody.DataString]);
          Synchronize(FireResult);
          Exit;
        end;
      except
        on E: Exception do begin
          FError := E.Message;
          Synchronize(FireResult);
          Exit;
        end;
      end;

      // Parse Anthropic envelope: {"content":[{"type":"text","text":"..."}],...}
      ContentText := '';
      RespParser := TJSONParser.Create(ResponseBody.DataString, []);
      try
        RespData := RespParser.Parse;
        try
          ContentArr := RespData.GetPath('content') as TJSONArray;
          if Assigned(ContentArr) and (ContentArr.Count > 0) then
            ContentText := (ContentArr.Items[0] as TJSONObject).Strings['text']
          else
            FError := 'Empty response from API';
        finally
          RespData.Free;
        end;
      finally
        RespParser.Free;
      end;

      if FError <> '' then begin
        Synchronize(FireResult);
        Exit;
      end;

      // Strip possible markdown fences that the model might add anyway
      ContentText := Trim(ContentText);
      if ContentText.StartsWith('```') then begin
        ContentText := ContentText.Substring(ContentText.IndexOf(#10) + 1);
        if ContentText.Contains('```') then
          ContentText := ContentText.Substring(0, ContentText.LastIndexOf('`') - 2);
        ContentText := Trim(ContentText);
      end;

      // Parse the inner {"sql":"...","explanation":"..."}
      InnerParser := TJSONParser.Create(ContentText, []);
      try
        try
          InnerData := InnerParser.Parse;
          try
            FSQL := InnerData.GetPath('sql').AsString;
            FExplanation := InnerData.GetPath('explanation').AsString;
          finally
            InnerData.Free;
          end;
        except
          on E: Exception do
            FError := 'Failed to parse AI response: ' + E.Message + #10 + ContentText;
        end;
      finally
        InnerParser.Free;
      end;

    finally
      Http.Free;
      RequestBody.Free;
      ResponseBody.Free;
    end;
  finally
    ReqObj.Free;
  end;

  Synchronize(FireResult);
end;


function BuildSchemaContext(Connection: TDBConnection; Database: String): String;
var
  Objects: TDBObjectList;
  Obj: TDBObject;
  Columns: TTableColumnList;
  Col: TTableColumn;
  Lines: TStringList;
  i: Integer;
begin
  Lines := TStringList.Create;
  try
    Lines.Add('DATABASE: ' + Database);
    Lines.Add('DATABASE_TYPE: ' + Connection.Parameters.NetTypeName(True));
    Lines.Add('SCHEMA:');

    if not Connection.DbObjectsCached(Database) then
      Connection.GetDbObjects(Database);

    Objects := Connection.GetDbObjects(Database);
    for i := 0 to Objects.Count - 1 do begin
      Obj := Objects[i];
      if not (Obj.NodeType in [lntTable, lntView]) then
        Continue;
      Lines.Add('TABLE ' + Obj.Name + ':');
      try
        Columns := Obj.TableColumns;
        try
          for Col in Columns do begin
            Lines.Add('  ' + Col.Name + ' ' + Col.DataType.Name +
              IfThen(Col.AllowNull, ' NULL', ' NOT NULL')
            );
          end;
        finally
          Columns.Free;
        end;
      except
        // Skip tables where column info fails
      end;
    end;

    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

end.
